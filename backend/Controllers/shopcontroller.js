/**
 * MEMBER 5 - Merchandise Store
 * Shop controller.
 *
 * Covers:
 *   - Product catalogue with category / fandom / price filtering and price sorting
 *   - Product details + related products
 *   - Wishlist (add / remove / toggle) with price-drop detection
 *   - Cart (add / update quantity / remove / clear) + bill summary
 *   - Simulated checkout that saves an order so "purchase history" exists
 *   - Order history / order details
 *
 * The SRS explicitly keeps real payment and delivery OUT of scope, so
 * "checkout" only produces an itemised bill and a saved order.
 *
 * SQLite is used for storage and caching (database/cache.js).
 */

import { all, get, run, asyncHandler, timeAgo } from "../database/dbhelpers.js";
import cache from "../database/cache.js";
import { notify } from "../utils/notify.js";

// ---------------------------------------------------------------------------
// store rules (kept in one place so the bill maths is easy to follow)
// ---------------------------------------------------------------------------

/** Flat shipping charged on orders that contain at least one physical item. */
const SHIPPING_FLAT = 6.99;

/** Orders at or above this subtotal ship free. */
const FREE_SHIPPING_THRESHOLD = 75;

/** Promo codes the Checkout screen can apply. */
export const PROMO_CODES = {
  FANDOM10: { type: "percent", value: 10, minSubtotal: 0, label: "10% off your order" },
  VERSE20: { type: "percent", value: 20, minSubtotal: 100, label: "20% off orders over $100" },
  NEWFAN: { type: "flat", value: 5, minSubtotal: 25, label: "$5 off orders over $25" },
  FREESHIP: { type: "shipping", value: 100, minSubtotal: 0, label: "Free shipping" },
};

export const PAYMENT_METHODS = [
  "Cash on Delivery (simulated)",
  "Card (simulated)",
  "Wallet (simulated)",
];

// ---------------------------------------------------------------------------
// product SQL
// ---------------------------------------------------------------------------

const PRODUCT_SELECT = `
  SELECT
    p.id, p.name, p.sku, p.description, p.category, p.fandom, p.brand,
    p.price, p.old_price, p.discount_percent, p.currency, p.image_url,
    p.stock, p.rating, p.rating_count, p.sold_count,
    p.is_featured, p.is_digital, p.status, p.created_at
  FROM products p
`;

const SORTS = {
  featured: "p.is_featured DESC, p.sold_count DESC",
  popular: "p.sold_count DESC, p.rating DESC",
  rating: "p.rating DESC, p.rating_count DESC",
  newest: "p.created_at DESC, p.id DESC",
  price_low: "p.price ASC, p.name ASC",
  price_high: "p.price DESC, p.name ASC",
  discount: "p.discount_percent DESC, p.price ASC",
  name: "p.name ASC",
};

function orderBy(value) {
  return SORTS[String(value || "featured").toLowerCase()] || SORTS.featured;
}

function round2(value) {
  return Math.round((Number(value) || 0) * 100) / 100;
}

/** Decorates a product row with the derived fields the UI needs. */
function shapeProduct(row) {
  if (!row) return null;

  return {
    ...row,
    is_featured: !!row.is_featured,
    is_digital: !!row.is_digital,
    in_stock: (row.stock || 0) > 0,
    has_discount: !!(row.old_price && row.old_price > row.price),
    savings: row.old_price ? round2(row.old_price - row.price) : 0,
  };
}

/** Builds the shared WHERE clause for catalogue queries. */
function buildWhere(query) {
  const conditions = ["p.status = 'active'"];
  const params = [];

  if (query.category && query.category.toLowerCase() !== "all") {
    conditions.push(`p.category = ?`);
    params.push(query.category);
  }
  if (query.fandom && query.fandom.toLowerCase() !== "all") {
    conditions.push(`p.fandom = ?`);
    params.push(query.fandom);
  }
  if (query.brand) {
    conditions.push(`p.brand = ?`);
    params.push(query.brand);
  }
  if (query.q) {
    conditions.push(
      `(p.name LIKE ? OR IFNULL(p.description,'') LIKE ?
        OR IFNULL(p.fandom,'') LIKE ? OR IFNULL(p.brand,'') LIKE ?
        OR p.category LIKE ?)`
    );
    const like = `%${query.q}%`;
    params.push(like, like, like, like, like);
  }
  if (query.min_price) {
    conditions.push(`p.price >= ?`);
    params.push(parseFloat(query.min_price) || 0);
  }
  if (query.max_price) {
    conditions.push(`p.price <= ?`);
    params.push(parseFloat(query.max_price) || 0);
  }
  if (String(query.in_stock || "") === "1" || query.in_stock === "true") {
    conditions.push(`p.stock > 0`);
  }
  if (String(query.discounted || "") === "1" || query.discounted === "true") {
    conditions.push(`p.old_price IS NOT NULL AND p.old_price > p.price`);
  }
  if (String(query.digital || "") === "1" || query.digital === "true") {
    conditions.push(`p.is_digital = 1`);
  }
  if (String(query.featured || "") === "1" || query.featured === "true") {
    conditions.push(`p.is_featured = 1`);
  }

  return {
    sql: conditions.length ? `WHERE ${conditions.join(" AND ")}` : "",
    params,
  };
}

