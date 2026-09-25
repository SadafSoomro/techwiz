/**
 * MEMBER 1 - Profile, Fandom Selection & Home
 * Profile / Edit Profile, Fandom Selection, Public Badges, Invite,
 * Social & Tasks, Settings and the aggregated Home dashboard.
 *
 * SRS reference: "1. User Registration and Profile Management".
 *
 * Storage: SQLite only.
 *   users / user_fandoms / fandom_categories -> the "Users + Fandoms" store
 *   profile_cache                            -> the "SQLite user cache"
 */

import { all, get, run, asyncHandler, timeAgo } from "../database/dbhelpers.js";
import cache from "../database/cache.js";
import { notify } from "../utils/notify.js";

const AVATARS = [
  "assets/images/avatars/avatar_01.jpg",
  "assets/images/avatars/avatar_02.jpg",
  "assets/images/avatars/avatar_03.jpg",
  "assets/images/avatars/avatar_04.jpg",
  "assets/images/avatars/avatar_05.jpg",
  "assets/images/avatars/avatar_06.jpg",
  "assets/images/avatars/avatar_07.jpg",
  "assets/images/avatars/avatar_08.jpg",
];

function me(req) {
  return req.user?.id ?? -1;
}

// ---------------------------------------------------------------------------
// shared helpers
// ---------------------------------------------------------------------------

/** Re-awards every badge whose rule the user now satisfies. */
async function awardEligibleBadges(userId) {
  const user = await get(
    `SELECT id, bio, avatar, invite_count, points FROM users WHERE id = ?`,
    [userId]
  );
  if (!user) return [];

  const counts = await get(
    `SELECT
       (SELECT COUNT(*) FROM user_fandoms WHERE user_id = ?) AS fandoms,
       (SELECT COUNT(*) FROM content_views cv JOIN content_items ci ON ci.id = cv.content_id
         WHERE cv.user_id = ? AND ci.content_type = 'news')      AS news,
       (SELECT COUNT(*) FROM content_views cv JOIN content_items ci ON ci.id = cv.content_id
         WHERE cv.user_id = ? AND ci.content_type = 'video')     AS videos,
       (SELECT COUNT(*) FROM content_views cv JOIN content_items ci ON ci.id = cv.content_id
         WHERE cv.user_id = ? AND ci.content_type = 'deep_dive') AS deep,
       (SELECT COUNT(*) FROM saved_events WHERE user_id = ?)     AS events,
       (SELECT COUNT(*) FROM bookmarks WHERE user_id = ?)        AS bookmarks`,
    [userId, userId, userId, userId, userId, userId]
  );

  const rules = {
    founder: true,
    first_fandom: (counts?.fandoms ?? 0) >= 1,
    multi_fandom: (counts?.fandoms ?? 0) >= 3,
    profile_pro: !!user.bio && !!user.avatar,
    news_junkie: (counts?.news ?? 0) >= 10,
    binge_watcher: (counts?.videos ?? 0) >= 10,
    deep_diver: (counts?.deep ?? 0) >= 1,
    social_butterfly: (user.invite_count ?? 0) >= 3,
    event_goer: (counts?.events ?? 0) >= 1,
    top_fan: (user.points ?? 0) >= 250,
  };

  const badges = await all(`SELECT id, code FROM profile_badges`);
  const newlyAwarded = [];

  for (const badge of badges) {
    if (!rules[badge.code]) continue;

    const result = await run(
      `INSERT OR IGNORE INTO user_badges (user_id, badge_id) VALUES (?, ?)`,
      [userId, badge.id]
    );

    if (result.changes > 0) {
      newlyAwarded.push(badge.code);
      await notify({
        userId,
        type: "system",
        message: `New badge unlocked: ${badge.code.replace(/_/g, " ")}`,
      });
    }
  }

  if (newlyAwarded.length) {
    await cache.invalidate(`profile:${userId}`);
  }
  return newlyAwarded;
}

