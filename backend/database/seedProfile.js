/**
 * MEMBER 1 - Profile, Fandom Selection & Home
 * Seeder for profile badges, social tasks, user settings, invite codes and
 * the SQLite profile cache.
 *
 * Run:  node database/seedProfile.js     (or)  npm run seed:profile
 *
 * Safe to run multiple times.
 */

import db from "./db.js";
import { initProfileSchema } from "./profileSchema.js";
import { all, get, run } from "./dbhelpers.js";

initProfileSchema();

// ---------------------------------------------------------------------------
// settings + invite codes for every existing account
// ---------------------------------------------------------------------------
async function seedSettings() {
  const users = await all(`SELECT id, name, bio, avatar FROM users`);
  const settings = await get(`SELECT COUNT(*) AS total FROM user_settings`);

  for (const user of users) {
    await run(
      `INSERT OR IGNORE INTO user_settings
        (user_id, language, dark_mode, push_enabled, push_events, push_content, push_community,
         email_updates, autoplay_video, offline_sync)
       VALUES (?, 'English', 1, 1, 1, 1, 1, 0, 1, 1)`,
      [user.id]
    );
    await run(
      `UPDATE users SET invite_code = 'FV' || printf('%05d', id) || upper(substr(hex(randomblob(2)), 1, 4))
       WHERE invite_code IS NULL OR invite_code = ''`,
      []
    );
  }

  console.log(`  users: ${users.length}   settings rows (before): ${settings ? settings.total : 0}`);
}

// ---------------------------------------------------------------------------
// badge awarding - mirrors the thresholds stored in profile_badges
// ---------------------------------------------------------------------------
async function awardBadges() {
  const users = await all(`SELECT id, bio, avatar, invite_count, points FROM users`);
  const badges = await all(`SELECT id, code, threshold FROM profile_badges`);
  const badgeByCode = Object.fromEntries(badges.map((b) => [b.code, b.id]));

  let awarded = 0;

  for (const user of users) {
    const fandoms = await get(
      `SELECT COUNT(*) AS total FROM user_fandoms WHERE user_id = ?`,
      [user.id]
    );
    const views = await get(
      `SELECT
         IFNULL(SUM(CASE WHEN ci.content_type = 'news'      THEN 1 ELSE 0 END), 0) AS news,
         IFNULL(SUM(CASE WHEN ci.content_type = 'video'     THEN 1 ELSE 0 END), 0) AS videos,
         IFNULL(SUM(CASE WHEN ci.content_type = 'deep_dive' THEN 1 ELSE 0 END), 0) AS deep
       FROM content_views cv
       JOIN content_items ci ON ci.id = cv.content_id
       WHERE cv.user_id = ?`,
      [user.id]
    );
    const savedEvents = await get(
      `SELECT COUNT(*) AS total FROM saved_events WHERE user_id = ?`,
      [user.id]
    );

    const fandomCount = fandoms ? fandoms.total : 0;

    const earned = [
      ["founder", true],
      ["first_fandom", fandomCount >= 1],
      ["multi_fandom", fandomCount >= 3],
      ["profile_pro", !!user.bio && !!user.avatar],
      ["news_junkie", (views ? views.news : 0) >= 10],
      ["binge_watcher", (views ? views.videos : 0) >= 10],
      ["deep_diver", (views ? views.deep : 0) >= 1],
      ["social_butterfly", (user.invite_count || 0) >= 3],
      ["event_goer", (savedEvents ? savedEvents.total : 0) >= 1],
      ["top_fan", (user.points || 0) >= 250],
    ];

    for (const [code, ok] of earned) {
      if (!ok || !badgeByCode[code]) continue;
      const result = await run(
        `INSERT OR IGNORE INTO user_badges (user_id, badge_id) VALUES (?, ?)`,
        [user.id, badgeByCode[code]]
      );
      awarded += result.changes || 0;
    }
  }

  console.log(`  badges awarded: ${awarded}`);
}

// ---------------------------------------------------------------------------
// default task progress + points from completed tasks
// ---------------------------------------------------------------------------
async function seedTasks() {
  const users = await all(`SELECT id, bio, avatar FROM users`);
  const tasks = await all(`SELECT code, reward_points, target_count FROM social_tasks`);

  for (const user of users) {
    const fandomCount = await get(
      `SELECT COUNT(*) AS total FROM user_fandoms WHERE user_id = ?`,
      [user.id]
    );
    const progressByCode = {
      complete_profile: user.bio && user.avatar ? 1 : 0,
      pick_fandoms: Math.min(fandomCount ? fandomCount.total : 0, 3),
    };

    let points = 0;

    for (const task of tasks) {
      const target = task.target_count || 1;
      const progress = Math.min(progressByCode[task.code] ?? 0, target);
      const completed = progress >= target ? 1 : 0;
      if (completed) points += task.reward_points || 0;

      await run(
        `INSERT INTO user_tasks (user_id, task_code, progress, is_completed, completed_at, updated_at)
         VALUES (?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
         ON CONFLICT (user_id, task_code) DO UPDATE SET
           progress = excluded.progress,
           is_completed = excluded.is_completed,
           completed_at = COALESCE(user_tasks.completed_at, excluded.completed_at),
           updated_at = CURRENT_TIMESTAMP`,
        [
          user.id,
          task.code,
          progress,
          completed,
          completed ? new Date().toISOString().slice(0, 19).replace("T", " ") : null,
        ]
      );
    }

    await run(`UPDATE users SET points = MAX(IFNULL(points, 0), ?) WHERE id = ?`, [
      points,
      user.id,
    ]);
  }

  console.log(`  task progress seeded for ${users.length} users`);
}

// ---------------------------------------------------------------------------
// SQLite profile cache warm-up (the "user cache" of the SRS)
// ---------------------------------------------------------------------------
async function warmProfileCache() {
  const users = await all(`SELECT id, name, email, bio, avatar FROM users`);

  for (const user of users) {
    const fandoms = await all(
      `SELECT fandom FROM user_fandoms WHERE user_id = ?`,
      [user.id]
    );
    const payload = {
      user: { ...user, selected_fandoms: fandoms.map((f) => f.fandom) },
      cachedAt: new Date().toISOString(),
    };

    await run(
      `INSERT INTO profile_cache (user_id, payload, updated_at)
       VALUES (?, ?, CURRENT_TIMESTAMP)
       ON CONFLICT (user_id) DO UPDATE SET
         payload = excluded.payload,
         updated_at = CURRENT_TIMESTAMP`,
      [user.id, JSON.stringify(payload)]
    );
  }

  console.log(`  profile cache warmed for ${users.length} users`);
}

async function main() {
  console.log("MEMBER 1 - seeding Profile / Fandom data...");
  await seedSettings();
  await seedTasks();
  await awardBadges();
  await warmProfileCache();

  const counts = await get(
    `SELECT
       (SELECT COUNT(*) FROM profile_badges) AS badges,
       (SELECT COUNT(*) FROM user_badges)    AS awarded,
       (SELECT COUNT(*) FROM social_tasks)   AS tasks,
       (SELECT COUNT(*) FROM user_settings)  AS settings,
       (SELECT COUNT(*) FROM profile_cache)  AS cached`
  );
  console.log("  catalogue:", counts);
  console.log("Done.");
}

main().catch((error) => {
  console.error("Seed failed:", error);
  process.exitCode = 1;
});

export default main;
