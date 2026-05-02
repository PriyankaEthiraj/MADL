const PROOF_EXTENSIONS = ["jpg", "jpeg", "png", "webp", "gif", "mp4", "mov", "webm", "pdf", "doc", "docx"];

const extractExtension = (value) => {
  try {
    const url = new URL(value);
    const path = url.pathname.toLowerCase();
    const match = path.match(/\.([a-z0-9]+)$/);
    return match?.[1] || "";
  } catch {
    return "";
  }
};

const isValidProofUrl = (value) => {
  if (typeof value !== "string" || !value.trim()) return false;

  try {
    const url = new URL(value.trim());
    if (url.protocol !== "http:" && url.protocol !== "https:") return false;
    const extension = extractExtension(url.toString());
    return PROOF_EXTENSIONS.includes(extension);
  } catch {
    return false;
  }
};

const summarizeResolution = (resolutionDescription) => {
  const text = resolutionDescription.replace(/\s+/g, " ").trim();
  if (text.length <= 120) return text;
  return `${text.slice(0, 117).trimEnd()}...`;
};

const formatDateDDMMYYYY = (dateValue) => {
  let date = new Date(dateValue);

  // Accept explicit dd-mm-yyyy from older/mobile clients.
  if (Number.isNaN(date.getTime()) && typeof dateValue === "string") {
    const match = dateValue.trim().match(/^(\d{2})-(\d{2})-(\d{4})$/);
    if (match) {
      const dd = Number.parseInt(match[1], 10);
      const mm = Number.parseInt(match[2], 10);
      const yyyy = Number.parseInt(match[3], 10);
      date = new Date(yyyy, mm - 1, dd);
      if (
        date.getFullYear() !== yyyy ||
        date.getMonth() !== mm - 1 ||
        date.getDate() !== dd
      ) {
        return "";
      }
    }
  }

  if (Number.isNaN(date.getTime())) return "";
  const dd = `${date.getDate()}`.padStart(2, "0");
  const mm = `${date.getMonth() + 1}`.padStart(2, "0");
  const yyyy = `${date.getFullYear()}`;
  return `${dd}-${mm}-${yyyy}`;
};

export const verifyResolutionProof = ({
  complaintId,
  originalDescription,
  resolutionDescription,
  departmentName,
  resolutionDate,
  proofType,
  proofUrl,
  imageUrl,
  videoUrl,
  documentUrl,
  geoLocation
}) => {
  const candidateProofs = [
    { type: "image", url: imageUrl },
    { type: "video", url: videoUrl },
    { type: "document", url: documentUrl },
    { type: proofType, url: proofUrl }
  ].filter((p) => typeof p.url === "string" && p.url.trim().length > 0);

  const seenProofUrls = new Set();
  const validProofs = candidateProofs.filter((p) => {
    if (!isValidProofUrl(p.url)) return false;
    const key = p.url.trim().toLowerCase();
    if (seenProofUrls.has(key)) return false;
    seenProofUrls.add(key);
    return true;
  });
  const primaryProof = validProofs[0] || null;
  const descriptionOk = typeof resolutionDescription === "string" && resolutionDescription.trim().length >= 10;
  const proofOk = validProofs.length > 0;
  const lat = Number(geoLocation?.lat);
  const lng = Number(geoLocation?.lng);
  const address = typeof geoLocation?.address === "string" ? geoLocation.address.trim() : "";
  const capturedAt = typeof geoLocation?.captured_at === "string" ? geoLocation.captured_at.trim() : "";
  const geoOk = Number.isFinite(lat) && Number.isFinite(lng);
  const dateFormatted = formatDateDDMMYYYY(resolutionDate) || formatDateDDMMYYYY(new Date().toISOString());

  const missingReasons = [];
  if (!descriptionOk) missingReasons.push("resolution description must be at least 10 characters");
  if (!proofOk) missingReasons.push("camera proof is required");
  if (!geoOk) missingReasons.push("geo-location is required");
  if (!dateFormatted) missingReasons.push("resolution date is invalid");

  const status = missingReasons.length === 0 ? "Pending Citizen Verification" : "Pending Verification";

  return {
    complaint_id: complaintId,
    department: departmentName,
    resolution_description: summarizeResolution(resolutionDescription),
    proof_type: primaryProof?.type || (proofType || ""),
    proof_url: primaryProof?.url || proofUrl || "",
    proofs: validProofs.map((proof) => ({
      type: proof.type || "proof",
      url: proof.url
    })),
    geo_location: {
      lat: geoOk ? `${lat}` : "",
      lng: geoOk ? `${lng}` : "",
      address,
      captured_at: capturedAt
    },
    date: dateFormatted,
    status,
    remarks: missingReasons.length === 0
      ? `Awaiting citizen verification. Original complaint: ${`${originalDescription || ""}`.slice(0, 80).replace(/\s+/g, " ")}${`${originalDescription || ""}`.length > 80 ? "..." : ""}`
      : `Pending verification because ${missingReasons.join(" and ")}.`
  };
};