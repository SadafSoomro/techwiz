import dotenv from "dotenv";
import nodemailer from "nodemailer";

dotenv.config();

export const getTransporter = () => {
  const emailUser = (process.env.EMAIL_USER || "").trim();
  const emailPass = (process.env.EMAIL_PASS || "").replace(/\s+/g, "").trim();

  return nodemailer.createTransport({
    service: "gmail",
    auth: {
      user: emailUser,
      pass: emailPass,
    },
    tls: {
      rejectUnauthorized: false,
    },
  });
};

const transporter = getTransporter();

export default transporter;