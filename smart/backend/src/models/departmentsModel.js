import { pool } from "../db/pool.js";

export const listDepartments = async () => {
  const result = await pool.query(
    `SELECT id, name, type FROM departments ORDER BY name ASC`
  );
  return result.rows;
};

export const findDepartmentById = async (id) => {
  const result = await pool.query(
    `SELECT id, name, type FROM departments WHERE id = $1`,
    [id]
  );
  return result.rows[0];
};

export const findDepartmentByName = async (name) => {
  const result = await pool.query(
    `SELECT id, name, type FROM departments WHERE name = $1 OR type = $1`,
    [name]
  );
  return result.rows[0];
};

export const addDepartment = async ({ name, type }) => {
  const result = await pool.query(
    `INSERT INTO departments (name, type) VALUES ($1, $2) RETURNING id, name, type`,
    [name, type]
  );
  return result.rows[0];
};

export const updateDepartmentById = async (id, { name, type }) => {
  const result = await pool.query(
    `UPDATE departments SET name = $1, type = $2 WHERE id = $3 RETURNING id, name, type`,
    [name, type, id]
  );
  return result.rows[0];
};

export const removeDepartment = async (id) => {
  const result = await pool.query(
    `DELETE FROM departments WHERE id = $1 RETURNING id`,
    [id]
  );
  return result.rows[0];
};
