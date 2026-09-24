/**
 * MEMBER 4 - Events & Maps
 * Events controller.
 *
 * Covers:
 *   - Event listing with filters (city, category, date range, keyword, sort)
 *   - GPS / "nearby" discovery using the Haversine formula
 *   - Calendar view (events grouped by day for a month)
 *   - Map pins (light payload with coordinates)
 *   - Event details
 *   - Save / interested toggle
 *   - Simulated ticket booking (no real payment - per SRS scope)
 *
 * SQLite is used for storage and caching (database/cache.js).
 */

import { all, get, run, asyncHandler, timeAgo } from "../database/dbhelpers.js";
import cache from "../database/cache.js";
import { notify } from "../utils/notify.js";

// ---------------------------------------------------------------------------
// helpers
// ---------------------------------------------------------------------------

/** Great-circle distance between two points in kilometres. */
export function haversineKm(lat1, lon1, lat2, lon2) {
  const R = 6371;
  const toRad = (deg) => (deg * Math.PI) / 180;

  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);

  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) * Math.sin(dLon / 2);

  return +(2 * R * Math.asin(Math.sqrt(a))).toFixed(2);
}

const EVENT_SELECT = `
  SELECT
    e.id, e.title, e.description, e.category,
    e.city_name AS city,
    e.venue_name AS venue,
    e.address,
    e.latitude, e.longitude,
    e.event_date, e.end_date, e.start_time, e.end_time,
    e.ticket_link, e.ticket_price, e.currency,
    e.image_url, e.organizer, e.capacity, e.attendees_count,
    e.is_featured, e.status, e.created_at,
    (SELECT COUNT(*) FROM saved_events s WHERE s.event_id = e.id) AS saves_count,
    (SELECT COUNT(*) FROM event_tickets t
      WHERE t.event_id = e.id AND t.status = 'confirmed')      AS tickets_sold
  FROM events e
`;

const SORTS = {
  date: "e.event_date ASC, e.start_time ASC",
  newest: "e.created_at DESC",
  popular: "(e.attendees_count + e.is_featured * 500) DESC",
  price_low: "e.ticket_price ASC, e.event_date ASC",
  price_high: "e.ticket_price DESC, e.event_date ASC",
};

function orderBy(value) {
  return SORTS[String(value || "date").toLowerCase()] || SORTS.date;
}

function todayIso() {
  return new Date().toISOString().slice(0, 10);
}

/** Builds the WHERE clause shared by list / map / nearby. */
function buildWhere(query, { includePast = false } = {}) {
  const conditions = [];
  const params = [];

  if (!includePast) {
    conditions.push(`e.event_date >= ?`);
    params.push(query.from || todayIso());
  } else if (query.from) {
    conditions.push(`e.event_date >= ?`);
    params.push(query.from);
  }

  if (query.to) {
    conditions.push(`e.event_date <= ?`);
    params.push(query.to);
  }
  if (query.city && query.city.toLowerCase() !== "all") {
    conditions.push(`e.city_name = ?`);
    params.push(query.city);
  }
  if (query.category && query.category.toLowerCase() !== "all") {
    conditions.push(`e.category = ?`);
    params.push(query.category);
  }
  if (String(query.featured || "") === "1" || query.featured === "true") {
    conditions.push(`e.is_featured = 1`);
  }
  if (String(query.free || "") === "1" || query.free === "true") {
    conditions.push(`e.ticket_price = 0`);
  }
  if (query.q) {
    conditions.push(
      `(e.title LIKE ? OR IFNULL(e.description,'') LIKE ?
        OR e.city_name LIKE ? OR IFNULL(e.venue_name,'') LIKE ?
        OR IFNULL(e.organizer,'') LIKE ?)`
    );
    const like = `%${query.q}%`;
    params.push(like, like, like, like, like);
  }

  return {
    sql: conditions.length ? `WHERE ${conditions.join(" AND ")}` : "",
    params,
  };
}

