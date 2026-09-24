/**
 * MEMBER 5 - Merchandise Store + AI Fan Helper
 * API smoke test.
 *
 * Run the server first, then:
 *    node tests/shop_api_test.js
 *
 * Exercises every /api/shop and /api/ai endpoint and writes
 * tests/shop_report.txt ("Test Data Used in the Project" evidence for the
 * SRS deliverables).
 *
 * NOTE: the checkout test creates a real (simulated) order and therefore
 * empties the demo cart. It re-adds the items afterwards so the app still
 * has cart data for a demo.
 */

import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const BASE = process.env.API_BASE || "http://localhost:5000/api";
const EMAIL = process.env.DEMO_EMAIL || "emma@fandomverse.com";
const PASSWORD = process.env.DEMO_PASSWORD || "Fandom@123";

const out = [];
const summary = [];
let token = "";
let passed = 0;
let failed = 0;

function check(condition, label) {
  if (condition) {
    passed++;
  } else {
    failed++;
    summary.push(`  !! FAILED: ${label}`);
  }
  return condition;
}

function log(label, result, pick) {
  summary.push(`${result.status} ${label}`);
  out.push(`\n--- ${label}  [HTTP ${result.status}] ---`);
  const value = pick ? pick(result.json) : result.json;
  out.push(JSON.stringify(value, null, 1));
}

async function hit(method, endpoint, body, withAuth = true) {
  try {
    const res = await fetch(`${BASE}${endpoint}`, {
      method,
      headers: {
        "Content-Type": "application/json",
        ...(withAuth && token ? { Authorization: `Bearer ${token}` } : {}),
      },
      body: body ? JSON.stringify(body) : undefined,
    });
    const json = await res.json().catch(() => ({}));
    return { status: res.status, json };
  } catch (error) {
    return { status: 0, json: { error: error.message } };
  }
}

const productLine = (p) =>
  `${p.name} | ${p.category} | ${p.fandom} | $${p.price}` +
  (p.has_discount ? ` (was $${p.old_price}, -${p.discount_percent}%)` : "") +
  ` | stock ${p.stock} | ${p.rating}/5`;

const cartLine = (item) =>
  `${item.name} x${item.quantity} @ $${item.price} = $${item.line_total}`;

const orderLine = (order) =>
  `${order.order_code} | ${order.item_count} item(s) | total $${order.total} | ${order.status}`;