/** Reads a still-fresh snapshot from the SQLite user cache. */
async function readCache(userId, ttlSeconds = 45) {
  const row = await get(
    `SELECT payload, updated_at FROM profile_cache WHERE user_id = ?`,
    [userId]
  );
  if (!row) return null;

  const updated = new Date(String(row.updated_at).replace(" ", "T") + "Z").getTime();
  if (Number.isNaN(updated) || Date.now() - updated > ttlSeconds * 1000) return null;

  try {
    return JSON.parse(row.payload);
  } catch {
    return null;
  }
}

async function writeCache(userId, payload) {
  await run(
    `INSERT INTO profile_cache (user_id, payload, updated_at)
     VALUES (?, ?, CURRENT_TIMESTAMP)
     ON CONFLICT (user_id) DO UPDATE SET
       payload = excluded.payload, updated_at = CURRENT_TIMESTAMP`,
    [userId, JSON.stringify(payload)]
  );
}

/** Full profile payload used by /me, the cache and the dashboard. */
async function buildProfile(userId) {
  const user = await get(
    `SELECT id, name, email, bio, avatar, invite_code, invite_count, points,
             streak_count, is_public, IFNULL(created_at, CURRENT_TIMESTAMP) AS created_at
     FROM users WHERE id = ?`,
    [userId]
  );
  if (!user) return null;

  const fandoms = await all(
    `SELECT uf.fandom AS name, IFNULL(fc.hashtag, '#' || uf.fandom) AS hashtag,
            IFNULL(fc.icon, 'auto_awesome_rounded') AS icon,
            IFNULL(fc.color, '#8B5CF6') AS color,
            IFNULL(fc.description, '') AS description,
            IFNULL(fc.followers_count, 0) AS followers_count
     FROM user_fandoms uf
     LEFT JOIN fandom_categories fc ON fc.name = uf.fandom
     WHERE uf.user_id = ?
     ORDER BY fc.name`,
    [userId]
  );

  const badges = await all(
    `SELECT pb.code, pb.name, pb.description, pb.icon, pb.color, pb.category,
            ub.awarded_at
     FROM user_badges ub
     JOIN profile_badges pb ON pb.id = ub.badge_id
     WHERE ub.user_id = ?
     ORDER BY pb.sort_order`,
    [userId]
  );

  const tasks = await all(
    `SELECT st.code, st.title, st.description, st.icon, st.color, st.reward_points,
            st.target_count, st.action, st.sort_order,
            IFNULL(ut.progress, 0) AS progress,
            IFNULL(ut.is_completed, 0) AS is_completed
     FROM social_tasks st
     LEFT JOIN user_tasks ut ON ut.task_code = st.code AND ut.user_id = ?
     ORDER BY st.sort_order`,
    [userId]
  );

  const stats = await get(
    `SELECT
       (SELECT COUNT(*) FROM user_fandoms   WHERE user_id = ?) AS fandom_count,
       (SELECT COUNT(*) FROM posts WHERE user_id = ? AND is_published = 1) AS posts_count,
       (SELECT COUNT(*) FROM bookmarks      WHERE user_id = ?) AS bookmarks_count,
       (SELECT COUNT(*) FROM content_views  WHERE user_id = ?) AS viewed_count,
       (SELECT COUNT(*) FROM content_views  WHERE user_id = ? AND is_offline = 1) AS offline_count,
       (SELECT COUNT(*) FROM saved_events   WHERE user_id = ?) AS saved_events_count,
       (SELECT COUNT(*) FROM event_tickets  WHERE user_id = ?) AS tickets_count,
       (SELECT COUNT(*) FROM user_badges    WHERE user_id = ?) AS badge_count,
       (SELECT COUNT(*) FROM follows WHERE follower_id = ?)  AS following_count,
       (SELECT COUNT(*) FROM follows WHERE following_id = ?) AS followers_count`,
    [userId, userId, userId, userId, userId, userId, userId, userId, userId, userId]
  );

  const completedTasks = tasks.filter((t) => t.is_completed === 1).length;

  return {
    user: {
      ...user,
      joined_ago: timeAgo(user.created_at),
      member_since: String(user.created_at).slice(0, 10),
      level: 1 + Math.floor((user.points || 0) / 100),
      next_level_points: (Math.floor((user.points || 0) / 100) + 1) * 100,
      selected_fandoms: fandoms.map((f) => f.name),
    },
    fandoms,
    badges,
    tasks,
    stats: { ...stats, completed_tasks: completedTasks, total_tasks: tasks.length },
    completion: tasks.length
      ? Math.round((completedTasks / tasks.length) * 100)
      : 0,
  };
}

