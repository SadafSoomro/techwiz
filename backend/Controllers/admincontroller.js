/**
 * Member 6 - Admin + Security controller.
 *
 * Replaces the "Firebase Admin CRUD + Security Rules + Notifications + Backup"
 * scope of the SRS with a SQLite-backed implementation:
 *
 *   - Admin login (role = 'admin' users only)
 *   - Dashboard analytics (counts + 7 day trend + recent activity)
 *   - Full CRUD for users / content / events / products / categories
 *   - Broadcast notifications (in-app rows for every user)
 *   - Security settings (password change, login alerts, 2FA flag)
 *   - Backup (a real copy of the SQLite file, downloadable)
 *   - Logs & analytics (admin_logs stream + level breakdown)
 */

import bcrypt from "bcrypt";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import jwt from "jsonwebtoken";
import db from "../database/db.js";
import { all, get, run, asyncHandler, timeAgo } from "../database/dbhelpers.js";
import { logAdminAction } from "../database/adminSchema.js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const DB_FILE = path.join(__dirname, "..", "mydb.sqlite");
const BACKUP_DIR = path.join(__dirname, "..", "backups");

/* =========================================================================
 * helpers
 * ========================================================================= */

const ok = (res, data = {}, message = "OK") =>
  res.json({ success: true, message, ...data });

/** Counts rows without letting a missing table/column blow up the dashboard. */
async function safeCount(sql, params = []) {
  try {
    const row = await get(sql, params);
    return row ? Number(Object.values(row)[0] || 0) : 0;
  } catch {
    return 0;
  }
}

async function safeRows(sql, params = []) {
  try {
    return await all(sql, params);
  } catch {
    return [];
  }
}

function slugify(text) {
  return String(text || "")
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
}

/** ISO date (YYYY-MM-DD) for `n` days ago. */
function dayKey(offset) {
  const d = new Date();
  d.setDate(d.getDate() - offset);
  return d.toISOString().slice(0, 10);
}

/* =========================================================================
 * auth
 * ========================================================================= */

/**
 * POST /api/admin/login
 * Separate from the fan login on purpose: an admin must explicitly enter the
 * portal, and a normal fan account is rejected here (and vice versa - see
 * authcontroller.login, which routes admins into the panel).
 */
export const adminLogin = asyncHandler(async (req, res) => {
  const email = String(req.body.email || "").trim().toLowerCase();
  const { password } = req.body;

  if (!email || !password) {
    return res.status(400).json({
      success: false,
      message: "Email and password are required.",
    });
  }

  const user = await get(`SELECT * FROM users WHERE LOWER(email) = ?`, [email]);

  if (!user) {
    await logAdminAction({
      level: "warn",
      action: "admin_login_failed",
      details: `Unknown admin email: ${email}`,
    });
    return res.status(401).json({
      success: false,
      message: "Invalid administrator credentials.",
    });
  }

  if (String(user.role || "user").toLowerCase() !== "admin") {
    await logAdminAction({
      level: "warn",
      action: "admin_login_denied",
      targetType: "user",
      targetId: user.id,
      details: `${email} tried to open the admin portal without admin role`,
    });
    return res.status(403).json({
      success: false,
      message: "This account does not have administrator access.",
    });
  }

  if (user.is_active === 0) {
    return res.status(403).json({
      success: false,
      message: "This administrator account has been deactivated.",
    });
  }

  const isMatch = await bcrypt.compare(password, user.password || "");
  if (!isMatch) {
    await logAdminAction({
      level: "warn",
      action: "admin_login_failed",
      targetType: "user",
      targetId: user.id,
      details: `Wrong password for ${email}`,
    });
    return res.status(401).json({
      success: false,
      message: "Invalid administrator credentials.",
    });
  }

  const token = jwt.sign(
    { id: user.id, email: user.email, role: "admin" },
    process.env.JWT_SECRET,
    { expiresIn: "7d" }
  );

  await run(
    `UPDATE users SET last_login_at = CURRENT_TIMESTAMP, last_active_at = CURRENT_TIMESTAMP WHERE id = ?`,
    [user.id]
  );

  await logAdminAction({
    adminId: user.id,
    adminEmail: user.email,
    action: "admin_login",
    targetType: "user",
    targetId: user.id,
    details: `${user.name || email} signed in to the admin portal`,
  });

  return ok(
    res,
    {
      token,
      admin: {
        id: user.id,
        name: user.name,
        email: user.email,
        role: "admin",
      },
    },
    "Admin login successful"
  );
});

/** GET /api/admin/me */
export const getMe = asyncHandler(async (req, res) => {
  const user = await get(
    `SELECT id, name, email, role, phone, avatar, created_at, last_login_at
       FROM users WHERE id = ?`,
    [req.admin.id]
  );
  return ok(res, { admin: user });
});

/**
 * PUT /api/admin/profile
 * Allows updating admin's name and password.
 * Strictly prevents changing the admin's email.
 */
export const updateProfile = asyncHandler(async (req, res) => {
  const name = req.body.name !== undefined ? String(req.body.name).trim() : null;
  const current = req.body.current_password ? String(req.body.current_password) : "";
  const next = req.body.new_password ? String(req.body.new_password) : "";

  const user = await get(`SELECT * FROM users WHERE id = ?`, [req.admin.id]);
  if (!user) {
    return res.status(404).json({ success: false, message: "Administrator account not found." });
  }

  // Handle password change if requested
  if (next) {
    if (!current) {
      return res.status(400).json({
        success: false,
        message: "Current password is required to change password.",
      });
    }
    const isMatch = await bcrypt.compare(current, user.password || "");
    if (!isMatch) {
      await logAdminAction({
        adminId: req.admin.id,
        adminEmail: req.admin.email,
        level: "warn",
        action: "password_change_failed",
        targetType: "user",
        targetId: String(req.admin.id),
        details: "Wrong current password during profile edit",
      });
      return res.status(401).json({
        success: false,
        message: "Your current password is incorrect.",
      });
    }
    if (next.length < 6) {
      return res.status(400).json({
        success: false,
        message: "New password must be at least 6 characters.",
      });
    }
    const hash = await bcrypt.hash(next, 10);
    await run(`UPDATE users SET password = ? WHERE id = ?`, [hash, req.admin.id]);

    await logAdminAction({
      adminId: req.admin.id,
      adminEmail: req.admin.email,
      level: "info",
      action: "password_changed",
      targetType: "user",
      targetId: String(req.admin.id),
      details: "Administrator password updated via profile edit",
    });
  }

  // Handle name update (strictly ignoring email changes so email remains constant)
  if (name !== null) {
    if (!name) {
      return res.status(400).json({
        success: false,
        message: "Name cannot be empty.",
      });
    }
    await run(`UPDATE users SET name = ? WHERE id = ?`, [name, req.admin.id]);
  }

  const updatedUser = await get(
    `SELECT id, name, email, role, phone, avatar, created_at, last_login_at
       FROM users WHERE id = ?`,
    [req.admin.id]
  );

  await logAdminAction({
    adminId: req.admin.id,
    adminEmail: req.admin.email,
    action: "profile_updated",
    targetType: "user",
    targetId: String(req.admin.id),
    details: `Administrator profile updated for ${req.admin.email}`,
  });

  return ok(res, { admin: updatedUser }, "Profile updated successfully.");
});

/* =========================================================================
 * dashboard
 * ========================================================================= */

