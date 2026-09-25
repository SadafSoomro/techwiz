/**
 * MEMBER 5 - AI Fan Helper
 *
 * SRS reference:
 *   "5. AI Fan Helper - Users can interact with a simple AI-powered assistant
 *    that answers predefined fandom FAQs or uses a basic AI API to answer
 *    common questions."
 *
 * The assistant answers in three tiers, cheapest first:
 *
 *   1. STORE LOOKUP   - the question names a product / fandom in the catalogue,
 *                       so the answer is grounded in real product rows
 *                       (price, stock, rating, brand).
 *   2. FAQ ENGINE     - keyword + fuzzy token scoring over the `ai_faqs` table
 *                       (the "predefined fandom FAQs" of the SRS). This tier
 *                       works completely offline, which satisfies the
 *                       "offline access" non-functional requirement.
 *   3. EXTERNAL AI    - if AI_API_KEY / AI_API_URL are configured, anything the
 *                       FAQ engine cannot answer confidently is forwarded to an
 *                       OpenAI-compatible chat-completions endpoint.
 *
 * Every exchange is stored in `ai_chat_messages` so the chat history survives
 * a screen change or an app restart.
 */

import { all, get, run, asyncHandler, timeAgo } from "../database/dbhelpers.js";
import cache from "../database/cache.js";

// ---------------------------------------------------------------------------
// text helpers
// ---------------------------------------------------------------------------

const STOPWORDS = new Set([
  "the", "a", "an", "is", "are", "was", "were", "be", "been", "am",
  "do", "does", "did", "of", "to", "in", "on", "at", "for", "with",
  "and", "or", "but", "if", "then", "so", "as", "by", "from", "about",
  "what", "who", "whom", "whose", "which", "when", "where", "why", "how",
  "can", "could", "would", "should", "will", "shall", "may", "might",
  "i", "me", "my", "we", "our", "you", "your", "it", "its", "this", "that",
  "these", "those", "there", "here", "tell", "give", "please", "want",
  "need", "know", "get", "got", "some", "any", "much", "many", "very",
]);

/** Lowercase word tokens with punctuation and stopwords removed. */
function tokenize(text) {
  return String(text || "")
    .toLowerCase()
    .replace(/[^a-z0-9\s]/g, " ")
    .split(/\s+/)
    .filter((word) => word.length > 1 && !STOPWORDS.has(word));
}

/** Normalised Levenshtein similarity in the range 0..1. */
function similarity(a, b) {
  if (a === b) return 1;
  if (!a || !b) return 0;

  const rows = a.length + 1;
  const cols = b.length + 1;

  let previous = Array.from({ length: cols }, (_, i) => i);

  for (let i = 1; i < rows; i++) {
    const current = [i];
    for (let j = 1; j < cols; j++) {
      const cost = a[i - 1] === b[j - 1] ? 0 : 1;
      current[j] = Math.min(
        previous[j] + 1, // deletion
        current[j - 1] + 1, // insertion
        previous[j - 1] + cost // substitution
      );
    }
    previous = current;
  }

  const distance = previous[cols - 1];
  return 1 - distance / Math.max(a.length, b.length);
}

// ---------------------------------------------------------------------------
// tier 1 - catalogue lookup
// ---------------------------------------------------------------------------

/**
 * Tries to answer from the real product catalogue.
 * Handles "how much is the Luffy figure?", "is the Naruto box in stock?",
 * "show me One Piece merch" and similar.
 */
