/**
 * MEMBER 3 - Search & Community
 * Community controller: Bookmarks (saved posts), Follow/Followers,
 * Notifications and the public User Profile screen.
 */

import { all, get, run, asyncHandler, timeAgo } from "../database/dbhelpers.js";
import cache from "../database/cache.js";
import { notifyWithActor } from "../utils/notify.js";

function me(req) {
  return req.user?.id ?? -1;
}

// ---------------------------------------------------------------------------
// GET /api/community/users/:id/profile
// Public profile of a member: stats + fandoms + recent posts
// ---------------------------------------------------------------------------
export const getUserProfile = asyncHandler(async (req, res) => {
  const profileId = parseInt(req.params.id, 10);
  const viewerId = me(req);

  const user = await get(
    `SELECT
       u.id, u.name, u.avatar, u.bio,
       IFNULL(u.created_at, CURRENT_TIMESTAMP) AS created_at,
       IFNULL(u.followers_count, 0) AS followers_count,
       IFNULL(u.following_count, 0) AS following_count,
       (SELECT COUNT(*) FROM posts p WHERE p.user_id = u.id AND p.is_published = 1) AS posts_count,
       (SELECT IFNULL(SUM(p.likes_count), 0) FROM posts p WHERE p.user_id = u.id) AS total_likes,
       EXISTS (SELECT 1 FROM follows f
               WHERE f.follower_id = ? AND f.following_id = u.id) AS is_following
     FROM users u
     WHERE u.id = ?`,
    [viewerId, profileId]
  );

  if (!user) {
    return res.status(404).json({ success: false, message: "User not found" });
  }

  const fandoms = await all(
    `SELECT uf.fandom, fc.hashtag, fc.icon, fc.color
     FROM user_fandoms uf
     LEFT JOIN fandom_categories fc ON fc.name = uf.fandom
     WHERE uf.user_id = ?`,
    [profileId]
  );

  const posts = await all(
    `SELECT
       p.id, p.title, p.content, p.fandom_category AS fandom, p.post_type,
       p.likes_count, p.comments_count, p.views_count, p.created_at,
       EXISTS (SELECT 1 FROM bookmarks b WHERE b.post_id = p.id AND b.user_id = ?) AS is_bookmarked
     FROM posts p
     WHERE p.user_id = ? AND p.is_published = 1
     ORDER BY p.created_at DESC
     LIMIT 10`,
    [viewerId, profileId]
  );

  const badges = await all(
    `SELECT type, message, created_at FROM notifications
     WHERE user_id = ? AND type = 'system' ORDER BY id DESC LIMIT 5`,
    [profileId]
  );

  res.json({
    success: true,
    isOwnProfile: profileId === viewerId,
    user: {
      ...user,
      joined_ago: timeAgo(user.created_at),
      selected_fandoms: fandoms.map((f) => f.fandom),
    },
    fandoms,
    posts: posts.map((p) => ({ ...p, created_ago: timeAgo(p.created_at) })),
    badges,
  });
});

// ---------------------------------------------------------------------------
// PUT /api/community/profile   -> update own bio / avatar / fandoms
// ---------------------------------------------------------------------------
export const updateMyProfile = asyncHandler(async (req, res) => {
  const { name, bio, avatar, selected_fandoms } = req.body;
  const userId = req.user.id;

  await run(
    `UPDATE users SET
       name   = COALESCE(?, name),
       bio    = COALESCE(?, bio),
       avatar = COALESCE(?, avatar)
     WHERE id = ?`,
    [name ?? null, bio ?? null, avatar ?? null, userId]
  );

  if (Array.isArray(selected_fandoms)) {
    await run(`DELETE FROM user_fandoms WHERE user_id = ?`, [userId]);
    for (const fandom of selected_fandoms) {
      await run(`INSERT OR IGNORE INTO user_fandoms (user_id, fandom) VALUES (?, ?)`, [
        userId,
        String(fandom),
      ]);
    }
  }

  const user = await get(
    `SELECT id, name, email, bio, avatar FROM users WHERE id = ?`,
    [userId]
  );

  res.json({ success: true, message: "Profile updated", user });
});

