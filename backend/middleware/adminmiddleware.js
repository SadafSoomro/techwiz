/**
 * Member 6 - Admin authorisation middleware.
 *
 * The admin panel is a completely separate surface from the fan-facing app, so
 * it gets its own guard instead of reusing `requireAuth`:
 *
 *   requireAdmin  -> valid JWT **and** users.role = 'admin' **and** active.
 *   requireRole   -> same, but accepts a list of roles (admin | editor | user).
 *
 * The role is re-read from the database on every request rather than trusted
 * from the token, so demoting an admin takes effect immediately instead of
 * after their 7-day token expires.
 */

import jwt from "jsonwebtoken";
import { get } from "../database/dbhelpers.js";

function readToken(req) {
  const header = req.headers.authorization || "";
  if (header.startsWith("Bearer ")) return header.slice(7).trim();
  if (req.query && req.query.token) return String(req.query.token);
  return null;
}

/**
 * Verifies the JWT and loads the current role/active state from SQLite.
 * Returns the user row, or null when the caller is not a valid admin.
 */
export async function resolveAdmin(token) {
  if (!token) return null;

  let decoded;
  try {
    decoded = jwt.verify(token, process.env.JWT_SECRET);
  } catch {
    return null;
  }

  const user = await get(
    `SELECT id, name, email, role, is_active FROM users WHERE id = ?`,
    [decoded.id]
  );

  if (!user) return null;
  if (user.is_active === 0) return null;
  return user;
}

export const requireAdmin = async (req, res, next) => {
  try {
    const user = await resolveAdmin(readToken(req));

    if (!user) {
      return res.status(401).json({
        success: false,
        message: "Admin authentication required. Please log in again.",
      });
    }

    if (String(user.role || "user").toLowerCase() !== "admin") {
      return res.status(403).json({
        success: false,
        message: "Access denied. Administrator privileges are required.",
      });
    }

    req.admin = { id: user.id, name: user.name, email: user.email };
    return next();
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

/** Guard for routes that admins and editors may both reach. */
export const requireRole = (...roles) => async (req, res, next) => {
  try {
    const user = await resolveAdmin(readToken(req));

    if (!user) {
      return res.status(401).json({
        success: false,
        message: "Authentication required. Please log in again.",
      });
    }

    const role = String(user.role || "user").toLowerCase();
    if (!roles.map((r) => r.toLowerCase()).includes(role)) {
      return res.status(403).json({
        success: false,
        message: "Access denied. You do not have permission for this action.",
      });
    }

    req.admin = { id: user.id, name: user.name, email: user.email, role };
    return next();
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

export default { requireAdmin, requireRole, resolveAdmin };
