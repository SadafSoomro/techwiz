# FANDOM VERSE — Member 3: Search & Community

> **Module owner:** Member 3
> **Frontend:** Flutter (Dart)
> **Backend:** Node.js + Express
> **Database / Cache:** SQLite
> **Replaces:** the SRS listed *PostgreSQL + Redis* for this module — both are
> replaced by a single SQLite database (relational tables + a TTL cache table).

---

## 1. What this module contains

| Area | Screens / Actions |
|---|---|
| **Search** | Search bar, live suggestions, recent searches, content-type filter (**Users / Posts / Fandoms**), fandom filter chips, sort by **Popular / Newest / Top / Trending** |
| **Search Results** | Grouped results with counts, per-type switching, post/user/fandom cards |
| **Trending** | Trending hashtags (`#Anime`, `#Gaming`, `#Movies`, `#Comics`, `#Music`, `#Sports`, `#SciFi`), top results tabs: **Users / Posts / Fandoms / Deep Dive** |
| **User Profile** | Avatar, bio, followers / following / posts / likes, fandom tags, follow-unfollow, user's posts |
| **Discussions (Deep Dive)** | Discussion list, sort by Popular / Newest / Top / Trending, fandom filter, keyword search |
| **Create Post** | Post *or* Deep Dive, title, content, fandom picker, hashtags, depth rating |
| **Post Details** | Full post, like, bookmark, comments list + add comment, delete own post |
| **Bookmarks** | Saved Posts list + grid view, clear all, swipe-free quick access from the Home tab |
| **Notifications** | New follower / like / comment / bookmark, all & unread filters, mark read, mark all read, swipe to delete, unread badge on the Home bell |

---

## 2. Backend — files added

```
backend/
├── config/
│   └── loadEnv.js                  # loads backend/.env no matter where node is started
├── database/
│   ├── communitySchema.js          # creates all Search & Community tables + seed fandoms
│   ├── cache.js                    # SQLite based replacement for Redis (TTL cache)
│   ├── dbhelpers.js                # promise wrappers (all / get / run) + asyncHandler
│   ├── seedCommunity.js            # demo data seeder
│   └── fandom_verse_schema.sql     # full SQL script (SRS deliverable: DB design)
├── middleware/
│   └── authmiddleware.js           # requireAuth / optionalAuth (JWT)
├── utils/
│   └── notify.js                   # creates notification rows
├── Controllers/
│   ├── searchcontroller.js         # search, filters, trending, suggestions, history
│   ├── postcontroller.js           # feed, discussions, like, comments
│   └── communitycontroller.js      # profile, follow, bookmarks, notifications, overview
├── Routes/
│   ├── searchroute.js
│   ├── postroute.js
│   └── communityroute.js
└── tests/
    └── community_api_test.js       # API smoke test (writes tests/report.txt)
```

`server.js` now loads the env first, initialises the community schema and mounts:

```js
app.use("/api/search",    searchRoutes);
app.use("/api/posts",     postRoutes);
app.use("/api/community", communityRoutes);
```

---

## 3. Database design (SQLite)

| Table | Purpose |
|---|---|
| `fandom_categories` | Anime, Gaming, Movies & TV, Comics, Music, Sports, Sci-Fi |
| `posts` | Community posts **and** Deep Dive discussions (`post_type = 'post' \| 'deep_dive'`) |
| `comments` | Comments on a post |
| `post_likes` | One row per user per post (unique constraint) |
| `bookmarks` | Saved posts |
| `follows` | follower_id → following_id |
| `notifications` | follow / like / comment / bookmark / system |
| `user_fandoms` | A user's selected fandom interests |
| `search_history` | Recent searches |
| `response_cache` | **Redis replacement** — `cache_key`, `payload`, `expires_at` |

Extra columns added to the shared `users` table: `bio`, `avatar`,
`selected_fandoms`, `followers_count`, `following_count`, `created_at`.

Full DDL is in `backend/database/fandom_verse_schema.sql`.

---

## 4. REST API

### Search — `/api/search`

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| GET | `/` | optional | Search. Query: `q`, `type=all\|users\|posts\|fandoms`, `fandom`, `sort`, `limit`, `offset` |
| GET | `/filters` | optional | Content types, sort options, fandom chips |
| GET | `/trending` | optional | Hashtags + top users / posts / fandoms / deep dives |
| GET | `/suggestions?q=` | optional | Live autocomplete + recent searches |
| GET | `/history` | required | My recent searches |
| DELETE | `/history` | required | Clear my search history |

### Posts / Discussions — `/api/posts`

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| GET | `/` | optional | Feed. Query: `type`, `fandom`, `sort`, `q`, `user_id`, `limit`, `offset` |
| GET | `/discussions` | optional | Deep Dive discussions only |
| GET | `/:id` | optional | Post details + comments (increments views) |
| POST | `/` | required | Create post / Deep Dive |
| PUT | `/:id` | required | Update own post |
| DELETE | `/:id` | required | Delete own post (cascades comments/likes/bookmarks) |
| POST | `/:id/like` | required | Toggle like |
| GET | `/:id/comments` | optional | List comments |
| POST | `/:id/comments` | required | Add comment |
| DELETE | `/comments/:commentId` | required | Delete comment (author or post owner) |