// ---------------------------------------------------------------------------
// POST /api/community/users/:id/follow   -> toggle follow
// ---------------------------------------------------------------------------
export const toggleFollow = asyncHandler(async (req, res) => {
  const targetId = parseInt(req.params.id, 10);
  const userId = req.user.id;

  if (targetId === userId) {
    return res.status(400).json({ success: false, message: "You cannot follow yourself" });
  }

  const target = await get(`SELECT id, name FROM users WHERE id = ?`, [targetId]);
  if (!target) {
    return res.status(404).json({ success: false, message: "User not found" });
  }

  const existing = await get(
    `SELECT id FROM follows WHERE follower_id = ? AND following_id = ?`,
    [userId, targetId]
  );

  if (existing) {
    await run(`DELETE FROM follows WHERE id = ?`, [existing.id]);
    await run(`UPDATE users SET following_count = MAX(IFNULL(following_count,0) - 1, 0) WHERE id = ?`, [userId]);
    await run(`UPDATE users SET followers_count = MAX(IFNULL(followers_count,0) - 1, 0) WHERE id = ?`, [targetId]);
  } else {
    await run(`INSERT INTO follows (follower_id, following_id) VALUES (?, ?)`, [userId, targetId]);
    await run(`UPDATE users SET following_count = IFNULL(following_count,0) + 1 WHERE id = ?`, [userId]);
    await run(`UPDATE users SET followers_count = IFNULL(followers_count,0) + 1 WHERE id = ?`, [targetId]);

    await notifyWithActor({
      userId: targetId,
      actorId: userId,
      type: "follow",
      action: "started following you",
    });
  }

  const counts = await get(
    `SELECT IFNULL(followers_count,0) AS followers_count,
            IFNULL(following_count,0) AS following_count
     FROM users WHERE id = ?`,
    [targetId]
  );

  await cache.invalidate("search:trending");

  res.json({
    success: true,
    following: !existing,
    followers_count: counts.followers_count,
    following_count: counts.following_count,
    message: existing ? `Unfollowed ${target.name}` : `Now following ${target.name}`,
  });
});

// GET /api/community/users/:id/followers
export const getFollowers = asyncHandler(async (req, res) => {
  const id = parseInt(req.params.id, 10);

  const rows = await all(
    `SELECT u.id, u.name, u.avatar, u.bio, IFNULL(u.followers_count,0) AS followers_count,
            EXISTS (SELECT 1 FROM follows f2
                    WHERE f2.follower_id = ? AND f2.following_id = u.id) AS is_following
     FROM follows f
     JOIN users u ON u.id = f.follower_id
     WHERE f.following_id = ?
     ORDER BY f.created_at DESC`,
    [me(req), id]
  );

  res.json({ success: true, count: rows.length, followers: rows });
});

// GET /api/community/users/:id/following
export const getFollowing = asyncHandler(async (req, res) => {
  const id = parseInt(req.params.id, 10);

  const rows = await all(
    `SELECT u.id, u.name, u.avatar, u.bio, IFNULL(u.followers_count,0) AS followers_count,
            EXISTS (SELECT 1 FROM follows f2
                    WHERE f2.follower_id = ? AND f2.following_id = u.id) AS is_following
     FROM follows f
     JOIN users u ON u.id = f.following_id
     WHERE f.follower_id = ?
     ORDER BY f.created_at DESC`,
    [me(req), id]
  );

  res.json({ success: true, count: rows.length, following: rows });
});

// ---------------------------------------------------------------------------
// BOOKMARKS  (Saved Posts screen)
// ---------------------------------------------------------------------------

// GET /api/community/bookmarks
export const getBookmarks = asyncHandler(async (req, res) => {
  const userId = me(req);

  const rows = await all(
    `SELECT
       b.id AS bookmark_id,
       b.saved_at,
       p.id, p.user_id, p.title, p.content, p.image_url, p.hashtags,
       p.fandom_category AS fandom, p.post_type,
       p.likes_count, p.comments_count, p.views_count, p.created_at,
       u.name AS author_name, u.avatar AS author_avatar,
       EXISTS (SELECT 1 FROM post_likes pl
               WHERE pl.post_id = p.id AND pl.user_id = ?) AS is_liked,
       1 AS is_bookmarked
     FROM bookmarks b
     JOIN posts p ON p.id = b.post_id
     JOIN users u ON u.id = p.user_id
     WHERE b.user_id = ?
     ORDER BY b.saved_at DESC`,
    [userId, userId]
  );

  res.json({
    success: true,
    count: rows.length,
    bookmarks: rows.map((r) => ({
      ...r,
      saved_ago: timeAgo(r.saved_at),
      created_ago: timeAgo(r.created_at),
    })),
  });
});

