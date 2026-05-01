import { useEffect, useMemo, useState } from "react";
import { useNavigate, useParams, useSearchParams } from "react-router-dom";
import Layout from "../components/Layout.jsx";
import { api } from "../services/api.js";
import { useAuth } from "../contexts/AuthContext.jsx";

const toAbsoluteMediaUrl = (url) => {
  if (!url) return "";
  if (/^https?:\/\//i.test(url)) return url;
  const apiBase = api.defaults.baseURL || "";
  const serverBase = apiBase.replace(/\/api\/?$/, "");
  return `${serverBase}${url.startsWith("/") ? "" : "/"}${url}`;
};

const formatDateDdMmYyyy = (date) => {
  const dd = `${date.getDate()}`.padStart(2, "0");
  const mm = `${date.getMonth() + 1}`.padStart(2, "0");
  const yyyy = `${date.getFullYear()}`;
  return `${dd}-${mm}-${yyyy}`;
};

export default function ResolutionVerificationPage() {
  const navigate = useNavigate();
  const { id } = useParams();
  const { user } = useAuth();
  const [searchParams] = useSearchParams();
  const from = searchParams.get("from") || "department";

  const [complaint, setComplaint] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [uploading, setUploading] = useState(false);
  const [submitting, setSubmitting] = useState(false);

  const [resolutionDescription, setResolutionDescription] = useState("");
  const [imageProof, setImageProof] = useState({ file: null, url: "" });
  const [videoProof, setVideoProof] = useState({ file: null, url: "" });
  const [geo, setGeo] = useState({ lat: null, lng: null });

  const backPath = useMemo(() => (from === "admin" ? "/admin/dashboard" : "/department/dashboard"), [from]);

  useEffect(() => {
    const load = async () => {
      try {
        setLoading(true);
        setError("");
        const res = await api.get(`/complaints/${id}`);
        const details = res.data?.data || {};
        setComplaint(details.complaint || null);
      } catch (err) {
        setError(err.response?.data?.message || err.message || "Failed to load complaint");
      } finally {
        setLoading(false);
      }
    };

    load();
  }, [id]);

  const captureGeo = async () => {
    if (!navigator.geolocation) {
      throw new Error("Geolocation is not supported in this browser");
    }
    const position = await new Promise((resolve, reject) => {
      navigator.geolocation.getCurrentPosition(resolve, reject, {
        enableHighAccuracy: true,
        timeout: 20000,
      });
    });

    return {
      lat: position.coords.latitude,
      lng: position.coords.longitude,
    };
  };

  const handleUploadProof = async (file, type) => {
    if (!file) return;
    try {
      setUploading(true);
      const currentGeo = await captureGeo();
      const formData = new FormData();
      formData.append("proof", file);

      const res = await api.post("/complaints/upload-proof", formData, {
        headers: { "Content-Type": "multipart/form-data" },
      });

      const url = res.data?.data?.url || res.data?.url || "";
      if (!url) throw new Error("Upload did not return URL");

      setGeo(currentGeo);
      if (type === "image") {
        setImageProof({ file, url });
      } else {
        setVideoProof({ file, url });
      }
    } catch (err) {
      alert(err.response?.data?.message || err.message || "Proof upload failed");
    } finally {
      setUploading(false);
    }
  };

  const handleSubmit = async () => {
    if (!complaint) return;
    if (resolutionDescription.trim().length < 10) {
      alert("Resolution description must be at least 10 characters");
      return;
    }
    const hasImage = Boolean(imageProof.url);
    const hasVideo = Boolean(videoProof.url);
    if (!hasImage && !hasVideo) {
      alert("Capture image or video proof first");
      return;
    }
    if (geo.lat == null || geo.lng == null) {
      alert("Geo-location is required. Please upload proof again.");
      return;
    }

    try {
      setSubmitting(true);
      const payload = {
        complaintId: Number(id),
        originalDescription: complaint.description || "",
        resolutionDescription: resolutionDescription.trim(),
        departmentName: complaint.department_name || user?.department_name || user?.name || "Department",
        resolutionDate: formatDateDdMmYyyy(new Date()),
        imageUrl: imageProof.url || undefined,
        videoUrl: videoProof.url || undefined,
        geoLocation: {
          lat: geo.lat,
          lng: geo.lng,
        },
      };

      const verifyRes = await api.post("/complaints/verify-resolution", payload);
      const verification = verifyRes.data?.data || verifyRes.data || {};

      if (`${verification.status}` !== "Pending Citizen Verification") {
        alert(verification.remarks || "Verification failed");
        return;
      }

      const proofJson = {
        complaint_id: verification.complaint_id,
        department: verification.department,
        resolution_description: payload.resolutionDescription,
        proof_type: verification.proof_type,
        proof_url: verification.proof_url,
        proofs: verification.proofs,
        geo_location: verification.geo_location,
        date: verification.date,
        status: verification.status,
      };

      await api.post(`/complaints/${id}/status`, {
        status: "Pending Citizen Verification",
        remark: `RESOLUTION_PROOF:${JSON.stringify(proofJson)}`,
      });

      alert("Complaint submitted for citizen approval");
      navigate(backPath);
    } catch (err) {
      alert(err.response?.data?.message || err.message || "Resolution submission failed");
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <Layout title="Resolution Verification">
      <div className="card" style={{ marginBottom: "var(--space-6)", padding: "var(--space-6)" }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", gap: "var(--space-3)", flexWrap: "wrap" }}>
          <h2 style={{ margin: 0 }}>Resolution Verification</h2>
          <button className="button secondary" onClick={() => navigate(backPath)}>Back</button>
        </div>
        <p style={{ marginTop: "var(--space-3)", color: "var(--gray-600)" }}>
          Fill all details and submit proof with geolocation.
        </p>
      </div>

      {loading && <div className="card" style={{ padding: "var(--space-6)" }}>Loading complaint details...</div>}
      {error && <div className="card" style={{ padding: "var(--space-6)", color: "var(--danger-600)" }}>{error}</div>}

      {!loading && !error && complaint && (
        <div className="card" style={{ padding: "var(--space-6)", display: "grid", gap: "var(--space-5)" }}>
          <div className="grid grid-2">
            <div>
              <label>Complaint ID</label>
              <input value={complaint.id || ""} readOnly />
            </div>
            <div>
              <label>Department</label>
              <input value={complaint.department_name || user?.department_name || user?.name || "Department"} readOnly />
            </div>
            <div>
              <label>Date</label>
              <input value={formatDateDdMmYyyy(new Date())} readOnly />
            </div>
            <div>
              <label>Status</label>
              <input value={complaint.status || "Pending"} readOnly />
            </div>
          </div>

          <div>
            <label>Original Complaint Description</label>
            <textarea value={complaint.description || ""} readOnly style={{ minHeight: 100, width: "100%" }} />
          </div>

          <div>
            <label>Resolution Description</label>
            <textarea
              value={resolutionDescription}
              onChange={(e) => setResolutionDescription(e.target.value)}
              placeholder="At least 10 characters"
              style={{ minHeight: 120, width: "100%" }}
            />
          </div>

          <div style={{ display: "grid", gap: "var(--space-3)" }}>
            <strong>Proof Capture (camera only)</strong>
            <div style={{ display: "flex", gap: "var(--space-3)", flexWrap: "wrap" }}>
              <label className="button secondary" style={{ cursor: uploading ? "not-allowed" : "pointer", opacity: uploading ? 0.7 : 1 }}>
                Capture Image
                <input
                  type="file"
                  accept="image/*"
                  capture="environment"
                  style={{ display: "none" }}
                  disabled={uploading || submitting}
                  onChange={(e) => handleUploadProof(e.target.files?.[0], "image")}
                />
              </label>

              <label className="button secondary" style={{ cursor: uploading ? "not-allowed" : "pointer", opacity: uploading ? 0.7 : 1 }}>
                Record Video
                <input
                  type="file"
                  accept="video/*"
                  capture="environment"
                  style={{ display: "none" }}
                  disabled={uploading || submitting}
                  onChange={(e) => handleUploadProof(e.target.files?.[0], "video")}
                />
              </label>
            </div>

            {uploading && <div>Uploading proof and capturing geo-location...</div>}

            {(imageProof.url || videoProof.url) && (
              <div className="card" style={{ padding: "var(--space-4)", background: "var(--gray-50)" }}>
                <p style={{ marginTop: 0 }}><strong>Proofs:</strong> {[
                  imageProof.url ? "image" : null,
                  videoProof.url ? "video" : null,
                ].filter(Boolean).join(", ")}</p>
                <p><strong>Geo:</strong> {geo.lat?.toFixed(6)}, {geo.lng?.toFixed(6)}</p>

                {imageProof.url && (
                  <img
                    src={toAbsoluteMediaUrl(imageProof.url)}
                    alt="Image proof"
                    style={{ width: "100%", maxHeight: 320, objectFit: "cover", borderRadius: 12 }}
                  />
                )}

                {videoProof.url && (
                  <video
                    controls
                    src={toAbsoluteMediaUrl(videoProof.url)}
                    style={{ width: "100%", borderRadius: 12, background: "#111827" }}
                  />
                )}
              </div>
            )}
          </div>

          <div style={{ display: "flex", justifyContent: "flex-end" }}>
            <button className="button" onClick={handleSubmit} disabled={uploading || submitting}>
              {submitting ? "Submitting..." : "Submit for Citizen Verification"}
            </button>
          </div>
        </div>
      )}
    </Layout>
  );
}
