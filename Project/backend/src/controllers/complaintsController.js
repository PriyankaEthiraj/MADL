import {
  submitComplaint,
  fetchComplaints,
  fetchComplaintDetails,
  assignDepartment,
  updateStatus,
  submitFeedback,
  approveResolutionProof
} from "../services/complaintService.js";
import { classifyComplaint } from "../services/classificationService.js";
import { detectWardByCoordinates, findNearestWard } from "../services/geolocationService.js";
import { findOfficerForAssignment } from "../services/officerService.js";
import { resolveDepartment } from "../services/departmentResolverService.js";
import { verifyResolutionProof } from "../services/resolutionVerificationService.js";
import { badRequest } from "../utils/errors.js";
import { ok, created } from "../utils/responses.js";
import { getPagination } from "../utils/pagination.js";
import { pool } from "../db/pool.js";

export const createComplaint = async (req, res, next) => {
  try {
    // Handle both single file (backward compatibility) and multiple files
    let photoUrl = null;
    let videoUrl = null;
    
    if (req.file) {
      // Single file upload (backward compatibility)
      const mimetype = req.file.mimetype;
      if (mimetype.startsWith("image/")) {
        photoUrl = `/uploads/${req.file.filename}`;
      } else if (mimetype.startsWith("video/")) {
        videoUrl = `/uploads/${req.file.filename}`;
      }
    } else if (req.files) {
      // Multiple files upload
      if (req.files.photo) {
        photoUrl = `/uploads/${req.files.photo[0].filename}`;
      }
      if (req.files.video) {
        videoUrl = `/uploads/${req.files.video[0].filename}`;
      }
    }

    if (!photoUrl && !videoUrl) {
      throw badRequest("Either photo or video attachment is required");
    }
    
    // Extract geotag data from body
    const photoData = {
      latitude: req.body.photo_latitude ? parseFloat(req.body.photo_latitude) : null,
      longitude: req.body.photo_longitude ? parseFloat(req.body.photo_longitude) : null,
      timestamp: req.body.photo_timestamp ? new Date(req.body.photo_timestamp) : null,
      locationName: req.body.photo_location_name || null
    };
    
    const videoData = {
      latitude: req.body.video_latitude ? parseFloat(req.body.video_latitude) : null,
      longitude: req.body.video_longitude ? parseFloat(req.body.video_longitude) : null,
      timestamp: req.body.video_timestamp ? new Date(req.body.video_timestamp) : null,
      locationName: req.body.video_location_name || null
    };
    
    const complaint = await submitComplaint({
      user: req.user,
      data: req.body,
      photoUrl,
      videoUrl,
      photoData,
      videoData
    });
    req.app.get("io")?.emit("complaint:created", complaint);
    return created(res, complaint, "complaint submitted");
  } catch (err) {
    return next(err);
  }
};

export const listComplaints = async (req, res, next) => {
  try {
    const { limit, offset, page } = getPagination(req.query);
    const filters = {
      type: req.query.type,
      area: req.query.area,
      status: req.query.status,
      fromDate: req.query.fromDate,
      toDate: req.query.toDate
    };
    const complaints = await fetchComplaints({
      user: req.user,
      filters,
      limit,
      offset
    });
    return ok(res, { items: complaints, page, limit }, "complaints");
  } catch (err) {
    return next(err);
  }
};

export const getComplaint = async (req, res, next) => {
  try {
    const complaintId = Number(req.params.id);
    const details = await fetchComplaintDetails({
      user: req.user,
      complaintId
    });
    return ok(res, details, "complaint details");
  } catch (err) {
    return next(err);
  }
};

export const assignComplaintToDepartment = async (req, res, next) => {
  try {
    const complaintId = Number(req.params.id);
    const { departmentId } = req.body;
    const complaint = await assignDepartment({ complaintId, departmentId });
    req.app.get("io")?.emit("complaint:assigned", complaint);
    return ok(res, complaint, "assigned");
  } catch (err) {
    return next(err);
  }
};

export const updateComplaintStatus = async (req, res, next) => {
  try {
    const complaintId = Number(req.params.id);
    const complaint = await updateStatus({
      complaintId,
      user: req.user,
      status: req.body.status,
      remark: req.body.remark
    });
    req.app.get("io")?.emit("complaint:status", complaint);
    return ok(res, complaint, "status updated");
  } catch (err) {
    return next(err);
  }
};

