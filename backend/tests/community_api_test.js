/**
 * MEMBER 3 - Search & Community
 * API smoke test.
 *
 * Starts nothing by itself - run the server first, then:
 *    node tests/community_api_test.js
 *
 * It exercises every Search & Community endpoint and prints a readable
 * report to tests/report.txt (useful as "Test Data Used in the Project"
 * evidence for the SRS deliverables).
 */

import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const BASE = process.env.API_BASE || "http://localhost:5000/api";
const DEMO_EMAIL = process.env.DEMO_EMAIL || "emma@fandomverse.com";
const DEMO_PASSWORD = process.env.DEMO_PASSWORD || "Fandom@123";

const out = [];
let token = "";
let createdPostId = null;

function log(label, result, pick) {
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
  // 0. health ---------------------------------------------------------
  log("GET /health", await hit("GET", "/health", null, false));

  // 1. login (Member 1 module) to obtain a JWT ------------------------
  const login = await hit(
    "POST",
    "/auth/login",
    { email: DEMO_EMAIL, password: DEMO_PASSWORD },
    false
  );
  token = login.json.token || "";
  log("POST /auth/login", login, (j) => ({
    message: j.message,
    hasToken: !!j.token,
    user: j.user,
  }));

  // 2. SEARCH ---------------------------------------------------------
  log("GET /search?q=naruto", await hit("GET", "/search?q=naruto"), (j) => ({
    posts: (j.posts || []).map((p) => p.title),
    totals: j.totals,
  }));
  log(
    "GET /search?q=lore&type=posts&sort=top",
    await hit("GET", "/search?q=lore&type=posts&sort=top"),
    (j) => (j.posts || []).map((p) => `${p.title} (likes ${p.likes_count})`)
  );
  log(
    "GET /search?type=users&sort=popular",
    await hit("GET", "/search?type=users&sort=popular"),
    (j) => (j.users || []).map((u) => `${u.name} (${u.followers_count} followers)`)
  );
  log("GET /search?type=fandoms", await hit("GET", "/search?type=fandoms"), (j) =>
    (j.fandoms || []).map((f) => `${f.name} -> ${f.posts_count} posts`)
  );

  // 3. FILTERS / TRENDING / SUGGESTIONS -------------------------------
  log("GET /search/filters", await hit("GET", "/search/filters"), (j) => ({
    contentTypes: (j.contentTypes || []).map((c) => c.key),
    sortOptions: (j.sortOptions || []).map((s) => s.key),
    fandoms: (j.fandoms || []).map((f) => f.name),
  }));
  log("GET /search/trending", await hit("GET", "/search/trending"), (j) => ({
    hashtags: (j.hashtags || []).map((h) => `${h.tag} (${h.posts_count})`),
    topUsers: (j.users || []).map((u) => u.name),
    topPosts: (j.posts || []).map((p) => p.title),
    topFandoms: (j.fandoms || []).map((f) => f.name),
    deepDives: (j.deepDives || []).map((d) => d.title),
  }));
  log(
    "GET /search/suggestions?q=an",
    await hit("GET", "/search/suggestions?q=an"),
    (j) => j.suggestions
  );

  // 4. FEED / DISCUSSIONS ---------------------------------------------
  log("GET /posts?limit=3", await hit("GET", "/posts?limit=3"), (j) =>
    (j.posts || []).map((p) => p.title)
  );
  log(
    "GET /posts/discussions?sort=top",
    await hit("GET", "/posts/discussions?sort=top"),
    (j) => (j.posts || []).map((p) => `${p.title} (likes ${p.likes_count})`)
  );

  // 5. CREATE -> LIKE -> COMMENT -> DETAILS ---------------------------
  const created = await hit("POST", "/posts", {
    title: "API Test: Best villain redemption arcs",
    content: "Created by tests/community_api_test.js to verify the endpoint.",
    fandom_category: "Anime",
    hashtags: ["Anime", "Lore"],
    post_type: "deep_dive",
    rating: 4,
  });
  createdPostId = created.json.post?.id;
  log("POST /posts", created, (j) => ({
    message: j.message,
    id: j.post?.id,
    title: j.post?.title,
  }));

  log(`POST /posts/${createdPostId}/like`, await hit("POST", `/posts/${createdPostId}/like`));
  log(
    `POST /posts/${createdPostId}/comments`,
    await hit("POST", `/posts/${createdPostId}/comments`, { body: "Test comment" })
  );
  log(`GET /posts/${createdPostId}`, await hit("GET", `/posts/${createdPostId}`), (j) => ({
    title: j.post?.title,
    likes: j.post?.likes_count,
    comments: (j.post?.comments || []).map((c) => c.body),
  }));

  // 6. BOOKMARKS ------------------------------------------------------
  log(
    `POST /community/bookmarks/${createdPostId}`,
    await hit("POST", `/community/bookmarks/${createdPostId}`)
  );
  log("GET /community/bookmarks", await hit("GET", "/community/bookmarks"), (j) =>
    (j.bookmarks || []).map((b) => b.title)
  );

  // 7. FOLLOW + USER PROFILE ------------------------------------------
  log("POST /community/users/2/follow", await hit("POST", "/community/users/2/follow"));
  log("GET /community/users/2/profile", await hit("GET", "/community/users/2/profile"), (j) => ({
    name: j.user?.name,
    followers: j.user?.followers_count,
    posts: j.user?.posts_count,
    isFollowing: j.user?.is_following,
  }));

  // 8. NOTIFICATIONS --------------------------------------------------
  log("GET /community/notifications", await hit("GET", "/community/notifications"), (j) => ({
    unread: j.unread_count,
    items: (j.notifications || []).map((n) => `${n.type}: ${n.message}`),
  }));
  log(
    "POST /community/notifications/read-all",
    await hit("POST", "/community/notifications/read-all")
  );

  // 9. OVERVIEW -------------------------------------------------------
  log("GET /community/overview", await hit("GET", "/community/overview"));

  // 10. CLEANUP -------------------------------------------------------
  log(`DELETE /posts/${createdPostId}`, await hit("DELETE", `/posts/${createdPostId}`));

  const reportPath = path.join(__dirname, "report.txt");
  fs.writeFileSync(reportPath, out.join("\n"), "utf8");
  console.log(out.join("\n"));
  console.log(`\nReport saved to ${reportPath}`);
}

main().catch((error) => {
  console.error("Smoke test failed:", error);
  process.exit(1);
});
