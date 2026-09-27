import sqlite3 from "sqlite3";
import path from "path";
import { fileURLToPath } from "url";

sqlite3.verbose();

// Resolve the database file relative to this file so the server works
// no matter which folder it is started from.
const __dirname = path.dirname(fileURLToPath(import.meta.url));
const DB_PATH = path.join(__dirname, "..", "mydb.sqlite");

const db = new sqlite3.Database(DB_PATH);

// Foreign keys are required by the Search & Community module
// (ON DELETE CASCADE on posts / comments).
db.run("PRAGMA foreign_keys = ON");

// ---------------------------------------------------------------
// Performance pragmas.
//
// SQLite's defaults (journal_mode = DELETE, synchronous = FULL) force
// multiple fsyncs per write and block readers while a writer is active. Every
// cached response, like, bookmark and order therefore paid a disk-sync penalty
// that showed up as sluggish API responses and a "hanging" first screen.
// ---------------------------------------------------------------
db.serialize(() => {
  // Write-ahead logging: readers never block the writer and vice versa.
  db.run("PRAGMA journal_mode = WAL");
  // Safe with WAL, and avoids an fsync on every single commit.
  db.run("PRAGMA synchronous = NORMAL");
  // Keep temp tables / sort spill in RAM.
  db.run("PRAGMA temp_store = MEMORY");
  // ~32 MB page cache (negative value = KiB).
  db.run("PRAGMA cache_size = -32000");
  // Wait instead of failing instantly when the DB is briefly locked.
  db.run("PRAGMA busy_timeout = 5000");
  // Reclaim space a little more eagerly so the file does not keep growing.
  db.run("PRAGMA wal_autocheckpoint = 512");
});

db.serialize(() => {
  db.run(`
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT,
      email TEXT UNIQUE,
      password TEXT,
      verified INTEGER DEFAULT 0,
      verificationCode TEXT,
      resetCode TEXT
    )
  `);

  db.run(`ALTER TABLE users ADD COLUMN resetCode TEXT`, (err) => {
    // Ignore error if column already exists
  });
});

export default db;