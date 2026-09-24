/**
 * Lightweight "Redis style" cache built on SQLite.
 * The SRS asked for Redis in Member 3 (Search & Community); this project
 * uses SQLite for the whole backend, so caching is done with a TTL table.
 *
 * Usage:
 *   const cached = await cache.get("search:anime");
 *   if (cached) { ... }
 *   await cache.set("search:anime", payload, 60); // 60 seconds
 *   await cache.invalidate("search");             // prefix flush
 */

import db from "./db.js";

const DEFAULT_TTL_SECONDS = 60;

function run(sql, params = []) {
  return new Promise((resolve, reject) => {
    db.run(sql, params, function (err) {
      if (err) reject(err);
      else resolve(this);
    });
  });
}

function get(sql, params = []) {
  return new Promise((resolve, reject) => {
    db.get(sql, params, (err, row) => {
      if (err) reject(err);
      else resolve(row);
    });
  });
}

export const cache = {
  /** Reads a cached value. Returns null when missing or expired. */
  async get(key) {
    try {
      const row = await get(
        `SELECT payload, expires_at FROM response_cache WHERE cache_key = ?`,
        [key]
      );

      if (!row) return null;

      if (row.expires_at < Date.now()) {
        await run(`DELETE FROM response_cache WHERE cache_key = ?`, [key]);
        return null;
      }

      return JSON.parse(row.payload);
    } catch {
      return null; // never let the cache break a request
    }
  },

  /** Stores a value with a TTL (seconds). */
  async set(key, value, ttlSeconds = DEFAULT_TTL_SECONDS) {
    try {
      const expiresAt = Date.now() + ttlSeconds * 1000;
      await run(
        `INSERT INTO response_cache (cache_key, payload, expires_at)
         VALUES (?, ?, ?)
         ON CONFLICT (cache_key)
         DO UPDATE SET payload = excluded.payload, expires_at = excluded.expires_at`,
        [key, JSON.stringify(value), expiresAt]
      );
    } catch {
      /* ignore cache write errors */
    }
  },

  /** Removes every key that starts with the given prefix (LIKE flush). */
  async invalidate(prefix = "") {
    try {
      await run(`DELETE FROM response_cache WHERE cache_key LIKE ?`, [`${prefix}%`]);
    } catch {
      /* ignore */
    }
  },

  /** Drops expired rows - called periodically from server.js */
  async purgeExpired() {
    try {
      await run(`DELETE FROM response_cache WHERE expires_at < ?`, [Date.now()]);
    } catch {
      /* ignore */
    }
  },
};

export default cache;
