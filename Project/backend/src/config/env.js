import dotenv from "dotenv";

dotenv.config();

export const env = {
  nodeEnv: process.env.NODE_ENV || "development",
  port: Number(process.env.PORT || 4000),
  jwtSecret: process.env.JWT_SECRET || "unsafe_dev_secret",
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || "1d",
  databaseUrl:
    process.env.DATABASE_URL ||
    "postgresql://postgres:password@localhost:5432/smartcity",
  corsOrigin: process.env.CORS_ORIGIN || "http://localhost:5173",
  serverUrl: process.env.SERVER_URL || "http://192.168.1.34:4000",
  uploadDir: process.env.UPLOAD_DIR || "uploads"
};
