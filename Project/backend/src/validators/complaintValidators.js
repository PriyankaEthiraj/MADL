import { z } from "zod";

export const createComplaintSchema = z.object({
  type: z.string().min(2),
  description: z.string().min(5),
  location: z.string().min(2),
  photo_latitude: z.coerce.number().optional(),
  photo_longitude: z.coerce.number().optional(),
  photo_timestamp: z.union([z.string(), z.date()]).optional(),
  photo_location_name: z.string().min(2).optional(),
  video_latitude: z.coerce.number().optional(),
  video_longitude: z.coerce.number().optional(),
  video_timestamp: z.union([z.string(), z.date()]).optional(),
  video_location_name: z.string().min(2).optional()
});

export const assignComplaintSchema = z.object({
  departmentId: z.number().int()
});

export const statusUpdateSchema = z.object({
  status: z.enum(["Pending", "In Progress", "Pending Citizen Verification", "Resolved", "Reopened", "Solved", "Closed"]),
  // Resolution proof remarks embed JSON payload and can exceed 500 chars.
  remark: z.string().min(2).max(20000).optional()
});

const optionalUrl = z.preprocess((value) => {
  if (typeof value !== "string") return undefined;
  const trimmed = value.trim();
  return trimmed.length ? trimmed : undefined;
}, z.string().url().optional());

export const resolutionVerificationSchema = z.object({
  complaintId: z.coerce.number().int().positive(),
  originalDescription: z.string().min(1),
  resolutionDescription: z.string().min(1),
  departmentName: z.string().min(1),
  resolutionDate: z.union([z.string().min(1), z.date()]),
  proofType: z.enum(["image", "video", "document"]).optional(),
  proofUrl: optionalUrl,
  imageUrl: optionalUrl,
  videoUrl: optionalUrl,
  documentUrl: optionalUrl,
  geoLocation: z.object({
    lat: z.coerce.number(),
    lng: z.coerce.number()
  }).optional()
});
