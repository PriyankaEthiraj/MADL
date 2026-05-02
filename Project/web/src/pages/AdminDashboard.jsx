import { useEffect, useMemo, useState } from "react";
import Layout from "../components/Layout.jsx";
import { api } from "../services/api.js";
import ComplaintTable from "../components/ComplaintTable.jsx";
import FilterBar from "../components/FilterBar.jsx";
import StatsCards from "../components/StatsCards.jsx";
import ComplaintDetailsModal from "../components/ComplaintDetailsModal.jsx";
import { useAuth } from "../contexts/AuthContext.jsx";
import { io } from "socket.io-client";
import { jsPDF } from "jspdf";
import { useNavigate } from "react-router-dom";

const socket = io(import.meta.env.VITE_SOCKET_URL || "http://localhost:4000");

const DEPARTMENT_TYPES = [
  "Road Maintenance",
  "Street Light",
  "Public Toilet & Sanitation",
  "Public Transport",
  "Water Supply",
  "Garbage & Waste Management"
];

export default function AdminDashboard() {
  const navigate = useNavigate();
  const { token } = useAuth();
  const [complaints, setComplaints] = useState([]);
  const [pageSize, setPageSize] = useState("all");
  const [stats, setStats] = useState(null);
  const [departments, setDepartments] = useState([]);
  const [feedback, setFeedback] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [filters, setFilters] = useState({
    type: "",
    area: "",
    status: "",
    fromDate: "",
    toDate: ""
  });
  const [assignTarget, setAssignTarget] = useState({
    complaintId: "",
    departmentType: ""
  });
  const [selectedComplaint, setSelectedComplaint] = useState(null);
  const [detailLoading, setDetailLoading] = useState(false);

  const handleOpenComplaintDetails = async (row) => {
    setSelectedComplaint({ complaint: row, logs: [] });
    setDetailLoading(true);
    try {
      const res = await api.get(`/complaints/${row.id}`);
      const details = res.data?.data || null;
      setSelectedComplaint(details);
    } catch (err) {
      console.error("Failed to load complaint details", err);
    } finally {
      setDetailLoading(false);
    }
  };

  const query = useMemo(() => {
    const params = new URLSearchParams();
    params.append("limit", pageSize);
    Object.entries(filters).forEach(([key, value]) => {
      if (value) params.append(key, value);
    });
    return params.toString();
  }, [filters, pageSize]);

  const loadData = async () => {
    if (!token) {
      console.log("⚠️ No token available, skipping data load");
      return;
    }
    
    try {
      setLoading(true);
      setError(null);
      const [complaintsRes, statsRes, departmentsRes, feedbackRes] = await Promise.all([
        api.get(`/complaints?${query}`),
        api.get("/stats"),
        api.get("/departments"),
        api.get("/feedback")
      ]);
      
      console.log("API Response - Complaints:", complaintsRes.data);
      
      // Handle both response formats
      const complaintsList = complaintsRes.data.data?.items || complaintsRes.data.data || [];
      const statsList = statsRes.data.data || statsRes.data || {};
      const deptList = departmentsRes.data.data || departmentsRes.data || [];
      const feedbackList = feedbackRes.data.data || feedbackRes.data || [];
      
      setComplaints(Array.isArray(complaintsList) ? complaintsList : []);
      setStats(statsList);
      setDepartments(Array.isArray(deptList) ? deptList : []);
      setFeedback(Array.isArray(feedbackList) ? feedbackList : []);
    } catch (err) {
      console.error("Failed to load dashboard data:", err);
      setError(err.response?.data?.message || err.message || "Failed to load dashboard data");
      setComplaints([]);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (token) {
      loadData();
      socket.on("complaint:created", loadData);
      socket.on("complaint:assigned", loadData);
      socket.on("complaint:status", loadData);
    }
    return () => {
      socket.off("complaint:created", loadData);
      socket.off("complaint:assigned", loadData);
      socket.off("complaint:status", loadData);
    };
  }, [query, token]);

  const handleAssign = async () => {
    if (!assignTarget.complaintId || !assignTarget.departmentType) return;
    const dept = departments.find(d => d.name === assignTarget.departmentType);
    if (!dept) {
      alert("Department not found");
      return;
    }
    try {
      await api.post(`/complaints/${assignTarget.complaintId}/assign`, {
        departmentId: Number(dept.id)
      });
      setAssignTarget({ complaintId: "", departmentType: "" });
      await loadData();
    } catch (err) {
      alert("Failed to assign complaint: " + err.message);
    }
  };

  const exportCsv = () => {
    const headers = ["id", "type", "status", "department", "location"];
    const rows = complaints.map((c) => [
      c.id,
      c.type,
      c.status,
      c.department_name || "",
      c.location
    ]);
    const content = [headers, ...rows].map((r) => r.join(",")).join("\n");
    const blob = new Blob([content], { type: "text/csv" });
    const url = URL.createObjectURL(blob);
    const link = document.createElement("a");
    link.href = url;
    link.download = "complaints.csv";
    link.click();
    URL.revokeObjectURL(url);
  };

  const exportPdf = () => {
    const doc = new jsPDF();
    doc.text("Complaints Report", 10, 10);
    complaints.forEach((c, index) => {
      const y = 20 + index * 8;
      doc.text(
        `${c.id} | ${c.type} | ${c.status} | ${c.department_name || ""}`,
        10,
        y
      );
    });
    doc.save("complaints.pdf");
  };

  const canResolve = (status) => {
    const value = `${status || ""}`.toLowerCase();
    return !["resolved", "solved", "closed", "pending citizen verification"].includes(value);
  };

  return (
    <Layout title="Admin Dashboard">
      {error && (
        <div style={{
          background: 'var(--danger-50)',
          border: '2px solid var(--danger-500)',
          borderRadius: 'var(--radius-xl)',
          padding: 'var(--space-4)',
          marginBottom: 'var(--space-6)',
          display: 'flex',
          alignItems: 'center',
          gap: 'var(--space-3)'
        }}>
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
            <circle cx="12" cy="12" r="10"/>
            <line x1="12" y1="8" x2="12" y2="12"/>
            <line x1="12" y1="16" x2="12.01" y2="16"/>
          </svg>
          <span style={{ color: 'var(--danger-600)', fontWeight: 600 }}>
            {error}
          </span>
        </div>
      )}
      
      {loading && (
        <div style={{
          textAlign: 'center',
          padding: 'var(--space-12)',
          background: 'white',
          borderRadius: 'var(--radius-xl)',
          boxShadow: 'var(--shadow-lg)'
        }}>
          <div style={{
            width: '48px',
            height: '48px',
            margin: '0 auto var(--space-4)',
            border: '4px solid var(--gray-200)',
            borderTopColor: 'var(--primary-500)',
            borderRadius: '50%',
            animation: 'spin 1s linear infinite'
          }}></div>
          <p style={{ color: 'var(--gray-600)', fontWeight: 600 }}>
            Loading dashboard data...
          </p>
        </div>
      )}
      
      {!loading && (
        <>
          <StatsCards stats={stats} />
          <FilterBar filters={filters} setFilters={setFilters} onApply={loadData} />

          <div className="card" style={{ marginBottom: 'var(--space-6)' }}>
            <div style={{
              display: 'flex',
              alignItems: 'center',
              gap: 'var(--space-3)',
              marginBottom: 'var(--space-5)'
            }}>
              <div style={{
                width: '40px',
                height: '40px',
                borderRadius: 'var(--radius-lg)',
                background: 'linear-gradient(135deg, var(--accent-600) 0%, var(--accent-500) 100%)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                color: 'white'
              }}>
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                  <path d="M16 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/>
                  <circle cx="8.5" cy="7" r="4"/>
                  <line x1="20" y1="8" x2="20" y2="14"/>
                  <line x1="23" y1="11" x2="17" y2="11"/>
                </svg>
              </div>
              <div>
                <h3 style={{
                  margin: 0,
                  fontSize: '1.125rem',
                  fontWeight: 600,
                  color: 'var(--gray-900)'
                }}>Assign Complaint</h3>
                <p style={{
                  margin: 0,
                  fontSize: '0.875rem',
                  color: 'var(--gray-600)'
                }}>Assign complaint to a department</p>
              </div>
            </div>
            
            <div className="grid grid-3">
              <input
                placeholder="Enter Complaint ID"
                value={assignTarget.complaintId}
                onChange={(e) =>
                  setAssignTarget({ ...assignTarget, complaintId: e.target.value })
                }
              />
              <select
                value={assignTarget.departmentType}
                onChange={(e) =>
                  setAssignTarget({ ...assignTarget, departmentType: e.target.value })
                }
              >
                <option value="">Select Department Type</option>
                {DEPARTMENT_TYPES.map((type) => (
                  <option key={type} value={type}>
                    {type}
                  </option>
                ))}
              </select>
              <button
                className="button"
                onClick={handleAssign}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: 'var(--space-2)',
                  justifyContent: 'center'
                }}
              >
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                  <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/>
                  <polyline points="22 4 12 14.01 9 11.01"/>
                </svg>
                Assign
              </button>
            </div>
          </div>

          <div style={{
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            marginBottom: 'var(--space-4)'
          }}>
            <h3 style={{
              margin: 0,
              fontSize: '1.25rem',
              fontWeight: 700,
              color: 'var(--gray-900)'
            }}>All Complaints</h3>
            <div style={{ display: 'flex', gap: 'var(--space-3)', alignItems: 'center' }}>
              <select
                value={pageSize}
                onChange={(e) => setPageSize(e.target.value)}
                aria-label="Complaints per page"
              >
                <option value="10">10</option>
                <option value="20">20</option>
                <option value="30">30</option>
                <option value="all">All</option>
              </select>
              <button
                className="button secondary"
                onClick={exportCsv}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: 'var(--space-2)'
                }}
              >
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                  <path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4M7 10l5 5 5-5M12 15V3"/>
                </svg>
                Export CSV
              </button>
              <button
                className="button"
                onClick={exportPdf}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: 'var(--space-2)'
                }}
              >
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                  <path d="M14 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V8z"/>
                  <polyline points="14 2 14 8 20 8"/>
                  <line x1="16" y1="13" x2="8" y2="13"/>
                  <line x1="16" y1="17" x2="8" y2="17"/>
                  <polyline points="10 9 9 9 8 9"/>
                </svg>
                Export PDF
              </button>
            </div>
          </div>

          <ComplaintTable
            complaints={complaints}
            onSelectComplaint={handleOpenComplaintDetails}
            renderActions={(c) => (
              canResolve(c.status) ? (
                <button
                  className="button"
                  onClick={() => navigate(`/resolve/${c.id}?from=admin`)}
                >
                  Resolve
                </button>
              ) : (
                <span style={{ color: 'var(--gray-500)', fontSize: '0.875rem' }}>Locked</span>
              )
            )}
          />

          <ComplaintDetailsModal
            open={Boolean(selectedComplaint)}
            details={selectedComplaint}
            loading={detailLoading}
            onClose={() => setSelectedComplaint(null)}
          />

          <div className="card" style={{ marginTop: 'var(--space-6)' }}>
            <div style={{
              display: 'flex',
              alignItems: 'center',
              gap: 'var(--space-3)',
              marginBottom: 'var(--space-4)'
            }}>
              <div style={{
                width: '40px',
                height: '40px',
                borderRadius: 'var(--radius-lg)',
                background: 'linear-gradient(135deg, var(--steel-700) 0%, var(--steel-500) 100%)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                color: 'white'
              }}>
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                  <path d="M21 11.5a8.38 8.38 0 01-.9 3.8 8.5 8.5 0 01-7.6 4.7 8.38 8.38 0 01-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 01-.9-3.8 8.5 8.5 0 014.7-7.6 8.38 8.38 0 013.8-.9h.5a8.48 8.48 0 018 8v.5z"/>
                </svg>
              </div>
              <div>
                <h3 style={{
                  margin: 0,
                  fontSize: '1.125rem',
                  fontWeight: 600,
                  color: 'var(--gray-900)'
                }}>Citizen Feedback</h3>
                <p style={{
                  margin: 0,
                  fontSize: '0.875rem',
                  color: 'var(--gray-600)'
                }}>Recent feedback from citizens</p>
              </div>
            </div>
            
            {feedback.length === 0 ? (
              <p style={{
                textAlign: 'center',
                padding: 'var(--space-8)',
                color: 'var(--gray-400)',
                fontStyle: 'italic'
              }}>No feedback available yet</p>
            ) : (
              <ul style={{
                listStyle: 'none',
                padding: 0,
                margin: 0,
                display: 'flex',
                flexDirection: 'column',
                gap: 'var(--space-3)'
              }}>
                {feedback.map((f) => (
                  <li key={f.id} style={{
                    padding: 'var(--space-4)',
                    background: 'var(--gray-50)',
                    borderRadius: 'var(--radius-lg)',
                    borderLeft: '4px solid var(--primary-500)'
                  }}>
                    <div style={{
                      display: 'flex',
                      justifyContent: 'space-between',
                      alignItems: 'start',
                      marginBottom: 'var(--space-2)'
                    }}>
                      <span style={{
                        fontWeight: 600,
                        color: 'var(--gray-900)',
                        fontSize: '0.9375rem'
                      }}>
                        {f.citizen_name}
                      </span>
                      <div style={{
                        display: 'flex',
                        alignItems: 'center',
                        gap: 'var(--space-1)'
                      }}>
                        {[...Array(5)].map((_, i) => (
                          <svg
                            key={i}
                            width="16"
                            height="16"
                            viewBox="0 0 24 24"
                            fill={i < f.rating ? '#1495e6' : 'none'}
                            stroke="#1495e6"
                            strokeWidth="2"
                          >
                            <path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"/>
                          </svg>
                        ))}
                      </div>
                    </div>
                    <p style={{
                      margin: 0,
                      color: 'var(--gray-600)',
                      fontSize: '0.875rem',
                      lineHeight: 1.6
                    }}>
                      <span style={{
                        color: 'var(--gray-500)',
                        fontWeight: 600
                      }}>
                        Complaint #{f.complaint_id}
                      </span>
                      {f.comment && `: ${f.comment}`}
                    </p>
                  </li>
                ))}
              </ul>
            )}
          </div>
        </>
      )}
    </Layout>
  );
}
