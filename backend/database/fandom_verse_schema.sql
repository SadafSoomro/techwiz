-- ============================================================================
--  FANDOM VERSE POCKET EDITION  --  SQLite database script
--  Module : Member 3 - Search & Community
--  (Frontend: Search, Trending, User Profile, Discussions, Bookmarks,
--   Notifications  |  Backend: SQLite replacing PostgreSQL + Redis)
-- ============================================================================
--  Run with:   sqlite3 mydb.sqlite < fandom_verse_schema.sql
--  NOTE: The Node/Express server also creates these tables automatically
--        through backend/database/communitySchema.js, so this script is
--        provided for the project report / manual database setup.
-- ============================================================================

PRAGMA foreign_keys = ON;

-- ---------------------------------------------------------------------------
-- 1. USERS  (shared by Member 1 auth module + Member 3 community module)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
    id               INTEGER PRIMARY KEY AUTOINCREMENT,
    name             TEXT,
    email            TEXT UNIQUE,
    password         TEXT,
    verified         INTEGER DEFAULT 0,
    verificationCode TEXT,
    resetCode        TEXT,
    bio              TEXT,
    avatar           TEXT,
    selected_fandoms TEXT,
    followers_count  INTEGER DEFAULT 0,
    following_count  INTEGER DEFAULT 0,
    created_at       TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_users_email ON users (email);
CREATE INDEX IF NOT EXISTS idx_users_name  ON users (name);

-- ---------------------------------------------------------------------------
-- 2. FANDOM CATEGORIES  (search filter chips / trending categories)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS fandom_categories (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    name            TEXT NOT NULL UNIQUE,
    hashtag         TEXT,
    icon            TEXT,
    color           TEXT,
    description     TEXT,
    followers_count INTEGER DEFAULT 0,
    created_at      TEXT DEFAULT CURRENT_TIMESTAMP
);

INSERT OR IGNORE INTO fandom_categories (name, hashtag, icon, color, description)
VALUES
    ('Anime',        '#Anime',  'auto_awesome_rounded',  '#EC4899', 'Japanese animation, manga and cosplay culture'),
    ('Gaming',       '#Gaming', 'sports_esports_rounded', '#3B82F6', 'Esports, RPGs and community speedrunning'),
    ('Movies & TV',  '#Movies', 'movie_creation_rounded', '#F59E0B', 'Cinematic universes and fantasy series'),
    ('Comics',       '#Comics', 'menu_book_rounded',      '#F97316', 'Superhero universes and indie graphic novels'),
    ('Music',        '#Music',  'music_note_rounded',     '#10B981', 'Artists, bands and K-Pop idol culture'),
    ('Sports',       '#Sports', 'emoji_events_rounded',   '#EF4444', 'Fan clubs and match-day communities'),
    ('Sci-Fi',       '#SciFi',  'rocket_launch_rounded',  '#8B5CF6', 'Space operas and futuristic franchises');

-- ---------------------------------------------------------------------------
-- 3. POSTS  (community posts + "Deep Dive" discussions)
--    post_type : 'post' | 'deep_dive'
-- ---------------------------------------------------------------------------
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
    FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_posts_user    ON posts (user_id);
CREATE INDEX IF NOT EXISTS idx_posts_fandom  ON posts (fandom_category);
CREATE INDEX IF NOT EXISTS idx_posts_type    ON posts (post_type);
CREATE INDEX IF NOT EXISTS idx_posts_created ON posts (created_at);
CREATE INDEX IF NOT EXISTS idx_posts_likes   ON posts (likes_count);