/**
 * Adds the per-user flags (is_wishlisted / quantity_in_cart) to a list of rows.
 * Called after the catalogue query so the same products endpoint works for
 * logged-out browsing and for the signed-in Shop Home.
 */
async function decorateForUser(rows, userId) {
  const products = rows.map(shapeProduct);
  if (!userId || !products.length) {
    return products.map((p) => ({ ...p, is_wishlisted: false, quantity_in_cart: 0 }));
  }

  const ids = products.map((p) => p.id);
  const placeholders = ids.map(() => "?").join(", ");

  const [wishes, cartRows] = await Promise.all([
    all(
      `SELECT product_id FROM wishlists WHERE user_id = ? AND product_id IN (${placeholders})`,
      [userId, ...ids]
    ),
    all(
      `SELECT product_id, quantity FROM cart_items
        WHERE user_id = ? AND product_id IN (${placeholders})`,
      [userId, ...ids]
    ),
  ]);

  const wishSet = new Set(wishes.map((w) => w.product_id));
  const cartMap = new Map(cartRows.map((c) => [c.product_id, c.quantity]));

  return products.map((p) => ({
    ...p,
    is_wishlisted: wishSet.has(p.id),
    quantity_in_cart: cartMap.get(p.id) || 0,
  }));
}

// ---------------------------------------------------------------------------
// bill maths
// ---------------------------------------------------------------------------

/**
 * Builds the simulated bill for a set of cart lines.
 * Returns the summary object shown on the Cart / Checkout screens.
 */
function buildBill(lines, promoCode) {
  const items = lines.map((line) => ({
    ...line,
    line_total: round2(line.price * line.quantity),
  }));

  const itemCount = items.reduce((sum, item) => sum + item.quantity, 0);
  const subtotal = round2(items.reduce((sum, item) => sum + item.line_total, 0));
  const hasPhysical = items.some((item) => !item.is_digital);

  // ------------------------------- promo -------------------------------
  const normalized = String(promoCode || "").trim().toUpperCase();
  const promo = PROMO_CODES[normalized];

  let promoApplied = false;
  let promoError = null;
  let promoLabel = null;
  let discount = 0;
  let freeShipping = false;

  if (normalized) {
    if (!promo) {
      promoError = `"${normalized}" is not a valid promo code`;
    } else if (subtotal < promo.minSubtotal) {
      promoError = `${normalized} needs a minimum subtotal of $${promo.minSubtotal.toFixed(2)}`;
    } else {
      promoApplied = true;
      promoLabel = `${normalized} - ${promo.label}`;

      if (promo.type === "percent") {
        discount = round2((subtotal * promo.value) / 100);
      } else if (promo.type === "flat") {
        discount = round2(Math.min(promo.value, subtotal));
      } else if (promo.type === "shipping") {
        freeShipping = true;
      }
    }
  }

  // ------------------------------ shipping ------------------------------
  // Digital-only orders never ship; otherwise free above the threshold.
  const afterDiscount = round2(subtotal - discount);
  if (!hasPhysical) freeShipping = true;

  const qualifiesFree =
    promoApplied && promo.type === "shipping"
      ? true
      : afterDiscount >= FREE_SHIPPING_THRESHOLD;

  if (qualifiesFree) freeShipping = true;

  const shippingFee = freeShipping || !hasPhysical ? 0 : SHIPPING_FLAT;
  const total = round2(Math.max(0, afterDiscount + shippingFee));

  return {
    items,
    item_count: itemCount,
    subtotal,
    discount,
    discount_label: promoApplied && discount > 0 ? promoLabel : null,
    shipping_fee: shippingFee,
    free_shipping: shippingFee === 0,
    free_shipping_threshold: FREE_SHIPPING_THRESHOLD,
    shipping_note:
      !hasPhysical
        ? "Digital order - no shipping charged"
        : shippingFee === 0
        ? "Free shipping applied"
        : `Add $${round2(FREE_SHIPPING_THRESHOLD - afterDiscount).toFixed(2)} more for free shipping`,
    promo_code: promoApplied ? normalized : null,
    promo_label: promoApplied ? promoLabel : null,
    promo_error: promoError,
    total,
    currency: items[0]?.currency || "USD",
    has_digital: items.some((item) => item.is_digital),
    has_physical: hasPhysical,
  };
}

/** Loads the user's cart lines joined with their product data. */
async function loadCartLines(userId) {
  return all(
    `SELECT
       c.id AS cart_item_id, c.quantity,
       p.id AS product_id, p.name, p.price, p.old_price, p.currency,
       p.image_url, p.category, p.fandom, p.brand, p.stock, p.is_digital,
       p.discount_percent
     FROM cart_items c
     JOIN products p ON p.id = c.product_id
     WHERE c.user_id = ?
     ORDER BY c.id DESC`,
    [userId]
  );
}

// ---------------------------------------------------------------------------
// PRICE DROP ALERTS
// ---------------------------------------------------------------------------

