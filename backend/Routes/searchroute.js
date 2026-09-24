/**
 * MEMBER 3 - Search & Community
 * Routes for search, filters, trending and suggestions.
 * Base path: /api/search
 */

import express from "express";
import {
  search,
  getFilters,
  getTrending,
  getSuggestions,
  getSearchHistory,
  clearSearchHistory,
} from "../Controllers/searchcontroller.js";
import { requireAuth, optionalAuth } from "../middleware/authmiddleware.js";

const router = express.Router();

// Public search (optionalAuth fills req.user when a token is sent)
router.get("/", optionalAuth, search);
router.get("/filters", optionalAuth, getFilters);
router.get("/trending", optionalAuth, getTrending);
router.get("/suggestions", optionalAuth, getSuggestions);

// Personal search history
router.get("/history", requireAuth, getSearchHistory);
router.delete("/history", requireAuth, clearSearchHistory);

export default router;
