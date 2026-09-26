/**
 * Contact Us - enquiry form.
 *
 * SRS: "General Functionalities For Users - Contact Us:
 *        o Inquiry form through which users can submit enquiries
 *        o Contact details about the organization/team that has developed the app
 *        o Google Maps integration for office location(s)"
 *
 * The office location is served from here too, so the app (and the map card in
 * the Contact Us screen) never hard-codes it in two places.
 */

import db from "../database/db.js";

/** Created on first use so no extra migration step is needed. */
const ensureInquiriesTable = () =>
  new Promise((resolve, reject) => {
    db.run(
      `CREATE TABLE IF NOT EXISTS contact_inquiries (
         id         INTEGER PRIMARY KEY AUTOINCREMENT,
         name       TEXT NOT NULL,
         email      TEXT NOT NULL,
         subject    TEXT,
         message    TEXT NOT NULL,
         status     TEXT DEFAULT 'new',
         created_at TEXT DEFAULT CURRENT_TIMESTAMP
       )`,
      (err) => (err ? reject(err) : resolve())
    );
  });

const EMAIL_PATTERN = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;

/** The team the app was built by. */
export const TEAM_OFFICE = {
  name: "FANDOM VERSE Studio",
  email: "support@fandomverse.com",
  phone: "+92 21 3456 7890",
  address: "Aptech Learning, Shahrah-e-Faisal, Karachi",
  city: "Karachi",
  latitude: 24.8607,
  longitude: 67.0011,
  hours: "Mon - Sat, 10:00 AM - 7:00 PM (PKT)",
};

/** GET /api/contact -> team contact details + office location */
export const getContactInfo = (req, res) => {
  res.json({ success: true, office: TEAM_OFFICE });
};

/** POST /api/contact -> store a visitor enquiry and confirm it */
export const submitInquiry = async (req, res) => {
  const name = String(req.body?.name || "").trim();
  const email = String(req.body?.email || "").trim().toLowerCase();
  const subject = String(req.body?.subject || "").trim();
  const message = String(req.body?.message || "").trim();

  if (!name || !email || !message) {
    return res.status(400).json({
      success: false,
      message: "Name, email and message are required",
    });
  }

  if (!EMAIL_PATTERN.test(email)) {
    return res.status(400).json({
      success: false,
      message: "Please enter a valid email address",
    });
  }

  if (message.length > 2000) {
    return res.status(400).json({
      success: false,
      message: "Please keep your message under 2000 characters",
    });
  }

  try {
    await ensureInquiriesTable();
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message });
  }

  db.run(
    `INSERT INTO contact_inquiries (name, email, subject, message)
     VALUES (?, ?, ?, ?)`,
    [name, email, subject || "General enquiry", message],
    function onInsert(err) {
      if (err) {
        return res.status(500).json({ success: false, message: err.message });
      }

      res.status(201).json({
        success: true,
        message:
          "Thanks for reaching out! Your enquiry has been received and our team replies within 2 working days.",
        inquiry_id: this.lastID,
      });
    }
  );
};