/**
 * Shared read for every wishlist row plus the product it points at.
 * `price_at_save` is the price recorded when the product was wishlisted, so
 * comparing it with the product's price today is what detects a drop.
 */
async function wishlistPriceRows(userId) {
  return all(
    `SELECT w.id AS wish_id, w.product_id, w.price_at_save, w.last_alerted_price,
            p.name, p.price, p.currency, p.image_url
       FROM wishlists w
       JOIN products p ON p.id = w.product_id
      WHERE w.user_id = ?`,
    [userId]
  );
}

/**
 * Turns a wishlist row into a price-drop object, or null when there is no drop.
 * `notified` records whether this exact price has already been announced, which
 * is what stops the same drop being reported twice.
 */
function toPriceDrop(row) {
  const current = Number(row.price) || 0;
  const saved = Number(row.price_at_save) || 0;

  // Not cheaper than when it was saved -> nothing to report.
  if (current <= 0 || saved <= 0 || current >= saved) return null;

  const drop = round2(saved - current);

  return {
    product_id: row.product_id,
    name: row.name,
    image_url: row.image_url,
    currency: row.currency,
    old_price: saved,
    new_price: current,
    drop_amount: drop,
    drop_percent: saved > 0 ? Math.round((drop / saved) * 100) : 0,
    notified:
      row.last_alerted_price != null &&
      Number(row.last_alerted_price) === current,
  };
}

/**
 * Every product on the wishlist that is currently cheaper than when it was
 * saved. Read-only.
 *
 * The Wishlist screen uses this (not `checkPriceDrops`) so the green "price
 * dropped" strip and the drop counter stay visible after the notification has
 * already been delivered - the user keeps seeing the saving until they act on it.
 */
export async function collectPriceDrops(userId) {
  const rows = await wishlistPriceRows(userId);
  return rows.map(toPriceDrop).filter(Boolean);
}

/**
 * The notification pass for the SRS "price drop alerts via push notifications"
 * requirement. Only rows whose current price has not been announced yet produce
 * a `price_alerts` row and a notification, so the user is never told the same
 * thing twice.
 *
 * @param {number} userId
 * @param {boolean} silent when true nothing is written (used for a dry run)
 * @returns {Promise<Array>} the drops that were announced
 */
export async function checkPriceDrops(userId, { silent = false } = {}) {
  const rows = await wishlistPriceRows(userId);
  const fired = [];

  for (const row of rows) {
    const drop = toPriceDrop(row);

    // No drop, or this exact price was already announced -> skip.
    if (!drop || drop.notified) continue;

    if (!silent) {
      await run(
        `INSERT INTO price_alerts (user_id, product_id, old_price, new_price, drop_amount)
         VALUES (?, ?, ?, ?, ?)`,
        [
          userId,
          drop.product_id,
          drop.old_price,
          drop.new_price,
          drop.drop_amount,
        ]
      );

      await notify({
        userId,
        actorId: null,
        type: "price_drop",
        message:
          `Price drop! ${drop.name} is now $${drop.new_price.toFixed(2)} ` +
          `(was $${drop.old_price.toFixed(2)}) - save $${drop.drop_amount.toFixed(2)}`,
        referenceId: drop.product_id,
      });

      await run(`UPDATE wishlists SET last_alerted_price = ? WHERE id = ?`, [
        drop.new_price,
        row.wish_id,
      ]);
    }

    fired.push(drop);
  }

  return fired;
}

// ---------------------------------------------------------------------------
// CATALOGUE
// ---------------------------------------------------------------------------

/**
 * GET /api/shop/products
 * Query: category, fandom, brand, q, sort, min_price, max_price,
 *        in_stock, discounted, digital, featured, limit, offset
 */
export const getProducts = asyncHandler(async (req, res) => {
  const { sql, params } = buildWhere(req.query);
  const sort = String(req.query.sort || "featured").toLowerCase();
  const limit = Math.min(parseInt(req.query.limit, 10) || 40, 100);
  const offset = Math.max(parseInt(req.query.offset, 10) || 0, 0);

  const rows = await all(
    `${PRODUCT_SELECT} ${sql} ORDER BY ${orderBy(sort)} LIMIT ? OFFSET ?`,
    [...params, limit, offset]
  );

  const countRow = await get(
    `SELECT COUNT(*) AS total FROM products p ${sql}`,
    params
  );

  const products = await decorateForUser(rows, req.user?.id);

  res.json({
    success: true,
    products,
    total: countRow?.total || products.length,
    limit,
    offset,
    sort,
  });
});

