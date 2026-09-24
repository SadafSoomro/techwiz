/**
 * MEMBER 4 - Events & Maps
 * Routes for events, nearby discovery, calendar, map pins and tickets.
 * Base path: /api/events
 *
 * IMPORTANT: every fixed path (/nearby, /map, /categories, /cities,
 * /calendar, /overview, /saved, /tickets) is declared BEFORE "/:id"
 * so Express does not treat them as an id.
 */

import express from "express";
import {
  getEvents,
  getNearbyEvents,
  getMapPins,
  getEventCategories,
  getEventCities,
  getEventCalendar,
  getEventById,
  createEvent,
  updateEvent,
  deleteEvent,
  toggleSaveEvent,
  getMySavedEvents,
  bookTicket,
  getMyTickets,
  getTicketById,
  cancelTicket,
  getEventsOverview,
} from "../Controllers/eventcontroller.js";
import { requireAuth, optionalAuth } from "../middleware/authmiddleware.js";

const router = express.Router();

// ------------------------- discovery / listing -------------------------
router.get("/", optionalAuth, getEvents);
router.get("/nearby", optionalAuth, getNearbyEvents);
router.get("/map", optionalAuth, getMapPins);
router.get("/overview", optionalAuth, getEventsOverview);

// ------------------------ filters (city/category) ----------------------
router.get("/categories", optionalAuth, getEventCategories);
router.get("/cities", optionalAuth, getEventCities);

// ------------------------------ calendar -------------------------------
router.get("/calendar", optionalAuth, getEventCalendar);

// -------------------------- saved / interested -------------------------
router.get("/saved/mine", requireAuth, getMySavedEvents);

// ------------------------------- tickets -------------------------------
router.get("/tickets/mine", requireAuth, getMyTickets);
router.get("/tickets/:ticketId", requireAuth, getTicketById);
router.delete("/tickets/:ticketId", requireAuth, cancelTicket);

// --------------------------- create / manage ---------------------------
router.post("/", requireAuth, createEvent);

// --------------------------- single event ------------------------------
router.get("/:id", optionalAuth, getEventById);
router.put("/:id", requireAuth, updateEvent);
router.delete("/:id", requireAuth, deleteEvent);

// --------------------------- event actions -----------------------------
router.post("/:id/save", requireAuth, toggleSaveEvent);
router.post("/:id/tickets", requireAuth, bookTicket);

export default router;
