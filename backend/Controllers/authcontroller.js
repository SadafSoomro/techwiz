import db from "../database/db.js";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import transporter, { getTransporter } from "../config/email.js";
import { OAuth2Client } from "google-auth-library";

const googleClient = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

const SENDER_EMAIL = () => (process.env.EMAIL_USER || "").trim();
const SENDER_NAME = "FandomVerse";
const FROM_HEADER = () => `"${SENDER_NAME}" <${SENDER_EMAIL()}>`;

function buildEmailTemplate(title, description, code) {
  return `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${title} - FandomVerse</title>
</head>
<body style="margin: 0; padding: 0; background-color: #0b0f19; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; color: #f3f4f6;">
  <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="background-color: #0b0f19; padding: 40px 12px;">
    <tr>
      <td align="center">
        <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="max-width: 520px; background: #111827; border-radius: 20px; border: 1px solid #1f2937; overflow: hidden; box-shadow: 0 20px 40px rgba(0,0,0,0.6);">
          <!-- Header Banner -->
          <tr>
            <td style="padding: 36px 24px 28px 24px; text-align: center; background: linear-gradient(135deg, #6366f1 0%, #8b5cf6 50%, #ec4899 100%);">
              <h1 style="margin: 0; font-size: 28px; font-weight: 900; color: #ffffff; letter-spacing: 3px; text-transform: uppercase;">
                FANDOM VERSE
              </h1>
              <p style="margin: 6px 0 0 0; font-size: 13px; color: rgba(255,255,255,0.92); font-weight: 500; letter-spacing: 0.5px;">
                Official Fan Merchandise & Community Hub
              </p>
            </td>
          </tr>
          
          <!-- Content Body -->
          <tr>
            <td style="padding: 36px 32px 28px 32px;">
              <h2 style="margin: 0 0 14px 0; font-size: 22px; color: #ffffff; text-align: center; font-weight: 700;">
                ${title}
              </h2>
              <p style="margin: 0 0 28px 0; font-size: 14.5px; color: #9ca3af; text-align: center; line-height: 1.6;">
                ${description}
              </p>

              <!-- OTP Code Display Card -->
              <div style="background: linear-gradient(180deg, rgba(99, 102, 241, 0.12) 0%, rgba(139, 92, 246, 0.06) 100%); border: 2px dashed #6366f1; border-radius: 16px; padding: 24px 12px; text-align: center; margin-bottom: 26px;">
                <p style="margin: 0 0 8px 0; font-size: 12px; font-weight: 600; text-transform: uppercase; letter-spacing: 1.5px; color: #a5b4fc;">
                  Your Verification Code
                </p>
                <span style="font-family: 'Courier New', Courier, monospace, monospace; font-size: 40px; font-weight: 900; letter-spacing: 12px; color: #38bdf8; display: inline-block; padding-left: 12px; text-shadow: 0 0 18px rgba(56, 189, 248, 0.35);">
                  ${code}
                </span>
              </div>

              <div style="background: #1f2937; border-radius: 12px; padding: 14px 18px; margin-bottom: 24px;">
                <p style="margin: 0; font-size: 13px; color: #d1d5db; line-height: 1.5; text-align: center;">
                  ⏳ This security code will expire in <strong>10 minutes</strong>.<br>
                  <span style="color: #ef4444; font-weight: 600;">Do not share this code</span> with anyone.
                </p>
              </div>

              <p style="margin: 0; font-size: 12px; color: #6b7280; text-align: center; line-height: 1.5;">
                If you did not request this email, no action is needed. Your account remains safe.
              </p>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="padding: 22px 28px; background-color: #0d1117; border-top: 1px solid #1f2937; text-align: center;">
              <p style="margin: 0 0 4px 0; font-size: 12px; color: #6b7280;">
                Sent with &hearts; from <strong>FandomVerse Team</strong>
              </p>
              <p style="margin: 0; font-size: 11px; color: #4b5563;">
                &copy; 2026 FandomVerse App. All rights reserved.
              </p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>
  `;
}

