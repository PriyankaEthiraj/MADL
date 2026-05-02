import { Router } from "express";
import { registerUser, loginUser, getCurrentUser, updateUserProfile } from "../controllers/authController.js";
import { validateBody } from "../middlewares/validate.js";
import { registerSchema, loginSchema } from "../validators/authValidators.js";
import { requireAuth } from "../middlewares/auth.js";

const router = Router();

router.post("/register", validateBody(registerSchema), registerUser);
router.post("/login", validateBody(loginSchema), loginUser);
router.get("/me", requireAuth, getCurrentUser);
router.put("/profile", requireAuth, updateUserProfile);

export default router;
