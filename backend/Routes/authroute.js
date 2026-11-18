import express from "express";
import {
  register,
  verifyEmail,
  login,
  forgotPassword,
  resetPassword,
  googleLogin,
  getSystemStatus,
  resendVerificationCode,
} from "../Controllers/authcontroller.js";

const router = express.Router();

router.get("/system-status", getSystemStatus);
router.post("/register", register);
router.post("/verify-email", verifyEmail);
router.post("/resend-code", resendVerificationCode);
router.post("/login", login);
router.post("/forgot-password", forgotPassword);
router.post("/reset-password", resetPassword);
router.post("/google", googleLogin);

export default router;