/** GET /api/admin/dashboard */
export const getDashboard = asyncHandler(async (req, res) => {
  const totalUsers = await safeCount(`SELECT COUNT(*) FROM users`);
  const totalContent = await safeCount(`SELECT COUNT(*) FROM content_items`);
  const totalPodcasts = await safeCount(
    `SELECT COUNT(*) FROM content_items WHERE content_type = 'podcast'`
  );
  const totalEvents = await safeCount(`SELECT COUNT(*) FROM events`);
  const totalProducts = await safeCount(`SELECT COUNT(*) FROM products`);
  const totalOrders = await safeCount(`SELECT COUNT(*) FROM orders`);
  const totalPosts = await safeCount(`SELECT COUNT(*) FROM posts`);
  const totalTickets = await safeCount(`SELECT COUNT(*) FROM event_tickets`);

  const revenueRow = await safeRows(`SELECT SUM(total) AS revenue FROM orders`);
  const revenue = Number(revenueRow[0]?.revenue || 0);

  const activeUsers = await safeCount(
    `SELECT COUNT(*) FROM users WHERE COALESCE(is_active, 1) = 1`
  );
  const verifiedUsers = await safeCount(
    `SELECT COUNT(*) FROM users WHERE verified = 1`
  );

  // ---- 7 day trend: signups, content published, orders placed ----
  const series = [];
  for (let offset = 6; offset >= 0; offset--) {
    const day = dayKey(offset);
    series.push({
      date: day,
      label: new Date(day).toLocaleDateString("en-GB", { weekday: "short" }),
      signups: await safeCount(
        `SELECT COUNT(*) FROM users WHERE date(created_at) = ?`,
        [day]
      ),
      content: await safeCount(
        `SELECT COUNT(*) FROM content_items WHERE date(created_at) = ?`,
        [day]
      ),
      orders: await safeCount(
        `SELECT COUNT(*) FROM orders WHERE date(placed_at) = ?`,
        [day]
      ),
    });
  }

  const newThisWeek = series.reduce((sum, d) => sum + d.signups, 0);

  // ---- role breakdown for the users donut ----
  const roleRows = await safeRows(
    `SELECT COALESCE(role, 'user') AS role, COUNT(*) AS total
       FROM users GROUP BY COALESCE(role, 'user') ORDER BY total DESC`
  );

  const contentByType = await safeRows(
    `SELECT content_type AS label, COUNT(*) AS total
       FROM content_items GROUP BY content_type ORDER BY total DESC LIMIT 6`
  );

  const recentUsers = await safeRows(
    `SELECT id, name, email, COALESCE(role,'user') AS role,
            COALESCE(is_active,1) AS is_active, created_at
       FROM users ORDER BY id DESC LIMIT 5`
  );

  const recentActivity = await safeRows(
    `SELECT id, admin_email, level, action, target_type, target_id, details, created_at
       FROM admin_logs ORDER BY id DESC LIMIT 8`
  );

  const topProducts = await safeRows(
    `SELECT id, name, price, currency, stock, sold_count, image_url
       FROM products ORDER BY COALESCE(sold_count,0) DESC, id DESC LIMIT 5`
  );

  const upcomingEvents = await safeRows(
    `SELECT id, title, city_name, event_date, status
       FROM events WHERE status = 'upcoming'
       ORDER BY event_date ASC LIMIT 5`
  );

  return ok(res, {
    stats: {
      totalUsers,
      activeUsers,
      verifiedUsers,
      newThisWeek,
      totalContent,
      totalPodcasts,
      totalEvents,
      totalProducts,
      totalOrders,
      totalPosts,
      totalTickets,
      revenue,
    },
    series,
    roleBreakdown: roleRows,
    contentByType,
    recentUsers,
    recentActivity: recentActivity.map((row) => ({
      ...row,
      ago: timeAgo(row.created_at),
    })),
    topProducts,
    upcomingEvents,
  });
});

/* =========================================================================
 * users
 * ========================================================================= */

/** GET /api/admin/users?search=&role=&status=&page=&limit= */
export const listUsers = asyncHandler(async (req, res) => {
  const search = String(req.query.search || "").trim();
  const role = String(req.query.role || "").trim();
  const status = String(req.query.status || "").trim();
  const page = Math.max(1, parseInt(req.query.page, 10) || 1);
  const limit = Math.min(100, Math.max(5, parseInt(req.query.limit, 10) || 20));
  const offset = (page - 1) * limit;

  const where = [];
  const params = [];

  if (search) {
    where.push(`(name LIKE ? OR email LIKE ? OR phone LIKE ?)`);
    params.push(`%${search}%`, `%${search}%`, `%${search}%`);
  }
  if (role) {
    where.push(`COALESCE(role,'user') = ?`);
    params.push(role);
  }
  if (status === "active") where.push(`COALESCE(is_active,1) = 1`);
  if (status === "blocked") where.push(`COALESCE(is_active,1) = 0`);
  if (status === "verified") where.push(`verified = 1`);
  if (status === "unverified") where.push(`COALESCE(verified,0) = 0`);

  const clause = where.length ? `WHERE ${where.join(" AND ")}` : "";

  const totalRow = await get(
    `SELECT COUNT(*) AS total FROM users ${clause}`,
    params
  );
  const total = Number(totalRow?.total || 0);

  const rows = await all(
    `SELECT id, name, email, phone, COALESCE(role,'user') AS role,
            COALESCE(is_active,1) AS is_active, COALESCE(verified,0) AS verified,
            avatar, COALESCE(points,0) AS points, created_at, last_login_at,
            last_active_at
       FROM users ${clause}
      ORDER BY id DESC LIMIT ? OFFSET ?`,
    [...params, limit, offset]
  );

  // Aggregate counts for the summary chips (independent of the active filter).
  const summary = {
    total: await safeCount(`SELECT COUNT(*) FROM users`),
    admins: await safeCount(
      `SELECT COUNT(*) FROM users WHERE LOWER(COALESCE(role,'user')) = 'admin'`
    ),
    editors: await safeCount(
      `SELECT COUNT(*) FROM users WHERE LOWER(COALESCE(role,'user')) = 'editor'`
    ),
    blocked: await safeCount(
      `SELECT COUNT(*) FROM users WHERE COALESCE(is_active,1) = 0`
    ),
  };

  return ok(res, {
    users: rows.map((u) => ({ ...u, joined_ago: timeAgo(u.created_at) })),
    pagination: { page, limit, total, pages: Math.max(1, Math.ceil(total / limit)) },
    summary,
  });
});

/** GET /api/admin/users/:id */
export const getUserDetail = asyncHandler(async (req, res) => {
  const id = Number(req.params.id);
  const user = await get(
    `SELECT id, name, email, phone, COALESCE(role,'user') AS role,
            COALESCE(is_active,1) AS is_active, COALESCE(verified,0) AS verified,
            avatar, bio, COALESCE(points,0) AS points,
            COALESCE(streak_count,0) AS streak_count, followers_count,
            following_count, created_at, last_login_at, last_active_at
       FROM users WHERE id = ?`,
    [id]
  );

  if (!user) {
    return res.status(404).json({ success: false, message: "User not found." });
  }

  const stats = {
    posts: await safeCount(`SELECT COUNT(*) FROM posts WHERE user_id = ?`, [id]),
    orders: await safeCount(`SELECT COUNT(*) FROM orders WHERE user_id = ?`, [id]),
    bookmarks: await safeCount(
      `SELECT COUNT(*) FROM bookmarks WHERE user_id = ?`,
      [id]
    ),
    tickets: await safeCount(
      `SELECT COUNT(*) FROM event_tickets WHERE user_id = ?`,
      [id]
    ),
  };

  return ok(res, { user, stats });
});

