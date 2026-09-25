# FANDOM VERSE — Member 1: Profile, Fandom Selection & Home

> **Module owner:** Member 1
> **Frontend:** Flutter (Dart) — Splash, Login, Sign Up, Fandom Selection, Profile,
> Edit Profile, Invite, Social & Tasks, Public Badges, Settings, Home Dashboard
> **Backend:** Node.js + Express
> **Database:** SQLite only (replaces Firebase Users + Fandoms)
> **Theme:** electric blue / indigo accent (`lib/theme/profile_theme.dart`)
> **SRS reference:** *"1. User Registration and Profile Management"* +
> *"Trending Fandoms Carousel"*

---

## 1. What this module contains

| Area | Screens / Actions |
|---|---|
| **Onboarding** | Animated splash screen, Login (email/password + Google), Sign Up, email verification, forgot/reset password |
| **Fandom Selection** | Catalogue of all fandoms with real cover artwork, multi-select, live counter, **Next** (saves) and **Skip** (defer) |
| **Profile** | Avatar with animated gradient ring, bio, fan level + points progress, activity stats (fandoms · badges · bookmarks · viewed · offline · events) |
| **Edit Profile** | Display name, bio (240 chars), avatar presets, public-profile switch, Save Changes, badge unlock toasts |
| **My Fandoms** | Same catalogue, edits an existing selection |
| **Public Badges** | 10-badge catalogue with earned/locked states, category filters, progress hero |
| **Invite** | Personal invite code, copy / share, friends joined list, claim a friend's code |
| **Social & Tasks** | 8 tasks with progress bars, fan points, quick actions |
| **Settings** | Dark mode, language (7), push switches (events / content / community / email), autoplay, offline sync, privacy, log out |
| **Home Dashboard** | Greeting + level card, search, trending fandoms carousel, your fandoms, "Continue", latest updates, Fandom Hub rail, "For You", badges, task progress, invite card, plus Member 3 / Member 4 quick access |

---

## 2. Backend — files added

```
backend/
├── database/
│   ├── profileSchema.js     # badges, tasks, settings, profile cache, user columns
│   └── seedProfile.js       # badge catalogue, tasks, settings, invite codes, cache warm-up
├── Controllers/
│   └── profilecontroller.js # profile, fandoms, badges, invite, tasks, settings, home
├── Routes/
│   └── profileroute.js      # all /api/profile routes
└── tests/
    └── profile_api_test.js  # API smoke test -> tests/profile_report.txt
```

`server.js` runs `initProfileSchema()` on boot and mounts
`app.use("/api/profile", profileRoutes)`.

Scripts: `npm run seed:profile`, `npm run test:profile`.

---

## 3. Database design (SQLite)

| Table | Purpose |
|---|---|
| `users` *(extended)* | invite_code, referred_by, invite_count, points, streak_count, avatar_frame, is_public, last_active_at |
| `profile_badges` | 10 badge definitions (Founder Fan, Fandom Starter, Multi-Fandom, Profile Pro, News Junkie, Binge Watcher, Deep Diver, Social Butterfly, Event Goer, Top Fan) |
| `user_badges` | Badges unlocked per user (auto-awarded when the rule matches) |
| `social_tasks` | 8 tasks with reward points and target counts |
| `user_tasks` | Per-user task progress / completion |
| `user_settings` | Language, dark mode, push preferences, autoplay, offline sync |
| `profile_cache` | **The "SQLite user cache"** — a JSON snapshot of the merged profile so the dashboard and profile screens open instantly and still work offline |
| `user_fandoms`, `fandom_categories` | Users + Fandoms store (shared with Member 3) |

---

## 4. API reference (`/api/profile`, JWT required)

| Method | Endpoint | Purpose |
|---|---|---|
| GET | `/home` | Home dashboard aggregate: profile, stats, trending fandoms, hubs, latest news, "for you", continue-watching, next event, unread count |
| GET | `/me` | Profile + fandoms + badges + tasks + stats (served from the SQLite cache when fresh) |
| PUT | `/me` | Edit Profile — name, bio, avatar preset, visibility |
| GET | `/avatars` | Avatar preset asset paths |
| GET | `/fandoms` | Fandom catalogue + current selection (with cover artwork) |
| PUT | `/fandoms` | Save the Fandom Selection screen (`skipped: true` defers) |
| GET | `/badges` | Public Badges screen payload |
| GET | `/invite` | Invite code, joined friends, share message |
| POST | `/invite/claim` | Claim a friend's invite code (+50 points to the inviter) |
| GET | `/tasks` | Social & Tasks payload + points |
| POST | `/tasks/:code/complete` | Complete one task and award its points |
| GET / PUT | `/settings` | Read / update user preferences |

---

## 5. Badge rules (auto-awarded)

| Badge | Unlocked when |
|---|---|
| Founder Fan | account exists |
| Fandom Starter | 1+ fandom selected |
| Multi-Fandom | 3+ fandoms selected |
| Profile Pro | bio **and** avatar set |
| News Junkie | 10 news stories read |
| Binge Watcher | 10 videos watched |
| Deep Diver | 1 deep-dive opened |
| Social Butterfly | 3 friends invited |
| Event Goer | 1 event saved |
| Top Fan | 250 fan points |

Fan points come from completed tasks (+50 per successful invite) and drive the
level shown on the profile and dashboard header (100 points per level).

---

## 6. Flutter files

