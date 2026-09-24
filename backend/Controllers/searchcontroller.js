/**
 * MEMBER 3 - Search & Community
 * Search controller: keyword search (Users / Posts / Fandoms),
 * filters, trending hashtags and search suggestions.
 *
 * Backend note: the SRS lists PostgreSQL + Redis here.
 * This project uses SQLite for both storage and caching.
 */

import { all, get, run, asyncHandler, timeAgo } from "../database/dbhelpers.js";
import cache from "../database/cache.js";

// Whitelisted sort modes -> ORDER BY clauses (prevents SQL injection).
const POST_SORTS = {
  newest: "p.created_at DESC",
  popular:
    "(p.views_count + (p.likes_count * 3) + (p.comments_count * 2)) DESC, p.created_at DESC",
  top: "p.likes_count DESC, p.comments_count DESC",
  trending:
    "((p.likes_count * 3) + (p.comments_count * 2) + p.views_count) DESC, p.created_at DESC",
  oldest: "p.created_at ASC",
};

const USER_SORTS = {
  newest: "u.id DESC",
  popular: "(u.followers_count + u.following_count) DESC",
  top: "u.followers_count DESC, u.id DESC",
  trending: "u.followers_count DESC, u.id DESC",
  oldest: "u.id ASC",
};

function pickSort(value, table) {
  const allowed = table === "users" ? USER_SORTS : POST_SORTS;
  return allowed[String(value || "popular").toLowerCase()] || allowed.popular;
}

/** Shared SELECT body for community posts. */
const POST_SELECT = `
  SELECT
    p.id,
    p.user_id,
    p.fandom_category   AS fandom,
    p.title,
    p.content,
    p.image_url,
    p.hashtags,
    p.post_type,
    p.rating,
    p.likes_count,
    p.comments_count,
    p.views_count,
    p.created_at,
    u.name              AS author_name,
    u.avatar            AS author_avatar,
    EXISTS (SELECT 1 FROM post_likes pl WHERE pl.post_id = p.id AND pl.user_id = ?)   AS is_liked,
    EXISTS (SELECT 1 FROM bookmarks  b  WHERE b.post_id  = p.id AND b.user_id  = ?)   AS is_bookmarked
  FROM posts p
  JOIN users u ON u.id = p.user_id
`;

function decorate(rows) {
  return rows.map((row) => ({ ...row, created_ago: timeAgo(row.created_at) }));
}

function currentUserId(req) {
  return req.user?.id ?? -1;
}