// ---------------------------------------------------------------------------
// GET /api/profile/me  -> profile + stats + badges + tasks (cached)
// ---------------------------------------------------------------------------
export const getMyProfile = asyncHandler(async (req, res) => {
  const userId = me(req);

  const cached = await readCache(userId);
  if (cached) {
    return res.json({ success: true, cached: true, ...cached });
  }

  const profile = await buildProfile(userId);
  if (!profile) {
    return res.status(404).json({ success: false, message: "User not found" });
  }

  profile.newBadges = await awardEligibleBadges(userId);
  const fresh = profile.newBadges.length ? await buildProfile(userId) : profile;

  await writeCache(userId, fresh);
  res.json({ success: true, cached: false, ...fresh });
});

// ---------------------------------------------------------------------------
// PUT /api/profile/me  -> Edit Profile (name / bio / avatar)
// ---------------------------------------------------------------------------
export const updateMyProfile = asyncHandler(async (req, res) => {
  const userId = me(req);
  const { name, bio, avatar, is_public } = req.body ?? {};

  if (name !== undefined && String(name).trim().length < 2) {
    return res.status(400).json({ success: false, message: "Name is too short" });
  }
  if (bio !== undefined && String(bio).length > 240) {
    return res.status(400).json({ success: false, message: "Bio must be 240 characters or less" });
  }
  if (avatar !== undefined && String(avatar).trim() !== "" && !AVATARS.includes(String(avatar))) {
    return res.status(400).json({ success: false, message: "Unknown avatar preset" });
  }

  await run(
    `UPDATE users SET
       name      = COALESCE(?, name),
       bio       = COALESCE(?, bio),
       avatar    = COALESCE(NULLIF(?, ''), avatar),
       is_public = COALESCE(?, is_public),
       last_active_at = CURRENT_TIMESTAMP
     WHERE id = ?`,
    [
      name === undefined ? null : String(name).trim(),
      bio === undefined ? null : String(bio),
      avatar === undefined ? null : String(avatar),
      is_public === undefined ? null : is_public ? 1 : 0,
      userId,
    ]
  );

  await cache.invalidate(`profile:${userId}`);
  await run(`DELETE FROM profile_cache WHERE user_id = ?`, [userId]);

  const profile = await buildProfile(userId);
  const newBadges = await awardEligibleBadges(userId);

  res.json({
    success: true,
    message: "Profile updated successfully",
    newBadges,
    ...(newBadges.length ? await buildProfile(userId) : profile),
  });
});

// ---------------------------------------------------------------------------
// GET /api/profile/avatars  -> avatar presets (asset paths)
// ---------------------------------------------------------------------------
export const getAvatars = asyncHandler(async (_req, res) => {
  res.json({ success: true, avatars: AVATARS });
});

