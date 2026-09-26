/**
 * Member 6 - Admin + Security (SQLite replaces Firebase Admin SDK).
 *
 * Adds the admin/moderation columns onto the shared `users` table, creates the
 * admin-only tables (activity logs, broadcast notifications, settings), and
 * seeds the single built-in administrator account.
 *
 * Everything here is idempotent: it runs on every boot and every statement is
 * written so that "already exists" is a harmless no-op.
 */

import bcrypt from "bcrypt";
import db from "./db.js";

/** Built-in administrator account. */
export const ADMIN_NAME = "Shazmeen Ayaz";
export const ADMIN_EMAIL = "shazmeenayaz1@gmail.com";
export const ADMIN_PASSWORD = "shazmeen12";

export function initAdminSchema() {
  db.serialize(() => {
    // ---------------- admin / moderation columns on users ----------------
    // `role` is what the admin middleware checks: 'admin' | 'editor' | 'user'.
    db.run(`ALTER TABLE users ADD COLUMN role TEXT DEFAULT 'user'`, () => {});
    db.run(`ALTER TABLE users ADD COLUMN phone TEXT`, () => {});
    // Soft ban flag - a deactivated user keeps their data but cannot log in.
    db.run(`ALTER TABLE users ADD COLUMN is_active INTEGER DEFAULT 1`, () => {});
    db.run(`ALTER TABLE users ADD COLUMN last_login_at TEXT`, () => {});

    // ------------------------- admin activity log -------------------------
    // Powers "Logs & Analytics" (user activity, system logs, error logs).
    db.run(`
      CREATE TABLE IF NOT EXISTS admin_logs (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        admin_id    INTEGER,
        admin_email TEXT,
        level       TEXT DEFAULT 'info',
        action      TEXT NOT NULL,
        target_type TEXT,
        target_id   TEXT,
        details     TEXT,
        created_at  TEXT DEFAULT CURRENT_TIMESTAMP
      )
    `);

    db.run(`CREATE INDEX IF NOT EXISTS idx_admin_logs_created ON admin_logs(created_at)`);

    // --------------------- broadcast notifications ------------------------
    // Records every announcement the admin pushes to users.
    db.run(`
      CREATE TABLE IF NOT EXISTS admin_notifications (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        title      TEXT NOT NULL,
        message    TEXT NOT NULL,
        audience   TEXT DEFAULT 'all',
        channel    TEXT DEFAULT 'in_app',
        icon       TEXT DEFAULT 'campaign',
        sent_by    TEXT,
        sent_count INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // ------------------------- security settings --------------------------
    // Key/value store for the Security Settings screen (login alerts, 2FA...).
    db.run(`
      CREATE TABLE IF NOT EXISTS admin_settings (
        key        TEXT PRIMARY KEY,
        value      TEXT,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    `);

    db.run(`
      INSERT OR IGNORE INTO admin_settings (key, value) VALUES
        ('login_alerts',   '1'),
        ('two_factor',     '0'),
        ('maintenance',    '0'),
        ('auto_backup',    '1'),
        ('registration',   '1')
    `);

    // One-time repair: accounts created before the admin module existed have a
    // NULL created_at / role / is_active, which would leave gaps in the
    // dashboard trend chart and make the role filter miss them.
    db.run(`UPDATE users SET created_at = CURRENT_TIMESTAMP WHERE created_at IS NULL`);
    db.run(`UPDATE users SET role = 'user' WHERE role IS NULL`);
    db.run(`UPDATE users SET is_active = 1 WHERE is_active IS NULL`);
  });

  seedAdminAccount();
}

/**
 * Creates the built-in admin if it is missing, and keeps its password/role in
 * sync with the constants above so the credentials in the SRS always work.
 */
async function seedAdminAccount() {
  try {
    const existing = await get(
      `SELECT id, role FROM users WHERE email = ?`,
      [ADMIN_EMAIL]
    );

    const hash = await bcrypt.hash(ADMIN_PASSWORD, 10);

    if (!existing) {
      await run(
        `INSERT INTO users
           (name, email, password, verified, role, is_active, bio, avatar_frame, created_at, last_active_at)
         VALUES (?, ?, ?, 1, 'admin', 1, 'Administrator of Fandom Verse.', 'gradient',
                 CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`,
        [ADMIN_NAME, ADMIN_EMAIL, hash]
      );
      console.log(`Admin account ready: ${ADMIN_EMAIL}`);
      await logAdminAction({
        action: "seed_admin",
        targetType: "user",
        details: `Built-in administrator ${ADMIN_EMAIL} created`,
      });
      return;
    }

    // Always re-assert admin role + verified + active so a bad edit cannot
    // lock the team out of the panel.
    await run(
      `UPDATE users
          SET role = 'admin', verified = 1, is_active = 1, password = ?
        WHERE email = ?`,
      [hash, ADMIN_EMAIL]
    );
    console.log(`Admin account verified: ${ADMIN_EMAIL}`);
  } catch (error) {
    console.error("Admin seed failed:", error.message);
  }
}

/* ---------------------------------------------------------------------------
 * tiny promise wrappers (kept local so this file has no import cycle risk)
 * ------------------------------------------------------------------------- */

function run(sql, params = []) {
  return new Promise((resolve, reject) => {
    db.run(sql, params, function (err) {
      if (err) reject(err);
      else resolve({ lastID: this.lastID, changes: this.changes });
    });
  });
}

function get(sql, params = []) {
  return new Promise((resolve, reject) => {
    db.get(sql, params, (err, row) => {
      if (err) reject(err);
      else resolve(row || null);
    });
  });
}

/**
 * Appends a row to `admin_logs`. Never throws - logging must not break the
 * request that triggered it.
 */
export async function logAdminAction({
  adminId = null,
  adminEmail = null,
  level = "info",
  action,
  targetType = null,
  targetId = null,
  details = null,
}) {
  try {
    await run(
      `INSERT INTO admin_logs
         (admin_id, admin_email, level, action, target_type, target_id, details)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [adminId, adminEmail, level, action, targetType, targetId, details]
    );
  } catch (error) {
    console.error("Admin log failed:", error.message);
  }
}

export default { initAdminSchema, logAdminAction, ADMIN_EMAIL };
