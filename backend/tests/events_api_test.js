/**
 * MEMBER 4 - Events & Maps
 * API smoke test.
 *
 * Run the server first, then:
 *    node tests/events_api_test.js
 *
 * Exercises every Events endpoint and writes tests/events_report.txt
 * ("Test Data Used in the Project" evidence for the SRS deliverables).
 */

import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const BASE = process.env.API_BASE || "http://localhost:5000/api";
const EMAIL = process.env.DEMO_EMAIL || "emma@fandomverse.com";
const PASSWORD = process.env.DEMO_PASSWORD || "Fandom@123";

const out = [];
let token = "";
const summary = [];

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

const eventLine = (e) =>
  `${e.title} | ${e.city} | ${e.event_date} ${e.start_time} | ` +
  `${e.ticket_price} ${e.currency}` +
  (e.distance_km != null ? ` | ${e.distance_km} km` : "");

async function main() {
  // 0. health
  log("GET /health", await hit("GET", "/health", null, false));

  // 1. login
  const login = await hit("POST", "/auth/login", { email: EMAIL, password: PASSWORD }, false);
  token = login.json.token || "";
  log("POST /auth/login", login, (j) => ({ message: j.message, hasToken: !!j.token }));

  // 2. listing + filters
  log("GET /events", await hit("GET", "/events"), (j) => ({
    total: j.total,
    events: (j.events || []).map(eventLine),
  }));

  log("GET /events?city=Karachi", await hit("GET", "/events?city=Karachi"), (j) =>
    (j.events || []).map(eventLine)
  );

  log(
    "GET /events?category=Cosplay Meetup",
    await hit("GET", `/events?category=${encodeURIComponent("Cosplay Meetup")}`),
    (j) => (j.events || []).map(eventLine)
  );

  log("GET /events?free=true", await hit("GET", "/events?free=true"), (j) =>
    (j.events || []).map(eventLine)
  );

  log("GET /events?q=gaming", await hit("GET", "/events?q=gaming"), (j) =>
    (j.events || []).map(eventLine)
  );

  // 3. GPS / distance
  const KHI = "lat=24.8607&lng=67.0011";
  log(`GET /events?sort=distance&${KHI}`, await hit("GET", `/events?sort=distance&${KHI}`), (j) =>
    (j.events || []).map(eventLine)
  );
  log(`GET /events/nearby?${KHI}&radius=150`, await hit("GET", `/events/nearby?${KHI}&radius=150`), (j) => ({
    origin: j.origin,
    radius_km: j.radius_km,
    count: j.count,
    events: (j.events || []).map(eventLine),
  }));

  // 4. map pins
  log("GET /events/map", await hit("GET", "/events/map"), (j) => ({
    count: j.count,
    pins: (j.pins || []).map((p) => `${p.title} @ ${p.latitude},${p.longitude}`),
  }));

  // 5. filters data
  log("GET /events/categories", await hit("GET", "/events/categories"), (j) =>
    (j.categories || []).map((c) => `${c.name} (${c.events_count})`)
  );
  log("GET /events/cities", await hit("GET", "/events/cities"), (j) =>
    (j.cities || []).map((c) => `${c.city} (${c.events_count})`)
  );

  // 6. calendar
  const month = new Date().toISOString().slice(0, 7);
  log(`GET /events/calendar?month=${month}`, await hit("GET", `/events/calendar?month=${month}`), (j) => ({
    month: j.month,
    total_events: j.total_events,
    days: (j.days || []).map((d) => `${d.date}: ${d.count}`),
  }));

  // 7. overview
  log("GET /events/overview", await hit("GET", "/events/overview"), (j) => ({
    stats: j.stats,
    nextEvent: j.nextEvent ? eventLine(j.nextEvent) : null,
  }));

  // 8. details
  const list = await hit("GET", "/events");
  const events = list.json.events || [];
  const first = events[0];

  log(`GET /events/${first?.id}`, await hit("GET", `/events/${first?.id}`), (j) => ({
    title: j.event?.title,
    city: j.event?.city,
    venue: j.event?.venue,
    days_until: j.event?.days_until,
    seats_left: j.event?.seats_left,
    is_saved: j.event?.is_saved,
    nearby: (j.nearby || []).map((n) => n.title),
  }));

  // 9. save / interested toggle
  log(`POST /events/${first?.id}/save`, await hit("POST", `/events/${first?.id}/save`));
  log("GET /events/saved/mine", await hit("GET", "/events/saved/mine"), (j) => ({
    count: j.count,
    events: (j.events || []).map(eventLine),
  }));
  log(`POST /events/${first?.id}/save (revert)`, await hit("POST", `/events/${first?.id}/save`));

  // 10. ticket booking on an event without an existing ticket
  const myTickets = await hit("GET", "/events/tickets/mine");
  const ownedIds = new Set((myTickets.json.tickets || []).map((t) => t.event_id));
  const bookable = events.find((e) => !ownedIds.has(e.id)) || events[1];

  log("GET /events/tickets/mine (before)", myTickets, (j) => ({
    count: j.count,
    tickets: (j.tickets || []).map((t) => `${t.ticket_code} · ${t.title}`),
  }));

  const booked = await hit("POST", `/events/${bookable?.id}/tickets`, { quantity: 2 });
  log(`POST /events/${bookable?.id}/tickets`, booked, (j) => ({
    message: j.message,
    ticket: j.ticket
      ? `${j.ticket.ticket_code} · ${j.ticket.title} · qty ${j.ticket.quantity} · ${j.ticket.total_price} ${j.ticket.currency}`
      : null,
  }));

  const ticketId = booked.json.ticket?.id;
  if (ticketId) {
    log(`GET /events/tickets/${ticketId}`, await hit("GET", `/events/tickets/${ticketId}`), (j) => ({
      code: j.ticket?.ticket_code,
      seat: j.ticket?.seat_number,
      status: j.ticket?.status,
    }));
    log("GET /events/tickets/mine (after)", await hit("GET", "/events/tickets/mine"), (j) =>
      (j.tickets || []).map((t) => `${t.ticket_code} · ${t.title} · ${t.status}`)
    );
    log(`DELETE /events/tickets/${ticketId}`, await hit("DELETE", `/events/tickets/${ticketId}`));
  }

  // 11. create -> update -> delete
  const created = await hit("POST", "/events", {
    title: "API Test: Fan Art Battle",
    description: "Created by tests/events_api_test.js",
    category: "Workshop",
    city_name: "Karachi",
    venue_name: "Arts Council of Pakistan",
    latitude: 24.872,
    longitude: 67.029,
    event_date: new Date(Date.now() + 86400000 * 20).toISOString().slice(0, 10),
    start_time: "15:00",
    end_time: "19:00",
    ticket_price: 500,
    organizer: "Test Organizer",
    capacity: 100,
  });
  const createdId = created.json.event?.id;
  log("POST /events", created, (j) => ({ message: j.message, id: j.event?.id, title: j.event?.title }));

  if (createdId) {
    log(
      `PUT /events/${createdId}`,
      await hit("PUT", `/events/${createdId}`, { ticket_price: 750, is_featured: true }),
      (j) => ({ message: j.message, price: j.event?.ticket_price, featured: j.event?.is_featured })
    );
    log(`DELETE /events/${createdId}`, await hit("DELETE", `/events/${createdId}`));
  }

  // ------------------------------- report -------------------------------
  const failed = summary.filter((line) => !/^(200|201) /.test(line));

  const report = [
    "FANDOM VERSE - Member 4 (Events & Maps) API smoke test",
    `Run at: ${new Date().toISOString()}`,
    `Base URL: ${BASE}`,
    "",
    `Total checks: ${summary.length}`,
    `Passed (2xx): ${summary.length - failed.length}`,
    `Failed: ${failed.length}`,
    ...failed.map((f) => `  FAIL -> ${f}`),
    "",
    out.join("\n"),
  ].join("\n");

  const reportPath = path.join(__dirname, "events_report.txt");
  fs.writeFileSync(reportPath, report, "utf8");

  console.log(out.join("\n"));
  console.log(
    `\n${summary.length - failed.length}/${summary.length} checks passed` +
      (failed.length ? `\nFAILURES:\n${failed.join("\n")}` : "") +
      `\nReport saved to ${reportPath}`
  );
}

main().catch((error) => {
  console.error("Events smoke test failed:", error);
  process.exit(1);
});