/** POST /api/admin/users */
export const createUser = asyncHandler(async (req, res) => {
  const name = String(req.body.name || "").trim();
  const email = String(req.body.email || "").trim().toLowerCase();
  const phone = String(req.body.phone || "").trim() || null;
  const role = String(req.body.role || "user").trim().toLowerCase();
  const password = String(req.body.password || "").trim() || "Fandom@123";
  const isActive = req.body.is_active === false ? 0 : 1;

  if (!name || !email) {
    return res.status(400).json({
      success: false,
      message: "Name and email are required.",
    });
  }

  const exists = await get(`SELECT id FROM users WHERE LOWER(email) = ?`, [email]);
  if (exists) {
    return res.status(400).json({
      success: false,
      message: "A user with this email already exists.",
    });
  }

  const hash = await bcrypt.hash(password, 10);

  const result = await run(
    `INSERT INTO users
       (name, email, password, phone, role, is_active, verified, created_at, last_active_at)
     VALUES (?, ?, ?, ?, ?, ?, 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`,
    [name, email, hash, phone, role, isActive]
  );

  await logAdminAction({
    adminId: req.admin.id,
    adminEmail: req.admin.email,
    action: "create_user",
    targetType: "user",
    targetId: String(result.lastID),
    details: `Created ${role} account for ${email}`,
  });

  return res.status(201).json({
    success: true,
    message: "User created successfully.",
    id: result.lastID,
  });
});

/** PUT /api/admin/users/:id */
export const updateUser = asyncHandler(async (req, res) => {
  const id = Number(req.params.id);
  const user = await get(`SELECT * FROM users WHERE id = ?`, [id]);

  if (!user) {
    return res.status(404).json({ success: false, message: "User not found." });
  }

  const name = String(req.body.name ?? user.name ?? "").trim();
  const email = String(req.body.email ?? user.email ?? "").trim().toLowerCase();
  const phone = String(req.body.phone ?? user.phone ?? "").trim() || null;
  const role = String(req.body.role ?? user.role ?? "user").trim().toLowerCase();
  const isActive =
    req.body.is_active === undefined
      ? Number(user.is_active ?? 1)
      : req.body.is_active
      ? 1
      : 0;

  // Never let the last admin be demoted or blocked out of the panel.
  if (String(user.role || "").toLowerCase() === "admin" && role !== "admin") {
    const admins = await safeCount(
      `SELECT COUNT(*) FROM users WHERE LOWER(COALESCE(role,'user')) = 'admin'`
    );
    if (admins <= 1) {
      return res.status(400).json({
        success: false,
        message: "Cannot remove the admin role from the only administrator.",
      });
    }
  }

  await run(
    `UPDATE users SET name = ?, email = ?, phone = ?, role = ?, is_active = ?
      WHERE id = ?`,
    [name, email, phone, role, isActive, id]
  );

  // Optional password reset from the admin form.
  const newPassword = String(req.body.password || "").trim();
  if (newPassword) {
    const hash = await bcrypt.hash(newPassword, 10);
    await run(`UPDATE users SET password = ? WHERE id = ?`, [hash, id]);
  }

  await logAdminAction({
    adminId: req.admin.id,
    adminEmail: req.admin.email,
    action: "update_user",
    targetType: "user",
    targetId: String(id),
    details: `Updated ${email}${newPassword ? " (password reset)" : ""}`,
  });

  return ok(res, {}, "User updated successfully.");
});

/** PATCH /api/admin/users/:id/status  { is_active } */
export const setUserStatus = asyncHandler(async (req, res) => {
  const id = Number(req.params.id);
  const user = await get(`SELECT * FROM users WHERE id = ?`, [id]);

  if (!user) {
    return res.status(404).json({ success: false, message: "User not found." });
  }

  if (id === req.admin.id) {
    return res.status(400).json({
      success: false,
      message: "You cannot deactivate your own admin account.",
    });
  }

  const isActive = req.body.is_active ? 1 : 0;
  await run(`UPDATE users SET is_active = ? WHERE id = ?`, [isActive, id]);

  await logAdminAction({
    adminId: req.admin.id,
    adminEmail: req.admin.email,
    level: isActive ? "info" : "warn",
    action: isActive ? "activate_user" : "deactivate_user",
    targetType: "user",
    targetId: String(id),
    details: `${isActive ? "Re-activated" : "Deactivated"} ${user.email}`,
  });

  return ok(
    res,
    { is_active: isActive },
    isActive ? "User activated." : "User deactivated."
  );
});

/** DELETE /api/admin/users/:id */
export const deleteUser = asyncHandler(async (req, res) => {
  const id = Number(req.params.id);
  const user = await get(`SELECT * FROM users WHERE id = ?`, [id]);

  if (!user) {
    return res.status(404).json({ success: false, message: "User not found." });
  }

  if (id === req.admin.id) {
    return res.status(400).json({
      success: false,
      message: "You cannot delete your own admin account.",
    });
  }

  await run(`DELETE FROM users WHERE id = ?`, [id]);

  // Clean up the rows that belong to the deleted account so no orphan data is
  // left behind (the fan-facing queries filter by user_id).
  for (const sql of [
    `DELETE FROM posts WHERE user_id = ?`,
    `DELETE FROM comments WHERE user_id = ?`,
    `DELETE FROM post_likes WHERE user_id = ?`,
    `DELETE FROM bookmarks WHERE user_id = ?`,
    `DELETE FROM followers WHERE follower_id = ? OR following_id = ?`,
    `DELETE FROM notifications WHERE user_id = ?`,
    `DELETE FROM user_fandoms WHERE user_id = ?`,
    `DELETE FROM wishlists WHERE user_id = ?`,
    `DELETE FROM cart_items WHERE user_id = ?`,
    `DELETE FROM saved_events WHERE user_id = ?`,
    `DELETE FROM user_tasks WHERE user_id = ?`,
    `DELETE FROM user_badges WHERE user_id = ?`,
  ]) {
    const pair = sql.includes("follower_id") ? [id, id] : [id];
    try {
      await run(sql, pair);
    } catch {
      // Table not part of this build - skip.
    }
  }

  await logAdminAction({
    adminId: req.admin.id,
    adminEmail: req.admin.email,
    level: "warn",
    action: "delete_user",
    targetType: "user",
    targetId: String(id),
    details: `Deleted user ${user.email}`,
  });

  return ok(res, {}, "User deleted successfully.");
});

/* =========================================================================
 * content
 * ========================================================================= */

const CONTENT_TYPES = ["news", "gallery", "video", "podcast", "deep_dive", "trivia"];

/** GET /api/admin/content?search=&type=&page= */
export const listContent = asyncHandler(async (req, res) => {
  const search = String(req.query.search || "").trim();
  const type = String(req.query.type || "").trim();
  const page = Math.max(1, parseInt(req.query.page, 10) || 1);
  const limit = Math.min(100, Math.max(5, parseInt(req.query.limit, 10) || 20));
  const offset = (page - 1) * limit;

  const where = [];
  const params = [];
  if (search) {
    where.push(`(title LIKE ? OR fandom LIKE ? OR author LIKE ?)`);
    params.push(`%${search}%`, `%${search}%`, `%${search}%`);
  }
  if (type) {
    where.push(`content_type = ?`);
    params.push(type);
  }
  const clause = where.length ? `WHERE ${where.join(" AND ")}` : "";

  const totalRow = await get(
    `SELECT COUNT(*) AS total FROM content_items ${clause}`,
    params
  );

  const rows = await all(
    `SELECT id, title, subtitle, content_type, fandom, author, image_url,
            COALESCE(views_count,0) AS views_count,
            COALESCE(likes_count,0) AS likes_count,
            COALESCE(is_published,1) AS is_published,
            COALESCE(is_featured,0) AS is_featured,
            published_at, created_at
       FROM content_items ${clause}
      ORDER BY id DESC LIMIT ? OFFSET ?`,
    [...params, limit, offset]
  );

  const total = Number(totalRow?.total || 0);

  return ok(res, {
    items: rows,
    types: CONTENT_TYPES,
    counts: {
      all: await safeCount(`SELECT COUNT(*) FROM content_items`),
      news: await safeCount(
        `SELECT COUNT(*) FROM content_items WHERE content_type = 'news'`
      ),
      gallery: await safeCount(
        `SELECT COUNT(*) FROM content_items WHERE content_type = 'gallery'`
      ),
      video: await safeCount(
        `SELECT COUNT(*) FROM content_items WHERE content_type = 'video'`
      ),
      podcast: await safeCount(
        `SELECT COUNT(*) FROM content_items WHERE content_type = 'podcast'`
      ),
    },
    pagination: { page, limit, total, pages: Math.max(1, Math.ceil(total / limit)) },
  });
});

