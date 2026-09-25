/**
 * MEMBER 2 - Fandom Content
 * API smoke test.
 *
 * Start the server first, then run:
 *   node tests/content_api_test.js      (or)  npm run test:content
 *
 * Writes a readable report to tests/content_report.txt which doubles as
 * "Test Data Used in the Project" evidence for the SRS deliverables.
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

const line = (i) => `${i.content_type} · ${i.title} · ${i.fandom} · ${i.duration_label || "-"}`;

async function main() {
  // 0. health
  log("GET /health", await hit("GET", "/health", null, false));

  // 1. login
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

  // 2. explore fandoms / hub cards
  log("GET /content/hub", await hit("GET", "/content/hub"), (j) => ({
    totals: j.totals,
    hubs: (j.hubs || []).map((h) => `${h.name} · ${h.items_count} items · ${h.total_views} views`),
    trending: (j.trending || []).map((h) => h.name),
  }));

  // 3. single fandom hub
  log("GET /content/hub/anime", await hit("GET", "/content/hub/anime"), (j) => ({
    hub: j.hub?.name,
    stats: { items: j.hub?.items, views: j.hub?.views, likes: j.hub?.likes },
    news: (j.news || []).map((n) => n.title),
    galleries: (j.galleries || []).map((g) => g.title),
    videos: (j.videos || []).map((v) => v.title),
    podcasts: (j.podcasts || []).map((p) => `Ep ${p.episode_number} · ${p.title}`),
    deepDives: (j.deepDives || []).map((d) => d.title),
    glossary: (j.glossary || []).map((g) => g.term),
  }));

  // 4. filtered lists
  log("GET /content?type=news", await hit("GET", "/content?type=news"), (j) => ({
    total: j.total,
    items: (j.items || []).map(line),
  }));

  log("GET /content?type=video", await hit("GET", "/content?type=video"), (j) => ({
    total: j.total,
    items: (j.items || []).map((v) => `${v.title} · ${v.duration_label}`),
  }));

  log("GET /content?type=podcast", await hit("GET", "/content?type=podcast"), (j) =>
    (j.items || []).map((p) => `S${p.season}E${p.episode_number} · ${p.title} · ${p.duration_label}`)
  );

  log("GET /content?type=gallery", await hit("GET", "/content?type=gallery"), (j) =>
    (j.items || []).map((g) => g.title)
  );

  log(
    "GET /content?fandom=Anime&sort=popular",
    await hit("GET", "/content?fandom=Anime&sort=popular"),
    (j) => (j.items || []).map(line)
  );

  log("GET /content?q=speedrun", await hit("GET", "/content?q=speedrun"), (j) =>
    (j.items || []).map(line)
  );

  // 5. discover feed
  log("GET /content/discover", await hit("GET", "/content/discover"), (j) => ({
    spotlight: j.spotlight?.title,
    trending: (j.trending || []).map((t) => t.title),
    latest: (j.latest || []).map((t) => t.title),
    collections: (j.collections || []).map((c) => c.title),
  }));

  // 6. glossary (beginner fan hub)
  log("GET /content/glossary", await hit("GET", "/content/glossary"), (j) => ({
    total: j.total,
    categories: Object.keys(j.grouped || {}),
    sample: (j.terms || []).slice(0, 5).map((t) => `${t.term}: ${t.definition}`),
  }));

  // 7. details of a gallery (media rows)
  const galleries = await hit("GET", "/content?type=gallery");
  const gallery = (galleries.json.items || [])[0];
  log(`GET /content/${gallery?.id}`, await hit("GET", `/content/${gallery?.id}`), (j) => ({
    title: j.item?.title,
    galleryCount: j.galleryCount,
    media: (j.media || []).map((m) => m.caption),
    related: (j.related || []).map((r) => r.title),
  }));

  // 8. details of a news story (paragraph splitting)
  const news = await hit("GET", "/content?type=news");
  const story = (news.json.items || [])[0];
  log(`GET /content/${story?.id}`, await hit("GET", `/content/${story?.id}`), (j) => ({
    title: j.item?.title,
    published_ago: j.item?.published_ago,
    paragraphs: (j.paragraphs || []).length,
    firstParagraph: (j.paragraphs || [])[0],
  }));

  // 9. view tracking -> recent list
  log(
    `POST /content/${story?.id}/view`,
    await hit("POST", `/content/${story?.id}/view`, { progress: 0.6 })
  );
  log("GET /content/recent", await hit("GET", "/content/recent"), (j) => ({
    recent: (j.recent || []).map((r) => `${r.content_type} · ${r.title}`),
    offlineCount: j.offlineCount,
  }));

  // 10. offline save / revert
  log(
    `POST /content/${story?.id}/offline`,
    await hit("POST", `/content/${story?.id}/offline`)
  );
  log("GET /content/offline", await hit("GET", "/content/offline"), (j) => ({
    totals: j.totals,
    offline: (j.offline || []).map((o) => o.title),
  }));

  // 11. like / unlike
  log(`POST /content/${story?.id}/like`, await hit("POST", `/content/${story?.id}/like`), (j) => ({
    message: j.message,
    isLiked: j.isLiked,
    likesCount: j.likesCount,
  }));

  // 12. error handling
  log("GET /content/999999", await hit("GET", "/content/999999"));

  // ------------------------------- report -------------------------------
  const failed = summary.filter((r) => !/^(200|201|404) /.test(r));

  const report = [
    "FANDOM VERSE - Member 2 (Fandom Content) API smoke test",
    `Run at: ${new Date().toISOString()}`,
    `Base URL: ${BASE}`,
    "",
    `Total checks: ${summary.length}`,
    `Passed (2xx/404): ${summary.length - failed.length}`,
    `Failed: ${failed.length}`,
    ...failed.map((f) => `  FAIL -> ${f}`),
    "",
    out.join("\n"),
  ].join("\n");

  const reportPath = path.join(__dirname, "content_report.txt");
  fs.writeFileSync(reportPath, report, "utf8");

  console.log(out.join("\n"));
  console.log(
    `\n${summary.length - failed.length}/${summary.length} checks passed` +
      (failed.length ? `\nFAILURES:\n${failed.join("\n")}` : "") +
      `\nReport saved to ${reportPath}`
  );
}

main().catch((error) => {
  console.error("Content smoke test failed:", error);
  process.exit(1);
});
