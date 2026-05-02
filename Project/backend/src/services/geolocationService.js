/**
 * Geo-location service for ward detection
 * Determines which ward a complaint belongs to based on latitude and longitude
 */

import { pool } from "../db/pool.js";

/**
 * Detect ward based on latitude and longitude
 * @param {number} latitude - Latitude coordinate
 * @param {number} longitude - Longitude coordinate
 * @returns {promise} Ward data or null if not found
 */
export const detectWardByCoordinates = async (latitude, longitude) => {
  // Input validation
  if (latitude === null || latitude === undefined || longitude === null || longitude === undefined) {
    return null;
  }

  if (typeof latitude !== "number" || typeof longitude !== "number") {
    return null;
  }

  // Query to find ward that contains the given coordinates
  // Uses geographic boundary checking: lat_min < lat < lat_max AND lon_min < lon < lon_max
  const result = await pool.query(
    `SELECT id, ward_number, name, lat_min, lat_max, lon_min, lon_max
     FROM wards
     WHERE $1 BETWEEN lat_min AND lat_max
       AND $2 BETWEEN lon_min AND lon_max
     LIMIT 1`,
    [latitude, longitude]
  );

  return result.rows[0] || null;
};

/**
 * Get all wards (for admin operations)
 * @returns {promise} Array of ward data
 */
export const getAllWards = async () => {
  const result = await pool.query(
    `SELECT id, ward_number, name, lat_min, lat_max, lon_min, lon_max, created_at
     FROM wards
     ORDER BY ward_number ASC`
  );
  return result.rows;
};

/**
 * Get ward by ID
 * @param {number} wardId - Ward ID
 * @returns {promise} Ward data or null
 */
export const getWardById = async (wardId) => {
  const result = await pool.query(
    `SELECT id, ward_number, name, lat_min, lat_max, lon_min, lon_max, created_at
     FROM wards
     WHERE id = $1`,
    [wardId]
  );
  return result.rows[0] || null;
};

/**
 * Create a new ward (admin only)
 * @param {object} wardData - Ward data (ward_number, name, lat_min, lat_max, lon_min, lon_max)
 * @returns {promise} Created ward data
 */
export const createWard = async ({ ward_number, name, lat_min, lat_max, lon_min, lon_max }) => {
  const result = await pool.query(
    `INSERT INTO wards (ward_number, name, lat_min, lat_max, lon_min, lon_max)
     VALUES ($1, $2, $3, $4, $5, $6)
     RETURNING *`,
    [ward_number, name, lat_min, lat_max, lon_min, lon_max]
  );
  return result.rows[0];
};

/**
 * Update ward boundaries (admin only)
 * @param {number} wardId - Ward ID
 * @param {object} updateData - Fields to update
 * @returns {promise} Updated ward data
 */
export const updateWard = async (wardId, updateData) => {
  const fields = [];
  const values = [wardId];
  let paramCount = 2;

  Object.entries(updateData).forEach(([key, value]) => {
    if (["name", "lat_min", "lat_max", "lon_min", "lon_max"].includes(key)) {
      fields.push(`${key} = $${paramCount}`);
      values.push(value);
      paramCount++;
    }
  });

  if (fields.length === 0) {
    return getWardById(wardId);
  }

  const result = await pool.query(
    `UPDATE wards SET ${fields.join(", ")}
     WHERE id = $1
     RETURNING *`,
    values
  );
  return result.rows[0];
};

/**
 * Delete ward (admin only)
 * @param {number} wardId - Ward ID
 * @returns {promise} Result
 */
export const deleteWard = async (wardId) => {
  const result = await pool.query(
    `DELETE FROM wards WHERE id = $1 RETURNING id`,
    [wardId]
  );
  return result.rows[0] ? true : false;
};

/**
 * Calculate distance between two coordinates (Haversine formula)
 * Useful for finding nearest ward if exact match not found
 * @param {number} lat1 - First latitude
 * @param {number} lon1 - First longitude
 * @param {number} lat2 - Second latitude
 * @param {number} lon2 - Second longitude
 * @returns {number} Distance in kilometers
 */
export const calculateDistance = (lat1, lon1, lat2, lon2) => {
  const R = 6371; // Earth's radius in kilometers
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
};

/**
 * Find nearest ward if exact match not found
 * @param {number} latitude - Latitude coordinate
 * @param {number} longitude - Longitude coordinate
 * @returns {promise} Nearest ward data
 */
export const findNearestWard = async (latitude, longitude) => {
  if (latitude === null || latitude === undefined || longitude === null || longitude === undefined) {
    return null;
  }

  // Get all wards and calculate distances
  const wards = await getAllWards();
  if (wards.length === 0) return null;

  // Calculate center of each ward for distance calculation
  const wardsWithDistance = wards.map((ward) => {
    const wardCenterLat = (ward.lat_min + ward.lat_max) / 2;
    const wardCenterLon = (ward.lon_min + ward.lon_max) / 2;
    const distance = calculateDistance(latitude, longitude, wardCenterLat, wardCenterLon);
    return { ...ward, distance };
  });

  // Sort by distance and return closest
  wardsWithDistance.sort((a, b) => a.distance - b.distance);
  return wardsWithDistance[0];
};

export default {
  detectWardByCoordinates,
  getAllWards,
  getWardById,
  createWard,
  updateWard,
  deleteWard,
  calculateDistance,
  findNearestWard
};