// POST /api/community/bookmarks/:postId  -> toggle save
export const toggleBookmark = asyncHandler(async (req, res) => {
  const postId = req.params.postId;
  const userId = req.user.id;

  const post = await get(`SELECT id, user_id, title FROM posts WHERE id = ?`, [postId]);
  if (!post) {
    return res.status(404).json({ success: false, message: "Post not found" });
  }

  const existing = await get(
    `SELECT id FROM bookmarks WHERE user_id = ? AND post_id = ?`,
    [userId, postId]
  );

  if (existing) {
    await run(`DELETE FROM bookmarks WHERE id = ?`, [existing.id]);
  } else {
    await run(`INSERT INTO bookmarks (user_id, post_id) VALUES (?, ?)`, [userId, postId]);

    await notifyWithActor({
      userId: post.user_id,
      actorId: userId,
      type: "bookmark",
      action: `saved your post "${post.title}"`,
      referenceId: Number(postId),
    });
  }

  const total = await get(`SELECT COUNT(*) AS total FROM bookmarks WHERE user_id = ?`, [userId]);

  res.json({
    success: true,
    bookmarked: !existing,
    total_bookmarks: total.total,
    message: existing ? "Removed from saved posts" : "Saved to bookmarks",
  });
});

// DELETE /api/community/bookmarks  -> clear all saved posts
export const clearBookmarks = asyncHandler(async (req, res) => {
  await run(`DELETE FROM bookmarks WHERE user_id = ?`, [req.user.id]);
  res.json({ success: true, message: "All saved posts removed" });
});

// ---------------------------------------------------------------------------
// NOTIFICATIONS
// ---------------------------------------------------------------------------

// GET /api/community/notifications?filter=all|unread
export const getNotifications = asyncHandler(async (req, res) => {
  const filter = String(req.query.filter || "all").toLowerCase();
  const userId = me(req);

  const where = filter === "unread" ? "AND n.is_read = 0" : "";

  const rows = await all(
    `SELECT
       n.id, n.type, n.message, n.reference_id, n.is_read, n.created_at,
       n.actor_id,
       u.name   AS actor_name,
       u.avatar AS actor_avatar
     FROM notifications n
     LEFT JOIN users u ON u.id = n.actor_id
     WHERE n.user_id = ? ${where}
     ORDER BY n.created_at DESC, n.id DESC
     LIMIT 60`,
    [userId]
  );

  const unread = await get(
    `SELECT COUNT(*) AS count FROM notifications WHERE user_id = ? AND is_read = 0`,
    [userId]
  );

  res.json({
    success: true,
    unread_count: unread.count,
    count: rows.length,
    notifications: rows.map((n) => ({ ...n, created_ago: timeAgo(n.created_at) })),
  });
});

// POST /api/community/notifications/:id/read
export const markNotificationRead = asyncHandler(async (req, res) => {
  await run(`UPDATE notifications SET is_read = 1 WHERE id = ? AND user_id = ?`, [
    req.params.id,
    req.user.id,
  ]);
  res.json({ success: true, message: "Notification marked as read" });
});

// POST /api/community/notifications/read-all
export const markAllRead = asyncHandler(async (req, res) => {
  await run(`UPDATE notifications SET is_read = 1 WHERE user_id = ?`, [req.user.id]);
  res.json({ success: true, message: "All notifications marked as read" });
});

// DELETE /api/community/notifications/:id
export const deleteNotification = asyncHandler(async (req, res) => {
  await run(`DELETE FROM notifications WHERE id = ? AND user_id = ?`, [
    req.params.id,
    req.user.id,
  ]);
  res.json({ success: true, message: "Notification deleted" });
});

// ---------------------------------------------------------------------------
// GET /api/community/overview -> small dashboard card for the community tab
// ---------------------------------------------------------------------------
export const getCommunityOverview = asyncHandler(async (req, res) => {
  const userId = me(req);

  const stats = await get(
    `SELECT
       (SELECT COUNT(*) FROM posts WHERE is_published = 1)                           AS total_posts,
       (SELECT COUNT(*) FROM posts WHERE post_type = 'deep_dive')                    AS total_discussions,
       (SELECT COUNT(*) FROM users WHERE verified = 1)                               AS total_members,
       (SELECT COUNT(*) FROM bookmarks WHERE user_id = ?)                            AS my_bookmarks,
       (SELECT COUNT(*) FROM notifications WHERE user_id = ? AND is_read = 0)       AS unread_notifications,
       (SELECT COUNT(*) FROM follows WHERE follower_id = ?)                          AS my_following`,
    [userId, userId, userId]
  );

  const trendingFandoms = await all(
    `SELECT name, hashtag, icon, color,
            (SELECT COUNT(*) FROM posts p
              WHERE p.fandom_category = fandom_categories.name) AS posts_count
     FROM fandom_categories
     ORDER BY posts_count DESC LIMIT 5`
  );

  res.json({ success: true, stats, trendingFandoms });
});

export default {
  getUserProfile,
  updateMyProfile,
  toggleFollow,
  getFollowers,
  getFollowing,
  getBookmarks,
  toggleBookmark,
  clearBookmarks,
  getNotifications,
  markNotificationRead,
  markAllRead,
  deleteNotification,
  getCommunityOverview,
};