// ---------------------------------------------------------------------------
// GET /api/profile/fandoms  -> fandom catalogue + current selection
// ---------------------------------------------------------------------------
export const getFandomSelection = asyncHandler(async (req, res) => {
  const userId = me(req);

  const catalogue = await all(
    `SELECT fc.id, fc.name, fc.hashtag, fc.icon, fc.color, fc.description,
            fc.followers_count,
            (SELECT COUNT(*) FROM fandom_hubs fh WHERE LOWER(fh.name) = LOWER(fc.name)) AS hub_count
     FROM fandom_categories fc
     ORDER BY fc.followers_count DESC, fc.name`
  );

  const selected = await all(
    `SELECT fandom FROM user_fandoms WHERE user_id = ?`,
    [userId]
  );
  const selectedNames = selected.map((s) => s.fandom);

  // Bundled cover artwork for each fandom (generated by the tool script).
  const slugFor = (name) =>
    ({
      Anime: "anime",
      Gaming: "gaming",
      "Movies & TV": "movies_tv",
      Comics: "comics",
      Music: "music",
      Sports: "sports",
      "Sci-Fi": "scifi",
    }[name] || "default");

  res.json({
    success: true,
    fandoms: catalogue.map((f) => ({
      ...f,
      image_url: `assets/images/fandoms/${slugFor(f.name)}.jpg`,
      is_selected: selectedNames.includes(f.name),
    })),
    selected: selectedNames,
    minRequired: 1,
    maxSelectable: catalogue.length,
  });
});

// ---------------------------------------------------------------------------
// PUT /api/profile/fandoms  -> save the Fandom Selection screen
// ---------------------------------------------------------------------------
export const saveFandomSelection = asyncHandler(async (req, res) => {
  const userId = me(req);
  const { fandoms, skipped } = req.body ?? {};

  if (!Array.isArray(fandoms)) {
    return res.status(400).json({ success: false, message: "fandoms must be an array" });
  }
  if (!skipped && fandoms.length === 0) {
    return res.status(400).json({ success: false, message: "Select at least one fandom" });
  }

  const valid = await all(`SELECT name FROM fandom_categories`);
  const validNames = new Set(valid.map((v) => v.name));
  const chosen = [...new Set(fandoms.map((f) => String(f)))].filter((f) =>
    validNames.has(f)
  );

  const before = await all(`SELECT fandom FROM user_fandoms WHERE user_id = ?`, [userId]);
  const beforeNames = before.map((b) => b.fandom);

  await run(`DELETE FROM user_fandoms WHERE user_id = ?`, [userId]);
  for (const fandom of chosen) {
    await run(`INSERT OR IGNORE INTO user_fandoms (user_id, fandom) VALUES (?, ?)`, [
      userId,
      fandom,
    ]);
  }

  // Keep the fandom follower counters in sync (drives the trending carousel).
  for (const name of chosen.filter((f) => !beforeNames.includes(f))) {
    await run(
      `UPDATE fandom_categories SET followers_count = followers_count + 1 WHERE name = ?`,
      [name]
    );
  }
  for (const name of beforeNames.filter((f) => !chosen.includes(f))) {
    await run(
      `UPDATE fandom_categories SET followers_count = MAX(followers_count - 1, 0) WHERE name = ?`,
      [name]
    );
  }

  await run(`UPDATE users SET selected_fandoms = ? WHERE id = ?`, [
    chosen.join(","),
    userId,
  ]);

  // Fandom selection is a task in the Social & Tasks screen.
  await run(
    `UPDATE user_tasks SET progress = ?, is_completed = ?,
       completed_at = CASE WHEN ? = 1 THEN CURRENT_TIMESTAMP ELSE completed_at END,
       updated_at = CURRENT_TIMESTAMP
     WHERE user_id = ? AND task_code = 'pick_fandoms'`,
    [Math.min(chosen.length, 3), chosen.length >= 3 ? 1 : 0, chosen.length >= 3 ? 1 : 0, userId]
  );

  await cache.invalidate(`profile:${userId}`);
  await run(`DELETE FROM profile_cache WHERE user_id = ?`, [userId]);

  const newBadges = await awardEligibleBadges(userId);

  res.json({
    success: true,
    message: skipped
      ? "You can pick your fandoms later from your profile"
      : `Saved ${chosen.length} fandom${chosen.length === 1 ? "" : "s"}`,
    selected: chosen,
    newBadges,
  });
});

