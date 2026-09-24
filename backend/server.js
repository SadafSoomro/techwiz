// Must be the first import: loads backend/.env before other modules run.
import "./config/loadEnv.js";

import express from "express";
import cors from "cors";
import authRoutes from "./Routes/authroute.js";
import userRoutes from "./Routes/userroute.js";
import searchRoutes from "./Routes/searchroute.js";
import postRoutes from "./Routes/postroute.js";
import communityRoutes from "./Routes/communityroute.js";
import eventRoutes from "./Routes/eventroute.js";
import shopRoutes from "./Routes/shoproute.js";
import aiRoutes from "./Routes/airoute.js";
import { initCommunitySchema } from "./database/communitySchema.js";
import { initEventsSchema } from "./database/eventsSchema.js";
import { initShopSchema } from "./database/shopSchema.js";
import cache from "./database/cache.js";

const app = express();

app.use(cors());
app.use(express.json());

// ---------------------------------------------------------------
// Member 3 - Search & Community tables (SQLite replaces PG + Redis)
// ---------------------------------------------------------------
initCommunitySchema();

// ---------------------------------------------------------------
// Member 4 - Events & Maps tables (SQLite replaces PG + Redis)
// ---------------------------------------------------------------
initEventsSchema();

// ---------------------------------------------------------------
// Member 5 - Merchandise Store + AI Fan Helper tables
// ---------------------------------------------------------------
initShopSchema();

// Drop expired cache rows on boot and every 10 minutes.
cache.purgeExpired();
setInterval(() => cache.purgeExpired(), 10 * 60 * 1000);

// ----------------------------- Member 1 -----------------------------
app.use("/api/auth", authRoutes);
app.use("/api/users", userRoutes);

// ----------------------------- Member 3 -----------------------------
app.use("/api/search", searchRoutes);       // search, filters, trending, suggestions
app.use("/api/posts", postRoutes);          // feed, deep dive, likes, comments
app.use("/api/community", communityRoutes); // profiles, follow, bookmarks, notifications

// ----------------------------- Member 4 -----------------------------
app.use("/api/events", eventRoutes);        // events, nearby, calendar, map, tickets

// ----------------------------- Member 5 -----------------------------
app.use("/api/shop", shopRoutes);          // catalogue, wishlist, cart, checkout, orders
app.use("/api/ai", aiRoutes);              // AI Fan Helper chat + suggestions

// Health check
app.get("/api/health", (req, res) => {
  res.json({
    success: true,
    message: "FANDOM VERSE API is running",
    modules: ["auth", "users", "search", "posts", "community", "events", "shop", "ai"],
  });
});

// 404 fallback
app.use((req, res) => {
  res.status(404).json({ success: false, message: `Route not found: ${req.originalUrl}` });
});

const PORT = process.env.PORT || 5000;

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
  console.log("Member 3 API: /api/search, /api/posts, /api/community");
  console.log("Member 4 API: /api/events");
  console.log("Member 5 API: /api/shop, /api/ai");
});