-- ---------------------------------------------------------------------------
-- 4. COMMENTS
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS comments (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    post_id     INTEGER NOT NULL,
    user_id     INTEGER NOT NULL,
    body        TEXT NOT NULL,
    likes_count INTEGER DEFAULT 0,
    created_at  TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (post_id) REFERENCES posts (id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_comments_post ON comments (post_id);

-- ---------------------------------------------------------------------------
-- 5. POST LIKES  (unique per user per post)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS post_likes (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    post_id    INTEGER NOT NULL,
    user_id    INTEGER NOT NULL,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (post_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_likes_post ON post_likes (post_id);

-- ---------------------------------------------------------------------------
-- 6. BOOKMARKS  (Saved Posts screen)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS bookmarks (
    id       INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id  INTEGER NOT NULL,
    post_id  INTEGER NOT NULL,
    saved_at TEXT DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (user_id, post_id)
);

CREATE INDEX IF NOT EXISTS idx_bookmarks_user ON bookmarks (user_id);

-- ---------------------------------------------------------------------------
-- 7. FOLLOWS
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS follows (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    follower_id  INTEGER NOT NULL,
    following_id INTEGER NOT NULL,
    created_at   TEXT DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (follower_id, following_id)
);

CREATE INDEX IF NOT EXISTS idx_follows_follower  ON follows (follower_id);
CREATE INDEX IF NOT EXISTS idx_follows_following ON follows (following_id);

-- ---------------------------------------------------------------------------
-- 8. NOTIFICATIONS
--    type : 'follow' | 'like' | 'comment' | 'bookmark' | 'system'
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS notifications (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id      INTEGER NOT NULL,
    actor_id     INTEGER,
    type         TEXT NOT NULL,
    message      TEXT NOT NULL,
    reference_id INTEGER,
    is_read      INTEGER DEFAULT 0,
    created_at   TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_notif_user ON notifications (user_id);

-- ---------------------------------------------------------------------------
-- 9. USER FANDOMS (profile interest tags)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS user_fandoms (
    id      INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    fandom  TEXT NOT NULL,
    UNIQUE (user_id, fandom)
);

-- ---------------------------------------------------------------------------
-- 10. SEARCH HISTORY
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS search_history (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id    INTEGER NOT NULL,
    query      TEXT NOT NULL,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- ---------------------------------------------------------------------------
-- 11. RESPONSE CACHE  (SQLite based replacement for Redis, TTL based)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS response_cache (
    cache_key  TEXT PRIMARY KEY,
    payload    TEXT NOT NULL,
    expires_at INTEGER NOT NULL,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
--  MEMBER 4 - EVENTS & MAPS
--  (Frontend: Events, Calendar, Map, Categories, Event Ticket
--   Backend : Events + Location + SQLite cache)
--  SRS: Location-Aware Event Discovery and Calendar
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 12. EVENT CATEGORIES
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS event_categories (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    name        TEXT NOT NULL UNIQUE,
    icon        TEXT,
    color       TEXT,
    description TEXT,
    created_at  TEXT DEFAULT CURRENT_TIMESTAMP
);

INSERT OR IGNORE INTO event_categories (name, icon, color, description)
VALUES
    ('Fan Convention',    'groups_rounded',        '#F97316', 'Big multi-fandom conventions and expos'),
    ('Cosplay Meetup',    'auto_awesome_rounded',  '#EC4899', 'Cosplay photoshoots and costume meetups'),
    ('Screening',         'movie_creation_rounded','#F59E0B', 'Anime, movie and series watch parties'),
    ('Gaming Tournament', 'sports_esports_rounded','#3B82F6', 'Esports cups and LAN tournaments'),
    ('Comic Con',         'menu_book_rounded',     '#F43F5E', 'Comics, artists alley and collector halls'),
    ('Concert',           'music_note_rounded',    '#10B981', 'K-Pop, J-Rock and OST live concerts'),
    ('Fan Meetup',        'diversity_3_rounded',   '#8B5CF6', 'Casual local fan club gatherings'),
    ('Workshop',          'construction_rounded',  '#06B6D4', 'Drawing, AMV editing and prop making workshops');

-- ---------------------------------------------------------------------------
-- 13. VENUES  (location data for the Map screen)
-- ---------------------------------------------------------------------------
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
);

CREATE INDEX IF NOT EXISTS idx_venues_city ON venues (city_name);

-- ---------------------------------------------------------------------------
-- 14. EVENTS
--     SRS minimum: Event_Id (PK), Title, City_Name, Event_Date, Ticket_Link
-- ---------------------------------------------------------------------------
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
);

CREATE INDEX IF NOT EXISTS idx_events_date     ON events (event_date);
CREATE INDEX IF NOT EXISTS idx_events_city     ON events (city_name);
CREATE INDEX IF NOT EXISTS idx_events_category ON events (category);
CREATE INDEX IF NOT EXISTS idx_events_latlng   ON events (latitude, longitude);

-- ---------------------------------------------------------------------------
-- 15. EVENT TICKETS  (simulated booking - no real payment)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS event_tickets (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    event_id    INTEGER NOT NULL,
    user_id     INTEGER NOT NULL,
    quantity    INTEGER DEFAULT 1,
    unit_price  REAL DEFAULT 0,
    total_price REAL DEFAULT 0,
    currency    TEXT DEFAULT 'PKR',
    ticket_code TEXT NOT NULL UNIQUE,
    seat_number TEXT,
    status      TEXT DEFAULT 'confirmed',
    booked_at   TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (event_id) REFERENCES events (id) ON DELETE CASCADE,
    FOREIGN KEY (user_id)  REFERENCES users  (id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_tickets_event ON event_tickets (event_id);
CREATE INDEX IF NOT EXISTS idx_tickets_user  ON event_tickets (user_id);

-- ---------------------------------------------------------------------------
-- 16. SAVED / INTERESTED EVENTS
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS saved_events (
    id       INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id  INTEGER NOT NULL,
    event_id INTEGER NOT NULL,
    saved_at TEXT DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (user_id, event_id),
    FOREIGN KEY (event_id) REFERENCES events (id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_saved_user ON saved_events (user_id);

-- ---------------------------------------------------------------------------
-- 17. EVENT REMINDERS
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS event_reminders (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id    INTEGER NOT NULL,
    event_id   INTEGER NOT NULL,
    remind_on  TEXT NOT NULL,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (user_id, event_id)
);

-- ============================================================================
--  MEMBER 1 - PROFILE, FANDOM SELECTION & HOME
--  (Frontend: Splash, Login, Sign Up, Fandom Selection, Profile, Edit Profile,
--   Invite, Social & Tasks, Public Badges, Settings, Home Dashboard
--   Backend : Users + Fandoms + SQLite user cache)
--  SRS: User Registration and Profile Management
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 18. EXTRA PROFILE COLUMNS ON users  (invite / points / visibility)
--     member_since is derived from users.created_at (added in section 1).
-- ---------------------------------------------------------------------------
-- ALTER TABLE users ADD COLUMN invite_code   TEXT;
-- ALTER TABLE users ADD COLUMN referred_by   INTEGER;
-- ALTER TABLE users ADD COLUMN invite_count  INTEGER DEFAULT 0;
-- ALTER TABLE users ADD COLUMN points        INTEGER DEFAULT 0;
-- ALTER TABLE users ADD COLUMN streak_count  INTEGER DEFAULT 0;
-- ALTER TABLE users ADD COLUMN avatar_frame  TEXT DEFAULT 'gradient';
-- ALTER TABLE users ADD COLUMN is_public     INTEGER DEFAULT 1;
-- ALTER TABLE users ADD COLUMN last_active_at TEXT;
-- (the server applies these idempotently in profileSchema.js)

CREATE UNIQUE INDEX IF NOT EXISTS idx_users_invite_code ON users (invite_code);

-- ---------------------------------------------------------------------------
-- 19. PROFILE BADGES  (Public Badges screen)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS profile_badges (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    code        TEXT NOT NULL UNIQUE,
    name        TEXT NOT NULL,
    description TEXT,
    icon        TEXT,
    color       TEXT,
    category    TEXT DEFAULT 'Milestone',
    threshold   INTEGER DEFAULT 0,
    sort_order  INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS user_badges (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id    INTEGER NOT NULL,
    badge_id   INTEGER NOT NULL,
    awarded_at TEXT DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (user_id, badge_id),
    FOREIGN KEY (user_id)  REFERENCES users (id) ON DELETE CASCADE,
    FOREIGN KEY (badge_id) REFERENCES profile_badges (id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_ubadges_user ON user_badges (user_id);

-- ---------------------------------------------------------------------------
-- 20. SOCIAL TASKS  ("Invite / Social & Task" screen)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS social_tasks (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    code          TEXT NOT NULL UNIQUE,
    title         TEXT NOT NULL,
    description   TEXT,
    icon          TEXT,
    color         TEXT,
    reward_points INTEGER DEFAULT 10,
    target_count  INTEGER DEFAULT 1,
    action        TEXT DEFAULT 'in_app',
    sort_order    INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS user_tasks (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id      INTEGER NOT NULL,
    task_code    TEXT NOT NULL,
    progress     INTEGER DEFAULT 0,
    is_completed INTEGER DEFAULT 0,
    completed_at TEXT,
    updated_at   TEXT DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (user_id, task_code)
);

CREATE INDEX IF NOT EXISTS idx_utasks_user ON user_tasks (user_id);

-- ---------------------------------------------------------------------------
-- 21. USER SETTINGS  (Notifications, Language, Dark Mode)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS user_settings (
    user_id        INTEGER PRIMARY KEY,
    language       TEXT DEFAULT 'English',
    dark_mode      INTEGER DEFAULT 1,
    push_enabled   INTEGER DEFAULT 1,
    push_events    INTEGER DEFAULT 1,
    push_content   INTEGER DEFAULT 1,
    push_community INTEGER DEFAULT 1,
    email_updates  INTEGER DEFAULT 0,
    autoplay_video INTEGER DEFAULT 1,
    offline_sync   INTEGER DEFAULT 1,
    updated_at     TEXT DEFAULT CURRENT_TIMESTAMP
);

-- ---------------------------------------------------------------------------
-- 22. PROFILE CACHE  (the "SQLite user cache" - instant / offline profile)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS profile_cache (
    user_id    INTEGER PRIMARY KEY,
    payload    TEXT NOT NULL,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
--  MEMBER 2 - FANDOM CONTENT
--  (Frontend: Fandom Hub, Explore Fandoms, News, Gallery, Video Player,
--   Podcasts, Discover, Glossary
--   Backend : Posts / Media + SQLite recent & offline content)
--  SRS: Fandom Exploration and Multimedia Hub
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 23. FANDOM HUBS  (Explore Fandoms / trending carousel)
-- ---------------------------------------------------------------------------
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
);

-- ---------------------------------------------------------------------------
-- 24. CONTENT ITEMS
--     content_type : 'news' | 'article' | 'gallery' | 'video' | 'podcast'
--                    | 'deep_dive'
-- ---------------------------------------------------------------------------
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
);

CREATE INDEX IF NOT EXISTS idx_content_type      ON content_items (content_type);
CREATE INDEX IF NOT EXISTS idx_content_fandom    ON content_items (fandom);
CREATE INDEX IF NOT EXISTS idx_content_hub       ON content_items (hub_slug);
CREATE INDEX IF NOT EXISTS idx_content_published ON content_items (published_at);

-- ---------------------------------------------------------------------------
-- 25. CONTENT MEDIA  (gallery images / media of one content item)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS content_media (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    content_id INTEGER NOT NULL,
    media_type TEXT NOT NULL DEFAULT 'image',
    url        TEXT NOT NULL,
    caption    TEXT,
    sort_order INTEGER DEFAULT 0,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (content_id) REFERENCES content_items (id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_media_content ON content_media (content_id);

-- ---------------------------------------------------------------------------
-- 26. CONTENT LIKES
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS content_likes (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    content_id INTEGER NOT NULL,
    user_id    INTEGER NOT NULL,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (content_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_clikes_content ON content_likes (content_id);

-- ---------------------------------------------------------------------------
-- 27. CONTENT VIEWS  (recent history + offline cache in one table)
--     is_offline = 1  ->  saved for offline reading / viewing
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS content_views (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id    INTEGER NOT NULL,
    content_id INTEGER NOT NULL,
    is_offline INTEGER DEFAULT 0,
    progress   REAL DEFAULT 0,
    viewed_at  TEXT DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (user_id, content_id)
);

CREATE INDEX IF NOT EXISTS idx_cviews_user    ON content_views (user_id);
CREATE INDEX IF NOT EXISTS idx_cviews_offline ON content_views (user_id, is_offline);

-- ---------------------------------------------------------------------------
-- 28. BEGINNER FAN GLOSSARY  (fandom terminology)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS glossary_terms (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    term       TEXT NOT NULL,
    definition TEXT NOT NULL,
    fandom     TEXT DEFAULT 'General',
    category   TEXT DEFAULT 'General',
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (term, fandom)
);

-- ============================================================================
--  End of script
-- ============================================================================
