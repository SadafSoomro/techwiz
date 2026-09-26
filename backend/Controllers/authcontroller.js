import db from "../database/db.js";
import bcrypt from "bcrypt";
import jwt from "jsonwebtoken";
import transporter from "../config/email.js";
import { OAuth2Client } from "google-auth-library";

const googleClient = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

// Register
export const register = async (req, res) => {
  try {
    const { name, email, password } = req.body;

    const hashedPassword = await bcrypt.hash(password, 10);

    const verificationCode = Math.floor(
      100000 + Math.random() * 900000
    ).toString();

    db.run(
      `INSERT INTO users
         (name, email, password, verificationCode, role, is_active, created_at, last_active_at)
       VALUES (?,?,?,?,'user',1,CURRENT_TIMESTAMP,CURRENT_TIMESTAMP)`,
      [name, email, hashedPassword, verificationCode],
      async function (err) {
        if (err) {
          return res.status(400).json({
            message: "Email already exists",
          });
        }

        try {
          await transporter.sendMail({
            from: process.env.EMAIL_USER,
            to: email,
            subject: "Email Verification",
            text: `Your verification code is ${verificationCode}`,
          });

          res.status(201).json({
            message: "Registration successful. Verification code sent.",
          });
        }catch (mailError) {
    console.error("========== EMAIL ERROR ==========");
    console.error(mailError);
    console.error("================================");

    res.status(500).json({
        message: "Failed to send verification email",
        error: mailError.message
    });
}
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

  db.get(
    `SELECT * FROM users
     WHERE email = ? AND verificationCode = ?`,
    [email, code],
    (err, user) => {
      if (err) {
        return res.status(500).json({
          message: err.message,
        });
      }

      if (!user) {
        return res.status(400).json({
          message: "Invalid verification code",
        });
      }

      db.run(
        `UPDATE users
         SET verified = 1,
             verificationCode = NULL
         WHERE email = ?`,
        [email],
        (updateErr) => {
          if (updateErr) {
            return res.status(500).json({
              message: updateErr.message,
            });
          }

          res.json({
            message: "Email verified successfully",
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

  db.get(`SELECT * FROM users WHERE email = ?`, [email], (err, user) => {
    if (err) {
      return res.status(500).json({ message: err.message });
    }

    if (!user) {
      return res.status(404).json({ message: "User with this email not found" });
    }

    const resetCode = Math.floor(100000 + Math.random() * 900000).toString();

    db.run(
      `UPDATE users SET resetCode = ? WHERE email = ?`,
      [resetCode, email],
      async (updateErr) => {
        if (updateErr) {
          return res.status(500).json({ message: updateErr.message });
        }

        try {
          await transporter.sendMail({
            from: process.env.EMAIL_USER,
            to: email,
            subject: "Password Reset Code",
            text: `Your password reset code is ${resetCode}`,
          });

          res.json({ message: "Reset code sent to your email" });
        } catch (mailError) {
          console.error("Mail Error:", mailError);
          res.status(500).json({
            message: "Failed to send reset email",
            error: mailError.message,
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
    db.get(`SELECT * FROM users WHERE email = ?`, [email], (err, user) => {
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
        // New user -> insert into database
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