/** GET /api/shop/products/:id -> product details + related products */
export const getProductById = asyncHandler(async (req, res) => {
  const id = parseInt(req.params.id, 10);
  if (Number.isNaN(id)) {
    return res.status(400).json({ success: false, message: "Invalid product id" });
  }

  const row = await get(`${PRODUCT_SELECT} WHERE p.id = ?`, [id]);
  if (!row) {
    return res.status(404).json({ success: false, message: "Product not found" });
  }

  const [product] = await decorateForUser([row], req.user?.id);

  // Related: same fandom first, then same category. Always excludes itself.
  const relatedRows = await all(
    `${PRODUCT_SELECT}
      WHERE p.status = 'active' AND p.id != ?
      ORDER BY
        (CASE WHEN p.fandom = ? THEN 0 ELSE 1 END),
        (CASE WHEN p.category = ? THEN 0 ELSE 1 END),
        p.sold_count DESC
      LIMIT 6`,
    [id, product.fandom || "", product.category]
  );

  const related = await decorateForUser(relatedRows, req.user?.id);

  // Aggregated rating breakdown so the details screen has a rating summary.
  const review = await get(
    `SELECT AVG(rating) AS avg_rating, COUNT(*) AS count
       FROM products WHERE category = ? AND rating > 0`,
    [product.category]
  );

  res.json({
    success: true,
    product,
    related,
    category_average_rating: review?.avg_rating
      ? round2(review.avg_rating)
      : product.rating,
  });
});

/** GET /api/shop/categories -> categories with live product counts */
export const getProductCategories = asyncHandler(async (req, res) => {
  const cached = await cache.get("shop:categories");
  if (cached) return res.json({ success: true, ...cached, cached: true });

  const categories = await all(`
    SELECT
      c.id, c.name, c.slug, c.icon, c.color, c.description, c.sort_order,
      (SELECT COUNT(*) FROM products p
        WHERE p.category = c.name AND p.status = 'active')          AS product_count,
      (SELECT COUNT(*) FROM products p
        WHERE p.category = c.name AND p.status = 'active'
          AND p.old_price IS NOT NULL AND p.old_price > p.price)    AS deal_count,
      (SELECT MIN(p.price) FROM products p
        WHERE p.category = c.name AND p.status = 'active')          AS min_price
    FROM product_categories c
    ORDER BY c.sort_order ASC, c.name ASC
  `);

  const payload = { categories };
  await cache.set("shop:categories", payload, 120);

  res.json({ success: true, ...payload });
});

/** GET /api/shop/fandoms -> fandoms with counts, used by the filter row */
export const getProductFandoms = asyncHandler(async (req, res) => {
  const cached = await cache.get("shop:fandoms");
  if (cached) return res.json({ success: true, ...cached, cached: true });

  const fandoms = await all(`
    SELECT fandom AS name, COUNT(*) AS product_count, MIN(price) AS min_price
      FROM products
     WHERE status = 'active' AND fandom IS NOT NULL AND fandom != ''
     GROUP BY fandom
     ORDER BY product_count DESC, fandom ASC
  `);

  const payload = { fandoms };
  await cache.set("shop:fandoms", payload, 120);

  res.json({ success: true, ...payload });
});

/**
 * GET /api/shop/overview
 * Everything the Shop Home screen needs in one round trip.
 */
export const getShopOverview = asyncHandler(async (req, res) => {
  const userId = req.user?.id ?? null;

  const [stats, featured, deals, newArrivals, bestSellers, categories] =
    await Promise.all([
      get(`SELECT
             (SELECT COUNT(*) FROM products WHERE status = 'active')            AS total_products,
             (SELECT COUNT(*) FROM product_categories)                          AS total_categories,
             (SELECT COUNT(*) FROM products
               WHERE status = 'active' AND stock = 0)                           AS out_of_stock,
             (SELECT COUNT(*) FROM products
               WHERE status = 'active'
                 AND old_price IS NOT NULL AND old_price > price)               AS total_deals,
             (SELECT IFNULL(SUM(sold_count), 0) FROM products)                  AS total_sold
          `),
      all(`${PRODUCT_SELECT} WHERE p.status='active' AND p.is_featured = 1
             ORDER BY p.sold_count DESC LIMIT 6`),
      all(`${PRODUCT_SELECT} WHERE p.status='active'
             AND p.old_price IS NOT NULL AND p.old_price > p.price
           ORDER BY p.discount_percent DESC, p.sold_count DESC LIMIT 6`),
      all(`${PRODUCT_SELECT} WHERE p.status='active'
           ORDER BY p.created_at DESC, p.id DESC LIMIT 6`),
      all(`${PRODUCT_SELECT} WHERE p.status='active'
           ORDER BY p.sold_count DESC LIMIT 6`),
      all(`SELECT c.name, c.icon, c.color, c.slug,
                  (SELECT COUNT(*) FROM products p
                    WHERE p.category = c.name AND p.status='active') AS product_count
             FROM product_categories c
            ORDER BY c.sort_order ASC`),
    ]);

  // Personal counters for the header badges (wishlist / cart / orders).
  let personal = { wishlist_count: 0, cart_count: 0, cart_quantity: 0, orders_count: 0 };

  if (userId) {
    const row = await get(
      `SELECT
         (SELECT COUNT(*) FROM wishlists   WHERE user_id = ?)             AS wishlist_count,
         (SELECT COUNT(*) FROM cart_items  WHERE user_id = ?)             AS cart_count,
         (SELECT IFNULL(SUM(quantity),0) FROM cart_items WHERE user_id = ?) AS cart_quantity,
         (SELECT COUNT(*) FROM orders      WHERE user_id = ?)             AS orders_count`,
      [userId, userId, userId, userId]
    );
    personal = row || personal;
  }

  const decorated = {
    featured: await decorateForUser(featured, userId),
    deals: await decorateForUser(deals, userId),
    new_arrivals: await decorateForUser(newArrivals, userId),
    best_sellers: await decorateForUser(bestSellers, userId),
  };

  res.json({
    success: true,
    stats: {
      total_products: stats?.total_products || 0,
      total_categories: stats?.total_categories || 0,
      out_of_stock: stats?.out_of_stock || 0,
      total_deals: stats?.total_deals || 0,
      total_sold: stats?.total_sold || 0,
      ...personal,
    },
    categories,
    ...decorated,
    shipping: {
      flat_fee: SHIPPING_FLAT,
      free_threshold: FREE_SHIPPING_THRESHOLD,
      currency: "USD",
    },
    promo_codes: Object.entries(PROMO_CODES).map(([code, config]) => ({
      code,
      label: config.label,
      min_subtotal: config.minSubtotal,
    })),
  });
});

