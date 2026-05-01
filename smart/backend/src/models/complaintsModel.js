import { pool } from "../db/pool.js";

export const createComplaint = async ({
  userId,
  departmentId,
  type,
  description,
  location,
  photoUrl,
  videoUrl,
  photoLatitude,
  photoLongitude,
  photoTimestamp,
  photoLocationName,
  videoLatitude,
  videoLongitude,
  videoTimestamp,
  videoLocationName,
  predictedDepartment,
  wardId,
  assignedOfficerId
}) => {
  const result = await pool.query(
    `INSERT INTO complaints
     (user_id, department_id, type, description, location, photo_url, video_url,
      photo_latitude, photo_longitude, photo_timestamp, photo_location_name,
      video_latitude, video_longitude, video_timestamp, video_location_name, 
      predicted_department, ward_id, assigned_officer_id, status)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, 'Pending')
     RETURNING *`,
    [userId, departmentId, type, description, location, photoUrl, videoUrl,
     photoLatitude, photoLongitude, photoTimestamp, photoLocationName,
     videoLatitude, videoLongitude, videoTimestamp, videoLocationName,
     predictedDepartment, wardId, assignedOfficerId]
  );
  return result.rows[0];
};

export const listComplaints = async ({
  role,
  userId,
  departmentId,
  filters,
  limit,
  offset
}) => {
  const conditions = [];
  const values = [];
  let idx = 1;

  if (role === "citizen") {
    conditions.push(`c.user_id = $${idx++}`);
    values.push(userId);
  }

  if (role === "department") {
    conditions.push(`c.department_id = $${idx++}`);
    values.push(departmentId);
  }

  if (filters?.status) {
    conditions.push(`c.status = $${idx++}`);
    values.push(filters.status);
  }

  if (filters?.type) {
    conditions.push(`c.type ILIKE $${idx++}`);
    values.push(`%${filters.type}%`);
  }

  if (filters?.area) {
    conditions.push(`c.location ILIKE $${idx++}`);
    values.push(`%${filters.area}%`);
  }

  if (filters?.fromDate) {
    conditions.push(`c.created_at >= $${idx++}`);
    values.push(filters.fromDate);
  }

  if (filters?.toDate) {
    conditions.push(`c.created_at <= $${idx++}`);
    values.push(filters.toDate);
  }

  const where = conditions.length ? `WHERE ${conditions.join(" AND ")}` : "";
  const paginationClause = limit === null ? "" : `LIMIT $${idx++} OFFSET $${idx++}`;
  const queryValues = limit === null ? values : [...values, limit, offset];

  const result = await pool.query(
    `SELECT c.*, u.name as citizen_name, d.name as department_name
     FROM complaints c
     JOIN users u ON u.id = c.user_id
     LEFT JOIN departments d ON d.id = c.department_id
     ${where}
     ORDER BY c.created_at DESC
     ${paginationClause}`,
    queryValues
  );
  return result.rows;
};

export const getComplaintById = async (id) => {
  const result = await pool.query(
    `SELECT c.*, u.name as citizen_name, d.name as department_name
     FROM complaints c
     JOIN users u ON u.id = c.user_id
     LEFT JOIN departments d ON d.id = c.department_id
     WHERE c.id = $1`,
    [id]
  );
  return result.rows[0];
};

export const assignComplaint = async (id, departmentId) => {
  const result = await pool.query(
    `UPDATE complaints
     SET department_id = $1, updated_at = NOW()
     WHERE id = $2
     RETURNING *`,
    [departmentId, id]
  );
  return result.rows[0];
};

export const updateComplaintStatus = async (id, status) => {
  const result = await pool.query(
    `UPDATE complaints
     SET status = $1, updated_at = NOW()
     WHERE id = $2
     RETURNING *`,
    [status, id]
  );
  return result.rows[0];
};

export const complaintsStats = async () => {
  const [byType, byStatus, byDepartment] = await Promise.all([
    pool.query(
      `SELECT type, COUNT(*)::int AS count FROM complaints GROUP BY type`
    ),
    pool.query(
      `SELECT status, COUNT(*)::int AS count FROM complaints GROUP BY status`
    ),
    pool.query(
      `SELECT d.name as department, COUNT(c.id)::int AS count
       FROM departments d
       LEFT JOIN complaints c ON c.department_id = d.id
       GROUP BY d.name`
    )
  ]);

  return {
    byType: byType.rows,
    byStatus: byStatus.rows,
    byDepartment: byDepartment.rows
  };
};