// ---------------------------------------------------------------------------
// GET /api/search?q=&type=all|users|posts|fandoms&fandom=&sort=&limit=&offset=
// ---------------------------------------------------------------------------
export const search = asyncHandler(async (req, res) => {
  const q = String(req.query.q || "").trim();
  const type = String(req.query.type || "all").toLowerCase();
  const fandom = String(req.query.fandom || "").trim();
  const sort = String(req.query.sort || "popular").toLowerCase();
  const limit = Math.min(parseInt(req.query.limit, 10) || 20, 50);
  const offset = parseInt(req.query.offset, 10) || 0;
  const me = currentUserId(req);

  const like = `%${q}%`;
  const result = {
    query: q,
    type,
    sort,
    fandom: fandom || null,
    users: [],
    posts: [],
    fandoms: [],
    totals: { users: 0, posts: 0, fandoms: 0 },
  };

  // ------------------------------- users -------------------------------
  if (type === "all" || type === "users") {
    const userWhere = q
      ? `WHERE (u.name LIKE ? OR IFNULL(u.bio, '') LIKE ?)`
      : `WHERE 1 = 1`;
    const userParams = q ? [like, like] : [];

    const rows = await all(
      `SELECT
         u.id, u.name, u.avatar, u.bio,
         IFNULL(u.followers_count, 0) AS followers_count,
         EXISTS (SELECT 1 FROM follows f
                 WHERE f.follower_id = ? AND f.following_id = u.id) AS is_following,
         (SELECT COUNT(*) FROM posts p2 WHERE p2.user_id = u.id) AS posts_count
       FROM users u
       ${userWhere}
       ${q ? "" : "AND u.verified = 1"}
       ORDER BY ${pickSort(sort, "users")}
       LIMIT ? OFFSET ?`,
      [me, ...userParams, limit, offset]
    );

    result.users = rows;
    result.totals.users = rows.length;
  }

  // ------------------------------- posts -------------------------------
  if (type === "all" || type === "posts") {
    const conditions = ["p.is_published = 1"];
    const params = [me, me];

    if (q) {
      conditions.push(`(p.title LIKE ? OR p.content LIKE ? OR IFNULL(p.hashtags,'') LIKE ?)`);
      params.push(like, like, like);
    }
    if (fandom && fandom.toLowerCase() !== "all") {
      conditions.push(`p.fandom_category = ?`);
      params.push(fandom);
    }

    const rows = await all(
      `${POST_SELECT}
       WHERE ${conditions.join(" AND ")}
       ORDER BY ${pickSort(sort, "posts")}
       LIMIT ? OFFSET ?`,
      [...params, limit, offset]
    );

    result.posts = decorate(rows);
    result.totals.posts = rows.length;
  }

  // ------------------------------ fandoms ------------------------------
  if (type === "all" || type === "fandoms") {
    const fandomWhere = q
      ? `WHERE (name LIKE ? OR IFNULL(description,'') LIKE ? OR IFNULL(hashtag,'') LIKE ?)`
      : ``;
    const fandomParams = q ? [like, like, like] : [];

    const rows = await all(
      `SELECT
         id, name, hashtag, icon, color, description,
         (SELECT COUNT(*) FROM posts p
           WHERE p.fandom_category = fandom_categories.name AND p.is_published = 1) AS posts_count
       FROM fandom_categories
       ${fandomWhere}
       ORDER BY posts_count DESC, name ASC
       LIMIT ? OFFSET ?`,
      [...fandomParams, limit, offset]
    );

    result.fandoms = rows;
    result.totals.fandoms = rows.length;
  }

  // keep recent searches (best effort)
  if (q && req.user?.id) {
    run(`INSERT INTO search_history (user_id, query) VALUES (?, ?)`, [req.user.id, q]).catch(
      () => {}
    );
  }

  res.json({ success: true, ...result });
});

// ---------------------------------------------------------------------------
// GET /api/search/filters  -> filter chips + sort options for the UI
// ---------------------------------------------------------------------------
export const getFilters = asyncHandler(async (req, res) => {
  const cached = await cache.get("search:filters");
  if (cached) return res.json({ success: true, ...cached, cached: true });

  const fandoms = await all(
    `SELECT name, hashtag, icon, color FROM fandom_categories ORDER BY name ASC`
  );

  const payload = {
    contentTypes: [
      { key: "all", label: "All" },
      { key: "users", label: "Users" },
      { key: "posts", label: "Posts" },
      { key: "fandoms", label: "Fandoms" },
    ],
    sortOptions: [
      { key: "popular", label: "Popular" },
      { key: "newest", label: "Newest" },
      { key: "top", label: "Top" },
      { key: "trending", label: "Trending" },
    ],
    fandoms: [{ name: "All", hashtag: "#All" }, ...fandoms],
  };

  await cache.set("search:filters", payload, 300);
  res.json({ success: true, ...payload, cached: false });
});

