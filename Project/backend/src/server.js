import http from "http";
import express from "express";
import { Server } from "socket.io";
import axios from "axios";
import swaggerUi from "swagger-ui-express";
import { swaggerSpec } from "./swagger.js";

import { createApp } from "./app.js";
import { env } from "./config/env.js";
import { registerSocketHandlers } from "./sockets/index.js";
import { runMigrations } from "./db/migrations.js";
import { notFoundHandler } from "./middlewares/notFound.js";
import { errorHandler } from "./middlewares/errorHandler.js";

import { classifyComplaint } from "./services/classificationService.js";

// -------------------------------
// FASTAPI ML CALL
// -------------------------------
async function detectCategoryML(text) {
  try {
    const response = await axios.post("http://127.0.0.1:8000/predict", {
      text
    });

    return {
      department: response.data.category,
      confidence: 0.9,
      source: "ML"
    };

  } catch (err) {
    console.log("⚠️ ML failed → Rule-based NLP activated");

    const ruleResult = classifyComplaint(text);

    return {
      ...ruleResult,
      source: "RULE_BASED"
    };
  }
}

// -------------------------------
// START SERVER
// -------------------------------
const startServer = async () => {
  try {
    await runMigrations();

    const app = createApp();
    const server = http.createServer(app);

    const io = new Server(server, {
      cors: { origin: env.corsOrigin, credentials: true }
    });

    registerSocketHandlers(io);
    app.set("io", io);

    app.get("/", (_req, res) => {
      res.json({
        message: "Smart City Backend API",
        health: `/health`,
        docs: `/api-docs`
      });
    });

    // -------------------------------
    // STEP 4: SWAGGER SETUP (ADD HERE)
    // -------------------------------
    app.use("/api-docs", swaggerUi.serve, swaggerUi.setup(swaggerSpec));

    // -------------------------------
    // STEP 5: API ROUTE (ADD HERE)
    // -------------------------------
    app.post("/api/complaint/classify", async (req, res) => {
      try {
        const { description } = req.body;

        if (!description) {
          return res.status(400).json({
            success: false,
            message: "Description is required"
          });
        }

        const result = await detectCategoryML(description);

        return res.json({
          success: true,
          description,
          ...result,
          system: "Hybrid AI (ML + Rule-based fallback)"
        });

      } catch (error) {
        return res.status(500).json({
          success: false,
          message: "Server error"
        });
      }
    });

    // Browser-friendly endpoint so quick URL checks don't return 404.
    app.get("/api/complaint/classify", async (req, res) => {
      try {
        const description = req.query.description;

        if (!description || typeof description !== "string") {
          return res.status(400).json({
            success: false,
            message: "Pass ?description=... in query"
          });
        }

        const result = await detectCategoryML(description);

        return res.json({
          success: true,
          description,
          ...result,
          system: "Hybrid AI (ML + Rule-based fallback)"
        });

      } catch (_error) {
        return res.status(500).json({
          success: false,
          message: "Server error"
        });
      }
    });

    app.use(notFoundHandler);
    app.use(errorHandler);

    // -------------------------------
    // START SERVER
    // -------------------------------
    server.listen(env.port, "0.0.0.0", () => {
      console.log(`\n🚀 Server Started`);
      console.log(`━━━━━━━━━━━━━━━━━━━━`);
      console.log(`🌐 Local: http://localhost:${env.port}`);
      console.log(`📘 Swagger: http://localhost:${env.port}/api-docs`);
      console.log(`━━━━━━━━━━━━━━━━━━━━\n`);
    });

  } catch (err) {
    console.error("❌ Failed to start server", err);
    process.exit(1);
  }
};

startServer();