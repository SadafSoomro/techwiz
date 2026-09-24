# FANDOM VERSE — Member 4: Events & Maps

> **Module owner:** Member 4
> **Frontend:** Flutter (Dart)
> **Backend:** Node.js + Express
> **Database / Cache:** SQLite
> **Theme:** orange / red accent on the shared dark app theme
> **SRS reference:** *"3. Location-Aware Event Discovery and Calendar"* —
> Map + GPS discovery and an event calendar filterable by city, with ticket links.

---

## 1. What this module contains

| Area | Screens / Actions |
|---|---|
| **Events** | Nearby / upcoming event list, next-event hero card, city filter, category filter, sort (Date · Nearest · Popular · Price ↑↓), free-only filter, keyword search, save ("Interested") |
| **Event Categories** | Grid of all 8 fandom event categories + a filtered event list per category |
| **Event Details** | Banner, date / time / venue / organizer cards, description, ticket availability bar, "Open map view", more events in the same city, **Get Ticket** |
| **Map** | Stylised map with a pin per event, city + category filters, current-location marker, tap-a-pin detail card, nearby carousel |
| **Event Details (Map View)** | Same map screen focused on one event (`focusEventId`) |
| **Calendar** | Month grid with event dots + counts, previous / next month, "Today", selected-day event list, full month list |
| **Event Ticket** | My Tickets list, ticket detail with perforated e-ticket design, generated QR-style code, seat, total paid, cancel booking |
| **Interested Events** | Saved events list |

---

## 2. Backend — files added

```
backend/
├── database/
│   ├── eventsSchema.js        # creates all Events & Maps tables + categories
│   └── seedEvents.js          # 11 venues + 16 upcoming events + demo ticket
├── Controllers/
│   └── eventcontroller.js     # events, nearby (Haversine), calendar, map pins, tickets
├── Routes/
│   └── eventroute.js          # all /api/events routes
└── tests/
    └── events_api_test.js     # API smoke test -> writes tests/events_report.txt
```

`server.js` now also runs `initEventsSchema()` and mounts
`app.use("/api/events", eventRoutes)`.

The SQL script `backend/database/fandom_verse_schema.sql` was extended with
sections **12–17** (categories, venues, events, tickets, saved events, reminders).

---

## 3. Database design (SQLite)

| Table | Purpose |
|---|---|
| `event_categories` | Fan Convention, Cosplay Meetup, Screening, Gaming Tournament, Comic Con, Concert, Fan Meetup, Workshop |
| `venues` | Venue name, address, city, **latitude / longitude**, capacity |
| `events` | SRS minimum *Event_Id, Title, City_Name, Event_Date, Ticket_Link* + description, category, venue, coordinates, times, price, organizer, capacity, attendees, featured flag |
| `event_tickets` | Simulated bookings — quantity, unit/total price, unique ticket code, seat, status |
| `saved_events` | "Interested" events |
| `event_reminders` | Reminder date per user / event |

Indexes exist on `event_date`, `city_name`, `category`, `(latitude, longitude)`.

**Cache:** the same `response_cache` table used by Member 3 acts as the Redis
replacement — `nearby`, `categories`, `cities` and `calendar` responses are
cached with a short TTL and invalidated on any write.

**Distance:** `haversineKm()` in `eventcontroller.js` computes the great-circle
distance, so "nearest event" and the `radius` filter work without PostGIS.

---

## 4. REST API

Base path: `/api/events`

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| GET | `/` | optional | List events. Query: `city`, `category`, `q`, `from`, `to`, `sort`, `lat`, `lng`, `free`, `featured`, `limit`, `offset` |
| GET | `/nearby?lat=&lng=&radius=` | optional | Events within `radius` km, sorted by distance |
| GET | `/map` | optional | Light pin payload (id, title, category, coords, date, price) |
| GET | `/overview` | optional | Counters + the next upcoming event |
| GET | `/categories` | optional | Categories with upcoming event counts |
| GET | `/cities` | optional | Cities with counts + average coordinates |
| GET | `/calendar?month=YYYY-MM` | optional | Events grouped per day for the month |
| GET | `/saved/mine` | required | My "Interested" events |
| GET | `/tickets/mine` | required | My bookings |
| GET | `/tickets/:ticketId` | required | Single ticket |
| DELETE | `/tickets/:ticketId` | required | Cancel a booking |
| POST | `/` | required | Create an event |
| GET | `/:id` | optional | Event details + venue + my ticket + nearby events |
| PUT | `/:id` | required | Update an event |
| DELETE | `/:id` | required | Delete an event |
| POST | `/:id/save` | required | Toggle "Interested" |
| POST | `/:id/tickets` | required | Book ticket(s) — body `{ quantity }` |

`sort` accepts `date` (default), `newest`, `popular`, `price_low`, `price_high`, `distance`.
Sort clauses are whitelisted, so they cannot be injected.

---

## 5. Frontend — files added

