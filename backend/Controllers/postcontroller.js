/**
 * MEMBER 3 - Search & Community
 * Posts / Discussions controller.
 *
 * Covers:
 *   - Community feed and "Deep Dive" discussions
 *   - Create / edit / delete post
 *   - Like toggle
 *   - Comments (add / list / delete)
 */

import { all, get, run, asyncHandler, timeAgo } from "../database/dbhelpers.js";
import cache from "../database/cache.js";
import { notifyWithActor } from "../utils/notify.js";

const SORTS = {
  newest: "p.created_at DESC",
  oldest: "p.created_at ASC",
  popular:
    "(p.views_count + (p.likes_count * 3) + (p.comments_count * 2)) DESC, p.created_at DESC",
  top: "p.likes_count DESC, p.comments_count DESC",
  trending:
    "((p.likes_count * 3) + (p.comments_count * 2) + p.views_count) DESC, p.created_at DESC",
};

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
    EXISTS (SELECT 1 FROM post_likes pl WHERE pl.post_id = p.id AND pl.user_id = ?) AS is_liked,
    EXISTS (SELECT 1 FROM bookmarks  b  WHERE b.post_id  = p.id AND b.user_id  = ?) AS is_bookmarked
  FROM posts p
  JOIN users u ON u.id = p.user_id
`;

function decorate(rows) {
  return rows.map((row) => ({ ...row, created_ago: timeAgo(row.created_at) }));
}

function orderBy(value) {
  return SORTS[String(value || "newest").toLowerCase()] || SORTS.newest;
}

function me(req) {
  return req.user?.id ?? -1;
}

/** Normalises hashtags sent as array OR comma string -> "Anime,OnePiece" */
function normaliseHashtags(input) {
  if (!input) return "";
  const list = Array.isArray(input) ? input : String(input).split(",");
  return list
    .map((t) => String(t).trim().replace(/^#/, ""))
    .filter(Boolean)
    .join(",");
}

// ---------------------------------------------------------------------------
// GET /api/posts
// ?fandom=Anime&type=post|deep_dive&sort=newest&q=&user_id=&limit=&offset=
// ---------------------------------------------------------------------------
async function queryPosts(req, forcedType = null) {
  const userId = me(req);
  const fandom = String(req.query.fandom || "").trim();
  const type = forcedType || String(req.query.type || "").trim().toLowerCase();
  const q = String(req.query.q || "").trim();
  const authorId = parseInt(req.query.user_id, 10);
  const limit = Math.min(parseInt(req.query.limit, 10) || 20, 50);
  const offset = parseInt(req.query.offset, 10) || 0;

  const conditions = ["p.is_published = 1"];
  const params = [userId, userId];

  if (fandom && fandom.toLowerCase() !== "all") {
    conditions.push(`p.fandom_category = ?`);
    params.push(fandom);
  }
  if (type === "post" || type === "deep_dive") {
    conditions.push(`p.post_type = ?`);
    params.push(type);
  }
  if (!Number.isNaN(authorId) && authorId > 0) {
    conditions.push(`p.user_id = ?`);
    params.push(authorId);
  }
  if (q) {
    conditions.push(`(p.title LIKE ? OR p.content LIKE ? OR IFNULL(p.hashtags,'') LIKE ?)`);
    const like = `%${q}%`;
    params.push(like, like, like);
  }

  const rows = await all(
    `${POST_SELECT}
     WHERE ${conditions.join(" AND ")}
     ORDER BY ${orderBy(req.query.sort)}
     LIMIT ? OFFSET ?`,
    [...params, limit, offset]
  );

  return { rows, limit };
}

export const getPosts = asyncHandler(async (req, res) => {
  const { rows, limit } = await queryPosts(req);

  res.json({
    success: true,
    count: rows.length,
    posts: decorate(rows),
    hasMore: rows.length === limit,
  });
});

// GET /api/posts/discussions  -> Deep Dive list screen
export const getDiscussions = asyncHandler(async (req, res) => {
  const { rows, limit } = await queryPosts(req, "deep_dive");

  res.json({
    success: true,
    count: rows.length,
    posts: decorate(rows),
    hasMore: rows.length === limit,
  });
});

// ---------------------------------------------------------------------------
// GET /api/posts/:id
// ---------------------------------------------------------------------------
export const getPostById = asyncHandler(async (req, res) => {
  const userId = me(req);

  const post = await get(`${POST_SELECT} WHERE p.id = ?`, [userId, userId, req.params.id]);

  if (!post) {
    return res.status(404).json({ success: false, message: "Post not found" });
  }

  await run(`UPDATE posts SET views_count = views_count + 1 WHERE id = ?`, [post.id]);

  const comments = await all(
    `SELECT
       c.id, c.post_id, c.user_id, c.body, c.likes_count, c.created_at,
       u.name AS author_name, u.avatar AS author_avatar
     FROM comments c
     JOIN users u ON u.id = c.user_id
     WHERE c.post_id = ?
     ORDER BY c.created_at DESC`,
    [post.id]
  );

  res.json({
    success: true,
    post: {
      ...post,
      views_count: post.views_count + 1,
      created_ago: timeAgo(post.created_at),
      comments: comments.map((c) => ({ ...c, created_ago: timeAgo(c.created_at) })),
    },
  });
});

// ---------------------------------------------------------------------------
// POST /api/posts      (Create Post / Start a Deep Dive)
// ---------------------------------------------------------------------------
export const createPost = asyncHandler(async (req, res) => {
  const {
    title,
    content,
    fandom_category,
    fandom,
    hashtags,
    image_url,
    post_type,
    rating,
  } = req.body;

  if (!title || !String(title).trim()) {
    return res.status(400).json({ success: false, message: "Title is required" });
  }
  if (!content || !String(content).trim()) {
    return res.status(400).json({ success: false, message: "Content is required" });
  }

  const type = String(post_type || "post").toLowerCase() === "deep_dive" ? "deep_dive" : "post";

  const result = await run(
    `INSERT INTO posts
       (user_id, fandom_category, title, content, image_url, hashtags, post_type, rating)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
    [
      req.user.id,
      fandom_category || fandom || "Anime",
      String(title).trim(),
      String(content).trim(),
      image_url || null,
      normaliseHashtags(hashtags),
      type,
      parseInt(rating, 10) || 0,
    ]
  );

  await cache.invalidate("search:trending");

  const post = await get(`${POST_SELECT} WHERE p.id = ?`, [
    me(req),
    me(req),
    result.lastID,
  ]);

  res.status(201).json({
    success: true,
    message: type === "deep_dive" ? "Deep Dive discussion created" : "Post created successfully",
    post: { ...post, created_ago: timeAgo(post.created_at) },
  });
});

