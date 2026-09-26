import express from "express";
import {
  getContactInfo,
  submitInquiry,
} from "../Controllers/contactcontroller.js";

const router = express.Router();

// Contact Us - office details + enquiry form
router.get("/", getContactInfo);
router.post("/", submitInquiry);

export default router;
