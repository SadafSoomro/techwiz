# FANDOM VERSE — Member 5: Merchandise Store + AI Fan Helper

> **Module owner:** Member 5
> **Frontend:** Flutter (Dart)
> **Backend:** Node.js + Express
> **Database / Cache:** SQLite
> **Theme:** purple / pink brand with gold prices and a cyan accent for the AI assistant
> **SRS reference:**
> * *"4. Official Fan Merchandise and Wishlist Store"* — product catalog with
>   category filtering and price sorting, wishlist, cart, price drop alerts,
>   and a **simulated** checkout that only produces a bill.
> * *"5. AI Fan Helper"* — an assistant that answers **predefined fandom FAQs**
>   or uses a **basic AI API**.

---

## 1. What this module contains

| Area | Screens / Actions |
|---|---|
| **Shop Home** | Animated hero banner, quick access to Wishlist · Cart · Orders · AI Helper, live stat tiles, keyword search, category chips, fandom + price-sort chips, "In stock only" / "On sale" toggles, auto-scrolling **Deals of the week**, **Fandom exclusives**, **New arrivals**, **Best sellers** shelves and the full product grid |
| **Product Details** | Large animated artwork, price + strike-through + discount badge, savings line, stock pill, rating, quantity stepper, **Add to Cart**, **Add to Wishlist**, full description, specification table, related products |
| **Wishlist** | Saved products, running totals (value · deal savings · price drops), the **price-drop** strip per item, "Move all to cart", "Clear wishlist", manual re-check of prices |
| **Cart** | Quantity stepper per line, remove line, empty cart, **free-shipping progress bar**, promo code box with one-tap demo codes, live bill (subtotal · discount · shipping · total) |
| **Checkout (Simulated)** | Order summary with per-line prices, delivery form (name · phone · city · address), simulated payment method, order note, **Confirm Order** |
| **Order Success** | Animated ring + self-drawing tick, order code, full bill, order information, **View Orders** · **Continue Shopping** · **Buy these items again** |
| **My Orders** | Purchase history (order code, status, items, total, saved amount), order detail bottom sheet with the complete bill and delivery details, delete order |
| **Price Alerts** | History of every price drop detected on the wishlist |
| **AI For Helper** | Animated assistant avatar, greeting, suggestion chips, chat transcript, follow-up chips, typing indicator, message composer, knowledge-base info sheet, clear conversation |

---

## 2. Backend — files added

```
backend/
├── database/
│   ├── shopSchema.js          # creates all Merchandise + AI tables
│   └── seedShop.js            # 5 categories + 29 products + 19 FAQs + demo data
├── Controllers/
│   ├── shopcontroller.js      # catalogue, wishlist, price drops, cart, checkout, orders
│   └── aicontroller.js        # AI Fan Helper (catalogue lookup + FAQ engine + AI API)
├── Routes/
│   ├── shoproute.js           # all /api/shop routes
│   └── airoute.js             # all /api/ai routes
└── tests/
    └── shop_api_test.js       # API smoke test -> writes tests/shop_report.txt
```

`server.js` now also runs `initShopSchema()` and mounts
`app.use("/api/shop", shopRoutes)` and `app.use("/api/ai", aiRoutes)`.

The SQL script `backend/database/fandom_verse_schema.sql` documents the same
tables (sections **18–26**).

### npm scripts

```bash
npm run seed:shop     # create the tables + catalogue + FAQs + demo data
npm run seed:all      # community + events + shop seeders
npm run test:shop     # 40 API checks, writes tests/shop_report.txt
```

---

## 3. Database design (SQLite)

| Table | Purpose |
|---|---|
| `product_categories` | Figures · Shirts · Collections · Accessories · Digital Assets (name, slug, icon, colour, description) |
| `products` | SRS minimum **Product_Id, Name, Price, Image_Url, Category** + SKU, description, fandom, brand, old price, discount %, stock, rating, rating count, sold count, featured flag, digital flag, status |
| `wishlists` | SRS **Wish_Id, User_Id, Product_Id, Saved_At** + `price_at_save` and `last_alerted_price` so price drops can be detected without repeating alerts |
| `cart_items` | One row per user/product with a quantity (unique per pair) |
| `orders` | Simulated order header — order code, item count, subtotal, discount, shipping, total, status, payment method, delivery details, note |
| `order_items` | Immutable snapshot of each ordered line (name, image, unit price, quantity, line total) |
| `price_alerts` | Every price drop that was detected and notified |
| `ai_faqs` | The predefined fandom knowledge base — question, answer, keywords, topic, image |
| `ai_chat_messages` | Persisted AI conversation per user |

