/**
 * Promise based helpers around the sqlite3 callback API.
 * Keeps the Search & Community controllers readable.
 */

import db from "./db.js";

export function all(sql, params = []) {
  return new Promise((resolve, reject) => {
    db.all(sql, params, (err, rows) => {
      if (err) reject(err);
      else resolve(rows || []);
    });
  });
}

export function get(sql, params = []) {
  return new Promise((resolve, reject) => {
    db.get(sql, params, (err, row) => {
      if (err) reject(err);
      else resolve(row || null);
    });
  });
}

export function run(sql, params = []) {
  return new Promise((resolve, reject) => {
    db.run(sql, params, function (err) {
      if (err) reject(err);
      else resolve({ lastID: this.lastID, changes: this.changes });
    });
  });
}

/** Wraps a controller body so DB errors always return a clean 500 response. */
export function asyncHandler(fn) {
  return async (req, res) => {
    try {
      await fn(req, res);
    } catch (error) {
      console.error("[Search & Community API]", error.message);
      if (!res.headersSent) {
        res.status(500).json({ success: false, message: error.message });
      }
    }
  };
}

/** "2 hours ago" style label used across the community feed. */
export function timeAgo(dateString) {
  if (!dateString) return "";
  const then = new Date(String(dateString).replace(" ", "T") + "Z").getTime();
  const seconds = Math.max(1, Math.floor((Date.now() - then) / 1000));

  const steps = [
    [31536000, "y"],
    [2592000, "mo"],
    [604800, "w"],
    [86400, "d"],
    [3600, "h"],
    [60, "m"],
  ];

  for (const [unit, label] of steps) {
    if (seconds >= unit) return `${Math.floor(seconds / unit)}${label} ago`;
  }
  return `${seconds}s ago`;
}

export default { all, get, run, asyncHandler, timeAgo };
