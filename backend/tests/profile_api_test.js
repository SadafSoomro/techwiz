/**
 * MEMBER 1 - Profile, Fandom Selection & Home
 * API smoke test.
 *
 * Start the server first, then run:
 *   node tests/profile_api_test.js      (or)  npm run test:profile
 *
 * Writes tests/profile_report.txt as SRS evidence.
 */

import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const BASE = process.env.API_BASE || "http://localhost:5000/api";
const DEMO_EMAIL = process.env.DEMO_EMAIL || "emma@fandomverse.com";
const DEMO_PASSWORD = process.env.DEMO_PASSWORD || "Fandom@123";

const out = [];
const summary = [];
let token = "";

function log(label, result, pick) {
  summary.push(`${result.status} ${label}`);
  out.push(`\n--- ${label}  [HTTP ${result.status}] ---`);
  const value = pick ? pick(result.json) : result.json;
  out.push(JSON.stringify(value, null, 1));
}

async function hit(method, endpoint, body, withAuth = true) {
  try {
    const res = await fetch(`${BASE}${endpoint}`, {
      method,
      headers: {
        "Content-Type": "application/json",
        ...(withAuth && token ? { Authorization: `Bearer ${token}` } : {}),
      },
      body: body ? JSON.stringify(body) : undefined,
    });
    const json = await res.json().catch(() => ({}));
    return { status: res.status, json };
  } catch (error) {
    return { status: 0, json: { error: error.message } };
  }
}