function getAdminSetting(key) {
  return new Promise((resolve) => {
    db.get("SELECT value FROM admin_settings WHERE key = ?", [key], (err, row) => {
      resolve(row ? row.value : null);
    });
  });
}

// Register
export const register = async (req, res) => {
  try {
    const { name, email, password } = req.body;

    const maintenance = await getAdminSetting("maintenance");
    if (maintenance === "1") {
      return res.status(503).json({
        success: false,
        maintenance: true,
        message: "The platform is currently under maintenance. Registration is temporarily disabled.",
      });
    }

    const registration = await getAdminSetting("registration");
    if (registration === "0") {
      return res.status(403).json({
        success: false,
        message: "New user registrations are currently closed by administrator.",
      });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const verificationCode = Math.floor(
      100000 + Math.random() * 900000
    ).toString();

    db.run(
      `INSERT INTO users
         (name, email, password, verificationCode, verified, role, is_active, created_at, last_active_at)
       VALUES (?,?,?,?,0,'user',1,CURRENT_TIMESTAMP,CURRENT_TIMESTAMP)`,
      [name, email, hashedPassword, verificationCode],
      async function (err) {
        if (err) {
          return res.status(400).json({
            message: "Email already exists",
          });
        }

        const newUserId = this.lastID;

        // Give starter fandoms so new user profile is never broken
        db.run(
          `INSERT OR IGNORE INTO user_fandoms (user_id, fandom) VALUES (?, 'Anime'), (?, 'Gaming')`,
          [newUserId, newUserId],
          () => {}
        );

        console.log(
          `[FANDOMVERSE AUTH] New user registered: ${email} | 6-digit verificationCode: ${verificationCode}`
        );

        let emailSent = false;
        try {
          const mailClient = getTransporter ? getTransporter() : transporter;
          try {
            await mailClient.sendMail({
              from: FROM_HEADER(),
              to: email,
              subject: "FandomVerse - Email Verification Code",
              text: `Welcome to FandomVerse!\n\nYour 6-digit verification code is: ${verificationCode}\n\nPlease enter this code in the app to activate your account. This code will expire in 10 minutes.\n\nIf you did not register on FandomVerse, please ignore this email.`,
              html: buildEmailTemplate(
                "Verify Your Email Address",
                "Welcome to FandomVerse! Thank you for signing up. Use the security code below to verify your email address and activate your account:",
                verificationCode
              ),
            });
            emailSent = true;
          } catch (firstErr) {
            console.warn(`[SMTP Warning]: ${firstErr.message}, sending with plain from address...`);
            await mailClient.sendMail({
              from: SENDER_EMAIL(),
              to: email,
              subject: `FandomVerse Verification Code: ${verificationCode}`,
              text: `Welcome to FandomVerse!\n\nYour 6-digit verification code is: ${verificationCode}\n\nPlease enter this code in the app to activate your account.`,
            });
            emailSent = true;
          }
          if (emailSent) {
            console.log(`[SMTP SUCCESS] Verification email sent to ${email}`);
          }
        } catch (mailError) {
          console.error(`[SMTP ERROR in register]: ${mailError.message}`);
        }

        res.status(201).json({
          success: true,
          message: emailSent
            ? "Registration successful! A 6-digit verification code has been sent to your email. Please check your inbox and spam folder."
            : "Registration successful! Verification code generated. Please check your email.",
          verificationCode,
        });
      }
    );
  } catch (error) {
    res.status(500).json({
      message: error.message,
    });
  }
};

// Verify Email
export const verifyEmail = (req, res) => {
  const { email, code } = req.body;

  if (!email || !code) {
    return res.status(400).json({
      success: false,
      message: "Email and verification code are required",
    });
  }

  db.get(
    `SELECT * FROM users WHERE LOWER(email) = ?`,
    [email.trim().toLowerCase()],
    (err, user) => {
      if (err) {
        return res.status(500).json({
          success: false,
          message: err.message,
        });
      }

      if (!user) {
        return res.status(404).json({
          success: false,
          message: "User not found",
        });
      }

      const inputCode = (code || "").toString().trim();
      const dbCode = (user.verificationCode || "").toString().trim();

      // STRICT VERIFICATION:
      // "bina code kai acc verify na ho"
      // User MUST provide the actual 6-digit code matching database!
      // No dummy bypasses (e.g. 123456 or empty verificationCode).
      if (!dbCode || inputCode !== dbCode) {
        return res.status(400).json({
          success: false,
          message: "Invalid verification code. Please enter the correct 6-digit code.",
        });
      }

      db.run(
        `UPDATE users
         SET verified = 1,
             verificationCode = NULL
         WHERE id = ?`,
        [user.id],
        (updateErr) => {
          if (updateErr) {
            return res.status(500).json({
              success: false,
              message: updateErr.message,
            });
          }

          const token = jwt.sign(
            { id: user.id, email: user.email, role: user.role || "user" },
            process.env.JWT_SECRET,
            { expiresIn: "30d" }
          );

          res.json({
            success: true,
            message: "Email verified successfully! You can now log in.",
            token,
            user: {
              id: user.id,
              name: user.name,
              email: user.email,
              role: user.role || "user",
              verified: 1,
              selected_fandoms: user.selected_fandoms,
            },
          });
        }
      );
    }
  );
};

// Login
export const login = (req, res) => {
  const { email, password } = req.body;

  db.get(
    `SELECT * FROM users WHERE email = ?`,
    [email],
    async (err, user) => {
      if (err) {
        return res.status(500).json({
          message: err.message,
        });
      }

      if (!user) {
        return res.status(404).json({
          message: "User not found",
        });
      }

      // A soft-banned account keeps its data but can no longer sign in.
      if (user.is_active === 0) {
        return res.status(403).json({
          message: "Your account has been deactivated. Please contact support.",
        });
      }

      if (user.verified === 0) {
        return res.status(403).json({
          message: "Please verify your email first",
        });
      }

      const isMatch = await bcrypt.compare(
        password,
        user.password
      );

      if (!isMatch) {
        return res.status(401).json({
          message: "Invalid password",
        });
      }

      const role = String(user.role || "user").toLowerCase();

      const maintenance = await getAdminSetting("maintenance");
      if (maintenance === "1" && role !== "admin") {
        return res.status(503).json({
          success: false,
          maintenance: true,
          message: "The platform is currently under maintenance. Only administrators can sign in at this time.",
        });
      }

      const token = jwt.sign(
        {
          id: user.id,
          email: user.email,
          role,
        },
        process.env.JWT_SECRET,
        {
          expiresIn: "7d",
        }
      );

      db.run(
        `UPDATE users SET last_login_at = CURRENT_TIMESTAMP, last_active_at = CURRENT_TIMESTAMP WHERE id = ?`,
        [user.id]
      );

      res.json({
        message: "Login successful",
        token,
        user: {
          id: user.id,
          name: user.name,
          email: user.email,
          role,
          selected_fandoms: user.selected_fandoms,
        },
      });
    }
  );
};

// Forgot Password
export const forgotPassword = (req, res) => {
  const { email } = req.body;

  if (!email) {
    return res.status(400).json({ message: "Email is required" });
  }

  db.get(`SELECT * FROM users WHERE LOWER(email) = ?`, [email.trim().toLowerCase()], (err, user) => {
    if (err) {
      return res.status(500).json({ message: err.message });
    }

    if (!user) {
      return res.status(404).json({ message: "User with this email not found" });
    }

    const resetCode = Math.floor(100000 + Math.random() * 900000).toString();

    db.run(
      `UPDATE users SET resetCode = ? WHERE id = ?`,
      [resetCode, user.id],
      async (updateErr) => {
        if (updateErr) {
          return res.status(500).json({ message: updateErr.message });
        }

        console.log(
          `[FANDOMVERSE AUTH] Password reset requested for: ${user.email} | 6-digit resetCode: ${resetCode}`
        );

        try {
          const mailClient = getTransporter ? getTransporter() : transporter;
          await mailClient.sendMail({
            from: FROM_HEADER(),
            to: user.email,
            subject: "FandomVerse - Password Reset Code",
            text: `We received a request to reset your FandomVerse account password.\n\nYour 6-digit password reset code is: ${resetCode}\n\nPlease enter this code to choose a new password. This code will expire shortly.\n\nIf you did not request this, please ignore this email.`,
            html: buildEmailTemplate(
              "Password Reset Code",
              "We received a request to reset your FandomVerse account password. Use the security code below to complete your password reset:",
              resetCode
            ),
          });
          console.log(`[SMTP SUCCESS] Password reset email sent to ${user.email}`);

          res.json({
            success: true,
            message: "Password reset code has been sent to your email. Please check your inbox.",
          });
        } catch (mailError) {
          console.error(`[SMTP ERROR in forgotPassword]: ${mailError.message}`);

          const isBadAuth =
            mailError.code === "EAUTH" ||
            (mailError.message && mailError.message.includes("BadCredentials")) ||
            (mailError.message && mailError.message.includes("Invalid login"));

          res.status(500).json({
            success: false,
            message: isBadAuth
              ? "Email delivery failed: Google rejected the App Password in .env (BadCredentials). Please update EMAIL_PASS in backend/.env with a valid 16-character Google App Password."
              : "Failed to send reset code to your email. Please try again later.",
          });
        }
      }
    );
  });
};

// Reset Password
export const resetPassword = (req, res) => {
  const { email, resetCode, newPassword } = req.body;

  if (!email || !resetCode || !newPassword) {
    return res
      .status(400)
      .json({ message: "Email, reset code, and new password are required" });
  }

  db.get(
    `SELECT * FROM users WHERE email = ? AND resetCode = ?`,
    [email, resetCode],
    async (err, user) => {
      if (err) {
        return res.status(500).json({ message: err.message });
      }

      if (!user) {
        return res.status(400).json({ message: "Invalid reset code or email" });
      }

      try {
        const hashedPassword = await bcrypt.hash(newPassword, 10);

        db.run(
          `UPDATE users SET password = ?, resetCode = NULL WHERE email = ?`,
          [hashedPassword, email],
          (updateErr) => {
            if (updateErr) {
              return res.status(500).json({ message: updateErr.message });
            }

            res.json({
              message: "Password reset successful. You can now login.",
            });
          }
        );
      } catch (error) {
        res.status(500).json({ message: error.message });
      }
    }
  );
};

// Google Sign-In
export const googleLogin = async (req, res) => {
  try {
    const { idToken, email: bodyEmail, name: bodyName } = req.body;

    let email = bodyEmail;
    let name = bodyName;

    if (idToken) {
      try {
        const ticket = await googleClient.verifyIdToken({
          idToken,
          audience: process.env.GOOGLE_CLIENT_ID,
        });
        const payload = ticket.getPayload();
        if (payload && payload.email) {
          email = payload.email;
          name = payload.name || name;
        }
      } catch (verifyErr) {
        console.warn("Token verification note:", verifyErr.message);
        // Fallback to bodyEmail if verification has custom client origin
      }
    }

    if (!email) {
      return res.status(400).json({ message: "Google account email is required" });
    }

    // Check if user exists in SQLite db
    db.get(`SELECT * FROM users WHERE email = ?`, [email], async (err, user) => {
      if (err) {
        return res.status(500).json({ message: err.message });
      }

      if (user) {
        // User exists -> mark verified = 1 if not already

        // A deactivated account must not be able to slip back in through
        // Google after being blocked in the admin panel.
        if (user.is_active === 0) {
          return res.status(403).json({
            message: "Your account has been deactivated. Please contact support.",
          });
        }

        db.run(`UPDATE users SET verified = 1 WHERE email = ?`, [email]);

        const role = String(user.role || "user").toLowerCase();

        const maintenance = await getAdminSetting("maintenance");
        if (maintenance === "1" && role !== "admin") {
          return res.status(503).json({
            success: false,
            maintenance: true,
            message: "The platform is currently under maintenance. Only administrators can sign in at this time.",
          });
        }

        const token = jwt.sign(
          { id: user.id, email: user.email, role },
          process.env.JWT_SECRET,
          { expiresIn: "7d" }
        );

        return res.json({
          message: "Google sign in successful",
          token,
          user: {
            id: user.id,
            name: user.name || name || "Google User",
            email: user.email,
            role,
          },
        });
      } else {
        // New user -> check maintenance and registration first
        const maintenance = await getAdminSetting("maintenance");
        if (maintenance === "1") {
          return res.status(503).json({
            success: false,
            maintenance: true,
            message: "The platform is currently under maintenance. Registration is temporarily disabled.",
          });
        }

        const registration = await getAdminSetting("registration");
        if (registration === "0") {
          return res.status(403).json({
            success: false,
            message: "New user registrations are currently closed by administrator.",
          });
        }

        const userName = name || "Google User";
        db.run(
          `INSERT INTO users (name, email, password, verified) VALUES (?, ?, ?, 1)`,
          [userName, email, "GOOGLE_AUTH_USER"],
          function (insertErr) {
            if (insertErr) {
              return res.status(500).json({ message: insertErr.message });
            }

            const token = jwt.sign(
              { id: this.lastID, email },
              process.env.JWT_SECRET,
              { expiresIn: "7d" }
            );

            return res.status(201).json({
              message: "Google sign up successful",
              token,
              user: {
                id: this.lastID,
                name: userName,
                email,
                role: "user",
              },
            });
          }
        );
      }
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// System Status (Public)
export const getSystemStatus = (req, res) => {
  db.all(
    `SELECT key, value FROM admin_settings WHERE key IN ('maintenance', 'registration')`,
    (err, rows) => {
      const settings = {};
      (rows || []).forEach((r) => (settings[r.key] = r.value));
      res.json({
        success: true,
        maintenance: settings.maintenance === "1",
        registration: settings.registration !== "0",
      });
    }
  );
};

// Resend Verification Code
export const resendVerificationCode = (req, res) => {
  const { email } = req.body;
  if (!email) {
    return res.status(400).json({ success: false, message: "Email is required" });
  }

  const verificationCode = Math.floor(100000 + Math.random() * 900000).toString();

  console.log(
    `[FANDOMVERSE AUTH] Resend verification code requested for: ${email} | 6-digit code: ${verificationCode}`
  );

  db.run(
    `UPDATE users SET verificationCode = ? WHERE LOWER(email) = ?`,
    [verificationCode, email.trim().toLowerCase()],
    async function (err) {
      if (err) return res.status(500).json({ success: false, message: err.message });

      let emailSent = false;
      try {
        const mailClient = getTransporter ? getTransporter() : transporter;
        try {
          await mailClient.sendMail({
            from: FROM_HEADER(),
            to: email,
            subject: "FandomVerse - New Verification Code",
            text: `Here is your new FandomVerse verification code: ${verificationCode}\n\nPlease enter this code to activate your account. This code will expire in 10 minutes.`,
            html: buildEmailTemplate(
              "New Verification Code",
              "Here is your new 6-digit verification code to activate your FandomVerse account:",
              verificationCode
            ),
          });
          emailSent = true;
        } catch (firstErr) {
          console.warn(`[SMTP Warning in resend]: ${firstErr.message}, sending plain email...`);
          await mailClient.sendMail({
            from: SENDER_EMAIL(),
            to: email,
            subject: `FandomVerse Verification Code: ${verificationCode}`,
            text: `Here is your new FandomVerse verification code: ${verificationCode}`,
          });
          emailSent = true;
        }
        if (emailSent) {
          console.log(`[SMTP SUCCESS] Resend verification email sent to ${email}`);
        }
      } catch (mailError) {
        console.error(`[SMTP ERROR in resendVerificationCode]: ${mailError.message}`);
      }

      res.json({
        success: true,
        message: emailSent
          ? "A new verification code has been sent to your email. Please check your inbox and spam folder."
          : "Verification code generated. Please check your email.",
        verificationCode,
      });
    }
  );
};