// ---------------------------------------------------------------------------
// GET /api/search/trending  -> Trending screen
// (hashtags + top results: users / posts / fandoms / deep dives)
// ---------------------------------------------------------------------------
export const getTrending = asyncHandler(async (req, res) => {
  const me = currentUserId(req);
  const cacheKey = `search:trending:${me}`;

  const cached = await cache.get(cacheKey);
  if (cached) return res.json({ success: true, ...cached, cached: true });

  // hashtags -> aggregated from posts.hashtags (comma separated column).
  // Aggregation is done in Node so it works on every SQLite build.
  const rawTags = await all(
    `SELECT hashtags, likes_count FROM posts
     WHERE is_published = 1 AND IFNULL(hashtags, '') <> ''`
  );

  const tagMap = new Map();
  rawTags.forEach((row) => {
    String(row.hashtags)
      .split(",")
      .map((tag) => tag.trim().replace(/^#/, ""))
      .filter(Boolean)
      .forEach((tag) => {
        const entry = tagMap.get(tag) || { tag: `#${tag}`, posts_count: 0, likes_count: 0 };
        entry.posts_count += 1;
        entry.likes_count += row.likes_count || 0;
        tagMap.set(tag, entry);
      });
  });

  const hashtags = [...tagMap.values()]
    .sort((a, b) => b.posts_count - a.posts_count || b.likes_count - a.likes_count)
    .slice(0, 12);

  const users = await all(
    `SELECT
       u.id, u.name, u.avatar, u.bio,
       IFNULL(u.followers_count, 0) AS followers_count,
       EXISTS (SELECT 1 FROM follows f
               WHERE f.follower_id = ? AND f.following_id = u.id) AS is_following
     FROM users u
     WHERE u.verified = 1
     ORDER BY u.followers_count DESC, u.id ASC
     LIMIT 6`,
    [me]
  );

  const posts = decorate(
    await all(
      `${POST_SELECT}
       WHERE p.is_published = 1
       ORDER BY ${POST_SORTS.trending}
       LIMIT 8`,
      [me, me]
    )
  );

  const fandoms = await all(
    `SELECT
       name, hashtag, icon, color, description,
       (SELECT COUNT(*) FROM posts p
         WHERE p.fandom_category = fandom_categories.name AND p.is_published = 1) AS posts_count
     FROM fandom_categories
     ORDER BY posts_count DESC
     LIMIT 8`
  );

  const deepDives = decorate(
    await all(
      `${POST_SELECT}
       WHERE p.is_published = 1 AND p.post_type = 'deep_dive'
       ORDER BY ${POST_SORTS.top}
       LIMIT 6`,
      [me, me]
    )
  );

  const payload = { hashtags, users, posts, fandoms, deepDives };
  await cache.set(cacheKey, payload, 45); // short TTL, mirrors a Redis trending cache

  res.json({ success: true, ...payload, cached: false });
});

// ---------------------------------------------------------------------------
// GET /api/search/suggestions?q=  -> live autocomplete
// ---------------------------------------------------------------------------
export const getSuggestions = asyncHandler(async (req, res) => {
  const q = String(req.query.q || "").trim();
  if (q.length < 1) {
    return res.json({ success: true, suggestions: [], recent: [] });
  }

  const like = `%${q}%`;

  const users = await all(
    `SELECT id, name, 'user' AS kind FROM users
     WHERE name LIKE ? AND verified = 1 LIMIT 5`,
    [like]
  );

  const posts = await all(
    `SELECT id, title AS name, 'post' AS kind FROM posts
     WHERE title LIKE ? AND is_published = 1 LIMIT 5`,
    [like]
  );

  const fandoms = await all(
    `SELECT name, hashtag AS label, 'fandom' AS kind FROM fandom_categories
     WHERE name LIKE ? LIMIT 5`,
    [like]
  );

  let recent = [];
  if (req.user?.id) {
    recent = await all(
      `SELECT DISTINCT query FROM search_history
       WHERE user_id = ? ORDER BY id DESC LIMIT 5`,
      [req.user.id]
    );
  }

  res.json({
    success: true,
    suggestions: [...fandoms, ...users, ...posts],
    recent: recent.map((r) => r.query),
  });
});

// ---------------------------------------------------------------------------
// GET /api/search/history  |  DELETE /api/search/history
// ---------------------------------------------------------------------------
export const getSearchHistory = asyncHandler(async (req, res) => {
  const rows = await all(
    `SELECT DISTINCT query, MAX(created_at) AS created_at
     FROM search_history WHERE user_id = ?
     GROUP BY query ORDER BY created_at DESC LIMIT 10`,
    [req.user.id]
  );
  res.json({ success: true, history: rows });
});

export const clearSearchHistory = asyncHandler(async (req, res) => {
  await run(`DELETE FROM search_history WHERE user_id = ?`, [req.user.id]);
  res.json({ success: true, message: "Search history cleared" });
});

export default {
  search,
  getFilters,
  getTrending,
  getSuggestions,
  getSearchHistory,
  clearSearchHistory,
};
