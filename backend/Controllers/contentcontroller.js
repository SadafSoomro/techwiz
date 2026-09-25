/**
 * MEMBER 2 - Fandom Content
 * Fandom Hub, Explore Fandoms, News, Gallery, Video Player, Podcasts,
 * Discover feed, glossary, and the SQLite backed recent / offline content.
 *
 * SRS reference: "2. Fandom Exploration and Multimedia Hub".
 */

import { all, get, run, asyncHandler, timeAgo } from "../database/dbhelpers.js";
import cache from "../database/cache.js";

const LIST_FIELDS = `
  ci.id, ci.fandom, ci.hub_slug, ci.content_type, ci.title, ci.subtitle, ci.summary,
  ci.image_url, ci.media_url, ci.duration_seconds, ci.author, ci.source, ci.tags,
  ci.episode_number, ci.season, ci.views_count, ci.likes_count, ci.comments_count,
  ci.is_featured, ci.published_at,
  IFNULL(fh.color, '#10B981') AS fandom_color,
  IFNULL(fh.icon, 'auto_awesome_rounded') AS fandom_icon`;

function me(req) {
  return req.user?.id ?? -1;
}

/** Adds derived/display fields so the Flutter models stay dumb. */
function decorate(row) {
  if (!row) return row;
  return {
    ...row,
    published_ago: timeAgo(row.published_at),
    duration_label: durationLabel(row.duration_seconds),
    tags_list: (row.tags || "")
      .split(",")
      .map((t) => t.trim())
      .filter(Boolean),
  };
}

function durationLabel(seconds) {
  const total = Number(seconds) || 0;
  if (total <= 0) return "";
  const minutes = Math.floor(total / 60);
  const rest = total % 60;
  return `${minutes}:${String(rest).padStart(2, "0")}`;
}

// ---------------------------------------------------------------------------
// GET /api/content/hub  -> Explore Fandoms (hub cards / trending carousel)
// ---------------------------------------------------------------------------
export const getFandomHubs = asyncHandler(async (req, res) => {
  const cached = await cache.get("content:hubs");
  if (cached) return res.json({ success: true, cached: true, ...cached });

  const hubs = await all(
    `SELECT
       fh.id, fh.slug, fh.name, fh.tagline, fh.description, fh.image_url, fh.icon,
       fh.color, fh.followers_count, fh.posts_count, fh.is_trending,
       (SELECT COUNT(*) FROM content_items ci
         WHERE ci.hub_slug = fh.slug AND ci.is_published = 1) AS items_count,
       (SELECT IFNULL(SUM(ci.views_count), 0) FROM content_items ci
         WHERE ci.hub_slug = fh.slug) AS total_views
     FROM fandom_hubs fh
     ORDER BY fh.is_trending DESC, fh.sort_order ASC, fh.name ASC`
  );

  const payload = {
    hubs,
    trending: hubs.filter((h) => h.is_trending === 1),
    totals: {
      hubs: hubs.length,
      items: hubs.reduce((sum, h) => sum + (h.items_count || 0), 0),
      views: hubs.reduce((sum, h) => sum + (h.total_views || 0), 0),
    },
  };

  await cache.set("content:hubs", payload, 120);
  res.json({ success: true, ...payload });
});

