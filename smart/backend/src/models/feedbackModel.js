import { pool } from "../db/pool.js";

export const addFeedback = async ({ complaintId, userId, rating, comment }) => {
  const result = await pool.query(
    `INSERT INTO feedback (complaint_id, user_id, rating, comment)
     VALUES ($1, $2, $3, $4)
     RETURNING *`,
    [complaintId, userId, rating, comment || null]
  );
  return result.rows[0];
};

export const listFeedback = async () => {
  const result = await pool.query(
    `SELECT f.*, u.name as citizen_name, c.type as complaint_type
     FROM feedback f
     JOIN users u ON u.id = f.user_id
     JOIN complaints c ON c.id = f.complaint_id
     ORDER BY f.created_at DESC`
  );
  return result.rows;
};
