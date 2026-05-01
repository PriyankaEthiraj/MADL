import { Router } from "express";
import {
  createComplaint,
  listComplaints,
  getComplaint,
  assignComplaintToDepartment,
  updateComplaintStatus,
  addFeedback,
  submitSimpleComplaint,
  verifyResolution,
  uploadResolutionProof,
  approveProof
} from "../controllers/complaintsController.js";
import { requireAuth } from "../middlewares/auth.js";
import { requireRole } from "../middlewares/rbac.js";
import { validateBody } from "../middlewares/validate.js";
import {
  createComplaintSchema,
  assignComplaintSchema,
  statusUpdateSchema,
  resolutionVerificationSchema
} from "../validators/complaintValidators.js";
import { feedbackSchema } from "../validators/feedbackValidators.js";
import { upload, uploadMultiple, uploadProof } from "../middlewares/upload.js";
import { z } from "zod";

const router = Router();

// Public endpoint for simple complaint submission (requires authentication)
router.post(
  "/submit",
  requireAuth,
  validateBody(
    z.object({
      description: z.string(),
      type: z.string().optional(),
      latitude: z.number(),
      longitude: z.number(),
      location: z.string().optional()
    })
  ),
  submitSimpleComplaint
);

// All other routes require authentication
router.use(requireAuth);

router.post(
  "/verify-resolution",
  requireRole("admin", "department"),
  validateBody(resolutionVerificationSchema),
  verifyResolution
);

router.post(
  "/:id/approve-proof",
  requireRole("citizen"),
  approveProof
);

router.post(
  "/upload-proof",
  requireRole("admin", "department"),
  (req, res, next) => {
    uploadProof.single("proof")(req, res, (err) => {
      if (err) {
        return res.status(400).json({ message: err.message || "Proof upload failed" });
      }
      next();
    });
  },
  uploadResolutionProof
);

router.get("/", listComplaints);
router.get("/:id", getComplaint);

router.post(
  "/",
  requireRole("citizen"),
  (req, res, next) => {
    // Handle both single file and multiple files
    uploadMultiple.fields([
      { name: 'photo', maxCount: 1 },
      { name: 'video', maxCount: 1 }
    ])(req, res, (err) => {
      if (err) {
        return res.status(400).json({ message: err.message || "File upload failed" });
      }
      next();
    });
  },
  validateBody(createComplaintSchema),
  createComplaint
);

router.post(
  "/:id/assign",
  requireRole("admin"),
  validateBody(assignComplaintSchema),
  assignComplaintToDepartment
);

router.post(
  "/:id/status",
  requireRole("admin", "department"),
  validateBody(statusUpdateSchema),
  updateComplaintStatus
);

router.post(
  "/:id/feedback",
  requireRole("citizen"),
  validateBody(feedbackSchema),
  addFeedback
);

export default router;