// ---------------------------------------------------------------------------
// GET /api/content/hub/:slug  -> one Fandom Hub (Anime / Gaming / ...)
// ---------------------------------------------------------------------------
export const getFandomHub = asyncHandler(async (req, res) => {
  const slug = String(req.params.slug);

  const hub = await get(`SELECT * FROM fandom_hubs WHERE slug = ?`, [slug]);
  if (!hub) {
    return res.status(404).json({ success: false, message: "Fandom hub not found" });
  }

  const viewerId = me(req);

  const pick = async (type, limit) => {
    const rows = await all(
      `SELECT ${LIST_FIELDS},
         EXISTS (SELECT 1 FROM content_likes cl
                 WHERE cl.content_id = ci.id AND cl.user_id = ?) AS is_liked,
         EXISTS (SELECT 1 FROM content_views cv
                 WHERE cv.content_id = ci.id AND cv.user_id = ? AND cv.is_offline = 1)
           AS is_offline
       FROM content_items ci
       LEFT JOIN fandom_hubs fh ON fh.slug = ci.hub_slug
       WHERE ci.hub_slug = ? AND ci.content_type = ? AND ci.is_published = 1
       ORDER BY ci.is_featured DESC, ci.published_at DESC
       LIMIT ?`,
      [viewerId, viewerId, slug, type, limit]
    );
    return rows.map(decorate);
  };

  const [news, galleries, videos, podcasts, deepDives] = await Promise.all([
    pick("news", 8),
    pick("gallery", 6),
    pick("video", 6),
    pick("podcast", 6),
    pick("deep_dive", 4),
  ]);

  const stats = await get(
    `SELECT
       COUNT(*) AS items,
       IFNULL(SUM(views_count), 0) AS views,
       IFNULL(SUM(likes_count), 0) AS likes
     FROM content_items WHERE hub_slug = ? AND is_published = 1`,
    [slug]
  );

  const glossary = await all(
    `SELECT term, definition, category FROM glossary_terms
     WHERE fandom = ? OR fandom = 'General'
     ORDER BY term LIMIT 12`,
    [hub.name]
  );

  res.json({
    success: true,
    hub: { ...hub, ...stats },
    sections: { news, galleries, videos, podcasts, deepDives },
    news,
    galleries,
    videos,
    podcasts,
    deepDives,
    glossary,
  });
});

// ---------------------------------------------------------------------------
// GET /api/content/glossary  -> Beginner Fan Hub glossary
// ---------------------------------------------------------------------------
export const getGlossary = asyncHandler(async (req, res) => {
  const fandom = req.query.fandom ? String(req.query.fandom) : "";
  const rows = fandom
    ? await all(
        `SELECT * FROM glossary_terms WHERE fandom = ? OR fandom = 'General' ORDER BY term`,
        [fandom]
      )
    : await all(`SELECT * FROM glossary_terms ORDER BY fandom, term`);

  const grouped = rows.reduce((acc, row) => {
    (acc[row.category] = acc[row.category] || []).push(row);
    return acc;
  }, {});

  res.json({ success: true, terms: rows, grouped, total: rows.length });
});

// ---------------------------------------------------------------------------
// GET /api/content/discover  -> Discover feed (mixed media types)
// ---------------------------------------------------------------------------
export const getDiscoverFeed = asyncHandler(async (req, res) => {
  const viewerId = me(req);
  const limit = Math.min(parseInt(req.query.limit ?? "20", 10) || 20, 50);

  const cached = await cache.get(`content:discover:${limit}`);
  const rows = await all(
    `SELECT ${LIST_FIELDS},
       EXISTS (SELECT 1 FROM content_likes cl
               WHERE cl.content_id = ci.id AND cl.user_id = ?) AS is_liked,
       EXISTS (SELECT 1 FROM content_views cv
               WHERE cv.content_id = ci.id AND cv.user_id = ? AND cv.is_offline = 1)
         AS is_offline
     FROM content_items ci
     LEFT JOIN fandom_hubs fh ON fh.slug = ci.hub_slug
     WHERE ci.is_published = 1
     ORDER BY ci.is_featured DESC, (ci.views_count * 1.0 / (1 + julianday('now') - julianday(ci.published_at))) DESC
     LIMIT ?`,
    [viewerId, viewerId, limit]
  );

  const spotlight = rows.length ? decorate(rows[0]) : null;

  const payload = {
    spotlight,
    trending: rows.filter((r) => r.is_featured === 1 && r.id !== spotlight?.id).slice(0, 6).map(decorate),
    latest: [...rows]
      .sort((a, b) => String(b.published_at).localeCompare(String(a.published_at)))
      .slice(0, 10)
      .map(decorate),
    collections: rows.filter((r) => r.content_type === "gallery").slice(0, 4).map(decorate),
    cached: !!cached,
  };

  await cache.set(`content:discover:${limit}`, payload, 90);
  res.json({ success: true, ...payload });
});