export const addFeedback = async (req, res, next) => {
  try {
    const complaintId = Number(req.params.id);
    const feedback = await submitFeedback({
      complaintId,
      user: req.user,
      rating: req.body.rating,
      comment: req.body.comment
    });
    return created(res, feedback, "feedback submitted");
  } catch (err) {
    return next(err);
  }
};

export const approveProof = async (req, res, next) => {
  try {
    const complaintId = Number(req.params.id);
    const complaint = await approveResolutionProof({
      complaintId,
      user: req.user,
      action: req.body?.action
    });
    req.app.get("io")?.emit("complaint:status", complaint);
    return ok(res, complaint, "proof approved");
  } catch (err) {
    return next(err);
  }
};

export const verifyResolution = async (req, res, next) => {
  try {
    const result = verifyResolutionProof(req.body);
    return res.json(result);
  } catch (err) {
    return next(err);
  }
};

export const uploadResolutionProof = async (req, res, next) => {
  try {
    if (!req.file) {
      throw badRequest("Proof file is required");
    }

    const { env } = await import("../config/env.js");
    const absoluteUrl = `${env.serverUrl}/uploads/${req.file.filename}`;
    const kind = req.file.mimetype.startsWith("video/")
      ? "video"
      : req.file.mimetype.startsWith("image/")
        ? "image"
        : "document";

    return ok(res, {
      url: absoluteUrl,
      kind,
      originalName: req.file.originalname
    }, "proof uploaded");
  } catch (err) {
    return next(err);
  }
};

/**
 * Simple complaint submission endpoint
 * Accepts: description, latitude, longitude
 * Returns: Classified category, detected ward, assigned officer
 */
export const submitSimpleComplaint = async (req, res, next) => {
  try {
    const { description, latitude, longitude, location, type } = req.body;

    // Validate required fields
    if (!description || description.trim().length === 0) {
      throw badRequest("Description is required");
    }

    if (latitude === null || latitude === undefined || longitude === null || longitude === undefined) {
      throw badRequest("Latitude and longitude are required");
    }

    // Use authenticated user ID, or create anonymous complaint
    const userId = req.user?.id;

    // Step 1: Classify complaint
    const classificationText = `${type || ""} ${description || ""}`.trim();
    const classification = classifyComplaint(classificationText);
    const predictedDepartment = classification.department;

    // Step 2: Get department ID
    let departmentId = null;
    const resolvedDepartment = await resolveDepartment(predictedDepartment);
    if (resolvedDepartment) {
      departmentId = resolvedDepartment.id;
    }

    // Step 3: Detect ward
    let wardData = null;
    let wardId = null;
    wardData = await detectWardByCoordinates(latitude, longitude);
    if (wardData) {
      wardId = wardData.id;
    } else {
      // Find nearest ward if no exact match
      wardData = await findNearestWard(latitude, longitude);
      if (wardData) {
        wardId = wardData.id;
      }
    }

    // Step 4: Find assigned officer
    let assignedOfficer = null;
    if (departmentId && wardId) {
      assignedOfficer = await findOfficerForAssignment(departmentId, wardId);
    }

    // Step 5: Create complaint in database
    // For anonymous submissions, we need a placeholder or make user_id nullable
    // For now, we'll require authentication
    if (!userId) {
      throw badRequest("User authentication is required to submit a complaint");
    }

    const result = await pool.query(
      `INSERT INTO complaints 
       (user_id, department_id, type, description, location, predicted_department, ward_id, assigned_officer_id, status)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, 'Pending')
       RETURNING id, description, predicted_department, ward_id, assigned_officer_id, status, created_at`,
      [
        userId,
        departmentId,
        predictedDepartment,
        description,
        location || `Lat: ${latitude}, Lon: ${longitude}`,
        predictedDepartment,
        wardId,
        assignedOfficer?.id || null
      ]
    );

    const complaint = result.rows[0];

    // Return formatted response
    return created(res, {
      message: "Complaint submitted successfully",
      complaintId: complaint.id,
      category: predictedDepartment,
      confidence: classification.confidence,
      matchedKeywords: classification.matchedKeywords,
      ward: wardData?.ward_number || null,
      wardName: wardData?.name || "Unknown",
      assignedOfficer: assignedOfficer ? {
        id: assignedOfficer.id,
        name: assignedOfficer.name,
        email: assignedOfficer.email,
        phone: assignedOfficer.phone
      } : null,
      status: complaint.status,
      createdAt: complaint.created_at
    }, "complaint submitted");
  } catch (err) {
    return next(err);
  }
};
