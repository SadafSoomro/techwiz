# FANDOM VERSE — Member 2: Fandom Content

> **Module owner:** Member 2
> **Frontend:** Flutter (Dart) — Fandom Hub, Explore Fandoms, News List, News Details,
> Gallery, Video Player, Podcasts, Discover, Glossary, Offline library
> **Backend:** Node.js + Express
> **Database:** SQLite only (replaces Firestore Posts/Media)
> **Theme:** emerald / cyan accent (`lib/theme/content_theme.dart`)
> **SRS reference:** *"2. Fandom Exploration and Multimedia Hub"* —
> Beginner Fan Hub + Glossary, resources filtered by fandom, trending carousel,
> Deep Dive, offline bookmarking

---

## 1. What this module contains

| Area | Screens / Actions |
|---|---|
| **Fandom Hub / Explore Fandoms** | Hub header with totals, trending fandom rail, grid of every hub with cover artwork |
| **Fandom Hub (Anime, Gaming, …)** | Hub cover + stats (items / views / followers), sections for News, Gallery, Videos, Podcasts, Deep Dive and the beginner glossary |
| **News List** | Fandom filter chips, sort (Latest · Popular · Most liked · Oldest), pull to refresh, like + offline actions |
| **News Details** | Hero artwork, type/fandom chips, author + published-ago, paragraphs, like, save offline, share, related content |
| **Gallery** | Fandom-filtered collections, staggered tile grid, full-screen viewer with captions and swipe navigation |
| **Video Player** | Simulated player: play/pause, seek bar, ±10s skip, playback speed, offline save, like, description, related clips |
| **Podcasts** | "Latest Episodes" list with covers and durations, animated waveform player, seek/skip, episode metadata, offline save |
| **Discover** | Spotlight story, trending, latest, gallery collections, recently viewed, inline search and type filters |
| **Library (Recent / Offline)** | Recently viewed history + offline-saved content with an offline storage meter |
| **Glossary** | Fandom terminology cards (Canon, Headcanon, Shipping, OTP, Fanart, AMV, Speedrun, Bias, …) |

---

## 2. Backend — files added

```
backend/
├── database/
│   ├── contentSchema.js     # hubs, content items, media, likes, views, glossary
│   └── seedContent.js       # 7 hubs, 14 articles, 6 galleries (39 images), 6 videos,
│                            # 6 podcasts, 16 glossary terms, demo recent/offline history
├── Controllers/
│   └── contentcontroller.js # hub, news, gallery, video, podcast, discover, offline
├── Routes/
│   └── contentroute.js      # all /api/content routes
└── tests/
    └── content_api_test.js  # API smoke test -> tests/content_report.txt
```

`server.js` runs `initContentSchema()` on boot and mounts
`app.use("/api/content", contentRoutes)`.

Scripts: `npm run seed:content`, `npm run test:content`.

---

## 3. Database design (SQLite)

| Table | Purpose |
|---|---|
| `fandom_hubs` | One row per fandom (slug, tagline, cover artwork, icon, colour, follower count, trending flag) |
| `content_items` | Every media entry discriminated by `content_type`: `news`, `article`, `gallery`, `video`, `podcast`, `deep_dive` — title, summary, body, artwork, media URL, duration, author, source, tags, episode/season, view & like counters, featured flag |
| `content_media` | Child rows of a gallery (image URL + caption) |
| `content_likes` | One like per user per content item |
| `content_views` | **The "SQLite recent / offline content" store** — one row per user + item with `viewed_at` (recent history) and `is_offline` (saved for offline reading / viewing) plus a `progress` value |
| `glossary_terms` | Beginner Fan Hub glossary |

---

## 4. API reference (`/api/content`)

`optionalAuth` endpoints still return `is_liked` / `is_offline` when a JWT is sent.

| Method | Endpoint | Auth | Purpose |
|---|---|---|---|
| GET | `/hub` | optional | Explore Fandoms: all hubs, trending subset, totals (cached 120s) |
| GET | `/hub/:slug` | optional | One Fandom Hub with its news / galleries / videos / podcasts / deep dives + glossary |
| GET | `/glossary` | optional | Glossary terms (optionally filtered by fandom), grouped by category |
| GET | `/discover` | optional | Spotlight + trending + latest + gallery collections |
| GET | `/recent` | required | Recently viewed content + offline count |
| GET | `/offline` | required | Saved-for-offline content + storage estimate |
| GET | `/` | optional | Filtered list: `type`, `fandom`, `hub`, `q`, `sort`, `limit`, `offset` |
| GET | `/:id` | optional | Details + paragraphs + gallery media + related items (+ view counter) |
| POST | `/:id/view` | optional | Record a view / progress (also used to open offline content) |
| POST | `/:id/offline` | required | Toggle "save for offline" |
| POST | `/:id/like` | required | Toggle like |