// ---------------------------------------------------------------------------
// GET /api/content/recent  -> recently viewed (SQLite recent content)
// GET /api/content/offline -> saved for offline
// ---------------------------------------------------------------------------
export const getRecentContent = asyncHandler(async (req, res) => {
  const rows = await all(
    `SELECT ${LIST_FIELDS}, cv.is_offline, cv.progress, cv.viewed_at,
       EXISTS (SELECT 1 FROM content_likes cl
               WHERE cl.content_id = ci.id AND cl.user_id = cv.user_id) AS is_liked
     FROM content_views cv
     JOIN content_items ci ON ci.id = cv.content_id
     LEFT JOIN fandom_hubs fh ON fh.slug = ci.hub_slug
     WHERE cv.user_id = ?
     ORDER BY cv.viewed_at DESC
     LIMIT 30`,
    [me(req)]
  );

  res.json({
    success: true,
    recent: rows.map(decorate),
    offlineCount: rows.filter((r) => r.is_offline === 1).length,
  });
});

export const getOfflineContent = asyncHandler(async (req, res) => {
  const rows = await all(
    `SELECT ${LIST_FIELDS}, cv.progress, cv.viewed_at
     FROM content_views cv
     JOIN content_items ci ON ci.id = cv.content_id
     LEFT JOIN fandom_hubs fh ON fh.slug = ci.hub_slug
     WHERE cv.user_id = ? AND cv.is_offline = 1
     ORDER BY cv.viewed_at DESC`,
    [me(req)]
  );

  const totals = await get(
    `SELECT
       IFNULL(SUM(ci.duration_seconds), 0) AS total_seconds,
       COUNT(*) AS items
     FROM content_views cv
     JOIN content_items ci ON ci.id = cv.content_id
     WHERE cv.user_id = ? AND cv.is_offline = 1`,
    [me(req)]
  );

  res.json({
    success: true,
    offline: rows.map(decorate),
    totals: {
      items: totals?.items ?? 0,
      sizeMb: Math.round(((totals?.total_seconds ?? 0) * 0.09 + (totals?.items ?? 0) * 0.4) * 10) / 10,
    },
  });
});

// ---------------------------------------------------------------------------
// GET /api/content  -> filtered content list (News / Gallery / Video / Podcast)
// ---------------------------------------------------------------------------
export const listContent = asyncHandler(async (req, res) => {
  const viewerId = me(req);
  const type = req.query.type ? String(req.query.type) : "";
  const fandom = req.query.fandom ? String(req.query.fandom) : "";
  const hub = req.query.hub ? String(req.query.hub) : "";
  const query = req.query.q ? String(req.query.q).trim() : "";
  const sort = req.query.sort ? String(req.query.sort) : "latest";
  const limit = Math.min(parseInt(req.query.limit ?? "20", 10) || 20, 60);
  const offset = Math.max(parseInt(req.query.offset ?? "0", 10) || 0, 0);

  // NOTE: Express 5 makes req.query a getter - it must never be mutated.
  const filters = ["ci.is_published = 1"];
  const params = [viewerId, viewerId];

  if (type && type !== "all") {
    filters.push("ci.content_type = ?");
    params.push(type);
  }
  if (fandom && fandom !== "all") {
    filters.push("ci.fandom = ?");
    params.push(fandom);
  }
  if (hub && hub !== "all") {
    filters.push("ci.hub_slug = ?");
    params.push(hub);
  }
  if (query) {
    filters.push("(ci.title LIKE ? OR ci.summary LIKE ? OR ci.tags LIKE ?)");
    params.push(`%${query}%`, `%${query}%`, `%${query}%`);
  }

  const orderBy =
    sort === "popular"
      ? "ci.views_count DESC, ci.likes_count DESC"
      : sort === "liked"
      ? "ci.likes_count DESC"
      : sort === "oldest"
      ? "ci.published_at ASC"
      : "ci.is_featured DESC, ci.published_at DESC";

  const rows = await all(
    `SELECT ${LIST_FIELDS},
       EXISTS (SELECT 1 FROM content_likes cl
               WHERE cl.content_id = ci.id AND cl.user_id = ?) AS is_liked,
       EXISTS (SELECT 1 FROM content_views cv
               WHERE cv.content_id = ci.id AND cv.user_id = ? AND cv.is_offline = 1)
         AS is_offline
     FROM content_items ci
     LEFT JOIN fandom_hubs fh ON fh.slug = ci.hub_slug
     WHERE ${filters.join(" AND ")}
     ORDER BY ${orderBy}
     LIMIT ? OFFSET ?`,
    [...params, limit, offset]
  );

  const totalRow = await get(
    `SELECT COUNT(*) AS total FROM content_items ci
     WHERE ${filters.join(" AND ")}`,
    params.slice(2)
  );

  res.json({
    success: true,
    items: rows.map(decorate),
    total: totalRow?.total ?? rows.length,
    limit,
    offset,
  });
});