// ---------------------------------------------------------------------------
// GET /api/profile/badges  -> Public Badges screen
// ---------------------------------------------------------------------------
export const getBadges = asyncHandler(async (req, res) => {
  const userId = me(req);
  await awardEligibleBadges(userId);

  const badges = await all(
    `SELECT pb.id, pb.code, pb.name, pb.description, pb.icon, pb.color, pb.category,
            pb.threshold,
            CASE WHEN ub.id IS NULL THEN 0 ELSE 1 END AS is_earned,
            ub.awarded_at
     FROM profile_badges pb
     LEFT JOIN user_badges ub ON ub.badge_id = pb.id AND ub.user_id = ?
     ORDER BY is_earned DESC, pb.sort_order`,
    [userId]
  );

  const earned = badges.filter((b) => b.is_earned === 1);

  res.json({
    success: true,
    badges: badges.map((b) => ({ ...b, earned_ago: timeAgo(b.awarded_at) })),
    earnedCount: earned.length,
    totalCount: badges.length,
    progress: badges.length ? Math.round((earned.length / badges.length) * 100) : 0,
  });
});

// ---------------------------------------------------------------------------
// GET /api/profile/invite  -> Invite Friends screen
// ---------------------------------------------------------------------------
export const getInvite = asyncHandler(async (req, res) => {
  const userId = me(req);

  const user = await get(
    `SELECT id, name, invite_code, IFNULL(invite_count, 0) AS invite_count
     FROM users WHERE id = ?`,
    [userId]
  );
  if (!user) {
    return res.status(404).json({ success: false, message: "User not found" });
  }

  const invited = await all(
    `SELECT id, name, IFNULL(created_at, CURRENT_TIMESTAMP) AS created_at
     FROM users WHERE referred_by = ? ORDER BY id DESC LIMIT 20`,
    [userId]
  );

  const reward = 50;

  res.json({
    success: true,
    inviteCode: user.invite_code,
    inviteCount: user.invite_count,
    pointsEarned: user.invite_count * reward,
    rewardPerInvite: reward,
    invited: invited.map((i) => ({ ...i, joined_ago: timeAgo(i.created_at) })),
    shareMessage:
      `Join me on FANDOM VERSE - one app for every fandom! ` +
      `Use my invite code ${user.invite_code} when you sign up: https://fandomverse.app/invite/${user.invite_code}`,
  });
});

// ---------------------------------------------------------------------------
// POST /api/profile/invite/claim  -> apply someone else's code
// ---------------------------------------------------------------------------
export const claimInvite = asyncHandler(async (req, res) => {
  const userId = me(req);
  const code = String(req.body?.code ?? "").trim().toUpperCase();

  if (!code) {
    return res.status(400).json({ success: false, message: "Invite code is required" });
  }

  const inviter = await get(
    `SELECT id, name, invite_code FROM users WHERE UPPER(invite_code) = ?`,
    [code]
  );
  if (!inviter) {
    return res.status(404).json({ success: false, message: "That invite code does not exist" });
  }
  if (inviter.id === userId) {
    return res.status(400).json({ success: false, message: "You cannot claim your own code" });
  }

  const already = await get(`SELECT referred_by FROM users WHERE id = ?`, [userId]);
  if (already?.referred_by) {
    return res
      .status(400)
      .json({ success: false, message: "You have already claimed an invite code" });
  }

  await run(`UPDATE users SET referred_by = ? WHERE id = ?`, [inviter.id, userId]);
  await run(
    `UPDATE users SET invite_count = IFNULL(invite_count, 0) + 1, points = IFNULL(points, 0) + 50
     WHERE id = ?`,
    [inviter.id]
  );
  await run(
    `UPDATE user_tasks SET progress = progress + 1,
       is_completed = CASE WHEN progress + 1 >= 1 THEN 1 ELSE 0 END,
       completed_at = COALESCE(completed_at, CURRENT_TIMESTAMP),
       updated_at = CURRENT_TIMESTAMP
     WHERE user_id = ? AND task_code = 'invite_friend'`,
    [userId]
  );

  await notify({
    userId: inviter.id,
    type: "system",
    message: `${code} was claimed - you earned 50 fan points!`,
  });
  await awardEligibleBadges(inviter.id);

  res.json({ success: true, message: `Invite from ${inviter.name} applied. Welcome!` });
});

