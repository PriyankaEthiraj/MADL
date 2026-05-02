import express from "express";
import cors from "cors";
import helmet from "helmet";
import morgan from "morgan";
import rateLimit from "express-rate-limit";
import path from "path";
import { env } from "./config/env.js";
import authRoutes from "./routes/authRoutes.js";
import complaintsRoutes from "./routes/complaintsRoutes.js";
import departmentsRoutes from "./routes/departmentsRoutes.js";
import feedbackRoutes from "./routes/feedbackRoutes.js";
import statsRoutes from "./routes/statsRoutes.js";
import adminRoutes from "./routes/adminRoutes.js";

export const createApp = () => {
  const app = express();

  app.use(
    cors({
      origin: env.corsOrigin,
      credentials: true
    })
  );
  app.use(
    helmet({
      crossOriginResourcePolicy: { policy: "cross-origin" }
    })
  );
  app.use(express.json({ limit: "2mb" }));
  app.use(express.urlencoded({ extended: true }));
  app.use(morgan("dev"));
  app.use(
    rateLimit({
      windowMs: 15 * 60 * 1000,
      limit: 200
    })
  );

  app.use("/uploads", express.static(path.resolve(env.uploadDir)));

  app.get("/health", (_req, res) => res.json({ status: "ok" }));
  app.get("/api/health", (_req, res) => res.json({ status: "ok" }));

  app.use("/api/auth", authRoutes);
  app.use("/api/complaints", complaintsRoutes);
  app.use("/api/departments", departmentsRoutes);
  app.use("/api/feedback", feedbackRoutes);
  app.use("/api/stats", statsRoutes);
  app.use("/api/admin", adminRoutes);

  return app;
};
