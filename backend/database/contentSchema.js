/**
 * FANDOM VERSE - Member 2 (Fandom Content) database schema
 * --------------------------------------------------------
 * SRS reference:
 *   "2. Fandom Exploration and Multimedia Hub"
 *     - Beginner Fan Hub + Glossary
 *     - News, galleries, video clips and podcasts filtered by fandom
 *     - Trending Fandoms Carousel
 *     - Deep Dive (hidden trivia / advanced lore)
 *     - Offline Bookmarking of articles + media
 *
 * The original spec suggested Cloud Firestore. This project uses a single
 * SQLite database for the whole backend (see backend/database/db.js), so the
 * "SQLite recent/offline content" part of the SRS is implemented here as the
 * `content_views` table (recent history) plus the `is_offline` flag on the
 * same table (content cached for offline reading / viewing).
 */

import db from "./db.js";

/** Creates every table / index needed by the Fandom Content module. */
export function initContentSchema() {
  db.serialize(() => {
    // ----------------------- fandom hubs -----------------------
    // "Explore Fandoms" -> Fandom Hub screen
    db.run(`
      CREATE TABLE IF NOT EXISTS fandom_hubs (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        slug            TEXT NOT NULL UNIQUE,
        name            TEXT NOT NULL,
        tagline         TEXT,
        description     TEXT,
        image_url       TEXT,
        icon            TEXT,
        color           TEXT,
        followers_count INTEGER DEFAULT 0,
        posts_count     INTEGER DEFAULT 0,
        is_trending     INTEGER DEFAULT 0,
        sort_order      INTEGER DEFAULT 0,
        created_at      TEXT DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // --------------------- content items ------------------------
    // One table holds every media type of the hub (news, gallery, video,
    // podcast, deep dive, trivia) - discriminated by `content_type`.
    db.run(`
      CREATE TABLE IF NOT EXISTS content_items (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        fandom           TEXT NOT NULL DEFAULT 'Anime',
        hub_slug         TEXT,
        content_type     TEXT NOT NULL DEFAULT 'news',
        title            TEXT NOT NULL,
        subtitle         TEXT,
        summary          TEXT,
        body             TEXT,
        image_url        TEXT,
        media_url        TEXT,
        duration_seconds INTEGER DEFAULT 0,
        author           TEXT,
        source           TEXT,
        tags             TEXT,
        episode_number   INTEGER,
        season           INTEGER,
        views_count      INTEGER DEFAULT 0,
        likes_count      INTEGER DEFAULT 0,
        comments_count   INTEGER DEFAULT 0,
        is_featured      INTEGER DEFAULT 0,
        is_published     INTEGER DEFAULT 1,
        published_at     TEXT DEFAULT CURRENT_TIMESTAMP,
        created_at       TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at       TEXT DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // ------------- gallery / multimedia children ----------------
    db.run(`
      CREATE TABLE IF NOT EXISTS content_media (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        content_id INTEGER NOT NULL,
        media_type TEXT NOT NULL DEFAULT 'image',
        url        TEXT NOT NULL,
        caption    TEXT,
        sort_order INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (content_id) REFERENCES content_items (id) ON DELETE CASCADE
      )
    `);

    // ------------------------ content likes ---------------------
    db.run(`
      CREATE TABLE IF NOT EXISTS content_likes (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        content_id INTEGER NOT NULL,
        user_id    INTEGER NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        UNIQUE (content_id, user_id)
      )
    `);

    // --------- recent views + offline cache (one table) ---------
    db.run(`
      CREATE TABLE IF NOT EXISTS content_views (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id    INTEGER NOT NULL,
        content_id INTEGER NOT NULL,
        is_offline INTEGER DEFAULT 0,
        progress   REAL DEFAULT 0,
        viewed_at  TEXT DEFAULT CURRENT_TIMESTAMP,
        UNIQUE (user_id, content_id)
      )
    `);

    // --------------------- beginner fan glossary ---------------
    db.run(`
      CREATE TABLE IF NOT EXISTS glossary_terms (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        term       TEXT NOT NULL,
        definition TEXT NOT NULL,
        fandom     TEXT DEFAULT 'General',
        category   TEXT DEFAULT 'General',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        UNIQUE (term, fandom)
      )
    `);

    // -------------------------- indexes -------------------------
    db.run(`CREATE INDEX IF NOT EXISTS idx_content_type      ON content_items (content_type)`);
    db.run(`CREATE INDEX IF NOT EXISTS idx_content_fandom    ON content_items (fandom)`);
    db.run(`CREATE INDEX IF NOT EXISTS idx_content_hub       ON content_items (hub_slug)`);
    db.run(`CREATE INDEX IF NOT EXISTS idx_content_featured  ON content_items (is_featured)`);
    db.run(`CREATE INDEX IF NOT EXISTS idx_content_published ON content_items (published_at)`);
    db.run(`CREATE INDEX IF NOT EXISTS idx_content_views     ON content_items (views_count)`);
    db.run(`CREATE INDEX IF NOT EXISTS idx_media_content     ON content_media (content_id)`);
    db.run(`CREATE INDEX IF NOT EXISTS idx_clikes_content    ON content_likes (content_id)`);
    db.run(`CREATE INDEX IF NOT EXISTS idx_cviews_user       ON content_views (user_id)`);
    db.run(`CREATE INDEX IF NOT EXISTS idx_cviews_offline    ON content_views (user_id, is_offline)`);
    db.run(`CREATE INDEX IF NOT EXISTS idx_glossary_fandom   ON glossary_terms (fandom)`);

    // --------------------- default fandom hubs -------------------
    const hubs = [
      ["anime", "Anime", "Subs, dubs & everything between", "Japanese animation, manga and cosplay culture", "assets/images/fandoms/anime.jpg", "auto_awesome_rounded", "#EC4899", 1],
      ["gaming", "Gaming", "Esports, RPGs, speedruns", "Competitive esports, retro gaming and open-world RPGs", "assets/images/fandoms/gaming.jpg", "sports_esports_rounded", "#3B82F6", 1],
      ["movies-tv", "Movies & TV", "Cinematic universes", "Expansive cinematic universes, fantasy series and sci-fi franchises", "assets/images/fandoms/movies_tv.jpg", "movie_creation_rounded", "#F59E0B", 1],
      ["comics", "Comics", "Panels, ink & origin stories", "Superhero universes and indie graphic novels", "assets/images/fandoms/comics.jpg", "menu_book_rounded", "#F97316", 1],
      ["music", "Music / K-Pop", "Idols, albums, comebacks", "Artists, bands and international pop subcultures such as K-Pop", "assets/images/fandoms/music.jpg", "music_note_rounded", "#10B981", 1],
      ["sci-fi", "Sci-Fi", "Space operas & future tech", "Space operas, cyberpunk worlds and futuristic franchises", "assets/images/fandoms/scifi.jpg", "rocket_launch_rounded", "#8B5CF6", 1],
      ["sports", "Sports", "Match-day communities", "Fan clubs and match-day communities around the world", "assets/images/fandoms/sports.jpg", "emoji_events_rounded", "#EF4444", 0],
    ];

    hubs.forEach(([slug, name, tagline, description, image, icon, color, trending], index) => {
      db.run(
        `INSERT OR IGNORE INTO fandom_hubs
         (slug, name, tagline, description, image_url, icon, color, is_trending, sort_order)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [slug, name, tagline, description, image, icon, color, trending, index]
      );
    });
  });
}

export default initContentSchema;