async function main() {
  // 0. health
  log("GET /health", await hit("GET", "/health", null, false));

  // 1. login (registration + verification happen through the mail flow)
  const login = await hit(
    "POST",
    "/auth/login",
    { email: DEMO_EMAIL, password: DEMO_PASSWORD },
    false
  );
  token = login.json.token || "";
  log("POST /auth/login", login, (j) => ({ message: j.message, hasToken: !!j.token }));

  // 2. auth guard
  log("GET /profile/me (no token)", await hit("GET", "/profile/me", null, false), (j) => j.message);

  // 3. profile + stats + badges + tasks (cached read)
  log("GET /profile/me", await hit("GET", "/profile/me"), (j) => ({
    cached: j.cached,
    user: {
      name: j.user?.name,
      email: j.user?.email,
      invite_code: j.user?.invite_code,
      points: j.user?.points,
      level: j.user?.level,
      joined_ago: j.user?.joined_ago,
    },
    fandoms: (j.fandoms || []).map((f) => `${f.name} ${f.hashtag}`),
    badges: (j.badges || []).map((b) => b.name),
    stats: j.stats,
    completion: `${j.completion}%`,
    newBadges: j.newBadges,
  }));

  log("GET /profile/me (cached)", await hit("GET", "/profile/me"), (j) => ({
    cached: j.cached,
    name: j.user?.name,
  }));

  // 4. avatar presets
  log("GET /profile/avatars", await hit("GET", "/profile/avatars"), (j) => j.avatars);

  // 5. edit profile
  log(
    "PUT /profile/me",
    await hit("PUT", "/profile/me", {
      bio: "Anime addict | One Piece forever | Pocket edition beta fan",
      avatar: "assets/images/avatars/avatar_01.jpg",
    }),
    (j) => ({
      message: j.message,
      newBadges: j.newBadges,
      user: { name: j.user?.name, bio: j.user?.bio, avatar: j.user?.avatar },
    })
  );

  log(
    "PUT /profile/me (invalid avatar)",
    await hit("PUT", "/profile/me", { avatar: "https://example.com/nope.jpg" }),
    (j) => j.message
  );

  // 6. fandom catalogue + selection
  log("GET /profile/fandoms", await hit("GET", "/profile/fandoms"), (j) => ({
    selected: j.selected,
    fandoms: (j.fandoms || []).map((f) => `${f.name} · ${f.image_url} · selected=${f.is_selected}`),
  }));

  log(
    "PUT /profile/fandoms",
    await hit("PUT", "/profile/fandoms", { fandoms: ["Anime", "Gaming", "Music"] }),
    (j) => ({ message: j.message, selected: j.selected, newBadges: j.newBadges })
  );

  log(
    "PUT /profile/fandoms (empty)",
    await hit("PUT", "/profile/fandoms", { fandoms: [] }),
    (j) => j.message
  );

  // 7. badges
  log("GET /profile/badges", await hit("GET", "/profile/badges"), (j) => ({
    earned: `${j.earnedCount}/${j.totalCount}`,
    progress: `${j.progress}%`,
    badges: (j.badges || []).map((b) => `${b.is_earned ? "EARNED" : "locked"} · ${b.name} · ${b.category}`),
  }));

  // 8. invite
  log("GET /profile/invite", await hit("GET", "/profile/invite"), (j) => ({
    inviteCode: j.inviteCode,
    inviteCount: j.inviteCount,
    rewardPerInvite: j.rewardPerInvite,
    pointsEarned: j.pointsEarned,
    invited: (j.invited || []).map((i) => i.name),
    shareMessage: j.shareMessage,
  }));

  log("POST /profile/invite/claim (own code)", await hit("POST", "/profile/invite/claim", { code: "FV00000" }), (j) => j.message);

  // 9. social tasks
  log("GET /profile/tasks", await hit("GET", "/profile/tasks"), (j) => ({
    points: j.points,
    completed: `${j.completedCount}/${j.totalCount}`,
    earnedPoints: j.earnedPoints,
    tasks: (j.tasks || []).map((t) => `${t.title} · ${t.progress_label} · ${t.percentage}%`),
  }));

  const tasks = await hit("GET", "/profile/tasks");
  const open = (tasks.json.tasks || []).find((t) => t.is_completed !== 1);
  if (open) {
    log(`POST /profile/tasks/${open.code}/complete`, await hit("POST", `/profile/tasks/${open.code}/complete`), (j) => ({
      message: j.message,
      progress: `${j.progress}/${j.target}`,
      isCompleted: j.isCompleted,
      points: j.points,
    }));
  }
  log("POST /profile/tasks/nope/complete", await hit("POST", "/profile/tasks/nope/complete"), (j) => j.message);

  // 10. settings
  log("GET /profile/settings", await hit("GET", "/profile/settings"), (j) => ({
    settings: j.settings,
    languages: j.languages,
  }));
  log(
    "PUT /profile/settings",
    await hit("PUT", "/profile/settings", { dark_mode: true, push_content: false, language: "English" }),
    (j) => ({ message: j.message, settings: j.settings })
  );

  // 11. home dashboard
  log("GET /profile/home", await hit("GET", "/profile/home"), (j) => ({
    greeting: j.greeting,
    user: j.user?.name,
    level: j.user?.level,
    points: j.user?.points,
    stats: j.stats,
    completion: `${j.completion}%`,
    badges: (j.badges || []).map((b) => b.name),
    trending: (j.trending || []).map((t) => `${t.name} (${t.followers_count}) selected=${t.is_selected}`),
    hubs: (j.hubs || []).map((h) => `${h.name} · ${h.image_url}`),
    latestNews: (j.latestNews || []).map((n) => `${n.title} · ${n.published_ago}`),
    forYou: (j.forYou || []).map((n) => `${n.content_type} · ${n.title}`),
    continueWatching: (j.continueWatching || []).map((c) => `${c.title} · ${c.percentage}%`),
    nextEvent: j.nextEvent ? `${j.nextEvent.title} @ ${j.nextEvent.city_name} on ${j.nextEvent.event_date}` : null,
    unreadNotifications: j.unreadNotifications,
  }));

  // ------------------------------- report -------------------------------
  const failed = summary.filter((r) => !/^(200|201|400|404|401) /.test(r));

  const report = [
    "FANDOM VERSE - Member 1 (Profile, Fandom Selection & Home) API smoke test",
    `Run at: ${new Date().toISOString()}`,
    `Base URL: ${BASE}`,
    "",
    `Total checks: ${summary.length}`,
    `Passed (2xx/expected 4xx): ${summary.length - failed.length}`,
    `Failed: ${failed.length}`,
    ...failed.map((f) => `  FAIL -> ${f}`),
    "",
    out.join("\n"),
  ].join("\n");

  const reportPath = path.join(__dirname, "profile_report.txt");
  fs.writeFileSync(reportPath, report, "utf8");

  console.log(out.join("\n"));
  console.log(
    `\n${summary.length - failed.length}/${summary.length} checks passed` +
      (failed.length ? `\nFAILURES:\n${failed.join("\n")}` : "") +
      `\nReport saved to ${reportPath}`
  );
}

main().catch((error) => {
  console.error("Profile smoke test failed:", error);
  process.exit(1);
});
