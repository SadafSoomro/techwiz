/**
 * MEMBER 4 - Events & Maps
 * Demo data seeder: venues (with real coordinates) + upcoming events so the
 * Events / Calendar / Map / Ticket screens are never empty.
 *
 * Run:  node database/seedEvents.js     (or)  npm run seed:events
 * Safe to run multiple times - existing rows are skipped.
 *
 * Event dates are generated relative to TODAY so the calendar always shows
 * upcoming events, no matter when the project is demoed.
 */

import db from "./db.js";
import { initEventsSchema } from "./eventsSchema.js";

initEventsSchema();

// ---------------------------------------------------------------------------
// helper: date offset from today -> "YYYY-MM-DD"
// ---------------------------------------------------------------------------
function dayOffset(days) {
  const date = new Date();
  date.setDate(date.getDate() + days);
  return date.toISOString().slice(0, 10);
}

// ---------------------------------------------------------------------------
// venues - name, address, city, lat, lng, capacity
// ---------------------------------------------------------------------------
const venues = [
  ["Expo Centre Karachi", "University Road, Gulshan-e-Iqbal", "Karachi", 24.908, 67.085, 12000],
  ["Arts Council of Pakistan", "M.R. Kayani Road, Saddar", "Karachi", 24.872, 67.029, 2500],
  ["Packages Mall Expo Hall", "Walton Road", "Lahore", 31.474, 74.363, 5000],
  ["Alhamra Arts Council", "Mall Road, GOR-1", "Lahore", 31.56, 74.332, 1800],
  ["Pak-China Friendship Centre", "Garden Avenue, Shakarparian", "Islamabad", 33.697, 73.07, 6000],
  ["Jinnah Convention Centre", "Blue Area, Jinnah Avenue", "Islamabad", 33.715, 73.065, 4000],
  ["Rawalpindi Sports Complex Hall", "Stadium Road", "Rawalpindi", 33.652, 73.078, 3000],
  ["Serena Hall Faisalabad", "Club Road, Civil Lines", "Faisalabad", 31.418, 73.079, 1500],
  ["Multan Arts Council", "Shah Rukn-e-Alam Colony", "Multan", 30.192, 71.47, 1200],
  ["Nishtar Hall Peshawar", "Nishtar Road", "Peshawar", 34.008, 71.578, 1400],
  ["Serena Hotel Quetta", "Zarghoon Road", "Quetta", 30.19, 67.02, 900],
];

