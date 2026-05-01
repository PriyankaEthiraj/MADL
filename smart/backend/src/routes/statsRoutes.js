import { Router } from "express";
import { getStats } from "../controllers/statsController.js";
import { requireAuth } from "../middlewares/auth.js";
import { requireRole } from "../middlewares/rbac.js";

const router = Router();

router.use(requireAuth, requireRole("admin"));
router.get("/", getStats);

export default router;
