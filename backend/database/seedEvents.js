/**
 * MEMBER 4 - Events & Maps
 * Demo data seeder: venues (with real coordinates across all cities) + upcoming events.
 */

import db from "./db.js";
import { initEventsSchema } from "./eventsSchema.js";

initEventsSchema();

function dayOffset(days) {
  const date = new Date();
  date.setDate(date.getDate() + days);
  return date.toISOString().slice(0, 10);
}

// ---------------------------------------------------------------------------
// Comprehensive Venues List with Exact Real-World Coordinates
// ---------------------------------------------------------------------------
const venues = [
  ["Expo Centre Karachi", "University Road, Gulshan-e-Iqbal", "Karachi", 24.908, 67.085, 12000],
  ["Arts Council of Pakistan", "M.R. Kayani Road, Saddar", "Karachi", 24.872, 67.029, 2500],
  ["Clifton Beach Fan Zone", "Sea View Road, Clifton", "Karachi", 24.813, 67.031, 5000],
  ["Packages Mall Expo Hall", "Walton Road", "Lahore", 31.474, 74.363, 5000],
  ["Alhamra Arts Council", "Mall Road, GOR-1", "Lahore", 31.560, 74.332, 1800],
  ["Emporium Mall Gaming Arena", "Abdul Haque Road, Johar Town", "Lahore", 31.467, 74.266, 3500],
  ["Pak-China Friendship Centre", "Garden Avenue, Shakarparian", "Islamabad", 33.697, 73.070, 6000],
  ["Jinnah Convention Centre", "Blue Area, Jinnah Avenue", "Islamabad", 33.715, 73.065, 4000],
  ["F-9 Park Amphitheatre", "Sector F-9", "Islamabad", 33.695, 73.018, 3000],
  ["Rawalpindi Sports Complex Hall", "Stadium Road", "Rawalpindi", 33.652, 73.078, 3000],
  ["Saddar Fan Plaza", "Bank Road, Saddar", "Rawalpindi", 33.595, 73.054, 1500],
  ["Serena Hall Faisalabad", "Club Road, Civil Lines", "Faisalabad", 31.418, 73.079, 1500],
  ["Clock Tower Anime Plaza", "City Center", "Faisalabad", 31.418, 73.079, 1200],
  ["Multan Arts Council", "Shah Rukn-e-Alam Colony", "Multan", 30.192, 71.470, 1200],
  ["Multan Garrison Club", "Cantt Area", "Multan", 30.180, 71.450, 2000],
  ["Nishtar Hall Peshawar", "Nishtar Road", "Peshawar", 34.008, 71.578, 1400],
  ["Peshawar University Arena", "Jamrud Road", "Peshawar", 33.998, 71.488, 2500],
  ["Serena Hotel Quetta", "Zarghoon Road", "Quetta", 30.190, 67.020, 900],
  ["Quetta Boy Scouts Hall", "Staff College Road", "Quetta", 30.200, 67.030, 1100],
  ["Tokyo Big Sight", "3-11-1 Ariake, Koto City", "Tokyo", 35.630, 139.794, 50000],
  ["Akihabara UDX Hall", "4-14-1 Sotokanda, Chiyoda City", "Tokyo", 35.698, 139.773, 8000],
  ["Dubai World Trade Centre", "Sheikh Zayed Road", "Dubai", 25.226, 55.286, 15000],
  ["ExCeL London", "Royal Victoria Dock", "London", 51.508, 0.028, 20000],
  ["Javits Center NYC", "429 11th Ave", "New York", 40.758, -74.002, 30000],
];

// ---------------------------------------------------------------------------
// Cloudinary Anime Image URLs
// ---------------------------------------------------------------------------
const ANIME_IMG = {
  one_piece: "https://images.unsplash.com/photo-1578632767115-351597cf2477?w=1000&auto=format&fit=crop",
  jjk: "https://images.unsplash.com/photo-1607604276583-eef5d076aa5f?w=1000&auto=format&fit=crop",
  demon_slayer: "https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=1000&auto=format&fit=crop",
  attack_on_titan: "https://images.unsplash.com/photo-1563089145-599997674d42?w=1000&auto=format&fit=crop",
  anime_expo: "https://images.unsplash.com/photo-1534447677768-be436bb09401?w=1000&auto=format&fit=crop",
};