Indexes exist on product category / fandom / price, wishlist user, cart user,
order user, order items, price alerts and AI chat.

**Cache:** the same `response_cache` table used by Members 3 and 4 acts as the
Redis replacement — `shop:categories`, `shop:fandoms` and `ai:suggestions` are
cached with a short TTL and invalidated on any catalogue or wishlist write.

---

## 4. REST API

### `/api/shop`

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| GET | `/overview` | optional | Shop Home payload — stats, categories, featured, deals, new arrivals, best sellers, shipping rules, promo codes |
| GET | `/categories` | optional | Categories with product counts, deal counts, lowest price |
| GET | `/fandoms` | optional | Fandoms with counts (filter chips) |
| GET | `/products` | optional | Catalogue. Query: `category`, `fandom`, `brand`, `q`, `sort`, `min_price`, `max_price`, `in_stock`, `discounted`, `digital`, `featured`, `limit`, `offset` |
| GET | `/products/:id` | optional | Product details + related products + category average rating |
| GET | `/wishlist` | required | My wishlist with per-item price-drop info and running totals |
| POST | `/wishlist/:productId` | required | Toggle add / remove |
| DELETE | `/wishlist/:productId` | required | Explicit remove |
| DELETE | `/wishlist` | required | Clear the wishlist |
| POST | `/wishlist/alerts/check` | required | Run price-drop detection and create the notifications |
| GET | `/wishlist/alerts` | required | Price alert history |
| GET | `/cart` | required | Cart lines + bill. Optional `promo` |
| POST | `/cart` | required | Add — body `{ product_id, quantity }` |
| PUT | `/cart/:productId` | required | Set quantity (0 removes the line) |
| DELETE | `/cart/:productId` | required | Remove a line |
| DELETE | `/cart` | required | Empty the cart |
| POST | `/cart/summary` | required | Recalculate the bill for a promo code (no changes) |
| POST | `/checkout` | required | Place the **simulated** order |
| GET | `/orders/mine` | required | Purchase history |
| GET | `/orders/:id` | required | One order with its lines |
| DELETE | `/orders/:id` | required | Remove a saved order |

`sort` accepts `featured` (default), `popular`, `rating`, `newest`,
`price_low`, `price_high`, `discount`, `name`. Sort clauses are whitelisted, so
they cannot be injected.

### `/api/ai`

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| GET | `/suggestions` | public | Greeting, starter chips, topic list, whether an external AI is configured |
| GET | `/topics` | public | Knowledge-base topics with counts |
| POST | `/chat` | optional | Ask the assistant — body `{ message }` |
| GET | `/history` | required | Persisted conversation |
| DELETE | `/history` | required | Clear the conversation |

---

## 5. How the AI Fan Helper answers

Three tiers, cheapest first:

1. **Store lookup (grounded)** — if the question names a product, fandom,
   category or brand in the catalogue, the answer is built from the real
   `products` row: name, price, discount, stock, rating and the brand.
   "How much is the Luffy Gear 5 Figure?" → live price and stock.
2. **FAQ engine (offline)** — keyword scoring plus fuzzy token matching
   (normalised Levenshtein) over the `ai_faqs` table. This is the SRS
   *"predefined fandom FAQs"* tier and it needs **no internet and no API key**,
   which also satisfies the "offline access" non-functional requirement.
3. **External AI API (optional)** — anything the first two tiers cannot answer
   confidently is forwarded to an OpenAI-compatible chat-completions endpoint
   when `AI_API_URL` and `AI_API_KEY` are set in `backend/.env`.

A question that clearly asks about the store (`price`, `stock`, `buy`, …) goes
to tier 1 first; a lore question goes to tier 2 first; whichever tier has an
answer acts as the fallback for the other. Small talk ("hi", "thanks", "bye")
and a friendly fallback with example questions are handled last.

**The knowledge base ships with 19 curated entries** covering: One Piece,
Naruto, Demon Slayer, Jujutsu Kaisen, Attack on Titan, Dragon Ball, figure and
apparel care, anime/manga recommendations, gift ideas, cosplay, fandoms,
events, and store help (orders, wishlist, cart, checkout, authenticity).