// ---------------------------------------------------------------------------
// GET /api/profile/tasks  -> Social & Tasks screen
// ---------------------------------------------------------------------------
export const getTasks = asyncHandler(async (req, res) => {
  const userId = me(req);

  const tasks = await all(
    `SELECT st.code, st.title, st.description, st.icon, st.color, st.reward_points,
            st.target_count, st.action, st.sort_order,
            IFNULL(ut.progress, 0) AS progress,
            IFNULL(ut.is_completed, 0) AS is_completed, ut.completed_at
     FROM social_tasks st
     LEFT JOIN user_tasks ut ON ut.task_code = st.code AND ut.user_id = ?
     ORDER BY is_completed ASC, st.sort_order`,
    [userId]
  );

  const user = await get(`SELECT IFNULL(points, 0) AS points FROM users WHERE id = ?`, [userId]);
  const completed = tasks.filter((t) => t.is_completed === 1);

  res.json({
    success: true,
    tasks: tasks.map((t) => ({
      ...t,
      progress_label: `${Math.min(t.progress, t.target_count)}/${t.target_count}`,
      percentage: t.target_count
        ? Math.min(100, Math.round((t.progress / t.target_count) * 100))
        : 0,
    })),
    points: user?.points ?? 0,
    completedCount: completed.length,
    totalCount: tasks.length,
    earnedPoints: completed.reduce((sum, t) => sum + (t.reward_points || 0), 0),
  });
});

// ---------------------------------------------------------------------------
// POST /api/profile/tasks/:code/complete
// ---------------------------------------------------------------------------
export const completeTask = asyncHandler(async (req, res) => {
  const userId = me(req);
  const code = String(req.params.code);

  const task = await get(`SELECT * FROM social_tasks WHERE code = ?`, [code]);
  if (!task) {
    return res.status(404).json({ success: false, message: "Task not found" });
  }

  const current = await get(
    `SELECT * FROM user_tasks WHERE user_id = ? AND task_code = ?`,
    [userId, code]
  );
  if (current?.is_completed === 1) {
    return res.status(400).json({ success: false, message: "Task already completed" });
  }

  const progress = Math.min((current?.progress ?? 0) + 1, task.target_count);
  const completed = progress >= task.target_count ? 1 : 0;

  await run(
    `INSERT INTO user_tasks (user_id, task_code, progress, is_completed, completed_at, updated_at)
     VALUES (?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
     ON CONFLICT (user_id, task_code) DO UPDATE SET
       progress = excluded.progress,
       is_completed = excluded.is_completed,
       completed_at = excluded.completed_at,
       updated_at = CURRENT_TIMESTAMP`,
    [
      userId,
      code,
      progress,
      completed,
      completed ? new Date().toISOString().slice(0, 19).replace("T", " ") : null,
    ]
  );

  if (completed) {
    await run(
      `UPDATE users SET points = IFNULL(points, 0) + ?, streak_count = IFNULL(streak_count, 0) + 1
       WHERE id = ?`,
      [task.reward_points, userId]
    );
  }

  await cache.invalidate(`profile:${userId}`);
  const newBadges = await awardEligibleBadges(userId);
  const user = await get(`SELECT IFNULL(points, 0) AS points FROM users WHERE id = ?`, [userId]);

  res.json({
    success: true,
    message: completed
      ? `Task complete! +${task.reward_points} fan points`
      : `Progress saved (${progress}/${task.target_count})`,
    progress,
    target: task.target_count,
    isCompleted: completed === 1,
    points: user?.points ?? 0,
    newBadges,
  });
});