// ---------------------------------------------------------------------------
// GET /api/content/:id  -> News Details / Video / Podcast / Gallery details
// ---------------------------------------------------------------------------
export const getContentDetails = asyncHandler(async (req, res) => {
  const id = parseInt(req.params.id, 10);
  const viewerId = me(req);

  const row = await get(
    `SELECT ${LIST_FIELDS}, ci.body, ci.published_at,
       IFNULL(fh.name, ci.fandom) AS hub_name,
       IFNULL(fh.tagline, '') AS hub_tagline,
       EXISTS (SELECT 1 FROM content_likes cl
               WHERE cl.content_id = ci.id AND cl.user_id = ?) AS is_liked,
       EXISTS (SELECT 1 FROM content_views cv
               WHERE cv.content_id = ci.id AND cv.user_id = ? AND cv.is_offline = 1)
         AS is_offline,
       IFNULL((SELECT cv2.progress FROM content_views cv2
               WHERE cv2.content_id = ci.id AND cv2.user_id = ?), 0) AS progress
     FROM content_items ci
     LEFT JOIN fandom_hubs fh ON fh.slug = ci.hub_slug
     WHERE ci.id = ?`,
    [viewerId, viewerId, viewerId, id]
  );

  if (!row) {
    return res.status(404).json({ success: false, message: "Content not found" });
  }

  const media = await all(
    `SELECT id, media_type, url, caption, sort_order
     FROM content_media WHERE content_id = ? ORDER BY sort_order`,
    [id]
  );

  const related = await all(
    `SELECT ${LIST_FIELDS}
     FROM content_items ci
     LEFT JOIN fandom_hubs fh ON fh.slug = ci.hub_slug
     WHERE ci.id != ? AND ci.is_published = 1
       AND (ci.hub_slug = ? OR ci.content_type = ?)
     ORDER BY ci.is_featured DESC, ci.published_at DESC
     LIMIT 6`,
    [id, row.hub_slug, row.content_type]
  );

  res.json({
    success: true,
    item: decorate({ ...row, body: row.body }),
    paragraphs: (row.body || "").split("\n").filter((p) => p.trim().length > 0),
    media,
    galleryCount: media.length,
    related: related.map(decorate),
  });
});