```
frontend/lib/
├── theme/profile_theme.dart           # blue/indigo palette + helpers
├── models/profile_models.dart         # ProfileUser, ProfileBadge, FandomOption, SocialTask,
│                                      # ProfileStats, UserSettings, InviteInfo, HomeDashboard
├── services/profile_service.dart      # HTTP layer over /api/profile
├── providers/profile_provider.dart    # state for every screen above
├── widgets/profile_widgets.dart       # ProfileScaffold, GradientActionButton, StatTile,
│                                      # BadgeTile, TaskTile, FandomSelectCard,
│                                      # SettingsSwitchTile, SettingsActionTile, PointsCard,
│                                      # InviteSummaryCard
└── screens/
    ├── splash_screen.dart             # animated logo + orbiting fandom icons
    ├── fandom_selection_screen.dart   # Select Fandoms → Next / Skip
    ├── profile_screen.dart            # profile tab (also the standalone page)
    ├── edit_profile_screen.dart
    ├── my_fandoms_screen.dart
    ├── profile_badges_screen.dart
    ├── invite_friends_screen.dart
    ├── social_tasks_screen.dart
    ├── settings_screen.dart
    └── home_screen.dart               # 6-tab shell: Home · Explore · Events · Shop · Saved · Profile
```

---

## 7. Animations added

- Splash: elastic logo pop, orbiting fandom icons, progress bar.
- Every screen: staggered `FadeSlideIn` entry for headers, cards and lists.
- Cards, chips and buttons: `PressScale` press-down feedback.
- Numbers (points, stats): `AnimatedCounter` count-up.
- Progress bars (level, tasks, offline storage): animated fill.
- Avatar: slowly rotating gradient ring.
- Bottom navigation: animated gradient pill on the selected tab.
- Loading states: shimmer placeholders instead of spinners.
- Fandom selection: card glow/border change + pulsing selection counter.
- Images: fade + scale-in via the shared `AppImage` widget.

---

## 7.1 Splash → next screen hand-off

The splash artwork (`assets/images/splash_bg.png` + the bottom loading bar) stays
on screen until the destination screen is **ready to be shown**:

1. The saved session is restored (`AuthProvider.checkAuthStatus()`).
2. If a session exists, `ProfileProvider.loadDashboard()` is awaited, so the Home
   dashboard is already populated when it appears (no shimmer/empty flash).
   The preload is capped with a timeout, so a slow API can never trap the splash.
3. If there is no session, the login screen's artwork (`fandom_logo.png`,
   `google_logo.png`) is precached so nothing pops in after the transition.
4. A 2.5 s minimum display time guarantees the splash is never skipped.
5. The hand-off uses a custom fade + slide route instead of an abrupt swap.

---

## 7.2 Notifications (themed alerts)

Every bottom notification in the app was replaced by a single themed alert
dialog: `widgets/app_alert.dart`.

| Helper | Use |
|---|---|
| `showSuccessAlert(context, msg, title:)` | green tick - "Login Successful", "Account Created", "Ticket Cancelled", "Task Complete" |
| `showErrorAlert(context, msg, title:)` | red cross - validation and API failures |
| `showWarningAlert(context, msg, title:)` | amber - "Verify Your Email" |
| `showInfoAlert(context, msg, title:)` | module accent - bookmarks, follow, copied, offline |

Each alert uses the dark card surface, an accent glow ring, an icon badge, the
Outfit/Inter type pairing and a gradient confirm button. Modules that own a
palette can pass `accent:` (`ProfileTheme.cyan`, `ContentTheme.primary`,
`EventTheme.primary`, ...) so the alert matches its section. Actions that
navigate away (`Login Successful` → Home, `Published` → back) wait for the alert
to be dismissed first, so the dialog is never popped by the navigation.

---

## 8. Demo credentials

| Field | Value |
|---|---|
| Email | `emma@fandomverse.com` |
| Password | `Fandom@123` |

---

## 9. How to run

### Backend

```bash
cd backend
npm install
npm run seed:profile   # tables + badge catalogue + tasks + settings + cache warm-up
npm start              # http://localhost:5000
```

`backend/.env` must contain at least:

```
PORT=5000
JWT_SECRET=your_secret
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
npm run test:profile   # in another -> prints a report + writes tests/profile_report.txt
```

Last verified run: **20/20 checks passed** (see section 10).

---

## 10. Verification & manual test checklist

Automated: `flutter analyze` reports **no issues** for `frontend/`, and
`npm run test:profile` passes **20/20** checks.

1. Log in as `emma@fandomverse.com` / `Fandom@123` — the animated splash
   hands over to the Home dashboard.
2. Home → greeting card shows the fan level, points and the activity stat row.
3. Home → **trending fandoms carousel** scrolls horizontally and the cards use the
   real fandom cover artwork (`assets/images/fandoms/*.jpg`).
4. Fandom Selection screen → multi-select fandoms → the counter animates →
   **Next** saves, **Skip** defers.
5. Profile tab → avatar gradient ring, bio, level progress, stats, badges.
6. Edit Profile → change the display name and avatar preset → **Save Changes**
   → a badge-unlock toast appears when a rule matches.
7. My Fandoms → edit the existing selection and re-save.
8. Public Badges → the 10-badge catalogue with earned/locked states and
   category filters.
9. Invite Friends → copy the invite code → claim a friend's code (+50 points).
10. Social & Tasks → task progress bars advance and award fan points.
11. Settings → toggle dark mode, language, push switches, autoplay, offline sync.
12. Home → the Member 3 / Member 4 quick-access cards open the community and
    events modules.
