import { api } from "../services/api.js";

const parseLatLng = (location) => {
  if (!location || typeof location !== "string") return null;
  const parts = location.split(",");
  if (parts.length < 2) return null;
  const lat = Number.parseFloat(parts[0].trim());
  const lng = Number.parseFloat(parts[1].trim());
  if (Number.isNaN(lat) || Number.isNaN(lng)) return null;
  return { lat, lng };
};

const toAbsoluteMediaUrl = (url) => {
  if (!url) return null;
  if (/^https?:\/\//i.test(url)) return url;
  const apiBase = api.defaults.baseURL || "";
  const serverBase = apiBase.replace(/\/api\/?$/, "");
  return `${serverBase}${url.startsWith("/") ? "" : "/"}${url}`;
};

const dedupeProofItems = (items) => {
  if (!Array.isArray(items)) return [];
  const seen = new Set();
  const deduped = [];

  for (const item of items) {
    const absoluteUrl = toAbsoluteMediaUrl(item?.url);
    const key = `${absoluteUrl || ""}`.trim().toLowerCase();
    if (!key || seen.has(key)) continue;
    seen.add(key);
    deduped.push(item);
  }

  return deduped;
};

const formatDateTime = (value) => {
  if (!value) return "N/A";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return String(value);
  return date.toLocaleString();
};

const statusLabel = (status) => {
  const value = `${status || ""}`.toLowerCase();
  if (value === "resolved" || value === "solved" || value === "closed") return "Solved";
  if (value === "in progress" || value === "in_progress") return "In Progress";
  if (value === "pending citizen verification") return "Pending Citizen Verification";
  return status || "Unknown";
};

export default function ComplaintDetailsModal({ open, details, loading, onClose }) {
  if (!open) return null;

  const complaint = details?.complaint || null;
  const logs = details?.logs || [];

  let resolutionProof = null;
  for (let i = logs.length - 1; i >= 0; i -= 1) {
    const remark = `${logs[i]?.remark || ""}`;
    if (!remark.startsWith("RESOLUTION_PROOF:")) continue;
    try {
      const raw = remark.slice("RESOLUTION_PROOF:".length);
      resolutionProof = JSON.parse(raw);
      break;
    } catch {
      resolutionProof = null;
    }
  }

  const photoUrl = toAbsoluteMediaUrl(complaint?.photo_url);
  const videoUrl = toAbsoluteMediaUrl(complaint?.video_url);
  const proofItemsRaw = Array.isArray(resolutionProof?.proofs) && resolutionProof.proofs.length > 0
    ? resolutionProof.proofs
    : resolutionProof?.proof_url
      ? [{ type: resolutionProof?.proof_type || "proof", url: resolutionProof.proof_url }]
      : [];
  const proofItems = dedupeProofItems(proofItemsRaw);
  const coords = parseLatLng(complaint?.location);

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal-panel" onClick={(e) => e.stopPropagation()}>
        <div className="modal-header">
          <h3 className="modal-title" style={{ margin: 0 }}>Complaint Details</h3>
          <button className="button secondary" onClick={onClose}>Close</button>
        </div>

        {loading && <p>Loading complaint details...</p>}

        {!loading && !complaint && <p>Unable to load complaint details.</p>}

        {!loading && complaint && (
          <div className="details-grid">
            <div className="card detail-list" style={{ padding: "16px" }}>
              <p><strong>ID:</strong> #{complaint.id}</p>
              <p><strong>Type:</strong> {complaint.type}</p>
              <p><strong>Description:</strong> {complaint.description}</p>
              <p><strong>Status:</strong> {statusLabel(complaint.status)}</p>
              <p><strong>Citizen:</strong> {complaint.citizen_name || "N/A"}</p>
              <p><strong>Department:</strong> {complaint.department_name || "Unassigned"}</p>
              <p><strong>Location:</strong> {complaint.location}</p>
              <p><strong>Created:</strong> {formatDateTime(complaint.created_at)}</p>
            </div>

            {(photoUrl || videoUrl || proofItems.length > 0) && (
              <div className="card" style={{ padding: "16px" }}>
                <h4 style={{ marginTop: 0 }}>Attachments</h4>
                {photoUrl && (
                  <div style={{ marginBottom: "16px" }}>
                    <p style={{ marginBottom: "8px", fontWeight: 600 }}>Photo</p>
                    <img src={photoUrl} alt="Complaint" style={{ width: "100%", maxHeight: "320px", objectFit: "cover", borderRadius: "12px" }} />
                    <p style={{ marginTop: "8px", fontSize: "0.875rem", color: "var(--gray-600)" }}>
                      <span className="media-caption">
                      Geotag: {complaint.photo_location_name || "N/A"} | {complaint.photo_latitude || "N/A"}, {complaint.photo_longitude || "N/A"} | {formatDateTime(complaint.photo_timestamp)}
                      </span>
                    </p>
                  </div>
                )}

                {videoUrl && (
                  <div>
                    <p style={{ marginBottom: "8px", fontWeight: 600 }}>Video</p>
                    <video
                      controls
                      preload="metadata"
                      src={videoUrl}
                      style={{ width: "100%", borderRadius: "12px", background: "#111827" }}
                    />
                    <p style={{ marginTop: "8px", fontSize: "0.875rem", color: "var(--gray-600)" }}>
                      <span className="media-caption">
                      Geotag: {complaint.video_location_name || "N/A"} | {complaint.video_latitude || "N/A"}, {complaint.video_longitude || "N/A"} | {formatDateTime(complaint.video_timestamp)}
                      </span>
                    </p>
                  </div>
                )}

                {proofItems.length > 0 && (
                  <div style={{ marginTop: "16px" }}>
                    <p style={{ marginBottom: "8px", fontWeight: 600 }}>Resolution Proof</p>
                    {proofItems.map((item, index) => {
                      const proofUrl = toAbsoluteMediaUrl(item?.url);
                      const proofType = `${item?.type || ""}`.toLowerCase();
                      const isImage = proofType.includes("image");
                      const isVideo = proofType.includes("video");
                      return (
                        <div key={`${proofUrl}-${index}`} style={{ marginBottom: index === proofItems.length - 1 ? 0 : "16px" }}>
                          <div style={{ marginBottom: "8px", fontWeight: 600, textTransform: "capitalize" }}>
                            {item?.type || "proof"}
                          </div>
                          {isImage && (
                            <img
                              src={proofUrl}
                              alt="Resolution proof"
                              style={{ width: "100%", maxHeight: "320px", objectFit: "cover", borderRadius: "12px" }}
                            />
                          )}
                          {isVideo && (
                            <video
                              controls
                              preload="metadata"
                              src={proofUrl}
                              style={{ width: "100%", borderRadius: "12px", background: "#111827" }}
                            />
                          )}
                        </div>
                      );
                    })}
                    <p style={{ marginTop: "8px", fontSize: "0.875rem", color: "var(--gray-600)" }}>
                      Geo: {resolutionProof?.geo_location?.address || "N/A"} | {resolutionProof?.geo_location?.lat || "N/A"}, {resolutionProof?.geo_location?.lng || "N/A"} | {formatDateTime(resolutionProof?.geo_location?.captured_at)}
                    </p>
                  </div>
                )}
              </div>
            )}

            {coords && (
              <div className="card" style={{ padding: "16px" }}>
                <h4 style={{ marginTop: 0 }}>Location Map</h4>
                <iframe
                  title="Complaint location map"
                  width="100%"
                  height="300"
                  style={{ border: 0, borderRadius: "12px" }}
                  loading="lazy"
                  referrerPolicy="no-referrer-when-downgrade"
                  src={`https://maps.google.com/maps?q=${coords.lat},${coords.lng}&z=15&output=embed`}
                />
              </div>
            )}

            {logs.length > 0 && (
              <div className="card" style={{ padding: "16px" }}>
                <h4 style={{ marginTop: 0 }}>Status Timeline</h4>
                <div className="timeline-list" style={{ display: "grid", gap: "10px" }}>
                  {logs.map((log, idx) => (
                    <div key={`${log.updated_at}-${idx}`} className="timeline-item">
                      <div><strong>{log.status}</strong></div>
                      <div style={{ fontSize: "0.875rem", color: "var(--gray-600)" }}>{formatDateTime(log.updated_at)}</div>
                      {log.updated_by_name && <div style={{ fontSize: "0.875rem" }}>by {log.updated_by_name}</div>}
                      {log.remark && <div style={{ fontSize: "0.875rem" }}>{log.remark}</div>}
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
}