/** Adds "distance_km" + ticket availability flags and sorting. */
async function fetchEvents(req, options = {}) {
  const { sql, params } = buildWhere(req.query, options);
  const lat = parseFloat(req.query.lat);
  const lng = parseFloat(req.query.lng);
  const hasOrigin = !Number.isNaN(lat) && !Number.isNaN(lng);
  const sort = String(req.query.sort || "date").toLowerCase();
  const limit = Math.min(parseInt(req.query.limit, 10) || 30, 100);

  const rows = await all(`${EVENT_SELECT} ${sql} ORDER BY ${orderBy(sort)}`, params);
  const userId = req.user?.id ?? -1;

  let enriched = rows.map((row) => {
    const distance =
      hasOrigin && row.latitude != null && row.longitude != null
        ? haversineKm(lat, lng, row.latitude, row.longitude)
        : null;

    return {
      ...row,
      distance_km: distance,
      is_saved: false,
      days_until: daysUntil(row.event_date),
      seats_left: Math.max(0, (row.capacity || 0) - (row.tickets_sold || 0)),
    };
  });

  // saved flags for the logged in user
  if (userId > 0 && enriched.length) {
    const saved = await all(
      `SELECT event_id FROM saved_events WHERE user_id = ?`,
      [userId]
    );
    const savedIds = new Set(saved.map((s) => s.event_id));
    enriched = enriched.map((event) => ({ ...event, is_saved: savedIds.has(event.id) }));
  }

  // distance sorting needs the computed values, so it happens in Node
  if (sort === "distance") {
    if (!hasOrigin) {
      enriched.sort((a, b) => String(a.event_date).localeCompare(String(b.event_date)));
    } else {
      enriched.sort((a, b) => (a.distance_km ?? 1e9) - (b.distance_km ?? 1e9));
    }
  }

  const offset = parseInt(req.query.offset, 10) || 0;

  return {
    events: enriched.slice(offset, offset + limit),
    total: enriched.length,
    limit,
    offset,
    hasMore: offset + limit < enriched.length,
  };
}

function daysUntil(dateString) {
  if (!dateString) return 0;
  const target = new Date(`${String(dateString).slice(0, 10)}T00:00:00Z`).getTime();
  const today = new Date(`${todayIso()}T00:00:00Z`).getTime();
  return Math.round((target - today) / 86400000);
}

function ticketCodeFor(eventId) {
  const random = Math.floor(1000 + Math.random() * 9000);
  return `FV-${String(eventId).padStart(4, "0")}-${random}`;
}

// ===========================================================================
// GET /api/events
// ?city=&category=&q=&from=&to=&sort=date|popular|price_low|price_high|distance
// &lat=&lng=&featured=&free=&limit=&offset=
// ===========================================================================
export const getEvents = asyncHandler(async (req, res) => {
  const result = await fetchEvents(req);

  res.json({
    success: true,
    ...result,
  });
});

// ===========================================================================
// GET /api/events/nearby?lat=&lng=&radius=
// GPS style discovery - the SRS "Map and GPS Integration" requirement.
// ===========================================================================
export const getNearbyEvents = asyncHandler(async (req, res) => {
  const lat = parseFloat(req.query.lat);
  const lng = parseFloat(req.query.lng);
  const radius = parseFloat(req.query.radius) || 100; // km

  if (Number.isNaN(lat) || Number.isNaN(lng)) {
    return res.status(400).json({
      success: false,
      message: "lat and lng query parameters are required",
    });
  }

  const cacheKey = `events:nearby:${lat.toFixed(2)}:${lng.toFixed(2)}:${radius}`;
  const cached = await cache.get(cacheKey);
  if (cached) {
    return res.json({ success: true, ...cached, cached: true });
  }

  const { sql, params } = buildWhere({});
  const rows = await all(`${EVENT_SELECT} ${sql} ORDER BY e.event_date ASC`, params);

  const withDistance = rows
    .map((row) => ({
      ...row,
      distance_km:
        row.latitude != null && row.longitude != null
          ? haversineKm(lat, lng, row.latitude, row.longitude)
          : null,
      days_until: daysUntil(row.event_date),
      seats_left: Math.max(0, (row.capacity || 0) - (row.tickets_sold || 0)),
    }))
    .filter((row) => row.distance_km != null && row.distance_km <= radius)
    .sort((a, b) => a.distance_km - b.distance_km);

  const payload = {
    origin: { latitude: lat, longitude: lng },
    radius_km: radius,
    count: withDistance.length,
    events: withDistance,
  };

  await cache.set(cacheKey, payload, 120);
  res.json({ success: true, ...payload, cached: false });
});