async function answerFromCatalogue(message) {
  const tokens = tokenize(message);
  if (!tokens.length) return null;

  const priceIntent = /\b(price|cost|how much|expensive|cheap|discount|deal|sale|off)\b/i.test(
    message
  );
  const stockIntent = /\b(stock|available|availability|left|sold out|in stock)\b/i.test(
    message
  );

  // Build a scoring pass over the catalogue using the meaningful tokens.
  const rows = await all(
    `SELECT id, name, sku, category, fandom, brand, price, old_price,
            discount_percent, currency, stock, rating, rating_count, is_digital,
            description
       FROM products WHERE status = 'active'`
  );

  let best = null;
  let bestScore = 0;

  for (const row of rows) {
    const haystack = tokenize(
      `${row.name} ${row.fandom || ""} ${row.category} ${row.brand || ""}`
    );

    let score = 0;
    for (const token of tokens) {
      if (haystack.includes(token)) {
        score += 3;
      } else if (haystack.some((word) => similarity(word, token) >= 0.82)) {
        score += 2;
      }
    }

    // A fandom or product-name hit is a stronger signal than a category word.
    if (row.fandom && tokens.some((t) => similarity(row.fandom.toLowerCase(), t) >= 0.9)) {
      score += 2;
    }

    if (score > bestScore) {
      bestScore = score;
      best = row;
    }
  }

  // Needs a reasonably confident match before we answer from the catalogue.
  const confident = bestScore >= 6 || (bestScore >= 4 && (priceIntent || stockIntent));
  if (!best || !confident) return null;

  const price = `$${Number(best.price).toFixed(2)}`;
  const wasPrice =
    best.old_price && best.old_price > best.price
      ? ` (was $${Number(best.old_price).toFixed(2)}, ${best.discount_percent}% off)`
      : "";
  const stockLine = best.is_digital
    ? "It is a digital download, so it is always available."
    : best.stock > 0
    ? `We have ${best.stock} in stock.`
    : "It is currently out of stock - add it to your wishlist and we will alert you when it returns.";

  let reply;

  if (stockIntent && !priceIntent) {
    reply = `${best.name} - ${stockLine}`;
  } else {
    reply = `${best.name} is ${price}${wasPrice}. ${stockLine}`;
  }

  if (best.description) {
    const short = best.description.split(". ")[0];
    reply += `\n\n${short}.`;
  }

  reply += `\n\nFound in the ${best.category} category${best.fandom ? ` under ${best.fandom}` : ""}. Rated ${Number(best.rating).toFixed(1)}/5 from ${best.rating_count} reviews.`;

  return {
    reply,
    topic: best.fandom || best.category,
    source: "catalogue",
    image_url: null,
    product: {
      id: best.id,
      name: best.name,
      price: best.price,
      currency: best.currency,
      image_url: `/api/shop/products/${best.id}`,
    },
  };
}

// ---------------------------------------------------------------------------
// tier 2 - FAQ engine
// ---------------------------------------------------------------------------

/**
 * Scores every FAQ row against the question.
 * Keyword hits carry the most weight, question-token overlap less, and
 * fuzzy matches least - so an exact keyword always wins.
 */
async function answerFromFaqs(message) {
  const faqs = await all(
    `SELECT id, question, answer, keywords, topic, image_url FROM ai_faqs`
  );
  if (!faqs.length) return null;

  const lower = String(message || "").toLowerCase();
  const tokens = tokenize(message);

  let best = null;
  let bestScore = 0;

  for (const faq of faqs) {
    let score = 0;

    // ---- keyword hits (the strongest signal) ----
    const keywords = String(faq.keywords || "")
      .split(",")
      .map((k) => k.trim().toLowerCase())
      .filter(Boolean);

    for (const keyword of keywords) {
      if (!keyword) continue;
      if (keyword.includes(" ")) {
        // multi-word keyword -> must appear as a phrase
        if (lower.includes(keyword)) score += 6;
      } else if (new RegExp(`\\b${keyword}\\b`, "i").test(lower)) {
        score += 3;
      } else if (tokens.some((t) => similarity(t, keyword) >= 0.85)) {
        score += 1;
      }
    }

    // ---- overlap with the stored question ----
    const questionTokens = tokenize(faq.question);
    for (const token of tokens) {
      if (questionTokens.includes(token)) score += 2;
      else if (questionTokens.some((q) => similarity(q, token) >= 0.82)) score += 1;
    }

    // ---- topic mentioned directly ----
    if (faq.topic && lower.includes(faq.topic.toLowerCase())) score += 2;

    if (score > bestScore) {
      bestScore = score;
      best = faq;
    }
  }

  if (!best || bestScore < 4) return null;

  return {
    reply: best.answer,
    topic: best.topic,
    source: "faq",
    image_url: best.image_url,
    faq_id: best.id,
  };
}

// ---------------------------------------------------------------------------
// tier 3 - external AI API (optional)
// ---------------------------------------------------------------------------

/** True when an OpenAI-compatible endpoint has been configured. */
export function isExternalAiConfigured() {
  return !!(process.env.AI_API_URL && process.env.AI_API_KEY);
}

const AI_SYSTEM_PROMPT = `You are the "AI Fan Helper" inside FANDOM VERSE Pocket Edition, an app for anime, manga, comics, gaming and pop-culture fans.

Rules:
- Answer in a friendly, concise way (2-5 sentences unless the user asks for a list).
- You cover: fandom lore and characters, anime/manga recommendations, cosplay tips, merchandise care, and how to use the Fandom Verse store (catalog, wishlist, cart, simulated checkout, orders) and events.
- The store checkout is simulated: no real payment or delivery happens. Never promise shipping or real payment.
- If you do not know something, say so plainly and suggest what to explore inside the app.
- Never invent product prices. Ask the user to check the Shop screen if unsure.`;

/**
 * Calls the configured AI endpoint. Returns null when it is not configured or
 * when the call fails, so the caller can fall back to the FAQ engine.
 */
