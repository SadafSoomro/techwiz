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
function buildWhere(query, { includePast = true } = {}) {
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
// Dynamic Nearby Events Generator around User Location
// ===========================================================================

/**
 * Automatically seeds nearby fan events around a user's located position (lat, lng)
 * if there are fewer than 5 events within 15km of those coordinates.
 */
async function ensureNearbyEvents(lat, lng, cityName = "", areaName = "") {
  if (Number.isNaN(lat) || Number.isNaN(lng) || lat === 0 || lng === 0) return;

  try {
    const existing = await all(
      `SELECT id, latitude, longitude FROM events WHERE latitude IS NOT NULL AND longitude IS NOT NULL`
    );

    const closeCount = existing.filter((e) => {
      if (e.latitude == null || e.longitude == null) return false;
      return haversineKm(lat, lng, e.latitude, e.longitude) <= 15;
    }).length;

    if (closeCount >= 5) {
      return; // Enough nearby events already exist
    }

    const city = cityName || "Nearby";
    const area = areaName || "Local Zone";
    const locationTag = areaName ? `${areaName}, ${city}` : city;

    const templates = [
      {
        title: `Cosplay & Anime Fan Meetup @ ${locationTag}`,
        description: `Gathering for local anime fans and cosplayers in ${locationTag}! Photoshoot, costume showcase, and fan networking.`,
        category: "Cosplay Meetup",
        venue: `${area} Fan Square`,
        latOffset: 0.0035,
        lngOffset: 0.0040,
        days: 2,
        start: "16:00",
        end: "20:00",
        price: 0,
        organizer: `${city} Cosplay Guild`,
        capacity: 400,
        attendees: 185,
        featured: 1,
        image_url: "assets/images/events/anime_expo_2025.jpg",
      },
      {
        title: `Otaku Hangout & Anime Trivia Night`,
        description: `Anime trivia, manga discussions, and fan art trading at ${area}. Bring your friends!`,
        category: "Fan Meetup",
        venue: `${area} Community Center`,
        latOffset: -0.0045,
        lngOffset: 0.0030,
        days: 4,
        start: "18:00",
        end: "21:30",
        price: 0,
        organizer: "FandomVerse Local Club",
        capacity: 250,
        attendees: 120,
        featured: 0,
        image_url: "assets/images/content/luffy_lore.jpg",
      },
      {
        title: `Demon Slayer & JJK Fan Screening`,
        description: `Big-screen anime movie screening with fan commentary, giveaways, and pop-up merch stall.`,
        category: "Screening",
        venue: `${locationTag} Cinema Arena`,
        latOffset: 0.0060,
        lngOffset: -0.0050,
        days: 6,
        start: "19:00",
        end: "22:00",
        price: 800,
        organizer: "Anime Screenings Co.",
        capacity: 500,
        attendees: 310,
        featured: 1,
        image_url: "assets/images/content/demon_slayer.jpg",
      },
      {
        title: `VALORANT & TEKKEN 8 Local Clash`,
        description: `Open esports tournament for competitive gamers. Custom trophies and gaming peripherals prize pool!`,
        category: "Gaming Tournament",
        venue: `${area} Gaming Hub`,
        latOffset: -0.0055,
        lngOffset: -0.0065,
        days: 8,
        start: "14:00",
        end: "21:00",
        price: 500,
        organizer: "Esports Alliance",
        capacity: 350,
        attendees: 240,
        featured: 1,
        image_url: "assets/images/content/gojo_jjk.jpg",
      },
      {
        title: `${city} Mini Fan Convention & Artist Alley`,
        description: `Full-day fandom convention featuring artist stalls, voice actor Q&A, and cosplay contest!`,
        category: "Fan Convention",
        venue: `${city} Central Convention Hall`,
        latOffset: 0.0110,
        lngOffset: 0.0090,
        days: 12,
        start: "11:00",
        end: "20:00",
        price: 1200,
        organizer: "FandomVerse Events",
        capacity: 2000,
        attendees: 1150,
        featured: 1,
        image_url: "assets/images/events/fan_convention.jpg",
      },
      {
        title: `One Piece & Shonen Manga Discussion League`,
        description: `Shonen manga theory breakdown, chapter review, and manga trading session.`,
        category: "Fan Meetup",
        venue: `${area} Open Park`,
        latOffset: -0.0085,
        lngOffset: 0.0110,
        days: 14,
        start: "17:00",
        end: "19:30",
        price: 0,
        organizer: "Grand Line Fan Club",
        capacity: 200,
        attendees: 95,
        featured: 0,
        image_url: "assets/images/content/luffy_lore.jpg",
      },
      {
        title: `Cosplay Crafting & Prop Building Workshop`,
        description: `Hands-on workshop teaching EVA foam sculpting, painting, and wig styling techniques for cosplayers.`,
        category: "Workshop",
        venue: `${area} Creative Studio`,
        latOffset: -0.0120,
        lngOffset: -0.0130,
        days: 16,
        start: "13:00",
        end: "17:00",
        price: 1000,
        organizer: "Cosplay Crafters Guild",
        capacity: 150,
        attendees: 80,
        featured: 0,
        image_url: "assets/images/events/anime_expo_2025.jpg",
      },
    ];

    for (const t of templates) {
      const eLat = +(lat + t.latOffset).toFixed(6);
      const eLng = +(lng + t.lngOffset).toFixed(6);
      const eDate = dayOffset(t.days);

      await run(
        `INSERT INTO events (
          title, description, category, city_name, venue_name, address,
          latitude, longitude, event_date, start_time, end_time,
          ticket_price, currency, organizer, capacity, attendees_count,
          is_featured, image_url
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [
          t.title,
          t.description,
          t.category,
          city,
          t.venue,
          `${t.venue}, ${locationTag}`,
          eLat,
          eLng,
          eDate,
          t.start,
          t.end,
          t.price,
          "PKR",
          t.organizer,
          t.capacity,
          t.attendees,
          t.featured,
          t.image_url,
        ]
      );
    }
  } catch (err) {
    console.error("Error auto-seeding nearby events:", err);
  }
}

// ===========================================================================
// GET /api/events/nearby?lat=&lng=&radius=
// GPS style discovery - the SRS "Map and GPS Integration" requirement.
// ===========================================================================
export const getNearbyEvents = asyncHandler(async (req, res) => {
  const lat = parseFloat(req.query.lat);
  const lng = parseFloat(req.query.lng);
  const radius = parseFloat(req.query.radius) || 20000; // km - default to worldwide search sorted by distance

  if (Number.isNaN(lat) || Number.isNaN(lng)) {
    return res.status(400).json({
      success: false,
      message: "lat and lng query parameters are required",
    });
  }

  await ensureNearbyEvents(lat, lng, req.query.city, req.query.area);

  const { sql, params } = buildWhere(req.query);
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
    .sort((a, b) => (a.distance_km ?? 1e9) - (b.distance_km ?? 1e9));

  const payload = {
    origin: { latitude: lat, longitude: lng },
    radius_km: radius,
    count: withDistance.length,
    events: withDistance,
  };

  res.json({ success: true, ...payload, cached: false });
});

// ===========================================================================
// GET /api/events/map  -> light payload for map pins
// ===========================================================================
export const getMapPins = asyncHandler(async (req, res) => {
  const lat = parseFloat(req.query.lat);
  const lng = parseFloat(req.query.lng);
  if (!Number.isNaN(lat) && !Number.isNaN(lng)) {
    await ensureNearbyEvents(lat, lng, req.query.city, req.query.area);
  }

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
// Dynamic Calendar Events Generator per Month
// ===========================================================================

/**
 * Ensures that every month has calendar events for all supported cities and categories.
 */
async function ensureCalendarEventsForMonth(month) {
  if (!/^\d{4}-\d{2}$/.test(month)) return;

  try {
    const existing = await all(
      `SELECT COUNT(*) AS c FROM events WHERE event_date LIKE ?`,
      [`${month}%`]
    );

    if (existing[0]?.c >= 10) return; // Month already has sufficient events

    const cities = [
      "Karachi",
      "Lahore",
      "Islamabad",
      "Rawalpindi",
      "Faisalabad",
      "Multan",
      "Peshawar",
      "Quetta",
    ];

    const cityCoords = {
      Karachi: [24.8607, 67.0011],
      Lahore: [31.5204, 74.3587],
      Islamabad: [33.6844, 73.0479],
      Rawalpindi: [33.5651, 73.0169],
      Faisalabad: [31.4180, 73.0790],
      Multan: [30.1575, 71.5249],
      Peshawar: [34.0151, 71.5249],
      Quetta: [30.1798, 66.9750],
    };

    const templates = [
      {
        title: "Anime & Gaming Grand Expo",
        category: "Fan Convention",
        venue: "Expo Center",
        days: ["02", "15", "28"],
        start: "10:00",
        end: "20:00",
        price: 1500,
        organizer: "FandomVerse Events",
        image: "assets/images/events/anime_expo_2025.jpg",
      },
      {
        title: "Cosplay Cosmos & Costume Meetup",
        category: "Cosplay Meetup",
        venue: "Arts & Culture Center",
        days: ["05", "18", "25"],
        start: "15:00",
        end: "19:30",
        price: 0,
        organizer: "Local Cosplay Guild",
        image: "assets/images/events/fan_convention.jpg",
      },
      {
        title: "One Piece & Shonen Fan Gathering",
        category: "Fan Meetup",
        venue: "Community Fan Hub",
        days: ["08", "20"],
        start: "17:00",
        end: "20:30",
        price: 0,
        organizer: "Grand Line Club",
        image: "assets/images/content/luffy_lore.jpg",
      },
      {
        title: "Demon Slayer Movie Premiere & Screening",
        category: "Screening",
        venue: "IMAX Grand Cinema",
        days: ["10", "22", "29"],
        start: "19:00",
        end: "22:00",
        price: 1000,
        organizer: "Anime Screenings Co.",
        image: "assets/images/content/demon_slayer.jpg",
      },
      {
        title: "VALORANT & TEKKEN 8 Championship",
        category: "Gaming Tournament",
        venue: "Nexus Esports Arena",
        days: ["12", "24"],
        start: "13:00",
        end: "21:00",
        price: 500,
        organizer: "Esports Alliance",
        image: "assets/images/content/gojo_jjk.jpg",
      },
      {
        title: "Cosplay Prop & Wig Styling Workshop",
        category: "Workshop",
        venue: "Creative Arts Studio",
        days: ["14", "26"],
        start: "14:00",
        end: "18:00",
        price: 800,
        organizer: "Cosplay Crafters Guild",
        image: "assets/images/events/anime_expo_2025.jpg",
      },
    ];

    for (const city of cities) {
      const coords = cityCoords[city] || [24.8607, 67.0011];
      for (const t of templates) {
        for (const d of t.days) {
          const eventDate = `${month}-${d}`;
          const lat = +(coords[0] + (Math.random() - 0.5) * 0.03).toFixed(6);
          const lng = +(coords[1] + (Math.random() - 0.5) * 0.03).toFixed(6);

          await run(
            `INSERT INTO events (
              title, description, category, city_name, venue_name, address,
              latitude, longitude, event_date, start_time, end_time,
              ticket_price, currency, organizer, capacity, attendees_count,
              is_featured, image_url
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
            [
              `${city} ${t.title}`,
              `Exciting ${t.category} event in ${city}! Join fellow fans for anime screenings, cosplay contests, and gaming.`,
              t.category,
              city,
              `${t.venue} ${city}`,
              `${t.venue}, ${city}`,
              lat,
              lng,
              eventDate,
              t.start,
              t.end,
              t.price,
              "PKR",
              t.organizer,
              500,
              230,
              1,
              t.image,
            ]
          );
        }
      }
    }
  } catch (err) {
    console.error("Error auto-seeding calendar events:", err);
  }
}

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

  await ensureCalendarEventsForMonth(month);

  const cacheKey = `events:calendar:${month}:${req.query.city || "all"}:${req.query.category || "all"}`;
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
// POST /api/events/:id/tickets   -> simulated booking (starts as 'pending')
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
    `SELECT id, ticket_code, status FROM event_tickets
     WHERE user_id = ? AND event_id = ? AND status IN ('confirmed', 'pending')`,
    [userId, eventId]
  );

  if (existing) {
    return res.status(400).json({
      success: false,
      message: `You already have a ticket (${existing.status}) for this event. Open My Tickets to view or confirm it.`,
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
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'pending')`,
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

  await notify({
    userId,
    actorId: null,
    type: "system",
    message: `Your ticket for "${event.title}" is reserved (On Pending). Please confirm your booking to activate pass. Code: ${ticketCode}.`,
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
    message: "Ticket reserved (On Pending). Please confirm your booking to activate.",
    ticket: { ...ticket, days_until: daysUntil(ticket.event_date) },
  });
});

// ===========================================================================
// POST /api/events/tickets/:ticketId/confirm  -> confirm ticket pass
// ===========================================================================
export const confirmTicket = asyncHandler(async (req, res) => {
  const ticketId = req.params.ticketId;
  const userId = req.user.id;

  const ticket = await get(
    `SELECT t.id, t.event_id, t.quantity, t.status, e.title
       FROM event_tickets t
       JOIN events e ON e.id = t.event_id
      WHERE t.id = ? AND t.user_id = ?`,
    [ticketId, userId]
  );

  if (!ticket) {
    return res.status(404).json({ success: false, message: "Ticket not found" });
  }

  if (ticket.status === "confirmed") {
    return res.json({ success: true, message: "Ticket is already confirmed" });
  }

  await run(`UPDATE event_tickets SET status = 'confirmed' WHERE id = ?`, [ticket.id]);
  await run(`UPDATE events SET attendees_count = attendees_count + ? WHERE id = ?`, [
    ticket.quantity || 1,
    ticket.event_id,
  ]);

  await notify({
    userId,
    actorId: null,
    type: "system",
    message: `Your ticket for "${ticket.title}" has been confirmed!`,
    referenceId: Number(ticket.event_id),
  });

  await cache.invalidate("events:");

  const updated = await get(
    `SELECT
       t.id, t.ticket_code, t.quantity, t.unit_price, t.total_price, t.currency,
       t.seat_number, t.status, t.booked_at,
       e.id AS event_id, e.title, e.category, e.city_name AS city,
       e.venue_name AS venue, e.address, e.latitude, e.longitude,
       e.event_date, e.end_date, e.start_time, e.end_time, e.organizer
     FROM event_tickets t
     JOIN events e ON e.id = t.event_id
     WHERE t.id = ?`,
    [ticket.id]
  );

  res.json({
    success: true,
    message: "Ticket confirmed successfully!",
    ticket: { ...updated, days_until: daysUntil(updated.event_date) },
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
  confirmTicket,
  getMyTickets,
  getTicketById,
  cancelTicket,
  getEventsOverview,
};
