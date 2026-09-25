/**
 * MEMBER 2 - Fandom Content routes
 * Mounted at /api/content in server.js
 */

import { Router } from "express";
import {
  getFandomHubs,
  getFandomHub,
  getGlossary,
  getDiscoverFeed,
  getRecentContent,
  getOfflineContent,
  listContent,
  getContentDetails,
  recordView,
  toggleOffline,
  toggleContentLike,
} from "../Controllers/contentcontroller.js";
import { requireAuth, optionalAuth } from "../middleware/authmiddleware.js";

const router = Router();

// Fandom Hub / Explore Fandoms
router.get("/hub", optionalAuth, getFandomHubs);
router.get("/hub/:slug", optionalAuth, getFandomHub);

// Beginner fan hub glossary
router.get("/glossary", optionalAuth, getGlossary);

// Discover feed (mixed media types)
router.get("/discover", optionalAuth, getDiscoverFeed);

// SQLite recent views + offline content (auth required - personal data)
router.get("/recent", requireAuth, getRecentContent);
router.get("/offline", requireAuth, getOfflineContent);

// Filtered content list (type / fandom / hub / search / sort)
router.get("/", optionalAuth, listContent);

// Single item + interactions
router.get("/:id", optionalAuth, getContentDetails);
router.post("/:id/view", optionalAuth, recordView);
router.post("/:id/offline", requireAuth, toggleOffline);
router.post("/:id/like", requireAuth, toggleContentLike);

export default router;
