/**
 * FANDOM VERSE - Member 1 (Profile, Fandom Selection & Home) database schema
 * -------------------------------------------------------------------------
 * SRS reference:
 *   "1. User Registration and Profile Management"
 *     - Role / category (fandom) selection during setup + profile badges
 *     - Profile / Dashboard: bio, avatar, liked fandoms, saved bookmarks,
 *       purchase history and offline content
 *   "Trending Fandoms Carousel" is fed from the same fandom tables.
 *
 * The original spec suggested Firebase Users + Fandoms. This project keeps a
 * single SQLite database, so:
 *   users / user_fandoms / fandom_categories -> the "Users + Fandoms" store
 *   profile_cache                            -> the "SQLite user cache"
 *                                               (instant + offline profile)
 */

import db from "./db.js";

/** Creates every table / index needed by the Profile & Fandom module. */
export function initProfileSchema() {
  db.serialize(() => {
    // ------------- extra profile columns on the users table -------------
    // SQLite rejects ADD COLUMN with UNIQUE / non-constant defaults, so columns
    // are added plainly (duplicate column errors are intentionally ignored)
    // and the values are back-filled right after.
    db.run(`ALTER TABLE users ADD COLUMN invite_code TEXT`, () => {});
    db.run(`ALTER TABLE users ADD COLUMN referred_by INTEGER`, () => {});
    db.run(`ALTER TABLE users ADD COLUMN invite_count INTEGER DEFAULT 0`, () => {});
    db.run(`ALTER TABLE users ADD COLUMN points INTEGER DEFAULT 0`, () => {});
    db.run(`ALTER TABLE users ADD COLUMN streak_count INTEGER DEFAULT 0`, () => {});
    db.run(`ALTER TABLE users ADD COLUMN avatar_frame TEXT DEFAULT 'gradient'`, () => {});
    db.run(`ALTER TABLE users ADD COLUMN is_public INTEGER DEFAULT 1`, () => {});
    db.run(`ALTER TABLE users ADD COLUMN last_active_at TEXT`, () => {});
    db.run(
      `UPDATE users SET last_active_at = CURRENT_TIMESTAMP
       WHERE last_active_at IS NULL OR last_active_at = ''`,
      () => {}
    );
    db.run(
      `UPDATE users SET invite_code = 'FV' || printf('%05d', id) || substr(hex(randomblob(2)), 1, 4)
       WHERE invite_code IS NULL OR invite_code = ''`,
      () => {}
    );
    db.run(`CREATE UNIQUE INDEX IF NOT EXISTS idx_users_invite_code ON users (invite_code)`);

    // ----------------------------- badges -----------------------------
    // "Public Badges" screen + the badge chips on the profile header.
    db.run(`
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
      )
    `);

    db.run(`
      CREATE TABLE IF NOT EXISTS user_badges (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id    INTEGER NOT NULL,
        badge_id   INTEGER NOT NULL,
        awarded_at TEXT DEFAULT CURRENT_TIMESTAMP,
        UNIQUE (user_id, badge_id),
        FOREIGN KEY (user_id)  REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (badge_id) REFERENCES profile_badges (id) ON DELETE CASCADE
      )
    `);

    // --------------------------- social tasks --------------------------
    // "Invite / Social & Task" screen: refer a friend + daily fan tasks.
    db.run(`
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
      )
    `);

    db.run(`
      CREATE TABLE IF NOT EXISTS user_tasks (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id      INTEGER NOT NULL,
        task_code    TEXT NOT NULL,
        progress     INTEGER DEFAULT 0,
        is_completed INTEGER DEFAULT 0,
        completed_at TEXT,
        updated_at   TEXT DEFAULT CURRENT_TIMESTAMP,
        UNIQUE (user_id, task_code)
      )
    `);

    // -------------------------- user settings --------------------------
    db.run(`
      CREATE TABLE IF NOT EXISTS user_settings (
        user_id          INTEGER PRIMARY KEY,
        language         TEXT DEFAULT 'English',
        dark_mode        INTEGER DEFAULT 1,
        push_enabled     INTEGER DEFAULT 1,
        push_events      INTEGER DEFAULT 1,
        push_content     INTEGER DEFAULT 1,
        push_community   INTEGER DEFAULT 1,
        email_updates    INTEGER DEFAULT 0,
        autoplay_video   INTEGER DEFAULT 1,
        offline_sync     INTEGER DEFAULT 1,
        updated_at       TEXT DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // ------------------------ SQLite user cache ------------------------
    // Snapshot of the merged profile payload so the dashboard / profile screen
    // opens instantly and still works offline.
    db.run(`
      CREATE TABLE IF NOT EXISTS profile_cache (
        user_id    INTEGER PRIMARY KEY,
        payload    TEXT NOT NULL,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // ---------------------------- indexes ------------------------------
    db.run(`CREATE INDEX IF NOT EXISTS idx_ubadges_user  ON user_badges (user_id)`);
    db.run(`CREATE INDEX IF NOT EXISTS idx_utasks_user   ON user_tasks (user_id)`);

    // ------------------------ default badge catalogue -------------------
    const badges = [
      ["founder", "Founder Fan", "Joined FANDOM VERSE during the pocket edition launch", "rocket_launch_rounded", "#8B5CF6", "Milestone", 0, 0],
      ["first_fandom", "Fandom Starter", "Selected your first fandom during setup", "auto_awesome_rounded", "#EC4899", "Setup", 1, 1],
      ["multi_fandom", "Multi-Fandom", "Picked 3 or more fandoms to follow", "diversity_3_rounded", "#06B6D4", "Setup", 3, 2],
      ["profile_pro", "Profile Pro", "Completed your bio and avatar", "badge_rounded", "#3B82F6", "Profile", 1, 3],
      ["news_junkie", "News Junkie", "Read 10 fandom news stories", "newspaper_rounded", "#F59E0B", "Content", 10, 4],
      ["binge_watcher", "Binge Watcher", "Watched 10 video clips in the hub", "play_circle_rounded", "#EF4444", "Content", 10, 5],
      ["deep_diver", "Deep Diver", "Unlocked advanced lore in Deep Dive", "psychology_alt_rounded", "#10B981", "Content", 1, 6],
      ["social_butterfly", "Social Butterfly", "Invited 3 friends to FANDOM VERSE", "group_add_rounded", "#F97316", "Social", 3, 7],
      ["event_goer", "Event Goer", "Saved your first fandom event", "event_available_rounded", "#F43F5E", "Events", 1, 8],
      ["top_fan", "Top Fan", "Reached 500 fan points", "workspace_premium_rounded", "#EAB308", "Milestone", 500, 9],
    ];

    badges.forEach(([code, name, description, icon, color, category, threshold, order]) => {
      db.run(
        `INSERT OR IGNORE INTO profile_badges
         (code, name, description, icon, color, category, threshold, sort_order)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
        [code, name, description, icon, color, category, threshold, order]
      );
    });

    // ------------------------ default social tasks ----------------------
    const tasks = [
      ["invite_friend", "Invite a friend", "Share your invite code with a fellow fan", "group_add_rounded", "#3B82F6", 50, 1, "invite", 0],
      ["complete_profile", "Complete your profile", "Add a bio and pick your avatar", "person_rounded", "#8B5CF6", 30, 1, "in_app", 1],
      ["pick_fandoms", "Pick 3 fandoms", "Tell us what you are a fan of", "auto_awesome_rounded", "#EC4899", 30, 3, "in_app", 2],
      ["read_news", "Read 3 news stories", "Catch up with the latest fandom news", "newspaper_rounded", "#F59E0B", 20, 3, "content", 3],
      ["watch_clip", "Watch a video clip", "Open any video in the fandom hub", "play_circle_rounded", "#EF4444", 20, 1, "content", 4],
      ["join_discussion", "Join a discussion", "Comment or create a community post", "forum_rounded", "#10B981", 40, 1, "community", 5],
      ["bookmark_media", "Bookmark media", "Save an article or gallery for offline", "bookmark_rounded", "#06B6D4", 25, 1, "content", 6],
      ["follow_fans", "Follow 2 fans", "Build your fandom circle", "diversity_3_rounded", "#F97316", 25, 2, "community", 7],
    ];

    tasks.forEach(([code, title, description, icon, color, points, target, action, order]) => {
      db.run(
        `INSERT OR IGNORE INTO social_tasks
         (code, title, description, icon, color, reward_points, target_count, action, sort_order)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [code, title, description, icon, color, points, target, action, order]
      );
    });
  });
}

export default initProfileSchema;