// ---------------------------------------------------------------------------
// GET / PUT /api/profile/settings  -> Settings screen
// ---------------------------------------------------------------------------
export const getSettings = asyncHandler(async (req, res) => {
  const userId = me(req);

  await run(
    `INSERT OR IGNORE INTO user_settings (user_id) VALUES (?)`,
    [userId]
  );

  const settings = await get(`SELECT * FROM user_settings WHERE user_id = ?`, [userId]);
  const user = await get(`SELECT is_public FROM users WHERE id = ?`, [userId]);

  res.json({
    success: true,
    settings: { ...settings, is_public: user?.is_public ?? 1 },
    languages: ["English", "اردو", "हिन्दी", "العربية", "Español", "日本語", "한국어"],
  });
});

export const updateSettings = asyncHandler(async (req, res) => {
  const userId = me(req);
  const body = req.body ?? {};

  await run(`INSERT OR IGNORE INTO user_settings (user_id) VALUES (?)`, [userId]);

  const toInt = (value) => (value === undefined ? null : value ? 1 : 0);

  await run(
    `UPDATE user_settings SET
       language       = COALESCE(?, language),
       dark_mode      = COALESCE(?, dark_mode),
       push_enabled   = COALESCE(?, push_enabled),
       push_events    = COALESCE(?, push_events),
       push_content   = COALESCE(?, push_content),
       push_community = COALESCE(?, push_community),
       email_updates  = COALESCE(?, email_updates),
       autoplay_video = COALESCE(?, autoplay_video),
       offline_sync   = COALESCE(?, offline_sync),
       updated_at     = CURRENT_TIMESTAMP
     WHERE user_id = ?`,
    [
      body.language === undefined ? null : String(body.language),
      toInt(body.dark_mode),
      toInt(body.push_enabled),
      toInt(body.push_events),
      toInt(body.push_content),
      toInt(body.push_community),
      toInt(body.email_updates),
      toInt(body.autoplay_video),
      toInt(body.offline_sync),
      userId,
    ]
  );

  if (body.is_public !== undefined) {
    await run(`UPDATE users SET is_public = ? WHERE id = ?`, [
      body.is_public ? 1 : 0,
      userId,
    ]);
  }

  const settings = await get(`SELECT * FROM user_settings WHERE user_id = ?`, [userId]);
  const user = await get(`SELECT is_public FROM users WHERE id = ?`, [userId]);

  res.json({
    success: true,
    message: "Settings saved",
    settings: { ...settings, is_public: user?.is_public ?? 1 },
  });
});