/** POST /api/admin/content */
export const createContent = asyncHandler(async (req, res) => {
  const title = String(req.body.title || "").trim();
  if (!title) {
    return res.status(400).json({ success: false, message: "Title is required." });
  }

  const result = await run(
    `INSERT INTO content_items
       (title, subtitle, summary, body, content_type, fandom, hub_slug, author,
        source, image_url, media_url, duration_seconds, is_published, is_featured)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [
      title,
      req.body.subtitle || null,
      req.body.summary || null,
      req.body.body || null,
      CONTENT_TYPES.includes(req.body.content_type) ? req.body.content_type : "news",
      req.body.fandom || "Anime",
      req.body.hub_slug || null,
      req.body.author || req.admin.name,
      req.body.source || null,
      req.body.image_url || null,
      req.body.media_url || null,
      Number(req.body.duration_seconds || 0),
      req.body.is_published === false ? 0 : 1,
      req.body.is_featured ? 1 : 0,
    ]
  );

  await logAdminAction({
    adminId: req.admin.id,
    adminEmail: req.admin.email,
    action: "create_content",
    targetType: "content",
    targetId: String(result.lastID),
    details: `Published content "${title}"`,
  });

  return res.status(201).json({
    success: true,
    message: "Content created successfully.",
    id: result.lastID,
  });
});

/** PUT /api/admin/content/:id */
export const updateContent = asyncHandler(async (req, res) => {
  const id = Number(req.params.id);
  const item = await get(`SELECT * FROM content_items WHERE id = ?`, [id]);
  if (!item) {
    return res.status(404).json({ success: false, message: "Content not found." });
  }

  await run(
    `UPDATE content_items
        SET title = ?, subtitle = ?, summary = ?, body = ?, content_type = ?,
            fandom = ?, author = ?, image_url = ?, media_url = ?,
            is_published = ?, is_featured = ?, updated_at = CURRENT_TIMESTAMP
      WHERE id = ?`,
    [
      String(req.body.title ?? item.title).trim(),
      req.body.subtitle ?? item.subtitle,
      req.body.summary ?? item.summary,
      req.body.body ?? item.body,
      req.body.content_type ?? item.content_type,
      req.body.fandom ?? item.fandom,
      req.body.author ?? item.author,
      req.body.image_url ?? item.image_url,
      req.body.media_url ?? item.media_url,
      req.body.is_published === undefined
        ? Number(item.is_published ?? 1)
        : req.body.is_published
        ? 1
        : 0,
      req.body.is_featured === undefined
        ? Number(item.is_featured ?? 0)
        : req.body.is_featured
        ? 1
        : 0,
      id,
    ]
  );

  await logAdminAction({
    adminId: req.admin.id,
    adminEmail: req.admin.email,
    action: "update_content",
    targetType: "content",
    targetId: String(id),
    details: `Updated content "${req.body.title ?? item.title}"`,
  });

  return ok(res, {}, "Content updated successfully.");
});

/** DELETE /api/admin/content/:id */
export const deleteContent = asyncHandler(async (req, res) => {
  const id = Number(req.params.id);
  const item = await get(`SELECT title FROM content_items WHERE id = ?`, [id]);
  if (!item) {
    return res.status(404).json({ success: false, message: "Content not found." });
  }

  await run(`DELETE FROM content_items WHERE id = ?`, [id]);
  try {
    await run(`DELETE FROM content_media WHERE content_id = ?`, [id]);
  } catch {
    /* optional table */
  }

  await logAdminAction({
    adminId: req.admin.id,
    adminEmail: req.admin.email,
    level: "warn",
    action: "delete_content",
    targetType: "content",
    targetId: String(id),
    details: `Deleted content "${item.title}"`,
  });

  return ok(res, {}, "Content deleted successfully.");
});

/* =========================================================================
 * events
 * ========================================================================= */

/** GET /api/admin/events?search=&status=&page= */
export const listEvents = asyncHandler(async (req, res) => {
  const search = String(req.query.search || "").trim();
  const status = String(req.query.status || "").trim();
  const page = Math.max(1, parseInt(req.query.page, 10) || 1);
  const limit = Math.min(100, Math.max(5, parseInt(req.query.limit, 10) || 20));
  const offset = (page - 1) * limit;

  const where = [];
  const params = [];
  if (search) {
    where.push(`(title LIKE ? OR city_name LIKE ? OR venue_name LIKE ?)`);
    params.push(`%${search}%`, `%${search}%`, `%${search}%`);
  }
  if (status) {
    where.push(`status = ?`);
    params.push(status);
  }
  const clause = where.length ? `WHERE ${where.join(" AND ")}` : "";

  const totalRow = await get(`SELECT COUNT(*) AS total FROM events ${clause}`, params);

  const rows = await all(
    `SELECT id, title, category, city_name, venue_name, event_date, end_date,
            start_time, ticket_price, currency, image_url, capacity,
            COALESCE(attendees_count,0) AS attendees_count,
            COALESCE(is_featured,0) AS is_featured, status
       FROM events ${clause}
      ORDER BY event_date DESC, id DESC LIMIT ? OFFSET ?`,
    [...params, limit, offset]
  );

  const total = Number(totalRow?.total || 0);

  return ok(res, {
    events: rows,
    counts: {
      all: await safeCount(`SELECT COUNT(*) FROM events`),
      upcoming: await safeCount(
        `SELECT COUNT(*) FROM events WHERE status = 'upcoming'`
      ),
      ongoing: await safeCount(
        `SELECT COUNT(*) FROM events WHERE status = 'ongoing'`
      ),
      completed: await safeCount(
        `SELECT COUNT(*) FROM events WHERE status = 'completed'`
      ),
      cancelled: await safeCount(
        `SELECT COUNT(*) FROM events WHERE status = 'cancelled'`
      ),
    },
    pagination: { page, limit, total, pages: Math.max(1, Math.ceil(total / limit)) },
  });
});

/** POST /api/admin/events */
export const createEvent = asyncHandler(async (req, res) => {
  const title = String(req.body.title || "").trim();
  const city = String(req.body.city_name || "").trim();
  const date = String(req.body.event_date || "").trim();

  if (!title || !city || !date) {
    return res.status(400).json({
      success: false,
      message: "Title, city and event date are required.",
    });
  }

  const result = await run(
    `INSERT INTO events
       (title, description, category, city_name, venue_name, address, event_date,
        end_date, start_time, end_time, ticket_price, currency, image_url,
        organizer, capacity, status, is_featured)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [
      title,
      req.body.description || null,
      req.body.category || "Fan Convention",
      city,
      req.body.venue_name || null,
      req.body.address || null,
      date,
      req.body.end_date || null,
      req.body.start_time || "10:00",
      req.body.end_time || "18:00",
      Number(req.body.ticket_price || 0),
      req.body.currency || "PKR",
      req.body.image_url || null,
      req.body.organizer || null,
      Number(req.body.capacity || 0),
      req.body.status || "upcoming",
      req.body.is_featured ? 1 : 0,
    ]
  );

  await logAdminAction({
    adminId: req.admin.id,
    adminEmail: req.admin.email,
    action: "create_event",
    targetType: "event",
    targetId: String(result.lastID),
    details: `Created event "${title}" in ${city}`,
  });

  return res.status(201).json({
    success: true,
    message: "Event created successfully.",
    id: result.lastID,
  });
});