Setting up the optional AI API:

```env
# backend/.env — leave blank to stay fully offline
AI_API_URL=https://api.openai.com/v1/chat/completions
AI_API_KEY=<your-api-key-here>
AI_MODEL=gpt-4o-mini
```

The Shop Home shows whether external AI is enabled, so the demo works either way.

---

## 6. Price drop alerts (SRS requirement)

The SRS asks for *"price drop alerts via push notifications"*.

* When a product is wishlisted, `wishlists.price_at_save` records the price at
  that moment.
* Two helpers share one comparison: `collectPriceDrops()` is **read-only** and
  returns every wishlisted product whose price is below its snapshot, while
  `checkPriceDrops()` performs the **notification pass**.
* `checkPriceDrops()` only acts on a drop that has not been announced yet. For
  each one it:
  1. inserts a row into `price_alerts`,
  2. creates a notification (`type = 'price_drop'`) that appears in Member 3's
     Notifications screen,
  3. records `last_alerted_price` so the same drop is never reported twice.
* The Wishlist screen uses `collectPriceDrops()`, so the green
  **"Price dropped N%"** strip with its **Grab it** button and the
  *Price drops* counter stay visible after the notification has been delivered -
  the user keeps seeing the saving until they act on it. Only the *notification*
  is de-duplicated, never the information itself.
* The seeder deliberately saves four wishlist items at prices **above** their
  current price, so a drop (and its notification) fires the first time the
  Wishlist screen opens.

Endpoint summary:

| Method | Endpoint | Behaviour |
|---|---|---|
| GET | `/wishlist` | Read-only. Reports the standing drops per item plus `price_drops` count |
| POST | `/wishlist/alerts/check` | Writes any *new* `price_alerts` rows + notifications |
| GET | `/wishlist/alerts` | The alert history, newest first |

---

## 7. Frontend — files added

```
frontend/lib/
├── theme/
│   └── shop_theme.dart          # palette, gradients, price/category/date helpers
├── models/
│   ├── shop_models.dart         # Product, ProductCategory, ProductFandom, WishlistItem,
│   │                            # PriceDrop, PriceAlert, CartLine, CartSummary,
│   │                            # PromoCode, Order, OrderLine, ShopStats, ShopOverview
│   └── ai_models.dart           # AiMessage, AiSuggestion, AiTopicCount, AiReply
├── services/
│   ├── shop_service.dart        # HTTP layer for /api/shop (JWT attached automatically)
│   └── ai_service.dart          # HTTP layer for /api/ai
├── providers/
│   ├── shop_provider.dart       # catalogue, filters, wishlist, cart, checkout, orders
│   └── ai_provider.dart         # conversation, suggestions, knowledge base metadata
├── widgets/
│   ├── shop_animated.dart       # the animation toolkit (see below)
│   ├── shop_scaffold.dart       # gradient scaffold + header actions with badges
│   ├── shop_widgets.dart        # chips, titles, stat tiles, price/stock/rating blocks,
│   │                            # wish button, quantity stepper, buttons, bill rows
│   ├── product_image.dart       # asset / network / gradient-fallback renderer
│   ├── product_card.dart        # grid card, mini card, wide card, skeleton loader
│   └── ai_widgets.dart          # animated avatar, chat bubbles, typing dots, chips
└── screens/
    ├── shop_screen.dart              # Shop Home (+ ShopScreen hero banner)
    ├── product_details_screen.dart
    ├── wishlist_screen.dart
    ├── cart_screen.dart
    ├── checkout_screen.dart
    ├── order_success_screen.dart
    ├── orders_screen.dart            # purchase history + price alerts
    └── ai_helper_screen.dart
```

### Wired into the existing app
- `main.dart` → registers `ShopProvider` and `AiProvider` in `MultiProvider`
- `home_screen.dart`
  - **Shop** bottom-nav tab (was a placeholder) → the real `ShopScreen`
  - Dashboard warms up the shop data and the AI assistant
  - New **Fandom Shop** section: a deals banner card with product thumbnails and
    quick tiles for Wishlist · Cart · My Orders · AI Helper
  - Profile tab → **Purchase History** and **My Wishlist** shortcuts
