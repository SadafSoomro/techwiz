import db from "../database/db.js";

// Get All Users
export const getAllUsers = (req, res) => {
  db.all(
    `SELECT id, name, email, verified FROM users`,
    [],
    (err, rows) => {
      if (err) {
        return res.status(500).json({
          message: err.message,
        });
      }

      res.status(200).json({
        success: true,
        count: rows.length,
        users: rows,
      });
    }
  );
};

// Get Single User by ID
export const getUserById = (req, res) => {
  const { id } = req.params;

  db.get(
    `SELECT id, name, email, verified FROM users WHERE id = ?`,
    [id],
    (err, user) => {
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

      res.status(200).json({
        success: true,
        user,
      });
    }
  );
};

// Delete User by ID
export const deleteUser = (req, res) => {
  const { id } = req.params;

  db.run(`DELETE FROM users WHERE id = ?`, [id], function (err) {
    if (err) {
      return res.status(500).json({
        message: err.message,
      });
    }

    if (this.changes === 0) {
      return res.status(404).json({
        message: "User not found",
      });
    }

    res.status(200).json({
      success: true,
      message: "User deleted successfully",
    });
  });
};