// ---------------------------------------------------------------------------
// GET /api/profile/home  -> Home Dashboard aggregate
// ---------------------------------------------------------------------------
export const getHomeDashboard = asyncHandler(async (req, res) => {
  const userId = me(req);

  const profile = await buildProfile(userId);
  if (!profile) {
    return res.status(404).json({ success: false, message: "User not found" });
  }

  // Trending fandoms carousel (SRS: "Trending Fandoms Carousel").
  const trendingFandoms = await all(
    `SELECT fc.name, fc.hashtag, fc.icon, fc.color, fc.description, fc.followers_count,
            (SELECT COUNT(*) FROM user_fandoms uf WHERE uf.fandom = fc.name) AS selected_by
     FROM fandom_categories fc
     ORDER BY fc.followers_count DESC, fc.name
     LIMIT 8`
  );

  const hubs = await all(
    `SELECT slug, name, tagline, image_url, icon, color, is_trending, posts_count
     FROM fandom_hubs ORDER BY is_trending DESC, sort_order LIMIT 6`
  );

  const contentForFandoms = profile.fandoms.length
    ? profile.fandoms.map((f) => `'${String(f.name).replace(/'/g, "''")}'`).join(",")
    : "'Anime'";

  const latestNews = await all(
    `SELECT ci.id, ci.title, ci.summary, ci.image_url, ci.fandom, ci.content_type,
            ci.views_count, ci.likes_count, ci.published_at, ci.duration_seconds,
            IFNULL(fh.color, '#10B981') AS fandom_color, IFNULL(fh.icon, 'newspaper_rounded') AS fandom_icon
     FROM content_items ci
     LEFT JOIN fandom_hubs fh ON fh.slug = ci.hub_slug
     WHERE ci.content_type = 'news' AND ci.is_published = 1
     ORDER BY ci.is_featured DESC, ci.published_at DESC
     LIMIT 6`
  );

  const forYou = await all(
    `SELECT ci.id, ci.title, ci.summary, ci.image_url, ci.fandom, ci.content_type,
            ci.views_count, ci.likes_count, ci.published_at, ci.duration_seconds,
            ci.episode_number, ci.season,
            IFNULL(fh.color, '#10B981') AS fandom_color, IFNULL(fh.icon, 'auto_awesome_rounded') AS fandom_icon
     FROM content_items ci
     LEFT JOIN fandom_hubs fh ON fh.slug = ci.hub_slug
     WHERE ci.is_published = 1 AND ci.fandom IN (${contentForFandoms})
     ORDER BY ci.is_featured DESC, ci.published_at DESC
     LIMIT 8`
  );

  const continueWatching = await all(
    `SELECT ci.id, ci.title, ci.image_url, ci.content_type, ci.fandom,
            ci.duration_seconds, cv.progress, cv.is_offline,
            IFNULL(fh.color, '#10B981') AS fandom_color
     FROM content_views cv
     JOIN content_items ci ON ci.id = cv.content_id
     LEFT JOIN fandom_hubs fh ON fh.slug = ci.hub_slug
     WHERE cv.user_id = ?
     ORDER BY cv.viewed_at DESC LIMIT 5`,
    [userId]
  );

  const nextEvent = await get(
    `SELECT id, title, city_name, event_date, image_url, category, venue_name
     FROM events WHERE event_date >= date('now') ORDER BY event_date LIMIT 1`
  );

  const unread = await get(
    `SELECT COUNT(*) AS total FROM notifications WHERE user_id = ? AND is_read = 0`,
    [userId]
  );

  res.json({
    success: true,
    greeting: buildGreeting(),
    ...profile,
    trending: trendingFandoms.map((f) => ({
      ...f,
      is_selected: profile.fandoms.some((pf) => pf.name === f.name),
    })),
    hubs,
    latestNews: latestNews.map((n) => ({ ...n, published_ago: timeAgo(n.published_at) })),
    forYou: forYou.map((n) => ({
      ...n,
      published_ago: timeAgo(n.published_at),
      duration_label: n.duration_seconds ? formatDuration(n.duration_seconds) : '',
    })),
    continueWatching: continueWatching.map((c) => ({
      ...c,
      duration_label: c.duration_seconds ? formatDuration(c.duration_seconds) : '',
      percentage: c.duration_seconds
        ? Math.min(100, Math.round((c.progress || 0) * 100))
        : Math.round((c.progress || 0) * 100),
    })),
    nextEvent,
    unreadNotifications: unread?.total ?? 0,
  });
});

function formatDuration(seconds) {
  const total = Number(seconds) || 0;
  const minutes = Math.floor(total / 60);
  return `${minutes}:${String(total % 60).padStart(2, "0")}`;
}

function buildGreeting() {
  const hour = new Date().getHours();
  if (hour < 12) return "Good morning";
  if (hour < 17) return "Good afternoon";
  return "Good evening";
}

export default {
  getMyProfile,
  updateMyProfile,
  getAvatars,
  getFandomSelection,
  saveFandomSelection,
  getBadges,
  getInvite,
  claimInvite,
  getTasks,
  completeTask,
  getSettings,
  updateSettings,
  getHomeDashboard,
};
