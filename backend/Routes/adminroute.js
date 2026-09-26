/**
 * Member 6 - Admin + Security routes.
 *
 * Mounted at /api/admin by server.js. Only `POST /login` is public; every other
 * route sits behind requireAdmin so the panel is unreachable without a valid
 * administrator token.
 */

import express from "express";
import * as admin from "../Controllers/admincontroller.js";
import { requireAdmin } from "../middleware/adminmiddleware.js";

const router = express.Router();

/* ------------------------------- public ------------------------------- */
router.post("/login", admin.adminLogin);

/* ------------------------- everything below is guarded ---------------- */
router.use(requireAdmin);

// session
router.get("/me", admin.getMe);
router.put("/profile", admin.updateProfile);

// dashboard
router.get("/dashboard", admin.getDashboard);

// users
router.get("/users", admin.listUsers);
router.post("/users", admin.createUser);
router.get("/users/:id", admin.getUserDetail);
router.put("/users/:id", admin.updateUser);
router.patch("/users/:id/status", admin.setUserStatus);
router.delete("/users/:id", admin.deleteUser);

// content
router.get("/content", admin.listContent);
router.post("/content", admin.createContent);
router.put("/content/:id", admin.updateContent);
router.delete("/content/:id", admin.deleteContent);

// events
router.get("/events", admin.listEvents);
router.post("/events", admin.createEvent);
router.put("/events/:id", admin.updateEvent);
router.delete("/events/:id", admin.deleteEvent);

// products
router.get("/products", admin.listProducts);
router.post("/products", admin.createProduct);
router.put("/products/:id", admin.updateProduct);
router.delete("/products/:id", admin.deleteProduct);

// categories (product | fandom | event)
router.get("/categories", admin.listCategories);
router.post("/categories", admin.createCategory);
router.put("/categories/:id", admin.updateCategory);
router.delete("/categories/:id", admin.deleteCategory);

// notifications
router.get("/notifications", admin.listNotifications);
router.post("/notifications", admin.sendNotification);
router.delete("/notifications/:id", admin.deleteNotification);

// security
router.get("/security", admin.getSecurity);
router.put("/security/password", admin.updatePassword);
router.put("/security/settings", admin.updateSecuritySettings);

// backup & database
router.get("/backup", admin.getBackupInfo);
router.post("/backup", admin.createBackup);
router.get("/backup/download", admin.downloadBackup);

// logs & analytics
router.get("/logs", admin.getLogs);
router.delete("/logs", admin.clearLogs);

export default router;
