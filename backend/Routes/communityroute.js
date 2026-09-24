/**
 * MEMBER 3 - Search & Community
 * Routes for user profiles, follow, bookmarks (saved posts)
 * and notifications.
 * Base path: /api/community
 */

import express from "express";
import {
  getUserProfile,
  updateMyProfile,
  toggleFollow,
  getFollowers,
  getFollowing,
  getBookmarks,
  toggleBookmark,
  clearBookmarks,
  getNotifications,
  markNotificationRead,
  markAllRead,
  deleteNotification,
  getCommunityOverview,
} from "../Controllers/communitycontroller.js";
import { requireAuth, optionalAuth } from "../middleware/authmiddleware.js";

const router = express.Router();

// ------------------------- my profile / overview -------------------------
router.get("/overview", requireAuth, getCommunityOverview);
router.put("/profile", requireAuth, updateMyProfile);

// ------------------------------- bookmarks -------------------------------
router.get("/bookmarks", requireAuth, getBookmarks);
router.delete("/bookmarks", requireAuth, clearBookmarks);
router.post("/bookmarks/:postId", requireAuth, toggleBookmark);

// ----------------------------- notifications -----------------------------
router.get("/notifications", requireAuth, getNotifications);
router.post("/notifications/read-all", requireAuth, markAllRead);
router.post("/notifications/:id/read", requireAuth, markNotificationRead);
router.delete("/notifications/:id", requireAuth, deleteNotification);

// ------------------------------ user profiles ----------------------------
router.get("/users/:id/profile", optionalAuth, getUserProfile);
router.get("/users/:id/followers", optionalAuth, getFollowers);
router.get("/users/:id/following", optionalAuth, getFollowing);
router.post("/users/:id/follow", requireAuth, toggleFollow);

export default router;