// ---------------------------------------------------------------------------
// WISHLIST
// ---------------------------------------------------------------------------

/** GET /api/shop/wishlist -> my wishlist, with any price drops detected */
export const getMyWishlist = asyncHandler(async (req, res) => {
  const userId = req.user.id;

  // Report every drop that is still standing (read-only), so the green strip
  // stays visible after the notification has already been delivered.
  const drops = await collectPriceDrops(userId);
  const dropByProduct = new Map(drops.map((d) => [d.product_id, d]));

  const rows = await all(
    `SELECT
       w.id AS wish_id, w.saved_at, w.price_at_save,
       p.id AS product_id, p.name, p.sku, p.description, p.category, p.fandom,
       p.brand, p.price, p.old_price, p.discount_percent, p.currency,
       p.image_url, p.stock, p.rating, p.rating_count, p.sold_count,
       p.is_featured, p.is_digital,
       (SELECT quantity FROM cart_items c
         WHERE c.user_id = w.user_id AND c.product_id = w.product_id) AS quantity_in_cart
     FROM wishlists w
     JOIN products p ON p.id = w.product_id
     WHERE w.user_id = ?
     ORDER BY w.id DESC`,
    [userId]
  );

  const items = rows.map((row) => {
    const product = shapeProduct(row);
    const drop = dropByProduct.get(row.product_id);

    return {
      ...product,
      wish_id: row.wish_id,
      saved_at: row.saved_at,
      saved_ago: timeAgo(row.saved_at),
      price_at_save: row.price_at_save,
      quantity_in_cart: row.quantity_in_cart || 0,
      is_wishlisted: true,
      // Signed difference: negative means it got cheaper since saving.
      price_change: round2((product.price || 0) - (Number(row.price_at_save) || 0)),
      has_price_drop: !!drop,
      price_drop: drop || null,
    };
  });

  const totalValue = round2(items.reduce((sum, item) => sum + item.price, 0));
  const totalSavings = round2(
    items
      .filter((item) => item.has_discount)
      .reduce((sum, item) => sum + item.savings, 0)
  );

  res.json({
    success: true,
    items,
    count: items.length,
    total_value: totalValue,
    total_savings: totalSavings,
    price_drops: drops.length,
    currency: items[0]?.currency || "USD",
  });
});

/** POST /api/shop/wishlist/:productId -> toggle add / remove */
export const toggleWishlist = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const productId = parseInt(req.params.productId, 10);

  if (Number.isNaN(productId)) {
    return res.status(400).json({ success: false, message: "Invalid product id" });
  }

  const product = await get(
    `SELECT id, name, price FROM products WHERE id = ? AND status = 'active'`,
    [productId]
  );
  if (!product) {
    return res.status(404).json({ success: false, message: "Product not found" });
  }

  const existing = await get(
    `SELECT id FROM wishlists WHERE user_id = ? AND product_id = ?`,
    [userId, productId]
  );

  await cache.invalidate("shop:");

  if (existing) {
    await run(`DELETE FROM wishlists WHERE id = ?`, [existing.id]);
    return res.json({
      success: true,
      wishlisted: false,
      message: `${product.name} removed from your wishlist`,
    });
  }

  // Remember the price at the moment of saving so a later drop can be detected.
  await run(
    `INSERT INTO wishlists (user_id, product_id, price_at_save) VALUES (?, ?, ?)`,
    [userId, productId, product.price]
  );

  res.json({
    success: true,
    wishlisted: true,
    message: `${product.name} added to your wishlist - we will alert you if the price drops`,
  });
});

/** DELETE /api/shop/wishlist/:productId -> explicit remove */
export const removeFromWishlist = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const productId = parseInt(req.params.productId, 10);

  const result = await run(
    `DELETE FROM wishlists WHERE user_id = ? AND product_id = ?`,
    [userId, productId]
  );

  if (!result.changes) {
    return res.status(404).json({ success: false, message: "Not in your wishlist" });
  }

  await cache.invalidate("shop:");
  res.json({ success: true, message: "Removed from wishlist" });
});

