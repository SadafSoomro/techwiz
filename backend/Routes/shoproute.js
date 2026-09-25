/**
 * MEMBER 5 - Merchandise Store
 * Routes for the product catalogue, wishlist, cart, checkout and orders.
 * Base path: /api/shop
 *
 * IMPORTANT: fixed paths (/overview, /categories, /fandoms, /products)
 * are declared BEFORE any "/:id" style route, and the more specific
 * /wishlist/alerts + /cart/summary routes come before their
 * /:productId siblings, so Express never mistakes a name for an id.
 */

import express from "express";
import { requireAuth, optionalAuth } from "../middleware/authmiddleware.js";
import {
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
} from "../Controllers/shopcontroller.js";

const router = express.Router();

// ------------------------------- overview -------------------------------
router.get("/overview", optionalAuth, getShopOverview);

// ------------------------------- filters --------------------------------
router.get("/categories", optionalAuth, getProductCategories);
router.get("/fandoms", optionalAuth, getProductFandoms);

// ------------------------------ catalogue -------------------------------
router.get("/products", optionalAuth, getProducts);
router.get("/products/:id", optionalAuth, getProductById);

// ------------------------ wishlist + price alerts -----------------------
router.get("/wishlist", requireAuth, getMyWishlist);
router.get("/wishlist/alerts", requireAuth, getMyPriceAlerts);
router.post("/wishlist/alerts/check", requireAuth, runPriceAlertCheck);
router.delete("/wishlist", requireAuth, clearWishlist);
router.post("/wishlist/:productId", requireAuth, toggleWishlist);
router.delete("/wishlist/:productId", requireAuth, removeFromWishlist);

// --------------------------------- cart ---------------------------------
router.get("/cart", requireAuth, getCart);
router.post("/cart", requireAuth, addToCart);
router.post("/cart/summary", requireAuth, previewBill);
router.delete("/cart", requireAuth, clearCart);
router.put("/cart/:productId", requireAuth, updateCartItem);
router.delete("/cart/:productId", requireAuth, removeCartItem);

// ------------------------- checkout + orders ----------------------------
router.post("/checkout", requireAuth, checkout);
router.get("/orders/mine", requireAuth, getMyOrders);
router.get("/orders/:id", requireAuth, getOrderById);
router.delete("/orders/:id", requireAuth, deleteOrder);

export default router;