// ---------------------------------------------------------------------------
// events
// days      -> start offset from today
// duration  -> number of days the event runs
// ---------------------------------------------------------------------------
const events = [
  {
    title: "One Piece Wano Finale Screening",
    description:
      "Big screen screening of the Wano arc finale with the Islamabad anime club. Cosplay is encouraged, and there is a fan theory panel right after the credits.",
    category: "Screening",
    city: "Islamabad",
    venue: "Pak-China Friendship Centre",
    days: 3,
    duration: 1,
    start: "18:00",
    end: "22:30",
    price: 1200,
    organizer: "Islamabad Anime Club",
    capacity: 600,
    attendees: 412,
    featured: 1,
  },
  {
    title: "Cosplay Cosmos Meetup",
    description:
      "Open-air cosplay photoshoot and costume contest. Photographers on site, prop repair desk, and a beginners corner for first-time cosplayers.",
    category: "Cosplay Meetup",
    city: "Lahore",
    venue: "Alhamra Arts Council",
    days: 5,
    duration: 1,
    start: "15:00",
    end: "20:00",
    price: 0,
    organizer: "Lahore Cosplay Guild",
    capacity: 800,
    attendees: 615,
    featured: 1,
  },
  {
    title: "Jujutsu Kaisen Trivia Night",
    description:
      "Team trivia covering the manga and the anime, including hidden details and cursed technique mechanics. Winning team takes home official merch.",
    category: "Fan Meetup",
    city: "Faisalabad",
    venue: "Serena Hall Faisalabad",
    days: 7,
    duration: 1,
    start: "19:00",
    end: "22:00",
    price: 0,
    organizer: "Cursed Energy Club",
    capacity: 300,
    attendees: 188,
  },
  {
    title: "K-Pop Night Live",
    description:
      "Live tribute stage, random dance play, and a lightstick sync section. Doors open an hour early for the fan merchandise bazaar.",
    category: "Concert",
    city: "Islamabad",
    venue: "Jinnah Convention Centre",
    days: 9,
    duration: 1,
    start: "17:00",
    end: "23:00",
    price: 3500,
    organizer: "Seoul Beats PK",
    capacity: 2500,
    attendees: 1975,
    featured: 1,
  },
  {
    title: "Karachi Anime Fest 2026",
    description:
      "Three days of anime screenings, artist alley, cosplay championship, gaming zone and guest panels with manga creators and voice actors.",
    category: "Fan Convention",
    city: "Karachi",
    venue: "Expo Centre Karachi",
    days: 12,
    duration: 3,
    start: "10:00",
    end: "21:00",
    price: 2500,
    organizer: "Fandom Verse Events",
    capacity: 12000,
    attendees: 8640,
    featured: 1,
  },
  {
    title: "AMV Editing Workshop",
    description:
      "Hands-on workshop on beat syncing, color grading and export settings. Bring a laptop with your editing software already installed.",
    category: "Workshop",
    city: "Karachi",
    venue: "Arts Council of Pakistan",
    days: 15,
    duration: 1,
    start: "11:00",
    end: "17:00",
    price: 1000,
    organizer: "Frame by Frame Collective",
    capacity: 120,
    attendees: 96,
  },
  {
    title: "VALORANT Community Cup",
    description:
      "Open bracket LAN tournament with a live shoutcaster desk. Bring your own peripherals, machines are provided by the venue.",
    category: "Gaming Tournament",
    city: "Karachi",
    venue: "Arts Council of Pakistan",
    days: 18,
    duration: 2,
    start: "12:00",
    end: "22:00",
    price: 1500,
    organizer: "PK Esports League",
    capacity: 400,
    attendees: 322,
  },
  {
    title: "Multan Fan Meetup",
    description:
      "Casual evening meetup for local fans. Trivia rounds, manga swap table and a screening of the community's top voted episode.",
    category: "Fan Meetup",
    city: "Multan",
    venue: "Multan Arts Council",
    days: 21,
    duration: 1,
    start: "16:00",
    end: "21:00",
    price: 0,
    organizer: "Multan Otaku Circle",
    capacity: 250,
    attendees: 140,
  },
  {
    title: "Indus Comic Con",
    description:
      "Comics, artists alley, collector halls and a retro gaming museum. Meet indie publishers and grab signed prints.",
    category: "Comic Con",
    city: "Lahore",
    venue: "Packages Mall Expo Hall",
    days: 25,
    duration: 3,
    start: "11:00",
    end: "22:00",
    price: 2000,
    organizer: "Indus Conventions",
    capacity: 5000,
    attendees: 3610,
    featured: 1,
  },
  {
    title: "Naruto Marathon Screening",
    description:
      "Selected arcs back to back on the big screen with ramen stalls and a shinobi quiz between blocks.",
    category: "Screening",
    city: "Peshawar",
    venue: "Nishtar Hall Peshawar",
    days: 28,
    duration: 1,
    start: "14:00",
    end: "23:00",
    price: 700,
    organizer: "Peshawar Anime Society",
    capacity: 500,
    attendees: 264,
  },
  {
    title: "Rawalpindi Gaming LAN Party",
    description:
      "Two days of LAN tournaments across fighting games, RTS and co-op shooters with open casual stations.",
    category: "Gaming Tournament",
    city: "Rawalpindi",
    venue: "Rawalpindi Sports Complex Hall",
    days: 31,
    duration: 2,
    start: "13:00",
    end: "23:00",
    price: 800,
    organizer: "Twin Cities Gamers",
    capacity: 600,
    attendees: 371,
  },
  {
    title: "Sci-Fi Cosplay Parade",
    description:
      "Street parade of sci-fi cosplayers followed by a costume judging round and a robotics showcase.",
    category: "Cosplay Meetup",
    city: "Islamabad",
    venue: "Pak-China Friendship Centre",
    days: 35,
    duration: 1,
    start: "16:00",
    end: "21:00",
    price: 500,
    organizer: "Galactic Guild",
    capacity: 900,
    attendees: 402,
  },
  {
    title: "Marvel Trivia Championship",
    description:
      "Season finale of the trivia league. Sixteen teams, four rounds and a live audience buzzer round.",
    category: "Fan Meetup",
    city: "Lahore",
    venue: "Alhamra Arts Council",
    days: 40,
    duration: 1,
    start: "18:00",
    end: "22:00",
    price: 600,
    organizer: "Multiverse Minds",
    capacity: 700,
    attendees: 521,
  },
  {
    title: "Genshin Impact Tournament",
    description:
      "Co-op speedrun brackets and a spiral abyss challenge stage with community casting.",
    category: "Gaming Tournament",
    city: "Karachi",
    venue: "Expo Centre Karachi",
    days: 45,
    duration: 2,
    start: "11:00",
    end: "21:00",
    price: 1800,
    organizer: "Teyvat Travellers PK",
    capacity: 1500,
    attendees: 903,
  },
  {
    title: "Winter Comic Bazaar",
    description:
      "Seasonal comics bazaar with graded back issues, indie zines and sketch commissions from local artists.",
    category: "Comic Con",
    city: "Islamabad",
    venue: "Jinnah Convention Centre",
    days: 52,
    duration: 2,
    start: "10:00",
    end: "20:00",
    price: 1500,
    organizer: "Indus Conventions",
    capacity: 3000,
    attendees: 1180,
  },
  {
    title: "Quetta Fan Convention",
    description:
      "The first multi-fandom convention in Quetta: screenings, cosplay contest, gaming corner and a local artists alley.",
    category: "Fan Convention",
    city: "Quetta",
    venue: "Serena Hotel Quetta",
    days: 60,
    duration: 2,
    start: "10:00",
    end: "20:00",
    price: 900,
    organizer: "Fandom Verse Events",
    capacity: 1200,
    attendees: 348,
  },
];