// ---------------------------------------------------------------------------
// PUT /api/posts/:id     (author only)
// ---------------------------------------------------------------------------
export const updatePost = asyncHandler(async (req, res) => {
  const existing = await get(`SELECT * FROM posts WHERE id = ?`, [req.params.id]);

  if (!existing) {
    return res.status(404).json({ success: false, message: "Post not found" });
  }
  if (existing.user_id !== req.user.id) {
    return res.status(403).json({ success: false, message: "You can only edit your own post" });
  }

  const { title, content, fandom_category, hashtags, image_url, post_type, rating } = req.body;

  await run(
    `UPDATE posts SET
       title           = COALESCE(?, title),
       content         = COALESCE(?, content),
       fandom_category = COALESCE(?, fandom_category),
       hashtags        = COALESCE(?, hashtags),
       image_url       = COALESCE(?, image_url),
       post_type       = COALESCE(?, post_type),
       rating          = COALESCE(?, rating),
       updated_at      = CURRENT_TIMESTAMP
     WHERE id = ?`,
    [
      title ?? null,
      content ?? null,
      fandom_category ?? null,
      hashtags !== undefined ? normaliseHashtags(hashtags) : null,
      image_url ?? null,
      post_type ?? null,
      rating !== undefined ? parseInt(rating, 10) || 0 : null,
      req.params.id,
    ]
  );

  await cache.invalidate("search:trending");

  const post = await get(`${POST_SELECT} WHERE p.id = ?`, [
    me(req),
    me(req),
    req.params.id,
  ]);

  res.json({ success: true, message: "Post updated successfully", post });
});

// ---------------------------------------------------------------------------
// DELETE /api/posts/:id  (author only) - cascades comments / likes / bookmarks
// ---------------------------------------------------------------------------
export const deletePost = asyncHandler(async (req, res) => {
  const existing = await get(`SELECT * FROM posts WHERE id = ?`, [req.params.id]);

  if (!existing) {
    return res.status(404).json({ success: false, message: "Post not found" });
  }
  if (existing.user_id !== req.user.id) {
    return res.status(403).json({ success: false, message: "You can only delete your own post" });
  }

  await run(`DELETE FROM comments   WHERE post_id = ?`, [req.params.id]);
  await run(`DELETE FROM post_likes WHERE post_id = ?`, [req.params.id]);
  await run(`DELETE FROM bookmarks  WHERE post_id = ?`, [req.params.id]);
  await run(`DELETE FROM notifications WHERE reference_id = ? AND type <> 'follow'`, [
    req.params.id,
  ]);
  await run(`DELETE FROM posts WHERE id = ?`, [req.params.id]);

  await cache.invalidate("search:trending");

  res.json({ success: true, message: "Post deleted successfully" });
});