---

## 5. Flutter files

```
frontend/lib/
├── theme/content_theme.dart          # emerald/cyan palette + type helpers
├── models/content_models.dart        # ContentItem, FandomHub, HubBundle, DiscoverBundle,
│                                     # RecentBundle, OfflineBundle, HubsBundle, ContentMedia,
│                                     # GlossaryTerm, ContentDetails
├── services/content_service.dart     # HTTP layer over /api/content
├── providers/content_provider.dart   # state + filters + like/offline toggles
├── widgets/content_widgets.dart      # ContentScaffold, ContentCard, ContentRowTile,
│                                     # VideoStillCard, PodcastTile, GalleryTile,
│                                     # FandomHubCard, TypeBadge, FandomChip, MetaItem,
│                                     # ContentLoadingList, EmptyContentState
└── screens/
    ├── discover_screen.dart          # also the "Explore" tab of the home shell
    ├── fandom_hub_screen.dart        # Explore Fandoms + HubContentScreen (incl. glossary)
    ├── news_list_screen.dart
    ├── news_details_screen.dart
    ├── gallery_screen.dart           # grid + GalleryViewerScreen
    ├── video_player_screen.dart
    ├── podcasts_screen.dart
    └── recent_content_screen.dart    # Recent / Offline library
```

`fandom_hub_screen.dart` also exports `openContentItem(context, item)`, the helper that
routes a tapped item to the correct screen (video → player, podcast → podcasts,
gallery → viewer, everything else → news details) using a fade + slide page transition.

---

## 6. Artwork

Every `image_url` in the database points at a bundled asset generated by
`frontend/tool/generate_banner_art.py` (Pillow only, no external downloads):

| Folder | Content | Size |
|---|---|---|
| `assets/images/fandoms/` | 7 fandom / hub covers + default | 1200×600 |
| `assets/images/content/news_*.jpg` | 8 news thumbnails | 900×600 |
| `assets/images/content/gallery_*.jpg` | 9 numbered gallery plates | 800×800 |
| `assets/images/content/video_*.jpg` | 6 letterboxed stills with a play mark | 960×540 |
| `assets/images/content/podcast_*.jpg` | 6 square podcast covers | 700×700 |
| `assets/images/avatars/` | 8 avatar presets (Member 1) | 420×420 |

Run: `py frontend/tool/generate_banner_art.py`

---

## 7. Animations added

- Staggered `FadeSlideIn` entries for every rail, grid and list.
- `PressScale` press feedback on cards, chips and buttons.
- Shared `AppImage` fade + scale-in when artwork resolves.
- Hero animation between the trending card and the hub cover.
- Animated waveform while a podcast "plays"; animated seek bar and skip feedback in the player.
- Gallery: staggered grid reveal and a full-screen viewer with swipe + fade transitions.
- Animated type/fandom filter pills, section headers and "empty" states.
- Shimmer placeholders while content loads.
- Custom fade + slide route transition when opening any content item.

---

## 8. How to run

### Backend

```bash
cd backend
npm install
npm run seed:content   # 32 content rows + gallery images + glossary terms
npm start              # http://localhost:5000
```

### Frontend

```bash
cd frontend
flutter pub get
flutter run
```

### Verify

```bash
cd backend
npm start              # in one terminal
npm run test:content   # in another -> prints a report + writes tests/content_report.txt
```

Last verified run: **20/20 checks passed** (see section 10).

---

## 9. Demo credentials

| Email | Password |
|---|---|
| `emma@fandomverse.com` | `Fandom@123` |
| `rahul@fandomverse.com` | `Fandom@123` |
| `aisha@fandomverse.com` | `Fandom@123` |
| `daniel@fandomverse.com` | `Fandom@123` |
| `mei@fandomverse.com` | `Fandom@123` |

---

## 10. Verification & manual test checklist

Automated: `flutter analyze` reports **no issues** for `frontend/`, and
`npm run test:content` passes **20/20** checks.

1. Log in and open the **Explore** tab → Discover shows the type rails
   (news, gallery, video, podcast) with the bundled artwork.
2. Open a **fandom hub** → cover image, trending chips, glossary and the
   sub-rails for every content type.
3. News List → the fandom filter pills switch the feed; open a story →
   News Details renders the body, tags, view count and like button.
4. Gallery → staggered grid → tap a plate → full-screen viewer with swipe.
5. Video Player → play/pause, seek bar, skip ±10s, like and offline toggle.
6. Podcasts → the waveform animates while "playing" and the seek bar follows.
7. Mark an item offline → it appears in the **Offline** library; Recent shows
   partially watched items with the saved progress.
8. Every `image_url` resolves to a bundled asset (see section 6) — no broken
   images or network placeholders during the demo.
