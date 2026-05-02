/**
 * Admin controller for managing wards and officers
 */

import {
  getAllWards,
  getWardById,
  createWard,
  updateWard,
  deleteWard
} from "../services/geolocationService.js";
import {
  getAllOfficers,
  getOfficersByDepartment,
  getOfficersByWard,
  getOfficerById,
  createOfficer,
  updateOfficer,
  deleteOfficer,
  getOfficerWorkload,
  logOverrideAction
} from "../services/officerService.js";
import { ok, created } from "../utils/responses.js";
import { notFound, badRequest } from "../utils/errors.js";
import { pool } from "../db/pool.js";

// ============ WARD MANAGEMENT ============

export const listWards = async (req, res, next) => {
  try {
    const wards = await getAllWards();
    return ok(res, { items: wards }, "wards list");
  } catch (err) {
    return next(err);
  }
};

export const getWard = async (req, res, next) => {
  try {
    const wardId = Number(req.params.id);
    const ward = await getWardById(wardId);
    if (!ward) throw notFound("Ward not found");
    return ok(res, ward, "ward details");
  } catch (err) {
    return next(err);
  }
};

export const addWard = async (req, res, next) => {
  try {
    const { ward_number, name, lat_min, lat_max, lon_min, lon_max } = req.body;

    // Validate required fields
    if (!ward_number || lat_min === undefined || lat_max === undefined || lon_min === undefined || lon_max === undefined) {
      throw badRequest("Missing required fields: ward_number, lat_min, lat_max, lon_min, lon_max");
    }

    // Validate boundaries
    if (lat_min >= lat_max || lon_min >= lon_max) {
      throw badRequest("Invalid boundaries: min must be less than max");
    }

    const ward = await createWard({ ward_number, name, lat_min, lat_max, lon_min, lon_max });
    return created(res, ward, "ward created");
  } catch (err) {
    return next(err);
  }
};

export const modifyWard = async (req, res, next) => {
  try {
    const wardId = Number(req.params.id);
    const ward = await updateWard(wardId, req.body);
    if (!ward) throw notFound("Ward not found");
    return ok(res, ward, "ward updated");
  } catch (err) {
    return next(err);
  }
};

export const removeWard = async (req, res, next) => {
  try {
    const wardId = Number(req.params.id);
    const result = await deleteWard(wardId);
    if (!result) throw notFound("Ward not found");
    return ok(res, { id: wardId }, "ward deleted");
  } catch (err) {
    return next(err);
  }
};

// ============ OFFICER MANAGEMENT ============

export const listOfficers = async (req, res, next) => {
  try {
    const officers = await getAllOfficers();
    // Get workload for each officer
    const officersWithWorkload = await Promise.all(
      officers.map(async (officer) => {
        const workload = await getOfficerWorkload(officer.id);
        return { ...officer, active_complaints: workload };
      })
    );
    return ok(res, { items: officersWithWorkload }, "officers list");
  } catch (err) {
    return next(err);
  }
};

export const getOfficer = async (req, res, next) => {
  try {
    const officerId = Number(req.params.id);
    const officer = await getOfficerById(officerId);
    if (!officer) throw notFound("Officer not found");
    
    const workload = await getOfficerWorkload(officerId);
    return ok(res, { ...officer, workload }, "officer details");
  } catch (err) {
    return next(err);
  }
};

export const addOfficer = async (req, res, next) => {
  try {
    const { name, email, phone, department_id, ward_id } = req.body;

    // Validate required fields
    if (!name || !department_id || !ward_id) {
      throw badRequest("Missing required fields: name, department_id, ward_id");
    }

    // Verify department and ward exist
    const deptCheck = await pool.query(`SELECT id FROM departments WHERE id = $1`, [department_id]);
    if (deptCheck.rows.length === 0) throw badRequest("Invalid department_id");

    const wardCheck = await pool.query(`SELECT id FROM wards WHERE id = $1`, [ward_id]);
    if (wardCheck.rows.length === 0) throw badRequest("Invalid ward_id");

    const officer = await createOfficer({ name, email, phone, department_id, ward_id });
    return created(res, officer, "officer created");
  } catch (err) {
    return next(err);
  }
};

export const modifyOfficer = async (req, res, next) => {
  try {
    const officerId = Number(req.params.id);
    const officer = await updateOfficer(officerId, req.body);
    if (!officer) throw notFound("Officer not found");
    return ok(res, officer, "officer updated");
  } catch (err) {
    return next(err);
  }
};

export const removeOfficer = async (req, res, next) => {
  try {
    const officerId = Number(req.params.id);
    const result = await deleteOfficer(officerId);
    if (!result) throw notFound("Officer not found");
    return ok(res, { id: officerId }, "officer deleted");
  } catch (err) {
    return next(err);
  }
};

export const getOfficersByDept = async (req, res, next) => {
  try {
    const departmentId = Number(req.params.departmentId);
    const officers = await getOfficersByDepartment(departmentId);
    return ok(res, { items: officers }, "officers by department");
  } catch (err) {
    return next(err);
  }
};

export const getOfficersByWd = async (req, res, next) => {
  try {
    const wardId = Number(req.params.wardId);
    const officers = await getOfficersByWard(wardId);
    return ok(res, { items: officers }, "officers by ward");
  } catch (err) {
    return next(err);
  }
};

// ============ ADMIN OVERRIDE ============

export const overrideComplaintAssignment = async (req, res, next) => {
  try {
    const complaintId = Number(req.params.complaintId);
    const { new_department_id, new_officer_id, reason } = req.body;

    // Get current complaint
    const complaintResult = await pool.query(
      `SELECT id, department_id, assigned_officer_id FROM complaints WHERE id = $1`,
      [complaintId]
    );
    if (complaintResult.rows.length === 0) throw notFound("Complaint not found");
    const complaint = complaintResult.rows[0];

    // Update complaint
    const updateResult = await pool.query(
      `UPDATE complaints SET department_id = $1, assigned_officer_id = $2 WHERE id = $3 RETURNING *`,
      [new_department_id || complaint.department_id, new_officer_id || complaint.assigned_officer_id, complaintId]
    );

    // Log override action
    await logOverrideAction({
      complaintId,
      adminId: req.user.id,
      oldDepartmentId: complaint.department_id,
      newDepartmentId: new_department_id,
      oldOfficerId: complaint.assigned_officer_id,
      newOfficerId: new_officer_id,
      reason: reason || "Manual override by admin"
    });

    return ok(res, updateResult.rows[0], "complaint assignment overridden");
  } catch (err) {
    return next(err);
  }
};

export default {
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
};
