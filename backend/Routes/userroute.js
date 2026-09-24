import express from "express";
import {
  getAllUsers,
  getUserById,
  deleteUser,
} from "../Controllers/usercontroller.js";

const router = express.Router();

router.get("/getall", getAllUsers);
router.get("/get/:id", getUserById);
router.delete("/delete/:id", deleteUser);

export default router;
