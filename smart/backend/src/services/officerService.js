/**
 * Officer assignment service
 * Handles automatic officer assignment based on department and ward
 */

import { pool } from "../db/pool.js";

/**
 * Find available officer for department and ward
 * @param {number} departmentId - Department ID
 * @param {number} wardId - Ward ID
 * @returns {promise} Officer data or null if not found
 */
export const findOfficerForAssignment = async (departmentId, wardId) => {
  // Input validation
  if (!departmentId || !wardId) {
    return null;
  }

  // Query to find active officer assigned to this department and ward
  const result = await pool.query(
    `SELECT id, name, email, phone, department_id, ward_id, status
     FROM officers
     WHERE department_id = $1 AND ward_id = $2 AND status = 'Active'
     LIMIT 1`,
    [departmentId, wardId]
  );

  return result.rows[0] || null;
};

/**
 * Get all officers for a department
 * @param {number} departmentId - Department ID
 * @returns {promise} Array of officers
 */
export const getOfficersByDepartment = async (departmentId) => {
  const result = await pool.query(
    `SELECT id, name, email, phone, department_id, ward_id, status, created_at
     FROM officers
     WHERE department_id = $1
     ORDER BY name ASC`,
    [departmentId]
  );
  return result.rows;
};

/**
 * Get all officers for a ward
 * @param {number} wardId - Ward ID
 * @returns {promise} Array of officers
 */
export const getOfficersByWard = async (wardId) => {
  const result = await pool.query(
    `SELECT id, name, email, phone, department_id, ward_id, status, created_at
     FROM officers
     WHERE ward_id = $1
     ORDER BY name ASC`,
    [wardId]
  );
  return result.rows;
};

/**
 * Get officer by ID
 * @param {number} officerId - Officer ID
 * @returns {promise} Officer data or null
 */
export const getOfficerById = async (officerId) => {
  const result = await pool.query(
    `SELECT id, name, email, phone, department_id, ward_id, status, created_at
     FROM officers
     WHERE id = $1`,
    [officerId]
  );
  return result.rows[0] || null;
};

/**
 * Create new officer (admin only)
 * @param {object} officerData - Officer data (name, email, phone, department_id, ward_id)
 * @returns {promise} Created officer data
 */
export const createOfficer = async ({ name, email, phone, department_id, ward_id }) => {
  // Check if officer already exists for this department-ward combo
  const existing = await pool.query(
    `SELECT id FROM officers WHERE department_id = $1 AND ward_id = $2`,
    [department_id, ward_id]
  );

  if (existing.rows.length > 0) {
    throw new Error(`Officer already exists for this department-ward combination`);
  }

  const result = await pool.query(
    `INSERT INTO officers (name, email, phone, department_id, ward_id, status)
     VALUES ($1, $2, $3, $4, $5, 'Active')
     RETURNING *`,
    [name, email, phone, department_id, ward_id]
  );
  return result.rows[0];
};

/**
 * Update officer (admin only)
 * @param {number} officerId - Officer ID
 * @param {object} updateData - Fields to update (name, email, phone, status)
 * @returns {promise} Updated officer data
 */
export const updateOfficer = async (officerId, updateData) => {
  const fields = [];
  const values = [officerId];
  let paramCount = 2;

  Object.entries(updateData).forEach(([key, value]) => {
    if (["name", "email", "phone", "status"].includes(key)) {
      fields.push(`${key} = $${paramCount}`);
      values.push(value);
      paramCount++;
    }
  });

  if (fields.length === 0) {
    return getOfficerById(officerId);
  }

  const result = await pool.query(
    `UPDATE officers SET ${fields.join(", ")}
     WHERE id = $1
     RETURNING *`,
    values
  );
  return result.rows[0];
};

/**
 * Delete officer (admin only)
 * @param {number} officerId - Officer ID
 * @returns {promise} Result
 */
export const deleteOfficer = async (officerId) => {
  const result = await pool.query(
    `DELETE FROM officers WHERE id = $1 RETURNING id`,
    [officerId]
  );
  return result.rows[0] ? true : false;
};

/**
 * Assign officer to complaint
 * @param {number} complaintId - Complaint ID
 * @param {number} officerId - Officer ID
 * @returns {promise} Result
 */
export const assignOfficerToComplaint = async (complaintId, officerId) => {
  const result = await pool.query(
    `UPDATE complaints SET assigned_officer_id = $1 WHERE id = $2 RETURNING *`,
    [officerId, complaintId]
  );
  return result.rows[0];
};

/**
 * Get all officers (admin only)
 * @returns {promise} Array of all officers with department and ward info
 */
export const getAllOfficers = async () => {
  const result = await pool.query(
    `SELECT o.id, o.name, o.email, o.phone, o.status, o.created_at,
            d.name as department_name, w.ward_number, w.name as ward_name
     FROM officers o
     JOIN departments d ON o.department_id = d.id
     JOIN wards w ON o.ward_id = w.id
     ORDER BY d.name, w.ward_number, o.name ASC`
  );
  return result.rows;
};

/**
 * Get officer workload (number of assigned complaints)
 * @param {number} officerId - Officer ID
 * @returns {promise} Workload count
 */
export const getOfficerWorkload = async (officerId) => {
  const result = await pool.query(
    `SELECT COUNT(*) as complaint_count
     FROM complaints
     WHERE assigned_officer_id = $1 AND status NOT IN ('Solved', 'Closed')`,
    [officerId]
  );
  return parseInt(result.rows[0].complaint_count) || 0;
};

/**
 * Get least busy officer for department-ward (for load balancing)
 * @param {number} departmentId - Department ID
 * @param {number} wardId - Ward ID
 * @returns {promise} Officer with least workload or null
 */
export const getLeastBusyOfficer = async (departmentId, wardId) => {
  const result = await pool.query(
    `SELECT o.id, o.name, o.email, o.phone,
            COUNT(c.id) as active_complaints
     FROM officers o
     LEFT JOIN complaints c ON o.id = c.assigned_officer_id 
       AND c.status NOT IN ('Solved', 'Closed')
     WHERE o.department_id = $1 AND o.ward_id = $2 AND o.status = 'Active'
     GROUP BY o.id, o.name, o.email, o.phone
     ORDER BY active_complaints ASC
     LIMIT 1`,
    [departmentId, wardId]
  );

  return result.rows[0] || null;
};

/**
 * Log admin override action
 * @param {object} overrideData - Override information
 * @returns {promise} Log entry
 */
export const logOverrideAction = async ({
  complaintId,
  adminId,
  oldDepartmentId,
  newDepartmentId,
  oldOfficerId,
  newOfficerId,
  reason
}) => {
  const result = await pool.query(
    `INSERT INTO complaint_override_logs 
     (complaint_id, admin_id, old_department_id, new_department_id, old_officer_id, new_officer_id, reason)
     VALUES ($1, $2, $3, $4, $5, $6, $7)
     RETURNING *`,
    [complaintId, adminId, oldDepartmentId, newDepartmentId, oldOfficerId, newOfficerId, reason]
  );
  return result.rows[0];
};

export default {
  findOfficerForAssignment,
  getOfficersByDepartment,
  getOfficersByWard,
  getOfficerById,
  createOfficer,
  updateOfficer,
  deleteOfficer,
  assignOfficerToComplaint,
  getAllOfficers,
  getOfficerWorkload,
  getLeastBusyOfficer,
  logOverrideAction
};
