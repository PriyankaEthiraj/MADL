import {
  createComplaint,
  listComplaints,
  getComplaintById,
  assignComplaint,
  updateComplaintStatus,
  complaintsStats
} from "../models/complaintsModel.js";
import { addStatusLog, listStatusLogs } from "../models/statusLogsModel.js";
import { addFeedback, listFeedback } from "../models/feedbackModel.js";
import { badRequest, forbidden, notFound } from "../utils/errors.js";
import { classifyComplaint } from "./classificationService.js";
import { detectWardByCoordinates, findNearestWard } from "./geolocationService.js";
import { findOfficerForAssignment } from "./officerService.js";
import { resolveDepartment } from "./departmentResolverService.js";

export const submitComplaint = async ({ user, data, photoUrl, videoUrl, photoData, videoData }) => {
  // Determine latitude and longitude from photo or video data
  const latitude = photoData?.latitude || videoData?.latitude;
  const longitude = photoData?.longitude || videoData?.longitude;

  // Step 1: Classify complaint based on description
  const classificationText = `${data.type || ""} ${data.description || ""}`.trim();
  const classification = classifyComplaint(classificationText);
  const predictedDepartment = classification.department;

  // Step 2: Get department ID from department name
  let departmentId = null;
  const resolvedDepartment = await resolveDepartment(predictedDepartment);
  if (resolvedDepartment) {
    departmentId = resolvedDepartment.id;
  }

  // Step 3: Detect ward based on coordinates
  let wardId = null;
  if (latitude !== null && latitude !== undefined && longitude !== null && longitude !== undefined) {
    const ward = await detectWardByCoordinates(latitude, longitude);
    if (ward) {
      wardId = ward.id;
    } else {
      // If no exact match, find nearest ward
      const nearestWard = await findNearestWard(latitude, longitude);
      if (nearestWard) {
        wardId = nearestWard.id;
      }
    }
  }

  // Step 4: Auto-assign officer based on department and ward
  let assignedOfficerId = null;
  if (departmentId && wardId) {
    const officer = await findOfficerForAssignment(departmentId, wardId);
    if (officer) {
      assignedOfficerId = officer.id;
    }
  }

  // Step 5: Create complaint with all auto-detected information
  const complaint = await createComplaint({
    userId: user.id,
    departmentId,
    type: data.type || predictedDepartment,
    description: data.description,
    location: data.location,
    photoUrl,
    videoUrl,
    photoLatitude: photoData?.latitude,
    photoLongitude: photoData?.longitude,
    photoTimestamp: photoData?.timestamp,
    photoLocationName: photoData?.locationName,
    videoLatitude: videoData?.latitude,
    videoLongitude: videoData?.longitude,
    videoTimestamp: videoData?.timestamp,
    videoLocationName: videoData?.locationName,
    predictedDepartment,
    wardId,
    assignedOfficerId
  });

  // Log the submission
  await addStatusLog({
    complaintId: complaint.id,
    status: complaint.status,
    updatedBy: user.id,
    remark: `Complaint submitted - Auto-classified: ${predictedDepartment}, Ward: ${wardId || 'Unknown'}, Officer: ${assignedOfficerId || 'Unassigned'}`
  });

  return {
    ...complaint,
    classification: {
      department: predictedDepartment,
      confidence: classification.confidence,
      matchedKeywords: classification.matchedKeywords
    }
  };
};

export const fetchComplaints = async ({ user, filters, limit, offset }) =>
  listComplaints({
    role: user.role,
    userId: user.id,
    departmentId: user.departmentId,
    filters,
    limit,
    offset
  });

export const fetchComplaintDetails = async ({ user, complaintId }) => {
  const complaint = await getComplaintById(complaintId);
  if (!complaint) throw notFound("Complaint not found");
  if (user.role === "citizen" && complaint.user_id !== user.id) {
    throw forbidden("Access denied");
  }
  if (user.role === "department" && complaint.department_id !== user.departmentId) {
    throw forbidden("Access denied");
  }
  const logs = await listStatusLogs(complaintId);
  return { complaint, logs };
};

export const assignDepartment = async ({ complaintId, departmentId }) => {
  const complaint = await assignComplaint(complaintId, departmentId);
  if (!complaint) throw notFound("Complaint not found");
  return complaint;
};

export const updateStatus = async ({ complaintId, user, status, remark }) => {
  const complaint = await getComplaintById(complaintId);
  if (!complaint) throw notFound("Complaint not found");
  if (user.role === "department" && complaint.department_id !== user.departmentId) {
    throw forbidden("Access denied");
  }
  if (user.role === "citizen") {
    throw forbidden("Citizens cannot update status");
  }

  const updated = await updateComplaintStatus(complaintId, status);
  await addStatusLog({
    complaintId,
    status,
    updatedBy: user.id,
    remark
  });
  return updated;
};

export const approveResolutionProof = async ({ complaintId, user, action }) => {
  const complaint = await getComplaintById(complaintId);
  if (!complaint) throw notFound("Complaint not found");
  if (user.role !== "citizen") {
    throw forbidden("Only citizens can approve proof");
  }
  if (complaint.user_id !== user.id) {
    throw forbidden("Access denied");
  }
  if ((complaint.status || "").toLowerCase() !== "pending citizen verification") {
    throw badRequest("Proof can only be reviewed while in Pending Citizen Verification");
  }

  const isApprove = (action || "approve").toLowerCase() === "approve";
  const nextStatus = isApprove ? "Solved" : "Reopened";
  const logRemark = isApprove
    ? "Citizen approved resolution proof"
    : "Citizen rejected resolution proof";

  const updated = await updateComplaintStatus(complaintId, nextStatus);
  await addStatusLog({
    complaintId,
    status: nextStatus,
    updatedBy: user.id,
    remark: logRemark
  });
  return updated;
};

export const submitResolutionVerification = async ({ complaintId, user, status, remark }) => {
  const complaint = await getComplaintById(complaintId);
  if (!complaint) throw notFound("Complaint not found");
  if (user.role === "department" && complaint.department_id !== user.departmentId) {
    throw forbidden("Access denied");
  }
  if (user.role === "citizen") {
    throw forbidden("Citizens cannot update status");
  }

  const updated = await updateComplaintStatus(complaintId, status);
  await addStatusLog({
    complaintId,
    status,
    updatedBy: user.id,
    remark
  });
  return updated;
};

export const submitFeedback = async ({ complaintId, user, rating, comment }) => {
  const complaint = await getComplaintById(complaintId);
  if (!complaint) throw notFound("Complaint not found");
  if (complaint.user_id !== user.id) throw forbidden("Access denied");
  if (complaint.status !== "Solved" && complaint.status !== "Closed") {
    throw badRequest("Feedback allowed only after solved or closed");
  }
  return addFeedback({ complaintId, userId: user.id, rating, comment });
};

export const fetchFeedback = async () => listFeedback();

export const fetchStats = async () => complaintsStats();