async function answerFromExternalAi(message, history = []) {
  if (!isExternalAiConfigured()) return null;

  const url = process.env.AI_API_URL;
  const model = process.env.AI_MODEL || "gpt-4o-mini";

  const messages = [
    { role: "system", content: AI_SYSTEM_PROMPT },
    // Keep the last few turns so follow-up questions keep their context.
    ...history.slice(-6).map((entry) => ({
      role: entry.sender === "user" ? "user" : "assistant",
      content: String(entry.message || "").slice(0, 1500),
    })),
    { role: "user", content: String(message).slice(0, 1500) },
  ];

  try {
    const response = await fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${process.env.AI_API_KEY}`,
      },
      body: JSON.stringify({
        model,
        messages,
        temperature: 0.7,
        max_tokens: 400,
      }),
      signal: AbortSignal.timeout(15000),
    });

    if (!response.ok) {
      console.error("[AI Fan Helper] upstream error", response.status);
      return null;
    }

    const json = await response.json();
    const reply =
      json?.choices?.[0]?.message?.content || json?.reply || json?.message || null;

    if (!reply || typeof reply !== "string") return null;

    return { reply: reply.trim(), topic: "AI Assistant", source: "ai_api" };
  } catch (error) {
    console.error("[AI Fan Helper] request failed:", error.message);
    return null;
  }
}

// ---------------------------------------------------------------------------
// small talk + fallback
// ---------------------------------------------------------------------------

const GREETINGS = ["hi", "hello", "hey", "salam", "assalam", "aoa", "yo", "hola"];

function smallTalk(message) {
  const lower = String(message || "").toLowerCase().trim();

  if (GREETINGS.includes(lower) || /^(hi|hello|hey)\b/.test(lower)) {
    return {
      reply:
        "Hi! I am your Fandom AI assistant. Ask me about a fandom, a character, anime recommendations, cosplay tips, or anything about the Fandom Verse shop - I can check prices and stock for you too.",
      topic: "Greeting",
      source: "smalltalk",
    };
  }

  if (/\b(thanks|thank you|shukriya|thx)\b/i.test(lower)) {
    return {
      reply:
        "Happy to help! Anything else you want to know about your fandoms or the store?",
      topic: "Greeting",
      source: "smalltalk",
    };
  }

  if (/\b(bye|goodbye|see you)\b/i.test(lower)) {
    return {
      reply: "See you around, fan! Come back any time you need a hand.",
      topic: "Greeting",
      source: "smalltalk",
    };
  }

  return null;
}

function fallbackReply() {
  return {
    reply:
      "I am not sure about that one yet. I am strongest on fandom lore and characters, anime and manga recommendations, cosplay and figure care, and anything about the Fandom Verse shop - prices, stock, wishlist, cart and orders.\n\nTry asking something like \"Who is Luffy?\", \"Suggestions for anime?\" or \"How do I care for my figure?\".",
    topic: "Unknown",
    source: "fallback",
  };
}

// ---------------------------------------------------------------------------
// routes
// ---------------------------------------------------------------------------

/** GET /api/ai/suggestions -> chips shown under the welcome message */
export const getSuggestions = asyncHandler(async (req, res) => {
  const cached = await cache.get("ai:suggestions");
  if (cached) return res.json({ success: true, ...cached, cached: true });

  // Prefer a hand-picked set that mirrors the design board, then top up with
  // real questions from the knowledge base.
  const preferred = [
    "Who is Luffy?",
    "Suggestions for anime?",
    "How do I care for my figure?",
    "How does the cart and checkout work?",
  ];

  const rows = await all(
    `SELECT question, topic FROM ai_faqs
      WHERE question IN (${preferred.map(() => "?").join(", ")})`,
    preferred
  );

  const byQuestion = new Map(rows.map((row) => [row.question, row]));
  const suggestions = preferred
    .filter((question) => byQuestion.has(question))
    .map((question) => ({
      question,
      topic: byQuestion.get(question).topic,
    }));

  if (suggestions.length < 6) {
    const extra = await all(
      `SELECT question, topic FROM ai_faqs
        WHERE question NOT IN (${preferred.map(() => "?").join(", ")})
        ORDER BY id ASC LIMIT ?`,
      [...preferred, 6 - suggestions.length]
    );
    suggestions.push(...extra);
  }

  const topics = await all(
    `SELECT topic, COUNT(*) AS count FROM ai_faqs
      WHERE topic IS NOT NULL
      GROUP BY topic ORDER BY count DESC`
  );

  const payload = {
    suggestions,
    topics,
    greeting:
      "Hi! I'm your Fandom AI assistant. How can I help you?",
    external_ai_enabled: isExternalAiConfigured(),
  };

  await cache.set("ai:suggestions", payload, 300);
  res.json({ success: true, ...payload });
});

/**
 * POST /api/ai/chat
 * Body: { message }
 * Optional auth - the chat works signed out, but history is only saved
 * for a signed-in user.
 */
export const chat = asyncHandler(async (req, res) => {
  const message = String(req.body?.message || "").trim();

  if (!message) {
    return res
      .status(400)
      .json({ success: false, message: "Please type a question first" });
  }
  if (message.length > 600) {
    return res
      .status(400)
      .json({ success: false, message: "Please keep your question under 600 characters" });
  }

  const userId = req.user?.id ?? null;

  // Recent turns, used both for external-AI context and for the reply metadata.
  let history = [];
  if (userId) {
    history = await all(
      `SELECT sender, message FROM ai_chat_messages
        WHERE user_id = ? ORDER BY id DESC LIMIT 8`,
      [userId]
    );
    history.reverse();
  }

  // ---- tiers 1 + 2: catalogue lookup and the predefined FAQs ----
  // Both are cheap and local, so we score them and then pick the better fit.
  // A question that clearly asks about the store (price, stock, buying) goes
  // to the catalogue; a lore question goes to the FAQ engine; whichever has an
  // answer is used as a fallback for the other.
  const wantsStoreInfo =
    /\b(price|cost|how much|expensive|cheap|discount|deal|sale|off|stock|available|availability|in stock|sold out|buy|purchase|order)\b/i.test(
      message
    );

  const [catalogueAnswer, faqAnswer] = await Promise.all([
    answerFromCatalogue(message),
    answerFromFaqs(message),
  ]);

  let answer = wantsStoreInfo
    ? catalogueAnswer || faqAnswer
    : faqAnswer || catalogueAnswer;

  // ---- tier 3: external AI ----
  if (!answer) answer = await answerFromExternalAi(message, history);

  // ---- small talk, then fallback ----
  if (!answer) answer = smallTalk(message);
  if (!answer) answer = fallbackReply();

  if (userId) {
    await run(
      `INSERT INTO ai_chat_messages (user_id, sender, message, topic, source)
       VALUES (?, 'user', ?, NULL, NULL)`,
      [userId, message]
    );
    await run(
      `INSERT INTO ai_chat_messages (user_id, sender, message, topic, source)
       VALUES (?, 'ai', ?, ?, ?)`,
      [userId, answer.reply, answer.topic || null, answer.source || null]
    );
  }

  // Follow-up chips: other FAQs in the same topic keep the conversation going.
  let followUps = [];
  if (answer.topic && answer.source === "faq") {
    followUps = await all(
      `SELECT question FROM ai_faqs
        WHERE topic = ? AND question != ?
        ORDER BY RANDOM() LIMIT 3`,
      [answer.topic, message]
    );
  } else if (answer.source === "fallback") {
    followUps = await all(`SELECT question FROM ai_faqs ORDER BY RANDOM() LIMIT 3`);
  }

  res.json({
    success: true,
    reply: answer.reply,
    topic: answer.topic || null,
    source: answer.source || "faq",
    image_url: answer.image_url || null,
    product: answer.product || null,
    answered_at: new Date().toISOString().slice(0, 19).replace("T", " "),
    follow_ups: followUps.map((row) => row.question),
    history_saved: !!userId,
  });
});

/** GET /api/ai/history -> previous conversation (requires auth) */
export const getChatHistory = asyncHandler(async (req, res) => {
  const limit = Math.min(parseInt(req.query.limit, 10) || 50, 200);

  const rows = await all(
    `SELECT id, sender, message, topic, source, created_at
       FROM ai_chat_messages
      WHERE user_id = ?
      ORDER BY id DESC
      LIMIT ?`,
    [req.user.id, limit]
  );

  rows.reverse();

  res.json({
    success: true,
    messages: rows.map((row) => ({
      ...row,
      created_ago: timeAgo(row.created_at),
    })),
    count: rows.length,
  });
});

/** DELETE /api/ai/history -> clear the conversation */
export const clearChatHistory = asyncHandler(async (req, res) => {
  await run(`DELETE FROM ai_chat_messages WHERE user_id = ?`, [req.user.id]);
  res.json({ success: true, message: "Chat history cleared" });
});

/** GET /api/ai/topics -> knowledge base topics with counts */
export const getTopics = asyncHandler(async (req, res) => {
  const topics = await all(
    `SELECT topic, COUNT(*) AS count FROM ai_faqs
      WHERE topic IS NOT NULL GROUP BY topic ORDER BY count DESC`
  );

  res.json({
    success: true,
    topics,
    total_faqs: topics.reduce((sum, topic) => sum + topic.count, 0),
    external_ai_enabled: isExternalAiConfigured(),
  });
});

export default {
  getSuggestions,
  chat,
  getChatHistory,
  clearChatHistory,
  getTopics,
  isExternalAiConfigured,
};