- `config/api_config.dart` → all `/api/shop` and `/api/ai` endpoints
- `pubspec.yaml` → `assets/images/products/` and `assets/images/shop/`

---

## 8. About the animations

The design board shows animated imagery, so every moving element is built with
Flutter's own animation system in `widgets/shop_animated.dart`. **No animated
GIF/WebP assets are used** — the effects stay crisp at any resolution, work on
every platform (web, Windows, Android, iOS) and add no download weight.

| Widget | Effect | Used by |
|---|---|---|
| `ShineSweep` | A light band travelling across the artwork | Product details hero, AI answer images |
| `FloatingBox` | Gentle breathing float (with optional sideways drift) | Hero banner, discount sticker, AI avatar, success tick |
| `PulseGlow` | Halo that pulses behind its child | Hero sticker, wishlist/empty states, AI avatar |
| `AnimatedGradientBox` | Slowly shifting multi-stop gradient | Shop scaffold header glow, hero banner |
| `AutoScrollRow` | Endlessly scrolling shelf that pauses while you drag | Deals of the week |
| `TypingDots` | Three bouncing dots while the AI answers | AI chat |
| `BounceIn` | Staggered entrance for cards and rows | Grid items, cart lines, suggestion chips |
| `AnimatedCounter` | Count-up numbers | Shop / wishlist / order stat tiles |
| `AnimatedStars` | Rating stars that pop in one by one | Product & wishlist ratings |
| `SpinningGradientRing` | Rotating conic ring (counter-rotated so the glyph stays upright) | AI avatar |
| `ScaleOnTap` | Springy press feedback | Every card and button |

Plus two one-shot animations: the **self-drawing success tick** on the order
confirmation, and the **free-shipping progress bar** on the cart.

---

## 9. About the artwork

Every product has a **real bundled image** — no external image host is needed.
They are generated with Pillow by
`frontend/tool/generate_product_art.py` (shapes come from
`frontend/tool/product_art_lib.py`, which reuses the shared gradient/pattern
helpers in `banner_lib.py`):

```
frontend/assets/images/products/     # 29 product images, one per SKU
frontend/assets/images/shop/         # shop_hero, shop_deals, shop_new, shop_digital
```

Each product image is drawn from its **category silhouette**:

| Category | Shape | Palette |
|---|---|---|
| Figures | A collectible figure on a pedestal with hair spikes and an energy arc | amber |
| Shirts | A flat-lay t-shirt outline with a collar and a printed emblem | purple |
| Collections | A stacked box set with a ribbon and a lid sparkle | cyan |
| Accessories | An enamel badge with a keyring loop and a star | emerald |
| Digital Assets | A device frame with a download arrow and a play badge | pink |

Three colour variants per category keep neighbouring products distinct.
`ProductImage` (`widgets/product_image.dart`) resolves `products.image_url` at runtime:

| `image_url` value | Rendering |
|---|---|
| `assets/...` | bundled artwork (`Image.asset`) |
| `http(s)://...` | remote image with a progress placeholder |
| empty / broken | category coloured gradient + category icon |

Regenerate at any time with:

```bash
py frontend/tool/generate_product_art.py
```

---

## 10. Store rules (the bill maths)

| Rule | Value |
|---|---|
| Flat shipping | `$6.99` on orders containing at least one physical item |
| Free shipping | Automatic at `$75` subtotal (after discount); digital-only orders never ship |
| `FANDOM10` | 10% off any order |
| `VERSE20` | 20% off orders over `$100` |
| `NEWFAN` | `$5` off orders over `$25` |
| `FREESHIP` | Waives the shipping fee |

Stock is enforced on both the cart and the checkout: adding or stepping past the
available quantity is rejected with a clear message, and confirming an order
reduces `products.stock` and increases `sold_count`.

> **Scope note (from the SRS):** *"actual purchase, payment, or delivery
> functionality will not be implemented in the app."* Checkout therefore only
> saves an order and shows the bill. No payment gateway is called and nothing
> ships — this is stated on the Checkout, Order Success and Product Details
> screens so the behaviour is never ambiguous.

---

## 11. How to run

```bash
cd backend
npm install
npm run seed:all        # community + events + shop (creates the tables + demo data)
npm start               # http://localhost:5000
```

`backend/.env` needs at least:

