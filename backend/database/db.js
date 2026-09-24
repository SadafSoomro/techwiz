import sqlite3 from "sqlite3";

sqlite3.verbose();

const db = new sqlite3.Database("./mydb.sqlite");

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