async function main() {
  // =====================================================================
  // 0. health + login
  // =====================================================================
  log("GET /health", await hit("GET", "/health", null, false));

  const login = await hit(
    "POST",
    "/auth/login",
    { email: EMAIL, password: PASSWORD },
    false
  );
  token = login.json.token || "";
  log("POST /auth/login", login, (j) => ({ message: j.message, hasToken: !!j.token }));
  check(!!token, "login returned a JWT token");

  // =====================================================================
  // 1. SHOP OVERVIEW
  // =====================================================================
  const overview = await hit("GET", "/shop/overview");
  log("GET /shop/overview", overview, (j) => ({
    stats: j.stats,
    categories: (j.categories || []).map((c) => `${c.name} (${c.product_count})`),
    featured: (j.featured || []).map((p) => p.name),
    deals: (j.deals || []).map((p) => `${p.name} -${p.discount_percent}%`),
    shipping: j.shipping,
    promo_codes: (j.promo_codes || []).map((p) => p.code),
  }));
  check(overview.status === 200, "GET /shop/overview returns 200");
  check((overview.json.stats?.total_products || 0) > 0, "catalogue has products");
  check((overview.json.categories || []).length === 5, "5 product categories");

  // =====================================================================
  // 2. CATEGORIES + FANDOMS
  // =====================================================================
  log("GET /shop/categories", await hit("GET", "/shop/categories"), (j) =>
    (j.categories || []).map((c) => `${c.name} | ${c.product_count} products | from $${c.min_price}`)
  );

  log("GET /shop/fandoms", await hit("GET", "/shop/fandoms"), (j) =>
    (j.fandoms || []).map((f) => `${f.name} (${f.product_count})`)
  );

  // =====================================================================
  // 3. CATALOGUE + FILTERS + PRICE SORTING  (SRS requirement)
  // =====================================================================
  const all = await hit("GET", "/shop/products?limit=100");
  log("GET /shop/products", all, (j) => ({
    total: j.total,
    products: (j.products || []).map(productLine),
  }));
  check((all.json.products || []).length > 0, "products endpoint returns rows");

  const cheap = await hit("GET", "/shop/products?sort=price_low&limit=5");
  log("GET /shop/products?sort=price_low", cheap, (j) =>
    (j.products || []).map((p) => `$${p.price} ${p.name}`)
  );
  const cheapPrices = (cheap.json.products || []).map((p) => p.price);
  check(
    cheapPrices.every((price, i) => i === 0 || cheapPrices[i - 1] <= price),
    "price_low sorting is ascending"
  );

  const expensive = await hit("GET", "/shop/products?sort=price_high&limit=5");
  log("GET /shop/products?sort=price_high", expensive, (j) =>
    (j.products || []).map((p) => `$${p.price} ${p.name}`)
  );
  const expPrices = (expensive.json.products || []).map((p) => p.price);
  check(
    expPrices.every((price, i) => i === 0 || expPrices[i - 1] >= price),
    "price_high sorting is descending"
  );

  log("GET /shop/products?category=Figures", await hit("GET", "/shop/products?category=Figures"), (j) =>
    (j.products || []).map(productLine)
  );
  log("GET /shop/products?category=Digital Assets", await hit("GET", "/shop/products?category=Digital%20Assets"), (j) =>
    (j.products || []).map(productLine)
  );
  log("GET /shop/products?q=luffy", await hit("GET", "/shop/products?q=luffy"), (j) =>
    (j.products || []).map(productLine)
  );
  log("GET /shop/products?discounted=true", await hit("GET", "/shop/products?discounted=true"), (j) =>
    (j.products || []).map((p) => `${p.name} -${p.discount_percent}%`)
  );
  log("GET /shop/products?max_price=15", await hit("GET", "/shop/products?max_price=15"), (j) =>
    (j.products || []).map((p) => `$${p.price} ${p.name}`)
  );
  log("GET /shop/products?in_stock=true", await hit("GET", "/shop/products?in_stock=true"), (j) =>
    `${(j.products || []).length} in-stock products`
  );

  // =====================================================================
  // 4. PRODUCT DETAILS
  // =====================================================================
  const firstProductId = all.json.products?.[0]?.id;
  const details = await hit("GET", `/shop/products/${firstProductId}`);
  log(`GET /shop/products/${firstProductId}`, details, (j) => ({
    product: productLine(j.product || {}),
    description: (j.product?.description || "").slice(0, 120) + "...",
    related: (j.related || []).map((p) => p.name),
    is_wishlisted: j.product?.is_wishlisted,
    quantity_in_cart: j.product?.quantity_in_cart,
  }));
  check(details.json.product?.id === firstProductId, "product details match the id");
  check((details.json.related || []).length > 0, "related products returned");

  const missing = await hit("GET", "/shop/products/999999");
  log("GET /shop/products/999999 (not found)", missing);
  check(missing.status === 404, "unknown product returns 404");

  // =====================================================================
  // 5. WISHLIST
  // =====================================================================
  const wishlist = await hit("GET", "/shop/wishlist");
  log("GET /shop/wishlist", wishlist, (j) => ({
    count: j.count,
    total_value: j.total_value,
    total_savings: j.total_savings,
    price_drops: j.price_drops,
    items: (j.items || []).map(
      (i) =>
        `${i.name} $${i.price}` +
        (i.has_price_drop
          ? `  << PRICE DROP was $${i.price_drop.old_price} (-$${i.price_drop.drop_amount})`
          : "")
    ),
  }));
  check(wishlist.status === 200, "GET /shop/wishlist returns 200");

  // price-drop detection writes the notifications
  const drops = await hit("POST", "/shop/wishlist/alerts/check");
  log("POST /shop/wishlist/alerts/check", drops, (j) => ({
    price_drops: j.price_drops,
    message: j.message,
    drops: (j.drops || []).map(
      (d) => `${d.name}: $${d.old_price} -> $${d.new_price} (save $${d.drop_amount}, -${d.drop_percent}%)`
    ),
  }));

  log("GET /shop/wishlist/alerts", await hit("GET", "/shop/wishlist/alerts"), (j) => ({
    count: j.count,
    alerts: (j.alerts || []).map(
      (a) => `${a.name}: $${a.old_price} -> $${a.new_price} (-${a.drop_percent}%) ${a.created_ago}`
    ),
  }));

  // The green "price dropped" strip must stay visible after the notification
  // has already been delivered - the user keeps seeing the saving.
  const wishlistAfterAlerts = await hit("GET", "/shop/wishlist");
  log("GET /shop/wishlist (after the alert check)", wishlistAfterAlerts, (j) => ({
    count: j.count,
    price_drops: j.price_drops,
    items_with_drop: (j.items || [])
      .filter((i) => i.has_price_drop)
      .map((i) => `${i.name}: -$${i.price_drop.drop_amount} (-${i.price_drop.drop_percent}%)`),
  }));
  check(
    (wishlistAfterAlerts.json.price_drops || 0) > 0,
    "price drops stay visible after the alert was sent"
  );

  // toggle a product on and off the wishlist
  const toggleTarget = all.json.products?.[2]?.id;
  const toggledOn = await hit("POST", `/shop/wishlist/${toggleTarget}`);
  log(`POST /shop/wishlist/${toggleTarget} (add)`, toggledOn, (j) => ({
    wishlisted: j.wishlisted,
    message: j.message,
  }));
  check(toggledOn.json.wishlisted === true, "wishlist toggle adds the product");

  const toggledOff = await hit("POST", `/shop/wishlist/${toggleTarget}`);
  log(`POST /shop/wishlist/${toggleTarget} (remove)`, toggledOff, (j) => ({
    wishlisted: j.wishlisted,
    message: j.message,
  }));
  check(toggledOff.json.wishlisted === false, "wishlist toggle removes the product");

  // =====================================================================
  // 6. CART
  // =====================================================================
  const cart = await hit("GET", "/shop/cart");
  log("GET /shop/cart", cart, (j) => ({
    item_count: j.item_count,
    subtotal: j.subtotal,
    shipping_fee: j.shipping_fee,
    shipping_note: j.shipping_note,
    total: j.total,
    items: (j.items || []).map(cartLine),
  }));
  check(cart.status === 200, "GET /shop/cart returns 200");

  const addTarget = all.json.products?.[5]?.id;
  const added = await hit("POST", "/shop/cart", { product_id: addTarget, quantity: 1 });
  log(`POST /shop/cart { product_id: ${addTarget}, quantity: 1 }`, added, (j) => ({
    message: j.message,
    item_count: j.item_count,
    total: j.total,
    items: (j.items || []).map(cartLine),
  }));
  check(added.status === 200, "add to cart succeeds");

  const qty = await hit("PUT", `/shop/cart/${addTarget}`, { quantity: 3 });
  log(`PUT /shop/cart/${addTarget} { quantity: 3 }`, qty, (j) => ({
    message: j.message,
    items: (j.items || []).map(cartLine),
  }));

  const overStock = await hit("PUT", `/shop/cart/${addTarget}`, { quantity: 99999 });
  log(`PUT /shop/cart/${addTarget} { quantity: 99999 } (stock guard)`, overStock, (j) => ({
    message: j.message,
  }));
  check(overStock.status === 400, "cart quantity is capped by stock");

  // promo codes
  const promo = await hit("POST", "/shop/cart/summary", { promo: "FANDOM10" });
  log("POST /shop/cart/summary { promo: FANDOM10 }", promo, (j) => ({
    subtotal: j.subtotal,
    discount: j.discount,
    discount_label: j.discount_label,
    shipping_fee: j.shipping_fee,
    total: j.total,
    promo_valid: j.promo_valid,
    available_promos: (j.available_promos || []).map((p) => p.code),
    payment_methods: j.payment_methods,
  }));
  check(promo.json.discount > 0, "FANDOM10 applies a discount");

  const badPromo = await hit("POST", "/shop/cart/summary", { promo: "NOPE123" });
  log("POST /shop/cart/summary { promo: NOPE123 }", badPromo, (j) => ({
    promo_valid: j.promo_valid,
    promo_error: j.promo_error,
  }));
  check(badPromo.json.promo_valid === false, "invalid promo code is rejected");

  const freeShipping = await hit("POST", "/shop/cart/summary", { promo: "FREESHIP" });
  log("POST /shop/cart/summary { promo: FREESHIP }", freeShipping, (j) => ({
    shipping_fee: j.shipping_fee,
    free_shipping: j.free_shipping,
    total: j.total,
  }));
  check(freeShipping.json.shipping_fee === 0, "FREESHIP removes the shipping fee");

  const removeLine = await hit("DELETE", `/shop/cart/${addTarget}`);
  log(`DELETE /shop/cart/${addTarget}`, removeLine, (j) => ({
    message: j.message,
    item_count: j.item_count,
    total: j.total,
  }));

  // =====================================================================
  // 7. CHECKOUT (simulated) + ORDERS
  // =====================================================================
  const checkout = await hit("POST", "/shop/checkout", {
    shipping_name: "Emma Carter",
    shipping_phone: "+92 300 1234567",
    shipping_city: "Karachi",
    shipping_address: "Apartment 4B, Gulshan-e-Iqbal Block 6",
    note: "Simulated order created by shop_api_test.js",
    payment_method: "Cash on Delivery (simulated)",
    promo: "FANDOM10",
  });
  log("POST /shop/checkout", checkout, (j) => ({
    message: j.message,
    order: j.order && {
      order_code: j.order.order_code,
      item_count: j.order.item_count,
      subtotal: j.order.subtotal,
      discount: j.order.discount,
      shipping_fee: j.order.shipping_fee,
      total: j.order.total,
      status: j.order.status,
      promo_code: j.order.promo_code,
      items: (j.order.items || []).map(
        (i) => `${i.name} x${i.quantity} @ $${i.unit_price} = $${i.line_total}`
      ),
    },
  }));
  check(checkout.status === 201, "checkout creates an order");
  check(!!checkout.json.order?.order_code, "order has an order code");

  const emptyCart = await hit("GET", "/shop/cart");
  log("GET /shop/cart (after checkout)", emptyCart, (j) => ({
    item_count: j.item_count,
    total: j.total,
    items: j.items,
  }));
  check(emptyCart.json.item_count === 0, "checkout empties the cart");

  const secondCheckout = await hit("POST", "/shop/checkout", {
    shipping_name: "Emma Carter",
    shipping_city: "Karachi",
    shipping_address: "Somewhere",
  });
  log("POST /shop/checkout (empty cart)", secondCheckout, (j) => ({ message: j.message }));
  check(secondCheckout.status === 400, "checkout with an empty cart is rejected");

  const orders = await hit("GET", "/shop/orders/mine");
  log("GET /shop/orders/mine", orders, (j) => ({
    count: j.count,
    total_spent: j.total_spent,
    orders: (j.orders || []).map(orderLine),
  }));
  check((orders.json.orders || []).length > 0, "purchase history has orders");

  const orderId = orders.json.orders?.[0]?.id;
  const orderDetail = await hit("GET", `/shop/orders/${orderId}`);
  log(`GET /shop/orders/${orderId}`, orderDetail, (j) => ({
    order_code: j.order?.order_code,
    status: j.order?.status,
    total: j.order?.total,
    placed_ago: j.order?.placed_ago,
    items: (j.order?.items || []).map(
      (i) => `${i.name} x${i.quantity} @ $${i.unit_price} = $${i.line_total}`
    ),
  }));
  check(orderDetail.status === 200, "order details load");

  // restore the demo cart so the app still shows data
  const restore = [
    { sku: "Gojo Satoru Figure", quantity: 1 },
    { sku: "Anime Enamel Pin Set", quantity: 2 },
  ];
  for (const item of restore) {
    const match = (all.json.products || []).find((p) => p.name === item.sku);
    if (match) {
      await hit("POST", "/shop/cart", {
        product_id: match.id,
        quantity: item.quantity,
      });
    }
  }
  log("POST /shop/cart (demo cart restored)", await hit("GET", "/shop/cart"), (j) => ({
    item_count: j.item_count,
    total: j.total,
  }));

  // =====================================================================
  // 8. AI FAN HELPER
  // =====================================================================
  log("GET /ai/suggestions", await hit("GET", "/ai/suggestions", null, false), (j) => ({
    greeting: j.greeting,
    external_ai_enabled: j.external_ai_enabled,
    suggestions: (j.suggestions || []).map((s) => `${s.question}  [${s.topic}]`),
  }));

  log("GET /ai/topics", await hit("GET", "/ai/topics", null, false), (j) => ({
    total_faqs: j.total_faqs,
    external_ai_enabled: j.external_ai_enabled,
    topics: (j.topics || []).map((t) => `${t.topic} (${t.count})`),
  }));

  const aiQuestions = [
    "Who is Luffy?",
    "What is Luffy's?",
    "Suggestions for anime?",
    "How do I care for my figure?",
    "How does the cart and checkout work?",
    "What is Gojo Satoru?",
    "How much is the Naruto Sage Mode Figure?",
    "Is the Tanjiro figure in stock?",
    "What are the best fandom gift ideas?",
    "hello",
    "asdkjhasd random nonsense",
  ];

  out.push("\n\n=================== AI FAN HELPER CONVERSATION ===================");

  for (const question of aiQuestions) {
    const answer = await hit("POST", "/ai/chat", { message: question }, false);
    summary.push(`${answer.status} POST /ai/chat "${question}" -> ${answer.json.source}`);

    const replyText = (answer.json.reply || "").replace(/\n+/g, " ");
    out.push(
      `\nQ: ${question}\n   [source: ${answer.json.source} | topic: ${answer.json.topic}]\n   A: ${
        replyText.length > 320 ? replyText.slice(0, 320) + "..." : replyText
      }`
    );
  }

  const luffy = await hit("POST", "/ai/chat", { message: "Who is Luffy?" }, false);
  check(luffy.json.reply?.toLowerCase().includes("one piece"), "FAQ engine answers the Luffy question");
  check(luffy.json.source === "faq", "Luffy question is answered from the FAQ table");

  const price = await hit("POST", "/ai/chat", { message: "How much is the Luffy Gear 5 Figure?" }, false);
  check(price.json.source === "catalogue", "price question is answered from the catalogue");
  check(price.json.reply?.includes("$"), "catalogue answer contains a price");

  const stock = await hit("POST", "/ai/chat", { message: "Is the Tanjiro figure in stock?" }, false);
  check(stock.json.source === "catalogue", "stock question is answered from the catalogue");

  const lore = await hit("POST", "/ai/chat", { message: "What is Gojo Satoru?" }, false);
  check(lore.json.source === "faq", "lore question is answered from the FAQ table, not the catalogue");

  const greeting = await hit("POST", "/ai/chat", { message: "hello" }, false);
  check(greeting.json.source === "smalltalk", "greeting is handled");

  const nonsense = await hit("POST", "/ai/chat", { message: "asdkjhasd random nonsense" }, false);
  check(nonsense.json.source === "fallback", "unknown question falls back gracefully");

  const empty = await hit("POST", "/ai/chat", { message: "" }, false);
  log("POST /ai/chat { message: '' }", empty, (j) => ({ message: j.message }));
  check(empty.status === 400, "empty message is rejected");

  // A signed-in chat is what gets persisted, so history is checked with a token.
  const signedInChat = await hit("POST", "/ai/chat", { message: "Who is Tanjiro Kamado?" });
  log("POST /ai/chat (signed in) { message: 'Who is Tanjiro Kamado?' }", signedInChat, (j) => ({
    source: j.source,
    topic: j.topic,
    history_saved: j.history_saved,
    reply: String(j.reply || "").slice(0, 160) + "...",
  }));
  check(signedInChat.json.history_saved === true, "signed-in chat reports history_saved");

  const history = await hit("GET", "/ai/history");
  log("GET /ai/history", history, (j) => ({
    count: j.count,
    messages: (j.messages || [])
      .slice(-4)
      .map((m) => `${m.sender}: ${String(m.message).slice(0, 90)}`),
  }));
  check((history.json.messages || []).length > 0, "chat history is persisted");

  log("DELETE /ai/history", await hit("DELETE", "/ai/history"), (j) => ({
    message: j.message,
  }));

  // =====================================================================
  // 9. AUTHORISATION GUARDS
  // =====================================================================
  const noAuthCart = await hit("GET", "/shop/cart", null, false);
  check(noAuthCart.status === 401, "cart requires authentication");

  const noAuthWishlist = await hit("GET", "/shop/wishlist", null, false);
  check(noAuthWishlist.status === 401, "wishlist requires authentication");

  const noAuthCheckout = await hit("POST", "/shop/checkout", {}, false);
  check(noAuthCheckout.status === 401, "checkout requires authentication");

  out.push("\n\n============ AUTHORISATION GUARDS ============");
  out.push(
    `GET /shop/cart without a token        -> ${noAuthCart.status} (expected 401)\n` +
      `GET /shop/wishlist without a token    -> ${noAuthWishlist.status} (expected 401)\n` +
      `POST /shop/checkout without a token   -> ${noAuthCheckout.status} (expected 401)`
  );

  // =====================================================================
  // report
  // =====================================================================
  const report = [
    "FANDOM VERSE - MEMBER 5 (Merchandise Store + AI Fan Helper)",
    "API smoke test report",
    `Generated: ${new Date().toISOString()}`,
    `Base URL : ${BASE}`,
    `Login    : ${EMAIL}`,
    "",
    `RESULT: ${passed} passed, ${failed} failed`,
    "",
    "===================== REQUEST SUMMARY =====================",
    ...summary,
    "",
    "===================== FULL RESPONSES =====================",
    ...out,
  ].join("\n");

  const reportPath = path.join(__dirname, "shop_report.txt");
  fs.writeFileSync(reportPath, report, "utf8");

  console.log(report.split("===================== FULL RESPONSES =====================")[0]);
  console.log(`\nFull report written to: ${reportPath}`);

  if (failed > 0) process.exitCode = 1;
}

main().catch((error) => {
  console.error("Test run failed:", error);
  process.exitCode = 1;
});
