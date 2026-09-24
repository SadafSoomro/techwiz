/**
 * FANDOM VERSE - Member 3 (Search & Community) database schema
 * ------------------------------------------------------------
 * Originally specified as "PostgreSQL + Redis".
 * This project replaces both with a single SQLite database:
 *   - Relational tables  -> replaces PostgreSQL
 *   - response_cache table -> replaces Redis (TTL based cache)
 *
 * Loaded automatically from server.js so every feature of Member 3
 * (Search, Trending, User Profile, Discussions, Bookmarks,
 *  Notifications) works out of the box.
 */

import db from "./db.js";

/** Creates every table / index needed by the Search & Community module. */
export function initCommunitySchema() {
  db.serialize(() => {
    // ---------- extra profile columns on the existing users table ----------
    // Wrapped in callbacks: SQLite throws if the column already exists,
    // so the error is intentionally ignored (safe migration).
    db.run(`ALTER TABLE users ADD COLUMN bio TEXT`, () => {});
    db.run(`ALTER TABLE users ADD COLUMN avatar TEXT`, () => {});
    db.run(`ALTER TABLE users ADD COLUMN selected_fandoms TEXT`, () => {});
    db.run(`ALTER TABLE users ADD COLUMN followers_count INTEGER DEFAULT 0`, () => {});
    db.run(`ALTER TABLE users ADD COLUMN following_count INTEGER DEFAULT 0`, () => {});

    // NOTE: SQLite does not allow CURRENT_TIMESTAMP as an ADD COLUMN default,
    // so the column is added empty and then back-filled below.
    db.run(`ALTER TABLE users ADD COLUMN created_at TEXT`, () => {});
    db.run(
      `UPDATE users SET created_at = CURRENT_TIMESTAMP WHERE created_at IS NULL OR created_at = ''`,
      () => {}
    );

    // ---------- fandom categories (search filter chips / trending) ----------
    db.run(`
      CREATE TABLE IF NOT EXISTS fandom_categories (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        name            TEXT NOT NULL UNIQUE,
        hashtag         TEXT,
        icon            TEXT,
        color           TEXT,
        description     TEXT,
        followers_count INTEGER DEFAULT 0,
        created_at      TEXT DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // ---------- posts: community posts + deep-dive discussions ----------
    db.run(`
      CREATE TABLE IF NOT EXISTS posts (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id         INTEGER NOT NULL,
        fandom_category TEXT NOT NULL DEFAULT 'Anime',
        title           TEXT NOT NULL,
        content         TEXT NOT NULL,
        image_url       TEXT,
        hashtags        TEXT,
        post_type       TEXT NOT NULL DEFAULT 'post',
        rating          INTEGER DEFAULT 0,
        likes_count     INTEGER DEFAULT 0,
        comments_count  INTEGER DEFAULT 0,
        views_count     INTEGER DEFAULT 0,
        is_published    INTEGER DEFAULT 1,
        created_at      TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at      TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    `);

    // ---------- comments on posts ----------
    db.run(`
      CREATE TABLE IF NOT EXISTS comments (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        post_id     INTEGER NOT NULL,
        user_id     INTEGER NOT NULL,
        body        TEXT NOT NULL,
        likes_count INTEGER DEFAULT 0,
        created_at  TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    `);

    // ---------- likes (one row per user per post) ----------
    db.run(`
      CREATE TABLE IF NOT EXISTS post_likes (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        post_id    INTEGER NOT NULL,
        user_id    INTEGER NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        UNIQUE (post_id, user_id)
      )
    `);

    // ---------- bookmarks / saved posts ----------
    db.run(`
      CREATE TABLE IF NOT EXISTS bookmarks (
        id       INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id  INTEGER NOT NULL,
        post_id  INTEGER NOT NULL,
        saved_at TEXT DEFAULT CURRENT_TIMESTAMP,
        UNIQUE (user_id, post_id)
      )
    `);

    // ---------- follows ----------
    db.run(`
      CREATE TABLE IF NOT EXISTS follows (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        follower_id  INTEGER NOT NULL,
        following_id INTEGER NOT NULL,
        created_at   TEXT DEFAULT CURRENT_TIMESTAMP,
        UNIQUE (follower_id, following_id)
      )
    `);

    // ---------- notifications ----------
    db.run(`
      CREATE TABLE IF NOT EXISTS notifications (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id      INTEGER NOT NULL,
        actor_id     INTEGER,
        type         TEXT NOT NULL,
        message      TEXT NOT NULL,
        reference_id INTEGER,
        is_read      INTEGER DEFAULT 0,
        created_at   TEXT DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // ---------- a user's selected fandoms (profile interests) ----------
    db.run(`
      CREATE TABLE IF NOT EXISTS user_fandoms (
        id       INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id  INTEGER NOT NULL,
        fandom   TEXT NOT NULL,
        UNIQUE (user_id, fandom)
      )
    `);

    // ---------- search history (recent searches) ----------
    db.run(`
      CREATE TABLE IF NOT EXISTS search_history (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id    INTEGER NOT NULL,
        query      TEXT NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // ---------- SQLite based replacement for Redis ----------
    db.run(`
      CREATE TABLE IF NOT EXISTS response_cache (
        cache_key  TEXT PRIMARY KEY,
        payload    TEXT NOT NULL,
        expires_at INTEGER NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // ---------- indexes (fast search like a real search backend) ----------
    db.run(`CREATE INDEX IF NOT EXISTS idx_posts_user        ON posts (user_id)`);
    db.run(`CREATE INDEX IF NOT EXISTS idx_posts_fandom      ON posts (fandom_category)`);
    db.run(`CREATE INDEX IF NOT EXISTS idx_posts_type        ON posts (post_type)`);
    db.run(`CREATE INDEX IF NOT EXISTS idx_posts_created     ON posts (created_at)`);
    db.run(`CREATE INDEX IF NOT EXISTS idx_posts_likes       ON posts (likes_count)`);
    db.run(`CREATE INDEX IF NOT EXISTS idx_comments_post     ON comments (post_id)`);
    db.run(`CREATE INDEX IF NOT EXISTS idx_likes_post        ON post_likes (post_id)`);
    db.run(`CREATE INDEX IF NOT EXISTS idx_bookmarks_user    ON bookmarks (user_id)`);
    db.run(`CREATE INDEX IF NOT EXISTS idx_follows_follower  ON follows (follower_id)`);
    db.run(`CREATE INDEX IF NOT EXISTS idx_follows_following ON follows (following_id)`);
    db.run(`CREATE INDEX IF NOT EXISTS idx_notif_user        ON notifications (user_id)`);
    db.run(`CREATE INDEX IF NOT EXISTS idx_users_name        ON users (name)`);
    db.run(`CREATE INDEX IF NOT EXISTS idx_users_email       ON users (email)`);

    // ---------- default fandom categories ----------
    const fandoms = [
      ["Anime", "#Anime", "auto_awesome_rounded", "#EC4899", "Japanese animation, manga and cosplay culture"],
      ["Gaming", "#Gaming", "sports_esports_rounded", "#3B82F6", "Esports, RPGs and community speedrunning"],
      ["Movies & TV", "#Movies", "movie_creation_rounded", "#F59E0B", "Cinematic universes and fantasy series"],
      ["Comics", "#Comics", "menu_book_rounded", "#F97316", "Superhero universes and indie graphic novels"],
      ["Music", "#Music", "music_note_rounded", "#10B981", "Artists, bands and K-Pop idol culture"],
      ["Sports", "#Sports", "emoji_events_rounded", "#EF4444", "Fan clubs and match-day communities"],
      ["Sci-Fi", "#SciFi", "rocket_launch_rounded", "#8B5CF6", "Space operas and futuristic franchises"],
    ];

    fandoms.forEach(([name, hashtag, icon, color, description]) => {
      db.run(
        `INSERT OR IGNORE INTO fandom_categories
         (name, hashtag, icon, color, description, followers_count)
         VALUES (?, ?, ?, ?, ?, ?)`,
        [name, hashtag, icon, color, description, 0]
      );
    });
  });
}

export default initCommunitySchema;