// ===========================================================================
// GET /api/events/map  -> light payload for map pins
// ===========================================================================
export const getMapPins = asyncHandler(async (req, res) => {
  const { sql, params } = buildWhere(req.query);

  const pins = await all(
    `SELECT
       e.id, e.title, e.category, e.city_name AS city, e.venue_name AS venue,
       e.latitude, e.longitude, e.event_date, e.start_time,
       e.ticket_price, e.currency, e.is_featured
     FROM events e
     ${sql}
     ORDER BY e.event_date ASC
     LIMIT 100`,
    params
  );

  res.json({ success: true, count: pins.length, pins });
});

// ===========================================================================
// GET /api/events/categories
// ===========================================================================
export const getEventCategories = asyncHandler(async (req, res) => {
  const cached = await cache.get("events:categories");
  if (cached) return res.json({ success: true, ...cached, cached: true });

  const categories = await all(
    `SELECT
       c.name, c.icon, c.color, c.description,
       (SELECT COUNT(*) FROM events e
         WHERE e.category = c.name AND e.event_date >= date('now')) AS events_count
     FROM event_categories c
     ORDER BY events_count DESC, c.name ASC`
  );

  const payload = { categories };
  await cache.set("events:categories", payload, 120);
  res.json({ success: true, ...payload, cached: false });
});

// ===========================================================================
// GET /api/events/cities  -> "filterable by city" (SRS requirement)
// ===========================================================================
export const getEventCities = asyncHandler(async (req, res) => {
  const cached = await cache.get("events:cities");
  if (cached) return res.json({ success: true, ...cached, cached: true });

  const cities = await all(
    `SELECT
       e.city_name AS city,
       COUNT(*)    AS events_count,
       AVG(e.latitude)  AS latitude,
       AVG(e.longitude) AS longitude
     FROM events e
     WHERE e.event_date >= date('now')
     GROUP BY e.city_name
     ORDER BY events_count DESC, e.city_name ASC`
  );

  const payload = { cities };
  await cache.set("events:cities", payload, 120);
  res.json({ success: true, ...payload, cached: false });
});

// ===========================================================================
// GET /api/events/calendar?month=YYYY-MM
// Events grouped per day for the Calendar screen.
// ===========================================================================
export const getEventCalendar = asyncHandler(async (req, res) => {
  const month = String(req.query.month || todayIso().slice(0, 7)).slice(0, 7);

  if (!/^\d{4}-\d{2}$/.test(month)) {
    return res.status(400).json({
      success: false,
      message: "month must use the YYYY-MM format",
    });
  }

  const cacheKey = `events:calendar:${month}:${req.query.city || "all"}`;
  const cached = await cache.get(cacheKey);
  if (cached) return res.json({ success: true, ...cached, cached: true });

  const { sql, params } = buildWhere(
    { ...req.query, from: `${month}-01`, to: `${month}-31` },
    { includePast: true }
  );

  const rows = await all(`${EVENT_SELECT} ${sql} ORDER BY e.event_date ASC`, params);

  // group by day
  const byDay = new Map();
  rows.forEach((row) => {
    const day = String(row.event_date).slice(0, 10);
    if (!byDay.has(day)) byDay.set(day, []);
    byDay.get(day).push({ ...row, days_until: daysUntil(row.event_date) });
  });

  const days = [...byDay.entries()]
    .map(([date, events]) => ({ date, count: events.length, events }))
    .sort((a, b) => a.date.localeCompare(b.date));

  const payload = {
    month,
    total_events: rows.length,
    days,
  };

  await cache.set(cacheKey, payload, 120);
  res.json({ success: true, ...payload, cached: false });
});