const events = [
  {
    title: "One Piece Wano Finale Screening",
    description: "Big screen screening of the Wano arc finale with the anime club. Cosplay encouraged!",
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
    image_url: ANIME_IMG.one_piece,
  },
  {
    title: "Cosplay Cosmos Meetup",
    description: "Open-air cosplay photoshoot and costume contest with professional anime photographers.",
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
    image_url: ANIME_IMG.anime_expo,
  },
  {
    title: "Jujutsu Kaisen Trivia & Gojo Fan Night",
    description: "Team trivia covering the JJK manga, Domain Expansions and Cursed Technique mechanics.",
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
    image_url: ANIME_IMG.jjk,
  },
  {
    title: "Karachi Anime Expo 2026",
    description: "Three days of anime screenings, artist alley, cosplay championship, and voice actor panels.",
    category: "Fan Convention",
    city: "Karachi",
    venue: "Expo Centre Karachi",
    days: 10,
    duration: 3,
    start: "10:00",
    end: "21:00",
    price: 2500,
    organizer: "Fandom Verse Events",
    capacity: 12000,
    attendees: 8640,
    featured: 1,
    image_url: ANIME_IMG.anime_expo,
  },
  {
    title: "Demon Slayer Movie Premiere Night",
    description: "Exclusive IMAX screening of the new Demon Slayer arc with fan merch giveaways.",
    category: "Screening",
    city: "Karachi",
    venue: "Arts Council of Pakistan",
    days: 12,
    duration: 1,
    start: "19:30",
    end: "22:30",
    price: 1500,
    organizer: "Karachi Film Society",
    capacity: 2500,
    attendees: 1890,
    featured: 1,
    image_url: ANIME_IMG.demon_slayer,
  },
  {
    title: "VALORANT & Gaming Championship",
    description: "Open bracket esports tournament with shoutcasting and custom anime peripherals prize pool.",
    category: "Gaming Tournament",
    city: "Lahore",
    venue: "Emporium Mall Gaming Arena",
    days: 14,
    duration: 2,
    start: "11:00",
    end: "21:00",
    price: 1000,
    organizer: "Esports PK",
    capacity: 3500,
    attendees: 2100,
    image_url: ANIME_IMG.jjk,
  },
  {
    title: "Attack on Titan Final Arc Panel",
    description: "Deep dive analysis into the themes, lore, and production of Attack on Titan.",
    category: "Fan Meetup",
    city: "Rawalpindi",
    venue: "Rawalpindi Sports Complex Hall",
    days: 16,
    duration: 1,
    start: "16:00",
    end: "19:00",
    price: 500,
    organizer: "Scout Regiment Society",
    capacity: 1500,
    attendees: 940,
    image_url: ANIME_IMG.attack_on_titan,
  },
  {
    title: "Multan Manga & Cosplay Fair",
    description: "Regional manga bazaar, costume showcase, and Japanese food stalls.",
    category: "Cosplay Meetup",
    city: "Multan",
    venue: "Multan Arts Council",
    days: 20,
    duration: 1,
    start: "14:00",
    end: "20:00",
    price: 300,
    organizer: "Multan Otaku Circle",
    capacity: 1200,
    attendees: 720,
    image_url: ANIME_IMG.anime_expo,
  },
  {
    title: "Peshawar Anime & Gaming Con",
    description: "Peshawar's biggest anime gathering featuring fighting game brackets and cosplay walk.",
    category: "Fan Convention",
    city: "Peshawar",
    venue: "Nishtar Hall Peshawar",
    days: 24,
    duration: 2,
    start: "10:00",
    end: "20:00",
    price: 800,
    organizer: "KPK Gamers",
    capacity: 1400,
    attendees: 980,
    image_url: ANIME_IMG.jjk,
  },
  {
    title: "Quetta Anime Festival 2026",
    description: "Anime screenings, cosplay contest, and manga swap tables.",
    category: "Fan Convention",
    city: "Quetta",
    venue: "Serena Hotel Quetta",
    days: 28,
    duration: 1,
    start: "11:00",
    end: "19:00",
    price: 600,
    organizer: "Quetta Anime Club",
    capacity: 900,
    attendees: 510,
    image_url: ANIME_IMG.one_piece,
  },
  {
    title: "Tokyo Anime Comiket 2026",
    description: "World's largest fan convention with doujinshi creators and official studio booths.",
    category: "Fan Convention",
    city: "Tokyo",
    venue: "Tokyo Big Sight",
    days: 35,
    duration: 3,
    start: "09:00",
    end: "18:00",
    price: 3000,
    organizer: "Comic Market Committee",
    capacity: 50000,
    attendees: 42000,
    featured: 1,
    image_url: ANIME_IMG.anime_expo,
  },
  {
    title: "Dubai Comic Con & Gaming Fest",
    description: "International pop culture festival featuring celebrity voice actors and gaming arenas.",
    category: "Comic Con",
    city: "Dubai",
    venue: "Dubai World Trade Centre",
    days: 42,
    duration: 3,
    start: "10:00",
    end: "22:00",
    price: 5000,
    organizer: "Middle East Film Fest",
    capacity: 15000,
    attendees: 11200,
    featured: 1,
    image_url: ANIME_IMG.demon_slayer,
  },
];

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
  console.log("Seeding venues and multi-city events...");

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

  for (const event of events) {
    const existing = await getAsync(`SELECT id FROM events WHERE title = ?`, [
      event.title,
    ]);
    if (existing) {
      await runAsync(
        `UPDATE events SET
          city_name = ?, venue_name = ?, image_url = ?
         WHERE title = ?`,
        [event.city, event.venue, event.image_url, event.title]
      );
      continue;
    }

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
        event.image_url,
        link,
        event.price,
        event.organizer,
        event.capacity,
        event.attendees,
        event.featured || 0,
      ]
    );
    console.log(`  + event: ${event.title} (${event.city})`);
  }

  // Update coordinates from matching venue row
  await runAsync(`
    UPDATE events SET
      latitude  = (SELECT v.latitude  FROM venues v
                   WHERE v.name = events.venue_name AND v.city_name = events.city_name),
      longitude = (SELECT v.longitude FROM venues v
                   WHERE v.name = events.venue_name AND v.city_name = events.city_name),
      address   = (SELECT v.address   FROM venues v
                   WHERE v.name = events.venue_name AND v.city_name = events.city_name)
  `);

  console.log("✅ Venues and events seed complete.");
  db.close();
}

seed().catch((err) => {
  console.error("Seed error:", err);
  db.close();
});