### Community — `/api/community`

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| GET | `/overview` | required | Counters + trending fandoms for the dashboard |
| PUT | `/profile` | required | Update own bio / avatar / fandoms |
| GET | `/bookmarks` | required | Saved posts |
| POST | `/bookmarks/:postId` | required | Toggle bookmark |
| DELETE | `/bookmarks` | required | Clear all bookmarks |
| GET | `/notifications?filter=all\|unread` | required | Notification list + unread count |
| POST | `/notifications/:id/read` | required | Mark one as read |
| POST | `/notifications/read-all` | required | Mark all as read |
| DELETE | `/notifications/:id` | required | Delete a notification |
| GET | `/users/:id/profile` | optional | Public profile + stats + posts |
| GET | `/users/:id/followers` | optional | Followers list |
| GET | `/users/:id/following` | optional | Following list |
| POST | `/users/:id/follow` | required | Toggle follow |

Sorting modes are whitelisted in the controllers (no SQL injection):
`popular`, `newest`, `top`, `trending`, `oldest`.

---

## 5. Frontend — files added

```
frontend/lib/
├── models/
│   └── community_models.dart        # CommunityPost, CommunityUser, PostComment,
│                                    # AppNotification, FandomCategory, TrendingHashtag,
│                                    # TrendingBundle, SearchBundle
├── services/
│   └── community_service.dart       # HTTP layer (JWT attached automatically)
├── providers/
│   └── community_provider.dart      # all Search & Community state
├── widgets/
│   ├── community_scaffold.dart      # shared gradient scaffold
│   ├── community_post_card.dart     # post card (banner, like / comment / bookmark)
│   ├── community_banner_image.dart  # fandom banner artwork (asset / network / gradient)
│   ├── community_user_tile.dart     # user row + follow button
│   └── community_chips.dart         # filter chips, stat tile, empty state
└── screens/
    ├── search_screen.dart
    ├── search_results_screen.dart
    ├── trending_screen.dart
    ├── discussions_screen.dart       # Deep Dive
    ├── create_post_screen.dart
    ├── post_details_screen.dart
    ├── bookmarks_screen.dart
    ├── notifications_screen.dart
    └── user_profile_screen.dart
```

### About the artwork
Every community post shows a **bundled fandom banner** — no external image host
needed. They are generated with Pillow by `frontend/tool/generate_banner_art.py`:

```
frontend/assets/images/fandoms/
├── anime.jpg      ├── music.jpg
├── gaming.jpg     ├── sports.jpg
├── movies_tv.jpg  ├── scifi.jpg
├── comics.jpg     └── default.jpg
```

Each post row stores its banner in `posts.image_url`
(e.g. `assets/images/fandoms/anime.jpg`). `CommunityBannerImage`
(`widgets/community_banner_image.dart`) renders an `assets/...` path directly,
loads `http(s)://...` images from the network, and falls back to a fandom
coloured gradient if the file is missing.

Regenerate the artwork at any time with:

```bash
py frontend/tool/generate_banner_art.py
```

**Wired into the existing app**

- `main.dart` → registers `CommunityProvider` in `MultiProvider`.
- `home_screen.dart`
  - Search icon → `SearchScreen`
  - Bell icon → `NotificationsScreen` **with unread badge**
  - **Bookmarks** bottom-nav tab → real `BookmarksScreen`
  - New **Community** quick-access section on the dashboard
    (Trending · Deep Dive · Search · Bookmarks)

---

## 6. How to run

### Backend

```bash
cd backend
npm install
npm run seed      # creates tables + demo users, posts, discussions, notifications
npm start         # http://localhost:5000
```

`backend/.env` must contain at least:

```
PORT=5000
JWT_SECRET=your_secret
```

> `config/loadEnv.js` loads `backend/.env` explicitly, so the server now works
> even when started from the workspace root.

### Frontend

```bash
cd frontend
flutter pub get
flutter run
```

The API base URL is auto-detected in `lib/config/api_config.dart`
(`10.0.2.2` on Android emulator, `localhost` elsewhere).

### Verify the API

```bash
cd backend
npm start           # in one terminal
npm run test:api    # in another -> prints a report + writes tests/report.txt
```

---

## 7. Demo credentials

| Email | Password |
|---|---|
| `emma@fandomverse.com` | `Fandom@123` |
| `rahul@fandomverse.com` | `Fandom@123` |
| `aisha@fandomverse.com` | `Fandom@123` |
| `daniel@fandomverse.com` | `Fandom@123` |
| `mei@fandomverse.com` | `Fandom@123` |

---

## 8. Manual test checklist

1. Log in as `emma@fandomverse.com` / `Fandom@123`.
2. Home → tap the **search** icon → type `naruto` → **Search** → results show Posts.
3. Switch the result filter to **Users** / **Fandoms** and change the sort.
4. Home → **Trending** → tap a hashtag like `#Lore` → opens matching results.
5. Home → **Deep Dive** → change sort to *Top* → open a discussion →
   like it, bookmark it, add a comment.
6. Home → **Deep Dive** → *New Discussion* → fill the form → Publish.
7. Home → **Community → Bookmarks** (or the bottom-nav **Bookmarks** tab) →
   the saved post appears; the grid/list toggle works.
8. Tap the bell icon → notifications load, unread badge clears after
   "mark all as read".
9. Open a post → tap the author → user profile → **Follow** / **Unfollow**.