// ===========================================================================
// GET /api/events/:id
// ===========================================================================
export const getEventById = asyncHandler(async (req, res) => {
  const userId = req.user?.id ?? -1;

  const event = await get(`${EVENT_SELECT} WHERE e.id = ?`, [req.params.id]);

  if (!event) {
    return res.status(404).json({ success: false, message: "Event not found" });
  }

  const saved = userId > 0
    ? await get(`SELECT id FROM saved_events WHERE user_id = ? AND event_id = ?`, [
        userId,
        req.params.id,
      ])
    : null;

  const myTicket = userId > 0
    ? await get(
        `SELECT * FROM event_tickets
         WHERE user_id = ? AND event_id = ? AND status = 'confirmed'
         ORDER BY id DESC LIMIT 1`,
        [userId, req.params.id]
      )
    : null;

  const venue = event.venue
    ? await get(`SELECT * FROM venues WHERE name = ? AND city_name = ?`, [
        event.venue,
        event.city,
      ])
    : null;

  // other events in the same city (shown as "Nearby Events" on details)
  const nearby = await all(
    `SELECT id, title, category, city_name AS city, venue_name AS venue,
            latitude, longitude, event_date, start_time, ticket_price, currency
     FROM events
     WHERE city_name = ? AND id <> ? AND event_date >= date('now')
     ORDER BY event_date ASC LIMIT 5`,
    [event.city, event.id]
  );

  res.json({
    success: true,
    event: {
      ...event,
      is_saved: !!saved,
      days_until: daysUntil(event.event_date),
      seats_left: Math.max(0, (event.capacity || 0) - (event.tickets_sold || 0)),
      created_ago: timeAgo(event.created_at),
    },
    venue,
    myTicket,
    nearby,
  });
});

// ===========================================================================
// POST /api/events          (create - organizer/admin)
// ===========================================================================
export const createEvent = asyncHandler(async (req, res) => {
  const {
    title, description, category, city_name, venue_name, address,
    latitude, longitude, event_date, end_date, start_time, end_time,
    ticket_link, ticket_price, image_url, organizer, capacity, is_featured,
  } = req.body;

  if (!title || !String(title).trim()) {
    return res.status(400).json({ success: false, message: "Title is required" });
  }
  if (!city_name || !String(city_name).trim()) {
    return res.status(400).json({ success: false, message: "City is required" });
  }
  if (!event_date) {
    return res.status(400).json({ success: false, message: "Event date is required" });
  }

  const result = await run(
    `INSERT INTO events
       (title, description, category, city_name, venue_name, address,
        latitude, longitude, event_date, end_date, start_time, end_time,
        ticket_link, ticket_price, currency, image_url, organizer, capacity, is_featured)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'PKR', ?, ?, ?, ?)`,
    [
      String(title).trim(),
      description ?? null,
      category || "Fan Convention",
      String(city_name).trim(),
      venue_name ?? null,
      address ?? null,
      latitude ?? null,
      longitude ?? null,
      event_date,
      end_date ?? null,
      start_time || "10:00",
      end_time || "18:00",
      ticket_link ?? null,
      parseFloat(ticket_price) || 0,
      image_url ?? null,
      organizer ?? null,
      parseInt(capacity, 10) || 0,
      is_featured ? 1 : 0,
    ]
  );

  await cache.invalidate("events:");

  const event = await get(`${EVENT_SELECT} WHERE e.id = ?`, [result.lastID]);
  res.status(201).json({ success: true, message: "Event created successfully", event });
});

