/**
 * FANDOM VERSE - Member 4 (Events & Maps) database schema
 * -------------------------------------------------------
 * SRS reference:
 *   "3. Location-Aware Event Discovery and Calendar"
 *     - Map and GPS integration (nearby conventions / meetups / screenings)
 *     - Event Calendar filterable by city, with ticket links
 *
 * SRS "Events Collection": Event_Id (PK), Title, City_Name, Event_Date, Ticket_Link
 * (extended with venue, coordinates, pricing and ticketing so the
 *  Map + Calendar + Ticket screens have real data to work with.)
 *
 * SQLite is used for storage AND for the cache (see database/cache.js),
 * which replaces the Redis requirement of the original spec.
 */

import db from "./db.js";

/** Creates every table / index needed by the Events & Maps module. */
export function initEventsSchema() {
  db.serialize(() => {
    // ----------------------- event categories -----------------------
    db.run(`
      CREATE TABLE IF NOT EXISTS event_categories (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        name        TEXT NOT NULL UNIQUE,
        icon        TEXT,
        color       TEXT,
        description TEXT,
        created_at  TEXT DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // ----------------------------- venues -----------------------------
    db.run(`
      CREATE TABLE IF NOT EXISTS venues (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        name       TEXT NOT NULL,
        address    TEXT,
        city_name  TEXT NOT NULL,
        country    TEXT DEFAULT 'Pakistan',
        latitude   REAL NOT NULL,
        longitude  REAL NOT NULL,
        capacity   INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        UNIQUE (name, city_name)
      )
    `);

    // ----------------------------- events -----------------------------
    db.run(`
      CREATE TABLE IF NOT EXISTS events (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        title           TEXT NOT NULL,
        description     TEXT,
        category        TEXT NOT NULL DEFAULT 'Fan Convention',
        city_name       TEXT NOT NULL,
        venue_name      TEXT,
        address         TEXT,
        latitude        REAL,
        longitude       REAL,
        event_date      TEXT NOT NULL,
        end_date        TEXT,
        start_time      TEXT DEFAULT '10:00',
        end_time        TEXT DEFAULT '18:00',
        ticket_link     TEXT,
        ticket_price    REAL DEFAULT 0,
        currency        TEXT DEFAULT 'PKR',
        image_url       TEXT,
        organizer       TEXT,
        capacity        INTEGER DEFAULT 0,
        attendees_count INTEGER DEFAULT 0,
        is_featured     INTEGER DEFAULT 0,
        status          TEXT DEFAULT 'upcoming',
        created_at      TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at      TEXT DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // ------------------------- booked tickets -------------------------
    db.run(`
      CREATE TABLE IF NOT EXISTS event_tickets (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        event_id     INTEGER NOT NULL,
        user_id      INTEGER NOT NULL,
        quantity     INTEGER DEFAULT 1,
        unit_price   REAL DEFAULT 0,
        total_price  REAL DEFAULT 0,
        currency     TEXT DEFAULT 'PKR',
        ticket_code  TEXT NOT NULL UNIQUE,
        seat_number  TEXT,
        status       TEXT DEFAULT 'confirmed',
        booked_at    TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (event_id) REFERENCES events (id) ON DELETE CASCADE,
        FOREIGN KEY (user_id)  REFERENCES users  (id) ON DELETE CASCADE
      )
    `);

    // ----------------- saved / interested events ----------------------
    db.run(`
      CREATE TABLE IF NOT EXISTS saved_events (
        id       INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id  INTEGER NOT NULL,
        event_id INTEGER NOT NULL,
        saved_at TEXT DEFAULT CURRENT_TIMESTAMP,
        UNIQUE (user_id, event_id),
        FOREIGN KEY (event_id) REFERENCES events (id) ON DELETE CASCADE
      )
    `);

    // ------------------------- event reminders ------------------------
    db.run(`
      CREATE TABLE IF NOT EXISTS event_reminders (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id    INTEGER NOT NULL,
        event_id   INTEGER NOT NULL,
        remind_on  TEXT NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        UNIQUE (user_id, event_id)
      )
    `);

    // ----------------------------- indexes -----------------------------
    db.run(`CREATE INDEX IF NOT EXISTS idx_events_date     ON events (event_date)`);
    db.run(`CREATE INDEX IF NOT EXISTS idx_events_city     ON events (city_name)`);
    db.run(`CREATE INDEX IF NOT EXISTS idx_events_category ON events (category)`);
    db.run(`CREATE INDEX IF NOT EXISTS idx_events_latlng   ON events (latitude, longitude)`);
    db.run(`CREATE INDEX IF NOT EXISTS idx_tickets_event   ON event_tickets (event_id)`);
    db.run(`CREATE INDEX IF NOT EXISTS idx_tickets_user    ON event_tickets (user_id)`);
    db.run(`CREATE INDEX IF NOT EXISTS idx_saved_user      ON saved_events (user_id)`);
    db.run(`CREATE INDEX IF NOT EXISTS idx_venues_city     ON venues (city_name)`);

    // ------------------------ default categories ------------------------
    const categories = [
      ["Fan Convention", "groups_rounded", "#F97316", "Big multi-fandom conventions and expos"],
      ["Cosplay Meetup", "auto_awesome_rounded", "#EC4899", "Cosplay photoshoots and costume meetups"],
      ["Screening", "movie_creation_rounded", "#F59E0B", "Anime, movie and series watch parties"],
      ["Gaming Tournament", "sports_esports_rounded", "#3B82F6", "Esports cups and LAN tournaments"],
      ["Comic Con", "menu_book_rounded", "#F43F5E", "Comics, artists alley and collector halls"],
      ["Concert", "music_note_rounded", "#10B981", "K-Pop, J-Rock and OST live concerts"],
      ["Fan Meetup", "diversity_3_rounded", "#8B5CF6", "Casual local fan club gatherings"],
      ["Workshop", "construction_rounded", "#06B6D4", "Drawing, AMV editing and prop making workshops"],
    ];

    categories.forEach(([name, icon, color, description]) => {
      db.run(
        `INSERT OR IGNORE INTO event_categories (name, icon, color, description)
         VALUES (?, ?, ?, ?)`,
        [name, icon, color, description]
      );
    });
  });
}

export default initEventsSchema;
