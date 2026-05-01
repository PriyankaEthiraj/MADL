/**
 * Admin routes for managing wards, officers, and complaint overrides
 */

import { Router } from "express";
import {
  listWards,
  getWard,
  addWard,
  modifyWard,
  removeWard,
  listOfficers,
  getOfficer,
  addOfficer,
  modifyOfficer,
  removeOfficer,
  getOfficersByDept,
  getOfficersByWd,
  overrideComplaintAssignment
} from "../controllers/adminController.js";
import { requireAuth } from "../middlewares/auth.js";
import { requireRole } from "../middlewares/rbac.js";
import { validateBody } from "../middlewares/validate.js";
import { z } from "zod";

const router = Router();

// Ensure authentication and admin role for all routes
router.use(requireAuth);
router.use(requireRole("admin"));

// ============ WARD MANAGEMENT ROUTES ============

router.get("/wards", listWards);
router.get("/wards/:id", getWard);
router.post("/wards", validateBody(

  z.object({
    ward_number: z.number(),
    name: z.string().optional(),
    lat_min: z.number(),
    lat_max: z.number(),
    lon_min: z.number(),
    lon_max: z.number()
  })
), addWard);
router.put("/wards/:id", modifyWard);
router.delete("/wards/:id", removeWard);

// ============ OFFICER MANAGEMENT ROUTES ============

router.get("/officers", listOfficers);
router.get("/officers/:id", getOfficer);
router.post("/officers", validateBody(
  z.object({
    name: z.string(),
    email: z.string().email().optional(),
    phone: z.string().optional(),
    department_id: z.number(),
    ward_id: z.number()
  })
), addOfficer);
router.put("/officers/:id", validateBody(
  z.object({
    name: z.string().optional(),
    email: z.string().email().optional(),
    phone: z.string().optional(),
    status: z.enum(["Active", "Inactive"]).optional()
  })
), modifyOfficer);
router.delete("/officers/:id", removeOfficer);

// Get officers by department
router.get("/officers/department/:departmentId", getOfficersByDept);

// Get officers by ward
router.get("/officers/ward/:wardId", getOfficersByWd);

// ============ COMPLAINT OVERRIDE ROUTES ============

router.post("/complaints/:complaintId/override", validateBody(
  z.object({
    new_department_id: z.number().optional(),
    new_officer_id: z.number().optional(),
    reason: z.string().optional()
  })
), overrideComplaintAssignment);

export default router;
