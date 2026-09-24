/**
 * JWT authentication middleware for the Search & Community module.
 *
 * requireAuth  -> request is rejected with 401 when no valid token is sent.
 * optionalAuth -> request continues, but req.user is filled when a token
 *                 is present (used by public feeds so they can show
 *                 "liked by me" / "bookmarked by me" flags).
 */

import jwt from "jsonwebtoken";

function readToken(req) {
  const header = req.headers.authorization || "";
  if (header.startsWith("Bearer ")) return header.slice(7).trim();
  if (req.query && req.query.token) return String(req.query.token);
  return null;
}

export const requireAuth = (req, res, next) => {
  const token = readToken(req);

  if (!token) {
    return res.status(401).json({
      success: false,
      message: "Authentication required. Please log in.",
    });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = { id: decoded.id, email: decoded.email };
    return next();
  } catch (error) {
    return res.status(401).json({
      success: false,
      message: "Session expired or invalid token. Please log in again.",
    });
  }
};

export const optionalAuth = (req, res, next) => {
  const token = readToken(req);

  if (token) {
    try {
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      req.user = { id: decoded.id, email: decoded.email };
    } catch {
      req.user = null;
    }
  } else {
    req.user = null;
  }

  return next();
};

export default { requireAuth, optionalAuth };