/** DELETE /api/shop/wishlist -> clear the whole wishlist */
export const clearWishlist = asyncHandler(async (req, res) => {
  await run(`DELETE FROM wishlists WHERE user_id = ?`, [req.user.id]);
  await cache.invalidate("shop:");
  res.json({ success: true, message: "Wishlist cleared" });
});

/**
 * POST /api/shop/wishlist/alerts/check
 * Runs the price-drop detection and writes the notifications.
 * The frontend calls this when the Shop / Wishlist screens open.
 */
export const runPriceAlertCheck = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const drops = await checkPriceDrops(userId);

  res.json({
    success: true,
    price_drops: drops.length,
    drops,
    message: drops.length
      ? `${drops.length} price drop${drops.length > 1 ? "s" : ""} found on your wishlist`
      : "No price drops right now - we are watching your wishlist",
  });
});

/** GET /api/shop/wishlist/alerts -> alert history */
export const getMyPriceAlerts = asyncHandler(async (req, res) => {
  const alerts = await all(
    `SELECT a.id, a.product_id, a.old_price, a.new_price, a.drop_amount,
            a.is_seen, a.created_at,
            p.name, p.image_url, p.currency, p.price AS current_price
       FROM price_alerts a
       LEFT JOIN products p ON p.id = a.product_id
      WHERE a.user_id = ?
      ORDER BY a.id DESC
      LIMIT 50`,
    [req.user.id]
  );

  await run(`UPDATE price_alerts SET is_seen = 1 WHERE user_id = ?`, [req.user.id]);

  res.json({
    success: true,
    alerts: alerts.map((alert) => ({
      ...alert,
      created_ago: timeAgo(alert.created_at),
      drop_percent:
        alert.old_price > 0
          ? Math.round((alert.drop_amount / alert.old_price) * 100)
          : 0,
    })),
    count: alerts.length,
  });
});

// ---------------------------------------------------------------------------
// CART
// ---------------------------------------------------------------------------

/** GET /api/shop/cart -> cart lines + the bill. Query: promo */
export const getCart = asyncHandler(async (req, res) => {
  const lines = await loadCartLines(req.user.id);
  const bill = buildBill(lines, req.query.promo);

  res.json({ success: true, ...bill });
});

/**
 * POST /api/shop/cart
 * Body: { product_id, quantity }
 * Adding a product that is already in the cart increases its quantity.
 */
export const addToCart = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const productId = parseInt(req.body?.product_id, 10);
  const quantity = Math.max(1, parseInt(req.body?.quantity, 10) || 1);

  if (Number.isNaN(productId)) {
    return res.status(400).json({ success: false, message: "product_id is required" });
  }

  const product = await get(
    `SELECT id, name, price, stock, is_digital FROM products
      WHERE id = ? AND status = 'active'`,
    [productId]
  );

  if (!product) {
    return res.status(404).json({ success: false, message: "Product not found" });
  }
  if (!product.is_digital && product.stock <= 0) {
    return res
      .status(400)
      .json({ success: false, message: `${product.name} is out of stock` });
  }

  const existing = await get(
    `SELECT id, quantity FROM cart_items WHERE user_id = ? AND product_id = ?`,
    [userId, productId]
  );

  const requested = (existing?.quantity || 0) + quantity;

  // Never let the cart exceed the available stock (digital items are unlimited).
  if (!product.is_digital && requested > product.stock) {
    return res.status(400).json({
      success: false,
      message: `Only ${product.stock} unit(s) of ${product.name} are in stock`,
    });
  }

  if (existing) {
    await run(`UPDATE cart_items SET quantity = ? WHERE id = ?`, [
      requested,
      existing.id,
    ]);
  } else {
    await run(
      `INSERT INTO cart_items (user_id, product_id, quantity) VALUES (?, ?, ?)`,
      [userId, productId, quantity]
    );
  }

  const lines = await loadCartLines(userId);
  const bill = buildBill(lines, req.body?.promo);

  res.json({
    success: true,
    message: `${product.name} added to your cart`,
    ...bill,
  });
});

/** PUT /api/shop/cart/:productId -> Body: { quantity } (0 removes the line) */
export const updateCartItem = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const productId = parseInt(req.params.productId, 10);
  const quantity = parseInt(req.body?.quantity, 10);

  if (Number.isNaN(productId) || Number.isNaN(quantity)) {
    return res
      .status(400)
      .json({ success: false, message: "productId and quantity are required" });
  }

  if (quantity <= 0) {
    await run(`DELETE FROM cart_items WHERE user_id = ? AND product_id = ?`, [
      userId,
      productId,
    ]);
    const lines = await loadCartLines(userId);
    return res.json({
      success: true,
      message: "Item removed from your cart",
      ...buildBill(lines, req.body?.promo),
    });
  }

  const product = await get(
    `SELECT name, stock, is_digital FROM products WHERE id = ?`,
    [productId]
  );
  if (!product) {
    return res.status(404).json({ success: false, message: "Product not found" });
  }
  if (!product.is_digital && quantity > product.stock) {
    return res.status(400).json({
      success: false,
      message: `Only ${product.stock} unit(s) of ${product.name} are in stock`,
    });
  }

  const result = await run(
    `UPDATE cart_items SET quantity = ? WHERE user_id = ? AND product_id = ?`,
    [quantity, userId, productId]
  );

  if (!result.changes) {
    return res.status(404).json({ success: false, message: "Item not in your cart" });
  }

  const lines = await loadCartLines(userId);
  res.json({
    success: true,
    message: `Quantity updated to ${quantity}`,
    ...buildBill(lines, req.body?.promo),
  });
});

