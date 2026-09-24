import dotenv from "dotenv";

dotenv.config();

import express from "express";
import cors from "cors";
import authRoutes from "./Routes/authroute.js";
import userRoutes from "./Routes/userroute.js";

const app = express();

app.use(cors());
app.use(express.json());

app.use("/api/auth", authRoutes);
app.use("/api/users", userRoutes);

const PORT = process.env.PORT || 5000;

app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});