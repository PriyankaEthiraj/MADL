import { useEffect, useMemo, useState } from "react";
import Layout from "../components/Layout.jsx";
import ComplaintTable from "../components/ComplaintTable.jsx";
import ComplaintDetailsModal from "../components/ComplaintDetailsModal.jsx";
import { api } from "../services/api.js";
import { useAuth } from "../contexts/AuthContext.jsx";
import { io } from "socket.io-client";
import { useNavigate } from "react-router-dom";

const socket = io(import.meta.env.VITE_SOCKET_URL || "http://localhost:4000");

export default function DepartmentDashboard() {
  const navigate = useNavigate();
  const { user, token } = useAuth();
  const [complaints, setComplaints] = useState([]);
  const [pageSize, setPageSize] = useState("all");
  const [form, setForm] = useState({ id: "", status: "In Progress", remark: "" });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
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
    return params.toString();
  }, [pageSize]);

  const loadData = async () => {
    if (!token) {
      console.log("⚠️ No token available, skipping complaint load");
      return;
    }
    
    try {
      setLoading(true);
      setError(null);
      console.log(`📋 Loading complaints for user: ${user?.name}, role: ${user?.role}, dept: ${user?.department_id}`);
      const res = await api.get(`/complaints?${query}`);
      // Backend filters based on user role automatically
      const allComplaints = res.data.data.items || res.data.data || [];
      setComplaints(allComplaints);
      console.log(`✓ Loaded ${allComplaints.length} complaints`);
    } catch (err) {
      console.error("Failed to load complaints", err);
      setError(err.response?.data?.message || err.message || "Failed to load complaints");
      setComplaints([]);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (user && token) {
      loadData();
      socket.on("complaint:assigned", loadData);
      socket.on("complaint:status", loadData);
    }
    return () => {
      socket.off("complaint:assigned", loadData);
      socket.off("complaint:status", loadData);
    };
  }, [user, token, query]);

  const handleUpdate = async () => {
    if (!form.id) return;
    await api.post(`/complaints/${form.id}/status`, {
      status: form.status,
      remark: form.remark
    });
    setForm({ id: "", status: "In Progress", remark: "" });
    await loadData();
  };

  const canResolve = (status) => {
    const value = `${status || ""}`.toLowerCase();
    return !["resolved", "solved", "closed", "pending citizen verification"].includes(value);
  };

  return (
    <Layout title="Department Dashboard">
      {user && user.role === "department" && (
        <div className="card" style={{ marginBottom: 'var(--space-6)' }}>
          <div style={{
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            flexWrap: 'wrap',
            gap: 'var(--space-4)'
          }}>
            <div>
              <h2 style={{
                margin: 0,
                fontSize: '1.5rem',
                fontWeight: 700,
                marginBottom: 'var(--space-2)',
                color: 'var(--gray-900)'
              }}>
                {user.name}
              </h2>
              <p style={{
                margin: 0,
                color: 'var(--gray-600)',
                fontSize: '0.9375rem'
              }}>
                Department ID: {user.department_id}
              </p>
            </div>
            <div style={{
              textAlign: 'right',
              background: 'linear-gradient(135deg, #149af2 0%, #17c2d8 100%)',
              padding: 'var(--space-4) var(--space-6)',
              borderRadius: 'var(--radius-lg)',
              color: 'white',
              boxShadow: 'var(--shadow-md)'
            }}>
              <div style={{
                fontSize: '2rem',
                fontWeight: 700,
                marginBottom: 'var(--space-1)'
              }}>
                {complaints.length}
              </div>
              <div style={{
                fontSize: '0.875rem',
                opacity: 0.95
              }}>
                Assigned Complaints
              </div>
            </div>
          </div>
        </div>
      )}
      
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
            Loading complaints...
          </p>
        </div>
      )}
      
      {!loading && !error && complaints.length === 0 && (
        <div style={{
          background: 'var(--success-50)',
          borderRadius: 'var(--radius-xl)',
          padding: 'var(--space-8)',
          textAlign: 'center',
          boxShadow: 'var(--shadow-lg)'
        }}>
          <div style={{
            width: '80px',
            height: '80px',
            margin: '0 auto var(--space-4)',
            borderRadius: 'var(--radius-full)',
            background: 'var(--success-500)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center'
          }}>
            <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2">
              <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/>
              <polyline points="22 4 12 14.01 9 11.01"/>
            </svg>
          </div>
          <p style={{
            margin: 0,
            fontSize: '1.125rem',
            fontWeight: 600,
            color: 'var(--success-600)'
          }}>
            All caught up!
          </p>
          <p style={{
            margin: 0,
            marginTop: 'var(--space-2)',
            color: 'var(--gray-600)'
          }}>
            No complaints assigned to your department yet
          </p>
        </div>
      )}
      
      {!loading && (
        <>
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
                background: 'linear-gradient(135deg, #149af2 0%, #17c2d8 100%)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                color: 'white'
              }}>
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                  <path d="M11 4H4a2 2 0 00-2 2v14a2 2 0 002 2h14a2 2 0 002-2v-7"/>
                  <path d="M18.5 2.5a2.121 2.121 0 013 3L12 15l-4 1 1-4 9.5-9.5z"/>
                </svg>
              </div>
              <div>
                <h3 style={{
                  margin: 0,
                  fontSize: '1.125rem',
                  fontWeight: 600,
                  color: 'var(--gray-900)'
                }}>Update Complaint Status</h3>
                <p style={{
                  margin: 0,
                  fontSize: '0.875rem',
                  color: 'var(--gray-600)'
                }}>Update progress and add remarks</p>
              </div>
            </div>
            
            <div className="grid grid-3">
              <input
                placeholder="Enter Complaint ID"
                value={form.id}
                onChange={(e) => setForm({ ...form, id: e.target.value })}
              />
              <select
                value={form.status}
                onChange={(e) => setForm({ ...form, status: e.target.value })}
              >
                <option value="Pending">Pending</option>
                <option value="In Progress">In Progress</option>
                <option value="Solved">Solved</option>
              </select>
              <input
                placeholder="Add a remark (optional)"
                value={form.remark}
                onChange={(e) => setForm({ ...form, remark: e.target.value })}
              />
            </div>
            <button
              className="button"
              style={{
                marginTop: 'var(--space-4)',
                display: 'flex',
                alignItems: 'center',
                gap: 'var(--space-2)',
                justifyContent: 'center'
              }}
              onClick={handleUpdate}
            >
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <path d="M19 21H5a2 2 0 01-2-2V5a2 2 0 012-2h11l5 5v11a2 2 0 01-2 2z"/>
                <polyline points="17 21 17 13 7 13 7 21"/>
                <polyline points="7 3 7 8 15 8"/>
              </svg>
              Update Status
            </button>
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
            }}>Assigned Complaints</h3>
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
          </div>
          <ComplaintTable
            complaints={complaints}
            onSelectComplaint={handleOpenComplaintDetails}
            renderActions={(c) => (
              canResolve(c.status) ? (
                <button
                  className="button"
                  onClick={() => navigate(`/resolve/${c.id}?from=department`)}
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
        </>
      )}
    </Layout>
  );
}