```env
PORT=5000
JWT_SECRET=...
```

`AI_API_URL` / `AI_API_KEY` are **optional** — without them the assistant uses
the offline FAQ engine.

```bash
cd frontend
flutter pub get
flutter run
```

Verify the API:

```bash
npm start              # terminal 1
npm run test:shop      # terminal 2 -> 40 checks + tests/shop_report.txt
```

> **Port tip (Windows):** if you ever started the server more than once, an old
> `node.exe` can keep answering on port 5000. Run `taskkill /F /IM node.exe`
> and start the server again.

---

## 12. Demo data & credentials

| Email | Password |
|---|---|
| `emma@fandomverse.com` | `Fandom@123` |

The seeder gives Emma:

* **4 wishlist items** — two of them saved at a *higher* price than today, so
  the price-drop alert is triggered on first launch
* **2 cart lines** (one with a quantity of 2, so the bill maths is visible)
* **1 past order** (Tanjiro + Nezuko figures) so Purchase History is not empty

Catalogue: **29 products** across the 5 categories, with 17 of them discounted.

---

## 13. Manual test checklist

1. Log in as `emma@fandomverse.com` / `Fandom@123`.
2. Bottom tab **Shop** → the hero banner animates, stat tiles count up, the
   *Deals of the week* shelf scrolls by itself and the product grid loads.
3. Tap a category chip (e.g. **Figures**) → the grid filters; tap a sort chip
   (e.g. **Price ↑**) → the order changes; use the search box ("luffy").
4. Tap **On sale** → only discounted products remain; tap **Reset** to clear.
5. Open a product → the artwork shines, stock and rating show, change the
   quantity → **Add to Cart**.
6. Tap the heart on a product → it appears under **Wishlist** with a running
   value. Two items show a green **price drop** strip.
7. Open **Wishlist** → the price-drop banner lists the drops; tap **Grab it** to
   move an item to the cart. Check the bell icon → a `price_drop` notification
   was created (Member 3's Notifications screen).
8. Open **Cart** → change a quantity, remove a line, apply **FANDOM10** (the
   discount line appears), then **FREESHIP** (shipping becomes free).
9. **Checkout** → the order summary matches the cart → fill the delivery form →
   **Confirm Order**.
10. **Order Success** → the tick draws itself, the order code and bill are shown
    → **View Orders**.
11. **My Orders** → the new order is listed; open it for the full bill and
    delivery details; try **Buy again**.
12. Tap the heart until the wishlist is empty → the empty state appears with a
    **Browse the shop** action.
13. Open **AI Helper** from the Shop header (or the dashboard tile).
14. Ask **"Who is Luffy?"** → the FAQ answer with a One Piece image, tagged
    *Fandom knowledge base*.
15. Ask **"How much is the Luffy Gear 5 Figure?"** → a live price answer tagged
    *Live catalogue*.
16. Ask **"Suggestions for anime?"** → the recommendation list; follow-up chips
    appear underneath.
17. Ask **"hello"** → small talk. Ask **"asdkjhasd"** → a friendly fallback with
    example questions.
18. Profile tab → **Purchase History** opens the orders list.
19. Sign out and back in → the AI conversation is restored from the database.

---

## 14. Test evidence

`npm run test:shop` runs **40 checks** against a live server and writes
`backend/tests/shop_report.txt`, which contains the request summary, every
response body and the full AI conversation transcript. It is the "Test Data
Used in the Project" evidence for the SRS deliverables.

Covered: overview, categories, fandoms, catalogue filters, ascending/descending
price sorting, product details, unknown product (404), wishlist, price-drop
detection, the persistent drop display after the alert was sent, wishlist
toggling, cart add/update/remove, the stock guard, promo codes (valid, invalid,
free shipping), checkout (success + empty-cart rejection), cart emptying after
checkout, order history, order details, all three AI tiers, small talk, the
fallback, chat history persistence, and the 401 authorisation guards on
cart / wishlist / checkout.

---

## 15. AI tool acknowledgement

In line with the SRS note on AI usage, AI tooling (GitHub Copilot) was used as a
supporting aid for scaffolding, boilerplate and debugging. The module design,
database schema, API contract, state management, UI layout and business rules
(the store rules, price-drop logic and AI tiering) were specified and reviewed
by the team, and every part is intended to be explainable during evaluation.