// ---------------------------------------------------------------------------
// POST /api/content/:id/view  -> record a view (recent + optional offline)
// ---------------------------------------------------------------------------
export const recordView = asyncHandler(async (req, res) => {
  const id = parseInt(req.params.id, 10);
  const { progress = 0, offline } = req.body ?? {};
  const userId = me(req);

  const exists = await get(`SELECT id FROM content_items WHERE id = ?`, [id]);
  if (!exists) {
    return res.status(404).json({ success: false, message: "Content not found" });
  }

  await run(
    `INSERT INTO content_views (user_id, content_id, is_offline, progress, viewed_at)
     VALUES (?, ?, COALESCE(?, 0), ?, CURRENT_TIMESTAMP)
     ON CONFLICT (user_id, content_id) DO UPDATE SET
       is_offline = COALESCE(?, content_views.is_offline),
       progress   = ?,
       viewed_at  = CURRENT_TIMESTAMP`,
    [
      userId,
      id,
      offline === undefined || offline === null ? 0 : offline ? 1 : 0,
      Number(progress) || 0,
      offline === undefined || offline === null ? null : offline ? 1 : 0,
      Number(progress) || 0,
    ]
  );

  await run(`UPDATE content_items SET views_count = views_count + 1 WHERE id = ?`, [id]);

  const saved = await get(
    `SELECT is_offline, progress FROM content_views WHERE user_id = ? AND content_id = ?`,
    [userId, id]
  );

  res.json({
    success: true,
    message: "View recorded",
    isOffline: saved?.is_offline === 1,
    progress: saved?.progress ?? 0,
  });
});

// ---------------------------------------------------------------------------
// POST /api/content/:id/offline  -> toggle "save for offline"
// ---------------------------------------------------------------------------
export const toggleOffline = asyncHandler(async (req, res) => {
  const id = parseInt(req.params.id, 10);
  const userId = me(req);

  const item = await get(`SELECT id FROM content_items WHERE id = ?`, [id]);
  if (!item) {
    return res.status(404).json({ success: false, message: "Content not found" });
  }

  const current = await get(
    `SELECT is_offline FROM content_views WHERE user_id = ? AND content_id = ?`,
    [userId, id]
  );

  const next = current?.is_offline === 1 ? 0 : 1;

  if (current) {
    await run(
      `UPDATE content_views SET is_offline = ?, viewed_at = CURRENT_TIMESTAMP
       WHERE user_id = ? AND content_id = ?`,
      [next, userId, id]
    );
  } else {
    await run(
      `INSERT INTO content_views (user_id, content_id, is_offline, progress)
       VALUES (?, ?, ?, 0)`,
      [userId, id, next]
    );
  }

  res.json({
    success: true,
    message: next ? "Saved for offline reading" : "Removed from offline content",
    isOffline: next === 1,
  });
});

// ---------------------------------------------------------------------------
// POST /api/content/:id/like  -> toggle like
// ---------------------------------------------------------------------------
export const toggleContentLike = asyncHandler(async (req, res) => {
  const id = parseInt(req.params.id, 10);
  const userId = me(req);

  const item = await get(`SELECT id FROM content_items WHERE id = ?`, [id]);
  if (!item) {
    return res.status(404).json({ success: false, message: "Content not found" });
  }

  const liked = await get(
    `SELECT id FROM content_likes WHERE content_id = ? AND user_id = ?`,
    [id, userId]
  );

  if (liked) {
    await run(`DELETE FROM content_likes WHERE id = ?`, [liked.id]);
    await run(
      `UPDATE content_items SET likes_count = MAX(likes_count - 1, 0) WHERE id = ?`,
      [id]
    );
  } else {
    await run(`INSERT INTO content_likes (content_id, user_id) VALUES (?, ?)`, [id, userId]);
    await run(`UPDATE content_items SET likes_count = likes_count + 1 WHERE id = ?`, [id]);
  }

  const fresh = await get(`SELECT likes_count FROM content_items WHERE id = ?`, [id]);

  res.json({
    success: true,
    message: liked ? "Like removed" : "Content liked",
    isLiked: !liked,
    likesCount: fresh?.likes_count ?? 0,
  });
});

export default {
  getFandomHubs,
  getFandomHub,
  getGlossary,
  getDiscoverFeed,
  getRecentContent,
  getOfflineContent,
  listContent,
  getContentDetails,
  recordView,
  toggleOffline,
  toggleContentLike,
};