```
frontend/lib/
├── theme/
│   └── event_theme.dart          # orange/red palette, card style, date/time/price helpers
├── models/
│   ├── json_utils.dart           # safe JSON parsing helpers
│   └── event_models.dart         # EventItem, EventCategory, EventCity, MapPin,
│                                 # EventTicket, CalendarDay, EventsStats
├── services/
│   └── event_service.dart        # HTTP layer (JWT attached automatically)
├── providers/
│   └── event_provider.dart       # all Events state + simulated location
├── widgets/
│   ├── event_scaffold.dart       # gradient scaffold with orange glow
│   ├── event_widgets.dart        # chips, section title, stat tile, empty state, date badge
│   ├── event_card.dart           # event card (banner, date badge, price, capacity bar, save)
│   ├── event_banner_image.dart   # asset / network / gradient banner renderer
│   ├── event_calendar.dart       # month grid with event dots
│   └── event_map_view.dart       # CustomPainter cartography + projected pins
└── screens/
    ├── events_screen.dart
    ├── event_categories_screen.dart   # + CategoryEventsScreen
    ├── event_details_screen.dart
    ├── event_map_screen.dart
    ├── event_calendar_screen.dart
    ├── event_ticket_screen.dart
    └── saved_events_screen.dart
```

### About the map
The Map screens do **not** need a Google Maps API key. `EventMapView` draws its
own cartography with a `CustomPainter` (blocks, roads, water, parks, grid,
compass, scale bar) and projects the real event `latitude`/`longitude` values
onto the canvas, so every pin is placed from actual data. This keeps the app
fully offline-capable and demo-safe.

### About the artwork
Every event has a **real bundled banner image** — no external image host is
needed. They are generated with Pillow by `frontend/tool/generate_banner_art.py`:

```
frontend/assets/images/events/
├── fan_convention.jpg      ├── comic_con.jpg
├── cosplay_meetup.jpg      ├── concert.jpg
├── screening.jpg           ├── fan_meetup.jpg
├── gaming_tournament.jpg   ├── workshop.jpg
└── default.jpg
```

Each event row stores its banner in `events.image_url`
(e.g. `assets/images/events/concert.jpg`). `EventBannerImage`
(`widgets/event_banner_image.dart`) resolves it at runtime:

| `image_url` value | Rendering |
|---|---|
| `assets/...` | bundled artwork (`Image.asset`) |
| `http(s)://...` | remote image with a placeholder while loading |
| empty / broken | category coloured gradient + category icon |

Regenerate the artwork at any time with:

```bash
py frontend/tool/generate_banner_art.py
```

(This same script also produces the Member 3 community fandom banners.)

### About location / GPS
`EventProvider` ships the coordinates of the 8 supported cities. "Use my
current location" snaps to the nearest of those cities and distances are then
computed by the backend. This satisfies the SRS "filterable by city" and
"nearby events" requirements without needing a runtime GPS permission —
`useDeviceLocation(lat:, lng:)` already accepts real coordinates, so a GPS
plugin can be dropped in later.

### Wired into the existing app
- `main.dart` → registers `EventProvider` in `MultiProvider`
- `home_screen.dart`
  - **Events** bottom-nav tab → real `EventsScreen`
  - New **Events Near You** section on the dashboard: next-event card plus
    Map · Calendar · Categories · Interested tiles

---

## 6. How to run

```bash
cd backend
npm install
npm run seed:events      # creates the events tables + demo data
npm start                # http://localhost:5000
```

`backend/.env` needs at least `PORT=5000` and `JWT_SECRET=...`.

```bash
cd frontend
flutter pub get
flutter run
```

Verify the API:

```bash
npm start              # terminal 1
npm run test:events    # terminal 2 -> 26 checks + tests/events_report.txt
```

> **Note:** `npm run seed:all` runs both the community and the events seeder.

> **Port tip (Windows):** if you ever started the server more than once, an old
> `node.exe` can keep answering on port 5000. Run `taskkill /F /IM node.exe`
> and start the server again.

---

## 7. Demo credentials

| Email | Password |
|---|---|
| `emma@fandomverse.com` | `Fandom@123` |

The seeder already gives Emma **1 booked ticket** and **1 interested event**, so
the Ticket and Interested screens have data on first launch.

---

## 8. Manual test checklist

1. Log in as `emma@fandomverse.com` / `Fandom@123`.
2. Bottom tab **Events** → the next-event hero, quick actions and the event list load.
3. Filter by **City** (e.g. Karachi) and by **Category** (e.g. Cosplay Meetup).
4. Sort by **Nearest** → distances appear on the cards; change **Location** to Lahore.
5. Tap **Free only** → only free-entry events remain.
6. Tap **Categories** → open one, e.g. *Gaming Tournament*.
7. Open an event → **Get Ticket** → choose quantity → Confirm →
   the e-ticket with its QR-style code is shown.
8. **Tickets** quick action → *My Tickets* → open a booking → *Cancel this ticket*.
9. Open an event → **Open map view** → pin focused, tap other pins, tap a pin → detail card.
10. **Calendar** → move to the next month, tap a highlighted day → that day's events.
11. Tap the heart on any event → it appears under **Interested**, and a
    notification is created (visible in Member 3's Notifications screen).