// ---------------------------------------------------------------------------
// POST /api/posts/:id/like   -> toggle like (returns new state + count)
// ---------------------------------------------------------------------------
export const toggleLike = asyncHandler(async (req, res) => {
  const postId = req.params.id;
  const userId = req.user.id;

  const post = await get(`SELECT id, user_id, title FROM posts WHERE id = ?`, [postId]);
  if (!post) {
    return res.status(404).json({ success: false, message: "Post not found" });
  }

  const existing = await get(
    `SELECT id FROM post_likes WHERE post_id = ? AND user_id = ?`,
    [postId, userId]
  );

  if (existing) {
    await run(`DELETE FROM post_likes WHERE id = ?`, [existing.id]);
    await run(`UPDATE posts SET likes_count = MAX(likes_count - 1, 0) WHERE id = ?`, [postId]);
  } else {
    await run(`INSERT INTO post_likes (post_id, user_id) VALUES (?, ?)`, [postId, userId]);
    await run(`UPDATE posts SET likes_count = likes_count + 1 WHERE id = ?`, [postId]);

    await notifyWithActor({
      userId: post.user_id,
      actorId: userId,
      type: "like",
      action: `liked your post "${post.title}"`,
      referenceId: Number(postId),
    });
  }

  const updated = await get(`SELECT likes_count FROM posts WHERE id = ?`, [postId]);
  await cache.invalidate("search:trending");

  res.json({
    success: true,
    liked: !existing,
    likes_count: updated.likes_count,
    message: existing ? "Like removed" : "Post liked",
  });
});

// ---------------------------------------------------------------------------
// GET /api/posts/:id/comments
// ---------------------------------------------------------------------------
export const getComments = asyncHandler(async (req, res) => {
  const rows = await all(
    `SELECT
       c.id, c.post_id, c.user_id, c.body, c.likes_count, c.created_at,
       u.name AS author_name, u.avatar AS author_avatar
     FROM comments c
     JOIN users u ON u.id = c.user_id
     WHERE c.post_id = ?
     ORDER BY c.created_at DESC`,
    [req.params.id]
  );

  res.json({
    success: true,
    count: rows.length,
    comments: rows.map((c) => ({ ...c, created_ago: timeAgo(c.created_at) })),
  });
});

// ---------------------------------------------------------------------------
// POST /api/posts/:id/comments
// ---------------------------------------------------------------------------
export const addComment = asyncHandler(async (req, res) => {
  const { body } = req.body;

  if (!body || !String(body).trim()) {
    return res.status(400).json({ success: false, message: "Comment cannot be empty" });
  }

  const post = await get(`SELECT id, user_id, title FROM posts WHERE id = ?`, [req.params.id]);
  if (!post) {
    return res.status(404).json({ success: false, message: "Post not found" });
  }

  const result = await run(
    `INSERT INTO comments (post_id, user_id, body) VALUES (?, ?, ?)`,
    [req.params.id, req.user.id, String(body).trim()]
  );

  await run(`UPDATE posts SET comments_count = comments_count + 1 WHERE id = ?`, [req.params.id]);

  await notifyWithActor({
    userId: post.user_id,
    actorId: req.user.id,
    type: "comment",
    action: `commented on your post "${post.title}"`,
    referenceId: Number(req.params.id),
  });

  const comment = await get(
    `SELECT
       c.id, c.post_id, c.user_id, c.body, c.likes_count, c.created_at,
       u.name AS author_name, u.avatar AS author_avatar
     FROM comments c JOIN users u ON u.id = c.user_id
     WHERE c.id = ?`,
    [result.lastID]
  );

  await cache.invalidate("search:trending");

  res.status(201).json({
    success: true,
    message: "Comment added",
    comment: { ...comment, created_ago: timeAgo(comment.created_at) },
  });
});

// ---------------------------------------------------------------------------
// DELETE /api/posts/comments/:commentId   (comment author or post author)
// ---------------------------------------------------------------------------
export const deleteComment = asyncHandler(async (req, res) => {
  const comment = await get(`SELECT * FROM comments WHERE id = ?`, [req.params.commentId]);

  if (!comment) {
    return res.status(404).json({ success: false, message: "Comment not found" });
  }

  const post = await get(`SELECT user_id FROM posts WHERE id = ?`, [comment.post_id]);
  const isOwner = comment.user_id === req.user.id || post?.user_id === req.user.id;

  if (!isOwner) {
    return res.status(403).json({ success: false, message: "Not allowed to delete this comment" });
  }

  await run(`DELETE FROM comments WHERE id = ?`, [comment.id]);
  await run(`UPDATE posts SET comments_count = MAX(comments_count - 1, 0) WHERE id = ?`, [
    comment.post_id,
  ]);

  res.json({ success: true, message: "Comment deleted" });
});

export default {
  getPosts,
  getDiscussions,
  getPostById,
  createPost,
  updatePost,
  deletePost,
  toggleLike,
  getComments,
  addComment,
  deleteComment,
};
