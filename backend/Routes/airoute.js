/**
 * MEMBER 5 - AI Fan Helper
 * Routes for the fandom assistant, its suggestions and chat history.
 * Base path: /api/ai
 *
 * /chat is mounted with optionalAuth so the assistant still answers for a
 * signed-out visitor - the chat history is simply not persisted for them.
 */

import express from "express";
import { requireAuth, optionalAuth } from "../middleware/authmiddleware.js";
import {
  getSuggestions,
  chat,
  getChatHistory,
  clearChatHistory,
  getTopics,
} from "../Controllers/aicontroller.js";

const router = express.Router();

router.get("/suggestions", getSuggestions);
router.get("/topics", getTopics);

router.post("/chat", optionalAuth, chat);

router.get("/history", requireAuth, getChatHistory);
router.delete("/history", requireAuth, clearChatHistory);

export default router;