/** DELETE /api/shop/cart/:productId */
export const removeCartItem = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const productId = parseInt(req.params.productId, 10);

  const result = await run(
    `DELETE FROM cart_items WHERE user_id = ? AND product_id = ?`,
    [userId, productId]
  );

  if (!result.changes) {
    return res.status(404).json({ success: false, message: "Item not in your cart" });
  }

  const lines = await loadCartLines(userId);
  res.json({
    success: true,
    message: "Item removed from your cart",
    ...buildBill(lines, req.query.promo),
  });
});

/** DELETE /api/shop/cart -> empty the cart */
export const clearCart = asyncHandler(async (req, res) => {
  await run(`DELETE FROM cart_items WHERE user_id = ?`, [req.user.id]);
  res.json({ success: true, message: "Cart cleared", ...buildBill([], null) });
});

/**
 * POST /api/shop/cart/summary
 * Body: { promo } - recalculates the bill without changing anything, so the
 * Checkout screen can preview a promo code before confirming.
 */
export const previewBill = asyncHandler(async (req, res) => {
  const lines = await loadCartLines(req.user.id);
  const bill = buildBill(lines, req.body?.promo);

  res.json({
    success: true,
    ...bill,
    promo_valid: !bill.promo_error,
    available_promos: Object.entries(PROMO_CODES).map(([code, config]) => ({
      code,
      label: config.label,
      min_subtotal: config.minSubtotal,
    })),
    payment_methods: PAYMENT_METHODS,
  });
});

// ---------------------------------------------------------------------------
// CHECKOUT (simulated) + ORDERS
// ---------------------------------------------------------------------------

function makeOrderCode() {
  const stamp = Date.now().toString(36).toUpperCase().slice(-5);
  const random = Math.floor(Math.random() * 900 + 100);
  return `FV-${stamp}${random}`;
}

/**
 * POST /api/shop/checkout
 * Body: { shipping_name, shipping_phone, shipping_city, shipping_address,
 *         note, payment_method, promo }
 *
 * Creates the order, copies every cart line into `order_items` and empties the
 * cart. No payment is taken and nothing ships - this is the SRS "simulated
 * checkout ... perform check out to view their bill" requirement.
 */