// ===========================================================================
// PUT /api/events/:id
// ===========================================================================
export const updateEvent = asyncHandler(async (req, res) => {
  const existing = await get(`SELECT id FROM events WHERE id = ?`, [req.params.id]);
  if (!existing) {
    return res.status(404).json({ success: false, message: "Event not found" });
  }

  const fields = [
    "title", "description", "category", "city_name", "venue_name", "address",
    "latitude", "longitude", "event_date", "end_date", "start_time", "end_time",
    "ticket_link", "ticket_price", "image_url", "organizer", "capacity", "status",
  ];

  const updates = [];
  const params = [];

  fields.forEach((field) => {
    if (req.body[field] !== undefined) {
      updates.push(`${field} = ?`);
      params.push(req.body[field]);
    }
  });

  if (req.body.is_featured !== undefined) {
    updates.push(`is_featured = ?`);
    params.push(req.body.is_featured ? 1 : 0);
  }

  if (!updates.length) {
    return res.status(400).json({ success: false, message: "Nothing to update" });
  }

  updates.push(`updated_at = CURRENT_TIMESTAMP`);

  await run(`UPDATE events SET ${updates.join(", ")} WHERE id = ?`, [
    ...params,
    req.params.id,
  ]);

  await cache.invalidate("events:");

  const event = await get(`${EVENT_SELECT} WHERE e.id = ?`, [req.params.id]);
  res.json({ success: true, message: "Event updated successfully", event });
});

// ===========================================================================
// DELETE /api/events/:id
// ===========================================================================
export const deleteEvent = asyncHandler(async (req, res) => {
  await run(`DELETE FROM saved_events WHERE event_id = ?`, [req.params.id]);
  await run(`DELETE FROM event_tickets WHERE event_id = ?`, [req.params.id]);
  await run(`DELETE FROM event_reminders WHERE event_id = ?`, [req.params.id]);
  const result = await run(`DELETE FROM events WHERE id = ?`, [req.params.id]);

  if (!result.changes) {
    return res.status(404).json({ success: false, message: "Event not found" });
  }

  await cache.invalidate("events:");
  res.json({ success: true, message: "Event deleted successfully" });
});

// ===========================================================================
// POST /api/events/:id/save   -> toggle "Interested"
// ===========================================================================
export const toggleSaveEvent = asyncHandler(async (req, res) => {
  const eventId = req.params.id;
  const userId = req.user.id;

  const event = await get(`SELECT id, title FROM events WHERE id = ?`, [eventId]);
  if (!event) {
    return res.status(404).json({ success: false, message: "Event not found" });
  }

  const existing = await get(
    `SELECT id FROM saved_events WHERE user_id = ? AND event_id = ?`,
    [userId, eventId]
  );

  if (existing) {
    await run(`DELETE FROM saved_events WHERE id = ?`, [existing.id]);
  } else {
    await run(`INSERT INTO saved_events (user_id, event_id) VALUES (?, ?)`, [
      userId,
      eventId,
    ]);

    await notify({
      userId,
      actorId: null,
      type: "system",
      message: `You are interested in "${event.title}". We will remind you before it starts.`,
      referenceId: Number(eventId),
    });
  }

  const total = await get(
    `SELECT COUNT(*) AS total FROM saved_events WHERE user_id = ?`,
    [userId]
  );

  res.json({
    success: true,
    saved: !existing,
    total_saved: total.total,
    message: existing ? "Removed from your events" : "Saved to your events",
  });
});

// ===========================================================================
// GET /api/events/saved/mine  -> saved / interested events
// ===========================================================================
export const getMySavedEvents = asyncHandler(async (req, res) => {
  const userId = req.user.id;

  const rows = await all(
    `SELECT
       e.id, e.title, e.description, e.category,
       e.city_name AS city, e.venue_name AS venue, e.address,
       e.latitude, e.longitude, e.event_date, e.end_date,
       e.start_time, e.end_time, e.ticket_link, e.ticket_price, e.currency,
       e.organizer, e.capacity, e.attendees_count, e.is_featured,
       s.saved_at,
       (SELECT COUNT(*) FROM event_tickets t
         WHERE t.event_id = e.id AND t.status = 'confirmed') AS tickets_sold
     FROM saved_events s
     JOIN events e ON e.id = s.event_id
     WHERE s.user_id = ?
     ORDER BY e.event_date ASC`,
    [userId]
  );

  res.json({
    success: true,
    count: rows.length,
    events: rows.map((row) => ({
      ...row,
      saved_ago: timeAgo(row.saved_at),
      days_until: daysUntil(row.event_date),
      is_saved: true,
    })),
  });
});