/** PUT /api/admin/events/:id */
export const updateEvent = asyncHandler(async (req, res) => {
  const id = Number(req.params.id);
  const e = await get(`SELECT * FROM events WHERE id = ?`, [id]);
  if (!e) {
    return res.status(404).json({ success: false, message: "Event not found." });
  }

  await run(
    `UPDATE events
        SET title = ?, description = ?, category = ?, city_name = ?, venue_name = ?,
            event_date = ?, start_time = ?, ticket_price = ?, currency = ?,
            capacity = ?, status = ?, is_featured = ?, updated_at = CURRENT_TIMESTAMP
      WHERE id = ?`,
    [
      String(req.body.title ?? e.title).trim(),
      req.body.description ?? e.description,
      req.body.category ?? e.category,
      req.body.city_name ?? e.city_name,
      req.body.venue_name ?? e.venue_name,
      req.body.event_date ?? e.event_date,
      req.body.start_time ?? e.start_time,
      req.body.ticket_price === undefined
        ? Number(e.ticket_price || 0)
        : Number(req.body.ticket_price),
      req.body.currency ?? e.currency,
      req.body.capacity === undefined ? Number(e.capacity || 0) : Number(req.body.capacity),
      req.body.status ?? e.status,
      req.body.is_featured === undefined
        ? Number(e.is_featured ?? 0)
        : req.body.is_featured
        ? 1
        : 0,
      id,
    ]
  );

  await logAdminAction({
    adminId: req.admin.id,
    adminEmail: req.admin.email,
    action: "update_event",
    targetType: "event",
    targetId: String(id),
    details: `Updated event "${req.body.title ?? e.title}"`,
  });

  return ok(res, {}, "Event updated successfully.");
});

/** DELETE /api/admin/events/:id */
export const deleteEvent = asyncHandler(async (req, res) => {
  const id = Number(req.params.id);
  const e = await get(`SELECT title FROM events WHERE id = ?`, [id]);
  if (!e) {
    return res.status(404).json({ success: false, message: "Event not found." });
  }

  await run(`DELETE FROM events WHERE id = ?`, [id]);
  for (const sql of [
    `DELETE FROM event_tickets WHERE event_id = ?`,
    `DELETE FROM saved_events WHERE event_id = ?`,
  ]) {
    try {
      await run(sql, [id]);
    } catch {
      /* optional table */
    }
  }

  await logAdminAction({
    adminId: req.admin.id,
    adminEmail: req.admin.email,
    level: "warn",
    action: "delete_event",
    targetType: "event",
    targetId: String(id),
    details: `Deleted event "${e.title}"`,
  });

  return ok(res, {}, "Event deleted successfully.");
});

/* =========================================================================
 * products
 * ========================================================================= */

/** GET /api/admin/products?search=&status=&page= */
export const listProducts = asyncHandler(async (req, res) => {
  const search = String(req.query.search || "").trim();
  const status = String(req.query.status || "").trim();
  const page = Math.max(1, parseInt(req.query.page, 10) || 1);
  const limit = Math.min(100, Math.max(5, parseInt(req.query.limit, 10) || 20));
  const offset = (page - 1) * limit;

  const where = [];
  const params = [];
  if (search) {
    where.push(`(name LIKE ? OR category LIKE ? OR fandom LIKE ? OR sku LIKE ?)`);
    params.push(`%${search}%`, `%${search}%`, `%${search}%`, `%${search}%`);
  }
  if (status) {
    where.push(`status = ?`);
    params.push(status);
  }
  const clause = where.length ? `WHERE ${where.join(" AND ")}` : "";

  const totalRow = await get(`SELECT COUNT(*) AS total FROM products ${clause}`, params);

  const rows = await all(
    `SELECT id, name, sku, category, fandom, brand, price, old_price,
            discount_percent, currency, image_url, stock, rating, rating_count,
            sold_count, is_featured, is_digital, status
       FROM products ${clause}
      ORDER BY id DESC LIMIT ? OFFSET ?`,
    [...params, limit, offset]
  );

  const total = Number(totalRow?.total || 0);
  const stockValue = await safeRows(
    `SELECT SUM(price * stock) AS value FROM products WHERE status = 'active'`
  );

  return ok(res, {
    products: rows,
    counts: {
      all: await safeCount(`SELECT COUNT(*) FROM products`),
      active: await safeCount(`SELECT COUNT(*) FROM products WHERE status = 'active'`),
      draft: await safeCount(`SELECT COUNT(*) FROM products WHERE status = 'draft'`),
      outOfStock: await safeCount(`SELECT COUNT(*) FROM products WHERE stock <= 0`),
      lowStock: await safeCount(
        `SELECT COUNT(*) FROM products WHERE stock > 0 AND stock <= 5`
      ),
      inventoryValue: Number(stockValue[0]?.value || 0),
    },
    pagination: { page, limit, total, pages: Math.max(1, Math.ceil(total / limit)) },
  });
});

