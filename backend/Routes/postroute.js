/**
 * MEMBER 3 - Search & Community
 * Routes for posts, deep-dive discussions, likes and comments.
 * Base path: /api/posts
 */

import express from "express";
import {
  getPosts,
  getDiscussions,
  getPostById,
  createPost,
  updatePost,
  deletePost,
  toggleLike,
  getComments,
  addComment,
  deleteComment,
} from "../Controllers/postcontroller.js";
import { requireAuth, optionalAuth } from "../middleware/authmiddleware.js";

const router = express.Router();

// Feed / listing (public, but personalised when logged in)
router.get("/", optionalAuth, getPosts);
router.get("/discussions", optionalAuth, getDiscussions);

// Comments of a specific comment id must be declared before "/:id"
router.delete("/comments/:commentId", requireAuth, deleteComment);

// Single post + comments
router.get("/:id", optionalAuth, getPostById);
router.get("/:id/comments", optionalAuth, getComments);
router.post("/:id/comments", requireAuth, addComment);

// Like toggle
router.post("/:id/like", requireAuth, toggleLike);

// Create / edit / delete
router.post("/", requireAuth, createPost);
router.put("/:id", requireAuth, updatePost);
router.delete("/:id", requireAuth, deletePost);

export default router;
