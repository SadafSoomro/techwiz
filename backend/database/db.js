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