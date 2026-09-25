/**
 * MEMBER 1 - Profile, Fandom Selection & Home routes
 * Mounted at /api/profile in server.js
 */

import { Router } from "express";
import {
  getMyProfile,
  updateMyProfile,
  getAvatars,
  getFandomSelection,
  saveFandomSelection,
  getBadges,
  getInvite,
  claimInvite,
  getTasks,
  completeTask,
  getSettings,
  updateSettings,
  getHomeDashboard,
} from "../Controllers/profilecontroller.js";
import { requireAuth } from "../middleware/authmiddleware.js";

const router = Router();

// Home dashboard aggregate (profile + trending + latest content + next event)
router.get("/home", requireAuth, getHomeDashboard);

// Profile / Edit Profile
router.get("/me", requireAuth, getMyProfile);
router.put("/me", requireAuth, updateMyProfile);
router.get("/avatars", requireAuth, getAvatars);

// Fandom selection
router.get("/fandoms", requireAuth, getFandomSelection);
router.put("/fandoms", requireAuth, saveFandomSelection);

// Public badges
router.get("/badges", requireAuth, getBadges);

// Invite a friend / referral
router.get("/invite", requireAuth, getInvite);
router.post("/invite/claim", requireAuth, claimInvite);

// Social & tasks
router.get("/tasks", requireAuth, getTasks);
router.post("/tasks/:code/complete", requireAuth, completeTask);

// Settings
router.get("/settings", requireAuth, getSettings);
router.put("/settings", requireAuth, updateSettings);

export default router;
