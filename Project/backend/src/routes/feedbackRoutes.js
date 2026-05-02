import { Router } from "express";
import { listFeedback } from "../controllers/feedbackController.js";
import { requireAuth } from "../middlewares/auth.js";
import { requireRole } from "../middlewares/rbac.js";

const router = Router();

router.use(requireAuth, requireRole("admin"));
router.get("/", listFeedback);

export default router;
