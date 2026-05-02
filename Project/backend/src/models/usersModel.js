import { pool } from "../db/pool.js";

export const createUser = async ({ name, email, password, role, departmentId, phone }) => {
  const result = await pool.query(
    `INSERT INTO users (name, email, password, role, department_id, phone)
     VALUES ($1, $2, $3, $4, $5, $6)
     RETURNING id, name, email, role, department_id, phone, address, created_at`,
    [name, email, password, role, departmentId, phone]
  );
  return result.rows[0];
};

export const findUserByEmail = async (email) => {
  const result = await pool.query(
    `SELECT id, name, email, password, role, department_id, phone, address, created_at
     FROM users WHERE LOWER(email) = LOWER($1)`,
    [email]
  );
  return result.rows[0];
};

export const updateUserPassword = async (id, password) => {
  const result = await pool.query(
    `UPDATE users
     SET password = $1
     WHERE id = $2
     RETURNING id`,
    [password, id]
  );
  return result.rows[0];
};

export const findUserByPhone = async (phone) => {
  const result = await pool.query(
    `SELECT id, name, email, password, role, department_id, phone, address, created_at
     FROM users WHERE phone = $1`,
    [phone]
  );
  return result.rows[0];
};

export const findUserById = async (id) => {
  const result = await pool.query(
    `SELECT id, name, email, role, department_id, phone, address, created_at
     FROM users WHERE id = $1`,
    [id]
  );
  return result.rows[0];
};

export const updateUser = async (id, { name, email, phone }) => {
  const result = await pool.query(
    `UPDATE users 
     SET name = $1, email = $2, phone = $3
     WHERE id = $4
     RETURNING id, name, email, role, department_id, phone, address, created_at`,
    [name, email, phone, id]
  );
  return result.rows[0];
};