/** POST /api/admin/products */
export const createProduct = asyncHandler(async (req, res) => {
  const name = String(req.body.name || "").trim();
  if (!name) {
    return res.status(400).json({ success: false, message: "Product name is required." });
  }

  const price = Number(req.body.price || 0);
  const oldPrice = req.body.old_price ? Number(req.body.old_price) : null;
  const discount =
    oldPrice && oldPrice > price
      ? Math.round(((oldPrice - price) / oldPrice) * 100)
      : 0;

  const sku =
    String(req.body.sku || "").trim() || `SKU-${slugify(name).toUpperCase()}-${Date.now() % 10000}`;

  const result = await run(
    `INSERT INTO products
       (name, sku, description, category, fandom, brand, price, old_price,
        discount_percent, currency, image_url, stock, is_featured, is_digital, status)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [
      name,
      sku,
      req.body.description || null,
      req.body.category || "Figures",
      req.body.fandom || null,
      req.body.brand || null,
      price,
      oldPrice,
      discount,
      req.body.currency || "PKR",
      req.body.image_url || null,
      Number(req.body.stock || 0),
      req.body.is_featured ? 1 : 0,
      req.body.is_digital ? 1 : 0,
      req.body.status || "active",
    ]
  );

  await logAdminAction({
    adminId: req.admin.id,
    adminEmail: req.admin.email,
    action: "create_product",
    targetType: "product",
    targetId: String(result.lastID),
    details: `Added product "${name}"`,
  });

  return res.status(201).json({
    success: true,
    message: "Product created successfully.",
    id: result.lastID,
  });
});

/** PUT /api/admin/products/:id */
export const updateProduct = asyncHandler(async (req, res) => {
  const id = Number(req.params.id);
  const p = await get(`SELECT * FROM products WHERE id = ?`, [id]);
  if (!p) {
    return res.status(404).json({ success: false, message: "Product not found." });
  }

  const price = req.body.price === undefined ? Number(p.price || 0) : Number(req.body.price);
  const oldPrice =
    req.body.old_price === undefined
      ? p.old_price
      : req.body.old_price
      ? Number(req.body.old_price)
      : null;

  const discount =
    oldPrice && oldPrice > price
      ? Math.round(((oldPrice - price) / oldPrice) * 100)
      : 0;

  await run(
    `UPDATE products
        SET name = ?, description = ?, category = ?, fandom = ?, brand = ?,
            price = ?, old_price = ?, discount_percent = ?, currency = ?,
            image_url = ?, stock = ?, is_featured = ?, is_digital = ?, status = ?,
            updated_at = CURRENT_TIMESTAMP
      WHERE id = ?`,
    [
      String(req.body.name ?? p.name).trim(),
      req.body.description ?? p.description,
      req.body.category ?? p.category,
      req.body.fandom ?? p.fandom,
      req.body.brand ?? p.brand,
      price,
      oldPrice,
      discount,
      req.body.currency ?? p.currency,
      req.body.image_url ?? p.image_url,
      req.body.stock === undefined ? Number(p.stock || 0) : Number(req.body.stock),
      req.body.is_featured === undefined
        ? Number(p.is_featured ?? 0)
        : req.body.is_featured
        ? 1
        : 0,
      req.body.is_digital === undefined
        ? Number(p.is_digital ?? 0)
        : req.body.is_digital
        ? 1
        : 0,
      req.body.status ?? p.status,
      id,
    ]
  );

  await logAdminAction({
    adminId: req.admin.id,
    adminEmail: req.admin.email,
    action: "update_product",
    targetType: "product",
    targetId: String(id),
    details: `Updated product "${req.body.name ?? p.name}"`,
  });

  return ok(res, {}, "Product updated successfully.");
});

/** DELETE /api/admin/products/:id */
export const deleteProduct = asyncHandler(async (req, res) => {
  const id = Number(req.params.id);
  const p = await get(`SELECT name FROM products WHERE id = ?`, [id]);
  if (!p) {
    return res.status(404).json({ success: false, message: "Product not found." });
  }

  await run(`DELETE FROM products WHERE id = ?`, [id]);
  for (const sql of [
    `DELETE FROM wishlists WHERE product_id = ?`,
    `DELETE FROM cart_items WHERE product_id = ?`,
    `DELETE FROM price_alerts WHERE product_id = ?`,
  ]) {
    try {
      await run(sql, [id]);
    } catch {
      /* optional table */
    }
  }

  await logAdminAction({
    adminId: req.admin.id,
    adminEmail: req.admin.email,
    level: "warn",
    action: "delete_product",
    targetType: "product",
    targetId: String(id),
    details: `Deleted product "${p.name}"`,
  });

  return ok(res, {}, "Product deleted successfully.");
});

/* =========================================================================
 * categories (product / fandom / event)
 * ========================================================================= */

const CATEGORY_KINDS = {
  product: {
    table: "product_categories",
    label: "Shop",
    hasSlug: true,
    hasSort: true,
    usage: { table: "products", column: "category" },
  },
  fandom: {
    table: "fandom_categories",
    label: "Fandom",
    hasSlug: false,
    hasSort: false,
    usage: { table: "content_items", column: "fandom" },
  },
  event: {
    table: "event_categories",
    label: "Event",
    hasSlug: false,
    hasSort: false,
    usage: { table: "events", column: "category" },
  },
};

function resolveKind(kind) {
  return CATEGORY_KINDS[String(kind || "product").toLowerCase()] || CATEGORY_KINDS.product;
}

/** GET /api/admin/categories?kind=product|fandom|event */
export const listCategories = asyncHandler(async (req, res) => {
  const kindKey = String(req.query.kind || "product").toLowerCase();
  const kind = resolveKind(kindKey);

  const rows = await safeRows(`SELECT * FROM ${kind.table} ORDER BY name ASC`);

  // Count how many records use each category so the screen can show usage.
  const withUsage = [];
  for (const row of rows) {
    const used = await safeCount(
      `SELECT COUNT(*) FROM ${kind.usage.table} WHERE ${kind.usage.column} = ?`,
      [row.name]
    );
    withUsage.push({ ...row, usage_count: used });
  }

  return ok(res, {
    kind: kindKey,
    label: kind.label,
    categories: withUsage,
    counts: {
      all: withUsage.length,
      used: withUsage.filter((c) => c.usage_count > 0).length,
      empty: withUsage.filter((c) => c.usage_count === 0).length,
    },
  });
});

/** POST /api/admin/categories  { kind, name, icon, color, description } */
export const createCategory = asyncHandler(async (req, res) => {
  const kindKey = String(req.body.kind || "product").toLowerCase();
  const kind = resolveKind(kindKey);

  const name = String(req.body.name || "").trim();
  if (!name) {
    return res.status(400).json({ success: false, message: "Category name is required." });
  }

  if (kind.hasSlug) {
    const slug = slugify(req.body.slug || name);
    const dup = await get(
      `SELECT id FROM ${kind.table} WHERE LOWER(name) = LOWER(?) OR slug = ?`,
      [name, slug]
    );
    if (dup) {
      return res.status(400).json({
        success: false,
        message: "A category with this name already exists.",
      });
    }

    const result = await run(
      `INSERT INTO ${kind.table} (name, slug, icon, color, description, sort_order)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [
        name,
        slug,
        req.body.icon || "category",
        req.body.color || "#7C3AED",
        req.body.description || null,
        Number(req.body.sort_order || 0),
      ]
    );

    await logAdminAction({
      adminId: req.admin.id,
      adminEmail: req.admin.email,
      action: "create_category",
      targetType: `${kindKey}_category`,
      targetId: String(result.lastID),
      details: `Added ${kind.label} category "${name}"`,
    });

    return res.status(201).json({
      success: true,
      message: "Category created successfully.",
      id: result.lastID,
    });
  }

  const dup = await get(`SELECT id FROM ${kind.table} WHERE LOWER(name) = LOWER(?)`, [
    name,
  ]);
  if (dup) {
    return res.status(400).json({
      success: false,
      message: "A category with this name already exists.",
    });
  }

  const result = await run(
    `INSERT INTO ${kind.table} (name, icon, color, description) VALUES (?, ?, ?, ?)`,
    [
      name,
      req.body.icon || "category",
      req.body.color || "#7C3AED",
      req.body.description || null,
    ]
  );

  await logAdminAction({
    adminId: req.admin.id,
    adminEmail: req.admin.email,
    action: "create_category",
    targetType: `${kindKey}_category`,
    targetId: String(result.lastID),
    details: `Added ${kind.label} category "${name}"`,
  });

  return res.status(201).json({
    success: true,
    message: "Category created successfully.",
    id: result.lastID,
  });
});

/** PUT /api/admin/categories/:id  { kind, ... } */
export const updateCategory = asyncHandler(async (req, res) => {
  const id = Number(req.params.id);
  const kindKey = String(req.body.kind || req.query.kind || "product").toLowerCase();
  const kind = resolveKind(kindKey);

  const existing = await get(`SELECT * FROM ${kind.table} WHERE id = ?`, [id]);
  if (!existing) {
    return res.status(404).json({ success: false, message: "Category not found." });
  }

  const name = String(req.body.name ?? existing.name).trim();

  if (kind.hasSlug) {
    await run(
      `UPDATE ${kind.table}
          SET name = ?, slug = ?, icon = ?, color = ?, description = ?, sort_order = ?
        WHERE id = ?`,
      [
        name,
        slugify(req.body.slug || name),
        req.body.icon ?? existing.icon,
        req.body.color ?? existing.color,
        req.body.description ?? existing.description,
        req.body.sort_order === undefined
          ? Number(existing.sort_order || 0)
          : Number(req.body.sort_order),
        id,
      ]
    );
  } else {
    await run(
      `UPDATE ${kind.table} SET name = ?, icon = ?, color = ?, description = ?
        WHERE id = ?`,
      [
        name,
        req.body.icon ?? existing.icon,
        req.body.color ?? existing.color,
        req.body.description ?? existing.description,
        id,
      ]
    );
  }

  await logAdminAction({
    adminId: req.admin.id,
    adminEmail: req.admin.email,
    action: "update_category",
    targetType: `${kindKey}_category`,
    targetId: String(id),
    details: `Renamed ${kind.label} category to "${name}"`,
  });

  return ok(res, {}, "Category updated successfully.");
});

/** DELETE /api/admin/categories/:id?kind= */
export const deleteCategory = asyncHandler(async (req, res) => {
  const id = Number(req.params.id);
  const kindKey = String(req.query.kind || req.body.kind || "product").toLowerCase();
  const kind = resolveKind(kindKey);

  const existing = await get(`SELECT * FROM ${kind.table} WHERE id = ?`, [id]);
  if (!existing) {
    return res.status(404).json({ success: false, message: "Category not found." });
  }

  const used = await safeCount(
    `SELECT COUNT(*) FROM ${kind.usage.table} WHERE ${kind.usage.column} = ?`,
    [existing.name]
  );

  if (used > 0) {
    return res.status(400).json({
      success: false,
      message: `Cannot delete "${existing.name}" - ${used} record(s) still use it.`,
    });
  }

  await run(`DELETE FROM ${kind.table} WHERE id = ?`, [id]);

  await logAdminAction({
    adminId: req.admin.id,
    adminEmail: req.admin.email,
    level: "warn",
    action: "delete_category",
    targetType: `${kindKey}_category`,
    targetId: String(id),
    details: `Deleted ${kind.label} category "${existing.name}"`,
  });

  return ok(res, {}, "Category deleted successfully.");
});

