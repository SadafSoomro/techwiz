/**
 * FANDOM VERSE - Member 5 (Merchandise Store + AI Fan Helper) database schema
 * --------------------------------------------------------------------------
 * SRS reference:
 *   "4. Official Fan Merchandise and Wishlist Store"
 *     - Product Catalog (apparel, collectibles, digital assets) with
 *       category filtering and price sorting
 *     - Wishlist + Cart: add / edit / remove items, price drop alerts,
 *       and a *simulated* checkout that only shows the bill
 *       (no real payment / delivery per the SRS scope note)
 *   "5. AI Fan Helper"
 *     - Predefined fandom FAQs + an optional basic AI API
 *
 * SRS example collections implemented here:
 *   Merchandise : Product_Id (PK), Name, Price, Image_Url, Category
 *   Wishlists   : Wish_Id (PK), User_Id (FK), Product_Id (FK), Saved_At
 *
 * SQLite is used for storage AND for the cache (see database/cache.js),
 * which replaces the Redis requirement of the original spec.
 */

import db from "./db.js";

/** Creates every table / index needed by the Merchandise + AI module. */
export function initShopSchema() {
  db.serialize(() => {
    // ------------------------- product categories -------------------------
    db.run(`
      CREATE TABLE IF NOT EXISTS product_categories (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        name        TEXT NOT NULL UNIQUE,
        slug        TEXT NOT NULL UNIQUE,
        icon        TEXT,
        color       TEXT,
        description TEXT,
        sort_order  INTEGER DEFAULT 0,
        created_at  TEXT DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // ------------------------------ products ------------------------------
    // SRS minimum: Product_Id, Name, Price, Image_Url, Category.
    // Extended with stock / rating / discount data so the Shop Home,
    // Product Details and price-drop alerts have real values to show.
    db.run(`
      CREATE TABLE IF NOT EXISTS products (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        name             TEXT NOT NULL,
        sku              TEXT UNIQUE,
        description      TEXT,
        category         TEXT NOT NULL DEFAULT 'Figures',
        fandom           TEXT,
        brand            TEXT,
        price            REAL NOT NULL DEFAULT 0,
        old_price        REAL,
        discount_percent INTEGER DEFAULT 0,
        currency         TEXT DEFAULT 'PKR',
        image_url        TEXT,
        stock            INTEGER DEFAULT 0,
        rating           REAL DEFAULT 0,
        rating_count     INTEGER DEFAULT 0,
        sold_count       INTEGER DEFAULT 0,
        is_featured      INTEGER DEFAULT 0,
        is_digital       INTEGER DEFAULT 0,
        status           TEXT DEFAULT 'active',
        created_at       TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at       TEXT DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // ----------------------------- wishlists ------------------------------
    // Wish_Id (PK), User_Id (FK), Product_Id (FK), Saved_At  + alert bookkeeping
    db.run(`
      CREATE TABLE IF NOT EXISTS wishlists (
        id             INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id        INTEGER NOT NULL,
        product_id     INTEGER NOT NULL,
        price_at_save  REAL DEFAULT 0,
        last_alerted_price REAL,
        saved_at       TEXT DEFAULT CURRENT_TIMESTAMP,
        UNIQUE (user_id, product_id)
      )
    `);

    // ---------------------------- cart items ------------------------------
    db.run(`
      CREATE TABLE IF NOT EXISTS cart_items (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id    INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        quantity   INTEGER NOT NULL DEFAULT 1,
        added_at   TEXT DEFAULT CURRENT_TIMESTAMP,
        UNIQUE (user_id, product_id)
      )
    `);

    // ------------------------- orders (simulated) -------------------------
    // The SRS explicitly excludes real payment / delivery - an order is only
    // a saved bill so "purchase history" can be shown on the profile.
    db.run(`
      CREATE TABLE IF NOT EXISTS orders (
        id             INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id        INTEGER NOT NULL,
        order_code     TEXT NOT NULL UNIQUE,
        item_count     INTEGER DEFAULT 0,
        subtotal       REAL DEFAULT 0,
        discount       REAL DEFAULT 0,
        shipping_fee   REAL DEFAULT 0,
        total          REAL DEFAULT 0,
        currency       TEXT DEFAULT 'PKR',
        status         TEXT DEFAULT 'placed',
        payment_method TEXT DEFAULT 'Cash on Delivery (simulated)',
        shipping_name  TEXT,
        shipping_phone TEXT,
        shipping_city  TEXT,
        shipping_address TEXT,
        note           TEXT,
        placed_at      TEXT DEFAULT CURRENT_TIMESTAMP
      )
    `);

    db.run(`
      CREATE TABLE IF NOT EXISTS order_items (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id   INTEGER NOT NULL,
        product_id INTEGER,
        name       TEXT NOT NULL,
        image_url  TEXT,
        unit_price REAL DEFAULT 0,
        quantity   INTEGER DEFAULT 1,
        line_total REAL DEFAULT 0,
        FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE
      )
    `);

    // --------------------------- price alerts -----------------------------
    // Powers the SRS "receive price drop alerts via push notifications".
    db.run(`
      CREATE TABLE IF NOT EXISTS price_alerts (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id    INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        old_price  REAL DEFAULT 0,
        new_price  REAL DEFAULT 0,
        drop_amount REAL DEFAULT 0,
        is_seen    INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // ---------------------- AI Fan Helper knowledge base -------------------
    // "answers predefined fandom FAQs" - the offline part of the assistant.
    db.run(`
      CREATE TABLE IF NOT EXISTS ai_faqs (
        id        INTEGER PRIMARY KEY AUTOINCREMENT,
        question  TEXT NOT NULL,
        answer    TEXT NOT NULL,
        keywords  TEXT,
        topic     TEXT,
        image_url TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // ------------------------ AI chat history -----------------------------
    db.run(`
      CREATE TABLE IF NOT EXISTS ai_chat_messages (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id    INTEGER,
        sender     TEXT NOT NULL,
        message    TEXT NOT NULL,
        topic      TEXT,
        source     TEXT DEFAULT 'faq',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // ------------------------------- indexes -------------------------------
    db.run(`CREATE INDEX IF NOT EXISTS idx_products_category ON products (category)`);
    db.run(`CREATE INDEX IF NOT EXISTS idx_products_fandom   ON products (fandom)`);
    db.run(`CREATE INDEX IF NOT EXISTS idx_products_price    ON products (price)`);
    db.run(`CREATE INDEX IF NOT EXISTS idx_wishlist_user     ON wishlists (user_id)`);
    db.run(`CREATE INDEX IF NOT EXISTS idx_cart_user         ON cart_items (user_id)`);
    db.run(`CREATE INDEX IF NOT EXISTS idx_orders_user       ON orders (user_id)`);
    db.run(`CREATE INDEX IF NOT EXISTS idx_order_items_order ON order_items (order_id)`);
    db.run(`CREATE INDEX IF NOT EXISTS idx_price_alerts_user ON price_alerts (user_id, is_seen)`);
    db.run(`CREATE INDEX IF NOT EXISTS idx_ai_chat_user      ON ai_chat_messages (user_id, id)`);
  });
}

export default initShopSchema;
