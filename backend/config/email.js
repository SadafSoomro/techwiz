import dotenv from "dotenv";
import nodemailer from "nodemailer";

dotenv.config();

console.log("EMAIL USER IN EMAIL.JS:", process.env.EMAIL_USER);
console.log(
    "EMAIL PASSWORD IN EMAIL.JS:",
    process.env.EMAIL_PASS ? "LOADED" : "MISSING"
);

const transporter = nodemailer.createTransport({
    host: "smtp.gmail.com",
    port: 465,
    secure: true,

    auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS
    }
});

export default transporter;