/* =========================================================================
 * notifications
 * ========================================================================= */

/** GET /api/admin/notifications */
export const listNotifications = asyncHandler(async (req, res) => {
  const rows = await all(
    `SELECT * FROM admin_notifications ORDER BY id DESC LIMIT 50`
  );

  return ok(res, {
    notifications: rows.map((n) => ({ ...n, ago: timeAgo(n.created_at) })),
    audiences: [
      { key: "all", label: "All Users" },
      { key: "new", label: "New Users" },
      { key: "active", label: "Active Fans" },
      { key: "admins", label: "Administrators" },
    ],
    stats: {
      total: await safeCount(`SELECT COUNT(*) FROM admin_notifications`),
      reach: await safeCount(`SELECT SUM(sent_count) FROM admin_notifications`),
      inAppUserNotifications: await safeCount(`SELECT COUNT(*) FROM notifications`),
    },
  });
});

/**
 * POST /api/admin/notifications
 * Stores the announcement AND fans it out into the `notifications` table so
 * the notification bell in the mobile app actually shows it.
 */
export const sendNotification = asyncHandler(async (req, res) => {
  const title = String(req.body.title || "").trim();
  const message = String(req.body.message || "").trim();
  const audience = String(req.body.audience || "all").toLowerCase();
  const icon = String(req.body.icon || "campaign");

  if (!title || !message) {
    return res.status(400).json({
      success: false,
      message: "Title and message are required.",
    });
  }

  // Pick the recipients for the chosen audience.
  let audienceClause = "";
  if (audience === "new") {
    audienceClause = `WHERE date(created_at) >= date('now','-7 days')`;
  } else if (audience === "active") {
    audienceClause = `WHERE COALESCE(is_active,1) = 1`;
  } else if (audience === "admins") {
    audienceClause = `WHERE LOWER(COALESCE(role,'user')) = 'admin'`;
  }

  const recipients = await safeRows(`SELECT id FROM users ${audienceClause}`);

  // The fan-facing `notifications` table is (user_id, actor_id, type, message,
  // reference_id, is_read, created_at) - it has no title/icon column, so the
  // title is folded into the message. `type = 'system'` renders with the amber
  // campaign icon in the app's notification screen.
  const text = `${title} — ${message}`;

  // Insert one row per recipient. Wrapped so a partially built notifications
  // table can never fail the whole request.
  let sent = 0;
  for (const r of recipients) {
    try {
      // Inserted directly instead of via utils/notify.js: an admin broadcast
      // must also reach the sending admin, whereas notify() skips self-notify.
      await run(
        `INSERT INTO notifications (user_id, actor_id, type, message, is_read, created_at)
         VALUES (?, ?, 'system', ?, 0, CURRENT_TIMESTAMP)`,
        [r.id, req.admin.id, text]
      );
      sent++;
    } catch (error) {
      console.error("[admin broadcast]", error.message);
    }
  }

  const result = await run(
    `INSERT INTO admin_notifications (title, message, audience, channel, icon, sent_by, sent_count)
     VALUES (?, ?, ?, ?, ?, ?, ?)`,
    [title, message, audience, "in_app", icon, req.admin.email, sent]
  );

  await logAdminAction({
    adminId: req.admin.id,
    adminEmail: req.admin.email,
    action: "send_notification",
    targetType: "notification",
    targetId: String(result.lastID),
    details: `Sent "${title}" to ${audience} (${sent} recipient(s))`,
  });

  return res.status(201).json({
    success: true,
    message: `Notification sent to ${sent} user(s).`,
    id: result.lastID,
    sent_count: sent,
  });
});

/** DELETE /api/admin/notifications/:id */
export const deleteNotification = asyncHandler(async (req, res) => {
  const id = Number(req.params.id);
  await run(`DELETE FROM admin_notifications WHERE id = ?`, [id]);

  await logAdminAction({
    adminId: req.admin.id,
    adminEmail: req.admin.email,
    action: "delete_notification",
    targetType: "notification",
    targetId: String(id),
    details: `Removed broadcast #${id}`,
  });

  return ok(res, {}, "Notification removed.");
});

/* =========================================================================
 * security
 * ========================================================================= */

async function readSettings() {
  const rows = await safeRows(`SELECT key, value FROM admin_settings`);
  const map = {};
  for (const row of rows) map[row.key] = row.value;
  return map;
}

/** GET /api/admin/security */
export const getSecurity = asyncHandler(async (req, res) => {
  const settings = await readSettings();

  const loginHistory = await safeRows(
    `SELECT id, admin_email, action, level, details, created_at
       FROM admin_logs
      WHERE action IN ('admin_login','admin_login_failed','admin_login_denied')
      ORDER BY id DESC LIMIT 12`
  );

  return ok(res, {
    settings: {
      login_alerts: settings.login_alerts === "1",
      two_factor: settings.two_factor === "1",
      maintenance: settings.maintenance === "1",
      auto_backup: settings.auto_backup === "1",
      registration: settings.registration === "1",
    },
    loginHistory: loginHistory.map((h) => ({ ...h, ago: timeAgo(h.created_at) })),
    stats: {
      admins: await safeCount(
        `SELECT COUNT(*) FROM users WHERE LOWER(COALESCE(role,'user')) = 'admin'`
      ),
      failedLogins: await safeCount(
        `SELECT COUNT(*) FROM admin_logs WHERE action = 'admin_login_failed'`
      ),
      securityEvents: await safeCount(
        `SELECT COUNT(*) FROM admin_logs WHERE level = 'warn'`
      ),
    },
  });
});

/** PUT /api/admin/security/password  { current_password, new_password } */
export const updatePassword = asyncHandler(async (req, res) => {
  const current = String(req.body.current_password || "");
  const next = String(req.body.new_password || "");

  if (!current || !next) {
    return res.status(400).json({
      success: false,
      message: "Current and new password are required.",
    });
  }

  if (next.length < 6) {
    return res.status(400).json({
      success: false,
      message: "New password must be at least 6 characters.",
    });
  }

  const user = await get(`SELECT * FROM users WHERE id = ?`, [req.admin.id]);
  const isMatch = await bcrypt.compare(current, user.password || "");

  if (!isMatch) {
    await logAdminAction({
      adminId: req.admin.id,
      adminEmail: req.admin.email,
      level: "warn",
      action: "password_change_failed",
      targetType: "user",
      targetId: String(req.admin.id),
      details: "Wrong current password on the security screen",
    });
    return res.status(401).json({
      success: false,
      message: "Your current password is incorrect.",
    });
  }

  const hash = await bcrypt.hash(next, 10);
  await run(`UPDATE users SET password = ? WHERE id = ?`, [hash, req.admin.id]);

  await logAdminAction({
    adminId: req.admin.id,
    adminEmail: req.admin.email,
    level: "warn",
    action: "password_changed",
    targetType: "user",
    targetId: String(req.admin.id),
    details: "Administrator password changed",
  });

  return ok(res, {}, "Password updated successfully.");
});