export const checkout = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const body = req.body || {};

  const lines = await loadCartLines(userId);
  if (!lines.length) {
    return res
      .status(400)
      .json({ success: false, message: "Your cart is empty - add an item first" });
  }

  const bill = buildBill(lines, body.promo);

  if (bill.promo_error) {
    return res.status(400).json({ success: false, message: bill.promo_error });
  }

  const shippingName = String(body.shipping_name || "").trim();
  const shippingCity = String(body.shipping_city || "").trim();
  const shippingAddress = String(body.shipping_address || "").trim();
  const phone = String(body.shipping_phone || "").trim();

  // Digital-only orders do not need an address.
  if (bill.has_physical) {
    if (!shippingName || !shippingCity || !shippingAddress) {
      return res.status(400).json({
        success: false,
        message: "Full name, city and delivery address are required",
      });
    }
  }

  const paymentMethod = PAYMENT_METHODS.includes(body.payment_method)
    ? body.payment_method
    : PAYMENT_METHODS[0];

  const orderCode = makeOrderCode();

  const order = await run(
    `INSERT INTO orders
       (user_id, order_code, item_count, subtotal, discount, shipping_fee, total,
        currency, status, payment_method, shipping_name, shipping_phone,
        shipping_city, shipping_address, note)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'placed', ?, ?, ?, ?, ?, ?)`,
    [
      userId,
      orderCode,
      bill.item_count,
      bill.subtotal,
      bill.discount,
      bill.shipping_fee,
      bill.total,
      bill.currency,
      paymentMethod,
      shippingName || null,
      phone || null,
      shippingCity || null,
      shippingAddress || null,
      body.note ? String(body.note).trim() : null,
    ]
  );

  for (const item of bill.items) {
    await run(
      `INSERT INTO order_items
         (order_id, product_id, name, image_url, unit_price, quantity, line_total)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [
        order.lastID,
        item.product_id,
        item.name,
        item.image_url,
        item.price,
        item.quantity,
        item.line_total,
      ]
    );

    // Reduce stock for physical products (digital items are unlimited).
    if (!item.is_digital) {
      await run(
        `UPDATE products
            SET stock = MAX(0, stock - ?),
                sold_count = sold_count + ?,
                updated_at = CURRENT_TIMESTAMP
          WHERE id = ?`,
        [item.quantity, item.quantity, item.product_id]
      );
    } else {
      await run(
        `UPDATE products SET sold_count = sold_count + ? WHERE id = ?`,
        [item.quantity, item.product_id]
      );
    }
  }

  await run(`DELETE FROM cart_items WHERE user_id = ?`, [userId]);

  await cache.invalidate("shop:");
  await cache.invalidate("events:");

  res.status(201).json({
    success: true,
    message: "Order placed! Your order has been placed successfully.",
    order: {
      id: order.lastID,
      order_code: orderCode,
      item_count: bill.item_count,
      subtotal: bill.subtotal,
      discount: bill.discount,
      shipping_fee: bill.shipping_fee,
      total: bill.total,
      currency: bill.currency,
      status: "placed",
      payment_method: paymentMethod,
      shipping_name: shippingName || null,
      shipping_phone: phone || null,
      shipping_city: shippingCity || null,
      shipping_address: shippingAddress || null,
      note: body.note || null,
      promo_code: bill.promo_code,
      placed_at: new Date().toISOString().slice(0, 19).replace("T", " "),
      items: bill.items.map((item) => ({
        product_id: item.product_id,
        name: item.name,
        image_url: item.image_url,
        unit_price: item.price,
        quantity: item.quantity,
        line_total: item.line_total,
      })),
    },
  });
});

/** GET /api/shop/orders/mine -> purchase history */
export const getMyOrders = asyncHandler(async (req, res) => {
  const orders = await all(
    `SELECT o.*,
            (SELECT COUNT(*) FROM order_items i WHERE i.order_id = o.id) AS line_count,
            (SELECT i.image_url FROM order_items i
              WHERE i.order_id = o.id ORDER BY i.id LIMIT 1)             AS preview_image,
            (SELECT i.name FROM order_items i
              WHERE i.order_id = o.id ORDER BY i.id LIMIT 1)             AS preview_name
       FROM orders o
      WHERE o.user_id = ?
      ORDER BY o.id DESC`,
    [req.user.id]
  );

  const items = await all(
    `SELECT i.* FROM order_items i
      JOIN orders o ON o.id = i.order_id
     WHERE o.user_id = ?
     ORDER BY i.id ASC`,
    [req.user.id]
  );

  const byOrder = new Map();
  for (const item of items) {
    if (!byOrder.has(item.order_id)) byOrder.set(item.order_id, []);
    byOrder.get(item.order_id).push(item);
  }

  const list = orders.map((order) => ({
    ...order,
    placed_ago: timeAgo(order.placed_at),
    items: byOrder.get(order.id) || [],
    additional_items: Math.max(0, (order.line_count || 0) - 1),
  }));

  const totalSpent = round2(list.reduce((sum, order) => sum + (order.total || 0), 0));

  res.json({
    success: true,
    orders: list,
    count: list.length,
    total_spent: totalSpent,
    currency: list[0]?.currency || "USD",
  });
});

/** GET /api/shop/orders/:id -> one order with its line items */
export const getOrderById = asyncHandler(async (req, res) => {
  const id = parseInt(req.params.id, 10);
  if (Number.isNaN(id)) {
    return res.status(400).json({ success: false, message: "Invalid order id" });
  }

  const order = await get(`SELECT * FROM orders WHERE id = ? AND user_id = ?`, [
    id,
    req.user.id,
  ]);

  if (!order) {
    return res.status(404).json({ success: false, message: "Order not found" });
  }

  const items = await all(
    `SELECT * FROM order_items WHERE order_id = ? ORDER BY id ASC`,
    [id]
  );

  const again = await get(
    `SELECT i.product_id, i.name, i.image_url FROM order_items i
      WHERE i.order_id = ? ORDER BY i.id LIMIT 1`,
    [id]
  );

  res.json({
    success: true,
    order: {
      ...order,
      placed_ago: timeAgo(order.placed_at),
      items,
      // Handy for the "Buy again" button on the Order Success screen.
      buy_again_product_id: again?.product_id || null,
    },
  });
});

/** DELETE /api/shop/orders/:id -> remove a saved (simulated) order */
export const deleteOrder = asyncHandler(async (req, res) => {
  const id = parseInt(req.params.id, 10);

  const order = await get(`SELECT id FROM orders WHERE id = ? AND user_id = ?`, [
    id,
    req.user.id,
  ]);
  if (!order) {
    return res.status(404).json({ success: false, message: "Order not found" });
  }

  await run(`DELETE FROM order_items WHERE order_id = ?`, [id]);
  await run(`DELETE FROM orders WHERE id = ?`, [id]);

  res.json({ success: true, message: "Order removed from your history" });
});

export default {
  getProducts,
  getProductById,
  getProductCategories,
  getProductFandoms,
  getShopOverview,
  getMyWishlist,
  toggleWishlist,
  removeFromWishlist,
  clearWishlist,
  runPriceAlertCheck,
  getMyPriceAlerts,
  getCart,
  addToCart,
  updateCartItem,
  removeCartItem,
  clearCart,
  previewBill,
  checkout,
  getMyOrders,
  getOrderById,
  deleteOrder,
  checkPriceDrops,
  collectPriceDrops,
};