// ===========================================================================
// POST /api/events/:id/tickets   -> simulated booking
// ===========================================================================
export const bookTicket = asyncHandler(async (req, res) => {
  const eventId = req.params.id;
  const userId = req.user.id;
  const quantity = Math.min(Math.max(parseInt(req.body.quantity, 10) || 1, 1), 10);

  const event = await get(
    `SELECT id, title, city_name, venue_name, event_date, start_time,
            ticket_price, currency, capacity,
            (SELECT COUNT(*) FROM event_tickets t
              WHERE t.event_id = events.id AND t.status = 'confirmed') AS tickets_sold
     FROM events WHERE id = ?`,
    [eventId]
  );

  if (!event) {
    return res.status(404).json({ success: false, message: "Event not found" });
  }

  const seatsLeft = Math.max(0, (event.capacity || 0) - (event.tickets_sold || 0));
  if (event.capacity > 0 && seatsLeft < quantity) {
    return res.status(400).json({
      success: false,
      message: `Only ${seatsLeft} seat(s) left for this event`,
    });
  }

  const existing = await get(
    `SELECT id, ticket_code FROM event_tickets
     WHERE user_id = ? AND event_id = ? AND status = 'confirmed'`,
    [userId, eventId]
  );

  if (existing) {
    return res.status(400).json({
      success: false,
      message: "You already have a ticket for this event. Open My Tickets to view it.",
      ticket_code: existing.ticket_code,
    });
  }

  const unitPrice = event.ticket_price || 0;
  const totalPrice = +(unitPrice * quantity).toFixed(2);
  const ticketCode = ticketCodeFor(event.id);

  const result = await run(
    `INSERT INTO event_tickets
       (event_id, user_id, quantity, unit_price, total_price, currency,
        ticket_code, seat_number, status)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'confirmed')`,
    [
      event.id,
      userId,
      quantity,
      unitPrice,
      totalPrice,
      event.currency || "PKR",
      ticketCode,
      `GATE A · ROW ${Math.floor(Math.random() * 12) + 1}`,
    ]
  );

  await run(`UPDATE events SET attendees_count = attendees_count + ? WHERE id = ?`, [
    quantity,
    event.id,
  ]);

  await notify({
    userId,
    actorId: null,
    type: "system",
    message: `Your ticket for "${event.title}" is confirmed. Ticket code ${ticketCode}.`,
    referenceId: Number(event.id),
  });

  await cache.invalidate("events:");

  const ticket = await get(
    `SELECT
       t.id, t.ticket_code, t.quantity, t.unit_price, t.total_price, t.currency,
       t.seat_number, t.status, t.booked_at,
       e.id AS event_id, e.title, e.category, e.city_name AS city,
       e.venue_name AS venue, e.address, e.latitude, e.longitude,
       e.event_date, e.end_date, e.start_time, e.end_time, e.organizer
     FROM event_tickets t
     JOIN events e ON e.id = t.event_id
     WHERE t.id = ?`,
    [result.lastID]
  );

  res.status(201).json({
    success: true,
    message: "Booking confirmed (simulated - no real payment taken)",
    ticket: { ...ticket, days_until: daysUntil(ticket.event_date) },
  });
});