// ---------------------------------------------------------------------------
// banner artwork (generated by frontend/tool/generate_banner_art.py)
// ---------------------------------------------------------------------------
const BANNERS = {
  "Fan Convention": "assets/images/events/fan_convention.jpg",
  "Cosplay Meetup": "assets/images/events/cosplay_meetup.jpg",
  "Screening": "assets/images/events/screening.jpg",
  "Gaming Tournament": "assets/images/events/gaming_tournament.jpg",
  "Comic Con": "assets/images/events/comic_con.jpg",
  "Concert": "assets/images/events/concert.jpg",
  "Fan Meetup": "assets/images/events/fan_meetup.jpg",
  "Workshop": "assets/images/events/workshop.jpg",
};
const DEFAULT_BANNER = "assets/images/events/default.jpg";

// ---------------------------------------------------------------------------
function runAsync(sql, params = []) {
  return new Promise((resolve, reject) => {
    db.run(sql, params, function (err) {
      if (err) reject(err);
      else resolve(this);
    });
  });
}

function getAsync(sql, params = []) {
  return new Promise((resolve, reject) => {
    db.get(sql, params, (err, row) => {
      if (err) reject(err);
      else resolve(row);
    });
  });
}

async function seed() {
  // ------------------------------ venues ------------------------------
  for (const [name, address, city, lat, lng, capacity] of venues) {
    const existing = await getAsync(
      `SELECT id FROM venues WHERE name = ? AND city_name = ?`,
      [name, city]
    );
    if (!existing) {
      await runAsync(
        `INSERT INTO venues (name, address, city_name, latitude, longitude, capacity)
         VALUES (?, ?, ?, ?, ?, ?)`,
        [name, address, city, lat, lng, capacity]
      );
      console.log(`  + venue: ${name} (${city})`);
    }
  }

  // ------------------------------ events ------------------------------
  for (const event of events) {
    const existing = await getAsync(`SELECT id FROM events WHERE title = ?`, [
      event.title,
    ]);
    if (existing) continue;

    const link = `https://fandomverse.app/tickets/${event.title
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, "-")
      .replace(/(^-|-$)/g, "")}`;

    await runAsync(
      `INSERT INTO events
        (title, description, category, city_name, venue_name, address,
         latitude, longitude, event_date, end_date, start_time, end_time,
         image_url, ticket_link, ticket_price, currency, organizer, capacity,
         attendees_count, is_featured, status)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'PKR', ?, ?, ?, ?, 'upcoming')`,
      [
        event.title,
        event.description,
        event.category,
        event.city,
        event.venue,
        null,
        null,
        null,
        dayOffset(event.days),
        dayOffset(event.days + Math.max(0, event.duration - 1)),
        event.start,
        event.end,
        BANNERS[event.category] || DEFAULT_BANNER,
        link,
        event.price,
        event.organizer,
        event.capacity,
        event.attendees,
        event.featured || 0,
      ]
    );
    console.log(`  + event: ${event.title}`);
  }

  // banner artwork: keeps existing databases in sync too
  for (const [category, banner] of Object.entries(BANNERS)) {
    await runAsync(`UPDATE events SET image_url = ? WHERE category = ?`, [
      banner,
      category,
    ]);
  }
  await runAsync(`UPDATE events SET image_url = ? WHERE image_url IS NULL`, [
    DEFAULT_BANNER,
  ]);

  // copy coordinates + address from the matching venue row
  await runAsync(`
    UPDATE events SET
      latitude  = (SELECT v.latitude  FROM venues v
                   WHERE v.name = events.venue_name AND v.city_name = events.city_name),
      longitude = (SELECT v.longitude FROM venues v
                   WHERE v.name = events.venue_name AND v.city_name = events.city_name),
      address   = (SELECT v.address   FROM venues v
                   WHERE v.name = events.venue_name AND v.city_name = events.city_name)
    WHERE latitude IS NULL
  `);

  // ------------------ demo ticket + saved event for Emma ------------------
  const emma = await getAsync(`SELECT id FROM users WHERE email = ?`, [
    "emma@fandomverse.com",
  ]);

  if (emma) {
    const firstEvent = await getAsync(
      `SELECT id, title, ticket_price FROM events ORDER BY event_date ASC LIMIT 1`
    );

    if (firstEvent) {
      const existingTicket = await getAsync(
        `SELECT id FROM event_tickets WHERE user_id = ? AND event_id = ?`,
        [emma.id, firstEvent.id]
      );

      if (!existingTicket) {
        await runAsync(
          `INSERT INTO event_tickets
             (event_id, user_id, quantity, unit_price, total_price, currency,
              ticket_code, seat_number, status)
           VALUES (?, ?, 2, ?, ?, 'PKR', ?, 'GATE A · ROW 4', 'confirmed')`,
          [
            firstEvent.id,
            emma.id,
            firstEvent.ticket_price,
            firstEvent.ticket_price * 2,
            `FV-${String(firstEvent.id).padStart(4, "0")}-0001`,
          ]
        );

        await runAsync(
          `INSERT INTO notifications (user_id, actor_id, type, message, reference_id)
           VALUES (?, NULL, 'system', ?, ?)`,
          [
            emma.id,
            `Your ticket for "${firstEvent.title}" is confirmed. Show the ticket screen at the gate.`,
            firstEvent.id,
          ]
        );
        console.log(`  + ticket for Emma: ${firstEvent.title}`);
      }
    }

    const secondEvent = await getAsync(
      `SELECT id FROM events ORDER BY event_date ASC LIMIT 1 OFFSET 2`
    );

    if (secondEvent) {
      await runAsync(
        `INSERT OR IGNORE INTO saved_events (user_id, event_id) VALUES (?, ?)`,
        [emma.id, secondEvent.id]
      );
    }
  }

  console.log("\n✅ Events seed complete.");
  console.log("   Demo login : emma@fandomverse.com  /  Fandom@123\n");

  db.close();
}

seed().catch((error) => {
  console.error("Events seed failed:", error.message);
  db.close();
});
