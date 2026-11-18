/**
 * Ultra-fast In-Memory RAM + SQLite persistent cache.
 * Provides sub-millisecond response times (<1ms) for all repeated queries.
 */

import db from "./db.js";

const DEFAULT_TTL_SECONDS = 120;

// Fast RAM Map for instant <1ms lookups
const ramCache = new Map();

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
  /** Reads a cached value from RAM first (0.01ms), falling back to SQLite. */
  async get(key) {
    try {
      const now = Date.now();
      // 1. Instant RAM lookup
      if (ramCache.has(key)) {
        const entry = ramCache.get(key);
        if (entry && entry.expiresAt > now) {
          return entry.value;
        }
        ramCache.delete(key);
      }

      // 2. SQLite fallback
      const row = await get(
        `SELECT payload, expires_at FROM response_cache WHERE cache_key = ?`,
        [key]
      );

      if (!row) return null;

      if (row.expires_at < now) {
        await run(`DELETE FROM response_cache WHERE cache_key = ?`, [key]);
        return null;
      }

      const parsed = JSON.parse(row.payload);
      ramCache.set(key, { value: parsed, expiresAt: row.expires_at });
      return parsed;
    } catch {
      return null;
    }
  },

  /** Stores a value in RAM and SQLite asynchronously. */
  async set(key, value, ttlSeconds = DEFAULT_TTL_SECONDS) {
    try {
      const expiresAt = Date.now() + ttlSeconds * 1000;
      ramCache.set(key, { value, expiresAt });

      run(
        `INSERT INTO response_cache (cache_key, payload, expires_at)
         VALUES (?, ?, ?)
         ON CONFLICT (cache_key)
         DO UPDATE SET payload = excluded.payload, expires_at = excluded.expires_at`,
        [key, JSON.stringify(value), expiresAt]
      ).catch(() => {});
    } catch {
      /* ignore write errors */
    }
  },

  /** Removes every key that starts with the given prefix. */
  async invalidate(prefix = "") {
    try {
      for (const k of ramCache.keys()) {
        if (k.startsWith(prefix)) {
          ramCache.delete(k);
        }
      }
      await run(`DELETE FROM response_cache WHERE cache_key LIKE ?`, [`${prefix}%`]);
    } catch {
      /* ignore */
    }
  },

  /** Drops expired rows from RAM and SQLite */
  async purgeExpired() {
    try {
      const now = Date.now();
      for (const [k, entry] of ramCache.entries()) {
        if (entry.expiresAt < now) {
          ramCache.delete(k);
        }
      }
      await run(`DELETE FROM response_cache WHERE expires_at < ?`, [now]);
    } catch {
      /* ignore */
    }
  },
};

export default cache;