/** PUT /api/admin/security/settings  { key: boolean, ... } */
export const updateSecuritySettings = asyncHandler(async (req, res) => {
  const allowed = ["login_alerts", "two_factor", "maintenance", "auto_backup", "registration"];
  const changed = [];

  for (const key of allowed) {
    if (!(key in req.body)) continue;
    const value = req.body[key] ? "1" : "0";
    await run(
      `INSERT INTO admin_settings (key, value, updated_at)
       VALUES (?, ?, CURRENT_TIMESTAMP)
       ON CONFLICT(key) DO UPDATE SET value = excluded.value, updated_at = CURRENT_TIMESTAMP`,
      [key, value]
    );
    changed.push(`${key}=${value}`);
  }

  if (changed.length) {
    await logAdminAction({
      adminId: req.admin.id,
      adminEmail: req.admin.email,
      action: "update_security_settings",
      targetType: "settings",
      details: changed.join(", "),
    });
  }

  return ok(res, { settings: await readSettings() }, "Security settings saved.");
});

/* =========================================================================
 * backup & database
 * ========================================================================= */

/** GET /api/admin/backup */
export const getBackupInfo = asyncHandler(async (req, res) => {
  let size = 0;
  let modified = null;

  try {
    const stat = fs.statSync(DB_FILE);
    size = stat.size;
    modified = stat.mtime.toISOString();
  } catch {
    /* db file missing */
  }

  const tables = await safeRows(
    `SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%' ORDER BY name`
  );

  const tableCounts = [];
  for (const t of tables) {
    tableCounts.push({
      table: t.name,
      rows: await safeCount(`SELECT COUNT(*) FROM "${t.name}"`),
    });
  }

  let backups = [];
  try {
    backups = fs
      .readdirSync(BACKUP_DIR)
      .filter((f) => f.endsWith(".sqlite"))
      .map((f) => {
        const stat = fs.statSync(path.join(BACKUP_DIR, f));
        return {
          file: f,
          size: stat.size,
          created_at: stat.mtime.toISOString(),
        };
      })
      .sort((a, b) => (a.created_at < b.created_at ? 1 : -1));
  } catch {
    backups = [];
  }

  return ok(res, {
    database: {
      file: path.basename(DB_FILE),
      size,
      modified,
      tables: tableCounts.length,
      totalRows: tableCounts.reduce((sum, t) => sum + t.rows, 0),
    },
    tables: tableCounts.sort((a, b) => b.rows - a.rows),
    backups,
  });
});

/** POST /api/admin/backup - writes a timestamped copy of the SQLite file. */
export const createBackup = asyncHandler(async (req, res) => {
  if (!fs.existsSync(BACKUP_DIR)) fs.mkdirSync(BACKUP_DIR, { recursive: true });

  const stamp = new Date()
    .toISOString()
    .replace(/[:.]/g, "-")
    .replace("T", "_")
    .slice(0, 19);

  const target = path.join(BACKUP_DIR, `techwizz_backup_${stamp}.sqlite`);
  fs.copyFileSync(DB_FILE, target);

  const size = fs.statSync(target).size;

  await logAdminAction({
    adminId: req.admin.id,
    adminEmail: req.admin.email,
    action: "create_backup",
    targetType: "database",
    details: `Backup written to ${path.basename(target)} (${size} bytes)`,
  });

  return res.status(201).json({
    success: true,
    message: "Backup created successfully.",
    backup: {
      file: path.basename(target),
      size,
      created_at: new Date().toISOString(),
    },
  });
});

/** GET /api/admin/backup/download?file= - streams a backup copy. */
export const downloadBackup = asyncHandler(async (req, res) => {
  const requested = String(req.query.file || "").trim();

  // Only allowed to serve files that live inside the backup folder.
  const target = requested
    ? path.join(BACKUP_DIR, path.basename(requested))
    : DB_FILE;

  if (!fs.existsSync(target)) {
    return res.status(404).json({ success: false, message: "Backup file not found." });
  }

  await logAdminAction({
    adminId: req.admin.id,
    adminEmail: req.admin.email,
    action: "download_backup",
    targetType: "database",
    details: `Downloaded ${path.basename(target)}`,
  });

  return res.download(target, path.basename(target));
});

/* =========================================================================
 * logs & analytics
 * ========================================================================= */

/** GET /api/admin/logs?level=&search=&page= */
export const getLogs = asyncHandler(async (req, res) => {
  const level = String(req.query.level || "").trim();
  const search = String(req.query.search || "").trim();
  const page = Math.max(1, parseInt(req.query.page, 10) || 1);
  const limit = Math.min(200, Math.max(10, parseInt(req.query.limit, 10) || 40));
  const offset = (page - 1) * limit;

  const where = [];
  const params = [];
  if (level) {
    where.push(`level = ?`);
    params.push(level);
  }
  if (search) {
    where.push(`(action LIKE ? OR details LIKE ? OR admin_email LIKE ?)`);
    params.push(`%${search}%`, `%${search}%`, `%${search}%`);
  }
  const clause = where.length ? `WHERE ${where.join(" AND ")}` : "";

  const totalRow = await get(`SELECT COUNT(*) AS total FROM admin_logs ${clause}`, params);

  const rows = await all(
    `SELECT * FROM admin_logs ${clause} ORDER BY id DESC LIMIT ? OFFSET ?`,
    [...params, limit, offset]
  );

  // API performance = how busy each endpoint family is, taken from the log.
  const apiPerformance = await safeRows(
    `SELECT action, COUNT(*) AS hits
       FROM admin_logs GROUP BY action ORDER BY hits DESC LIMIT 8`
  );

  const dailyActivity = await safeRows(
    `SELECT date(created_at) AS day, COUNT(*) AS total
       FROM admin_logs
      GROUP BY date(created_at) ORDER BY day DESC LIMIT 7`
  );

  const total = Number(totalRow?.total || 0);

  return ok(res, {
    logs: rows.map((row) => ({ ...row, ago: timeAgo(row.created_at) })),
    counts: {
      all: await safeCount(`SELECT COUNT(*) FROM admin_logs`),
      info: await safeCount(`SELECT COUNT(*) FROM admin_logs WHERE level = 'info'`),
      warn: await safeCount(`SELECT COUNT(*) FROM admin_logs WHERE level = 'warn'`),
      error: await safeCount(`SELECT COUNT(*) FROM admin_logs WHERE level = 'error'`),
    },
    apiPerformance,
    dailyActivity: dailyActivity.reverse(),
    system: {
      uptimeSeconds: Math.floor(process.uptime()),
      nodeVersion: process.version,
      platforms: process.platform,
      memoryMb: Math.round(process.memoryUsage().rss / 1024 / 1024),
      environment: process.env.NODE_ENV || "development",
    },
    pagination: { page, limit, total, pages: Math.max(1, Math.ceil(total / limit)) },
  });
});

/** DELETE /api/admin/logs - clears everything except the audit of the clear. */
export const clearLogs = asyncHandler(async (req, res) => {
  const level = String(req.query.level || "").trim();

  if (level) {
    await run(`DELETE FROM admin_logs WHERE level = ?`, [level]);
  } else {
    await run(`DELETE FROM admin_logs`);
  }

  await logAdminAction({
    adminId: req.admin.id,
    adminEmail: req.admin.email,
    level: "warn",
    action: "clear_logs",
    targetType: "logs",
    details: level ? `Cleared ${level} logs` : "Cleared all logs",
  });

  return ok(res, {}, "Logs cleared.");
});

export default {
  adminLogin,
  getMe,
  getDashboard,
  listUsers,
  getUserDetail,
  createUser,
  updateUser,
  setUserStatus,
  deleteUser,
  listContent,
  createContent,
  updateContent,
  deleteContent,
  listEvents,
  createEvent,
  updateEvent,
  deleteEvent,
  listProducts,
  createProduct,
  updateProduct,
  deleteProduct,
  listCategories,
  createCategory,
  updateCategory,
  deleteCategory,
  listNotifications,
  sendNotification,
  deleteNotification,
  getSecurity,
  updatePassword,
  updateSecuritySettings,
  getBackupInfo,
  createBackup,
  downloadBackup,
  getLogs,
  clearLogs,
};