// ===========================================================================
// GET /api/events/tickets/mine
// ===========================================================================
export const getMyTickets = asyncHandler(async (req, res) => {
  const rows = await all(
    `SELECT
       t.id, t.ticket_code, t.quantity, t.unit_price, t.total_price, t.currency,
       t.seat_number, t.status, t.booked_at,
       e.id AS event_id, e.title, e.category, e.city_name AS city,
       e.venue_name AS venue, e.address, e.latitude, e.longitude,
       e.event_date, e.end_date, e.start_time, e.end_time, e.organizer
     FROM event_tickets t
     JOIN events e ON e.id = t.event_id
     WHERE t.user_id = ?
     ORDER BY e.event_date ASC`,
    [req.user.id]
  );

  res.json({
    success: true,
    count: rows.length,
    tickets: rows.map((row) => ({
      ...row,
      days_until: daysUntil(row.event_date),
      booked_ago: timeAgo(row.booked_at),
    })),
  });
});

// ===========================================================================
// GET /api/events/tickets/:ticketId
// ===========================================================================
export const getTicketById = asyncHandler(async (req, res) => {
  const ticket = await get(
    `SELECT
       t.id, t.ticket_code, t.quantity, t.unit_price, t.total_price, t.currency,
       t.seat_number, t.status, t.booked_at,
       e.id AS event_id, e.title, e.category, e.city_name AS city,
       e.venue_name AS venue, e.address, e.latitude, e.longitude,
       e.event_date, e.end_date, e.start_time, e.end_time, e.organizer
     FROM event_tickets t
     JOIN events e ON e.id = t.event_id
     WHERE t.id = ? AND t.user_id = ?`,
    [req.params.ticketId, req.user.id]
  );

  if (!ticket) {
    return res.status(404).json({ success: false, message: "Ticket not found" });
  }

  res.json({
    success: true,
    ticket: { ...ticket, days_until: daysUntil(ticket.event_date) },
  });
});

// ===========================================================================
// DELETE /api/events/tickets/:ticketId   -> cancel booking
// ===========================================================================
export const cancelTicket = asyncHandler(async (req, res) => {
  const ticket = await get(
    `SELECT id, event_id, quantity FROM event_tickets
     WHERE id = ? AND user_id = ?`,
    [req.params.ticketId, req.user.id]
  );

  if (!ticket) {
    return res.status(404).json({ success: false, message: "Ticket not found" });
  }

  await run(`UPDATE event_tickets SET status = 'cancelled' WHERE id = ?`, [ticket.id]);
  await run(
    `UPDATE events SET attendees_count = MAX(attendees_count - ?, 0) WHERE id = ?`,
    [ticket.quantity || 1, ticket.event_id]
  );

  await cache.invalidate("events:");
  res.json({ success: true, message: "Ticket cancelled" });
});

// ===========================================================================
// GET /api/events/overview -> small stat block for the Events tab header
// ===========================================================================
export const getEventsOverview = asyncHandler(async (req, res) => {
  const userId = req.user?.id ?? -1;

  const stats = await get(
    `SELECT
       (SELECT COUNT(*) FROM events WHERE event_date >= date('now'))            AS upcoming_events,
       (SELECT COUNT(DISTINCT city_name) FROM events WHERE event_date >= date('now')) AS cities,
       (SELECT COUNT(*) FROM events WHERE is_featured = 1 AND event_date >= date('now')) AS featured,
       (SELECT COUNT(*) FROM saved_events WHERE user_id = ?)                    AS my_saved,
       (SELECT COUNT(*) FROM event_tickets WHERE user_id = ? AND status = 'confirmed') AS my_tickets`,
    [userId, userId]
  );

  const nextEvent = await get(
    `${EVENT_SELECT} WHERE e.event_date >= date('now') ORDER BY e.event_date ASC LIMIT 1`
  );

  res.json({
    success: true,
    stats,
    nextEvent: nextEvent
      ? { ...nextEvent, days_until: daysUntil(nextEvent.event_date) }
      : null,
  });
});

export default {
  getEvents,
  getNearbyEvents,
  getMapPins,
  getEventCategories,
  getEventCities,
  getEventCalendar,
  getEventById,
  createEvent,
  updateEvent,
  deleteEvent,
  toggleSaveEvent,
  getMySavedEvents,
  bookTicket,
  getMyTickets,
  getTicketById,
  cancelTicket,
  getEventsOverview,
};
