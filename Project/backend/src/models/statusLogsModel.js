import { pool } from "../db/pool.js";

export const addStatusLog = async ({ complaintId, status, updatedBy, remark }) => {
  const result = await pool.query(
    `INSERT INTO status_logs (complaint_id, status, updated_by, remark)
     VALUES ($1, $2, $3, $4)
     RETURNING *`,
    [complaintId, status, updatedBy, remark || null]
  );
  return result.rows[0];
};

export const listStatusLogs = async (complaintId) => {
  const result = await pool.query(
    `SELECT s.*, u.name as updated_by_name
     FROM status_logs s
     JOIN users u ON u.id = s.updated_by
     WHERE complaint_id = $1
     ORDER BY updated_at ASC`,
    [complaintId]
  );
  return result.rows;
};
