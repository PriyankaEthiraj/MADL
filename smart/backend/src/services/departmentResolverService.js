import { pool } from "../db/pool.js";

const departmentAliasMap = {
  Road: ["road", "road maintenance", "roads"],
  "Garbage & Waste Management": [
    "garbage",
    "waste",
    "waste management",
    "sanitation",
    "public toilet & sanitation"
  ],
  Sanitation: ["sanitation", "garbage", "waste", "public toilet & sanitation"],
  Water: ["water", "water supply", "drainage"],
  "Street Light": ["street light", "electricity", "electrical", "power"],
  Electricity: ["electricity", "street light", "electrical", "power"],
  "Public Transport": ["public transport", "transport", "bus"],
  Transport: ["transport", "public transport", "bus"],
  General: ["general"]
};

const getAliases = (predictedDepartment) => {
  const base = (predictedDepartment || "General").trim();
  const mapped = departmentAliasMap[base] || [];
  const merged = [base, ...mapped]
    .map((item) => item.toLowerCase())
    .filter(Boolean);
  return [...new Set(merged)];
};

export const resolveDepartment = async (predictedDepartment) => {
  const aliases = getAliases(predictedDepartment);
  const primary = (predictedDepartment || "").toLowerCase();

  const exact = await pool.query(
    `SELECT id, name, type
     FROM departments
     WHERE lower(name) = ANY($1::text[])
        OR lower(type) = ANY($1::text[])
     ORDER BY
       CASE
         WHEN lower(name) = $2 THEN 0
         WHEN lower(type) = $2 THEN 1
         ELSE 2
       END,
       id ASC
     LIMIT 1`,
    [aliases, primary]
  );

  if (exact.rows[0]) {
    return exact.rows[0];
  }

  const fuzzy = await pool.query(
    `SELECT DISTINCT d.id, d.name, d.type
     FROM departments d
     JOIN unnest($1::text[]) AS a(alias)
       ON lower(d.name) LIKE '%' || a.alias || '%'
       OR lower(COALESCE(d.type, '')) LIKE '%' || a.alias || '%'
     ORDER BY d.id ASC
     LIMIT 1`,
    [aliases]
  );

  return fuzzy.rows[0] || null;
};
