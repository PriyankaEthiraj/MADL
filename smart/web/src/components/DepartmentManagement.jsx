import { useEffect, useState } from "react";
import { api } from "../services/api.js";

const DEPARTMENT_TYPES = [
  "Road Maintenance",
  "Street Light",
  "Public Toilet & Sanitation",
  "Public Transport",
  "Water Supply",
  "Garbage & Waste Management",
];

export default function DepartmentManagement() {
  const [departments, setDepartments] = useState([]);
  const [newDept, setNewDept] = useState({ name: "", type: "" });
  const [editingId, setEditingId] = useState(null);
  const [editData, setEditData] = useState({ name: "", type: "" });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [success, setSuccess] = useState(null);

  useEffect(() => {
    loadDepartments();
  }, []);

  const loadDepartments = async () => {
    try {
      const res = await api.get("/departments");
      setDepartments(res.data.data || []);
    } catch (err) {
      setError("Failed to load departments");
    }
  };

  const handleAddDepartment = async () => {
    if (!newDept.name.trim() || !newDept.type) {
      setError("Please fill in all fields");
      return;
    }

    setLoading(true);
    try {
      await api.post("/departments", {
        name: newDept.name,
        type: newDept.type,
      });
      setSuccess("Department added successfully!");
      setNewDept({ name: "", type: "" });
      loadDepartments();
      setTimeout(() => setSuccess(null), 3000);
    } catch (err) {
      setError(err.response?.data?.message || "Failed to add department");
    } finally {
      setLoading(false);
    }
  };

  const handleUpdateDepartment = async (id) => {
    if (!editData.name.trim() || !editData.type) {
      setError("Please fill in all fields");
      return;
    }

    setLoading(true);
    try {
      await api.put(`/departments/${id}`, {
        name: editData.name,
        type: editData.type,
      });
      setSuccess("Department updated successfully!");
      setEditingId(null);
      loadDepartments();
      setTimeout(() => setSuccess(null), 3000);
    } catch (err) {
      setError(err.response?.data?.message || "Failed to update department");
    } finally {
      setLoading(false);
    }
  };

  const handleDeleteDepartment = async (id) => {
    if (!window.confirm("Are you sure you want to delete this department?"))
      return;

    setLoading(true);
    try {
      await api.delete(`/departments/${id}`);
      setSuccess("Department deleted successfully!");
      loadDepartments();
      setTimeout(() => setSuccess(null), 3000);
    } catch (err) {
      setError(err.response?.data?.message || "Failed to delete department");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="card">
      <h3>Department Management</h3>

      {error && (
        <div style={{ padding: "12px", background: "#deefff", color: "#0a4f8d", borderRadius: "8px", marginBottom: "12px" }}>
          {error}
        </div>
      )}
      {success && (
        <div style={{ padding: "12px", background: "#e5f4ff", color: "#1276bf", borderRadius: "8px", marginBottom: "12px" }}>
          {success}
        </div>
      )}

      <div style={{ marginBottom: "24px", padding: "16px", background: "#eff8ff", borderRadius: "8px" }}>
        <h4 style={{ marginTop: 0 }}>Add New Department</h4>
        <div className="grid grid-3" style={{ gap: "12px" }}>
          <input
            type="text"
            placeholder="Department Name"
            value={newDept.name}
            onChange={(e) => setNewDept({ ...newDept, name: e.target.value })}
          />
          <select
            value={newDept.type}
            onChange={(e) => setNewDept({ ...newDept, type: e.target.value })}
          >
            <option value="">Select Type</option>
            {DEPARTMENT_TYPES.map((type) => (
              <option key={type} value={type}>
                {type}
              </option>
            ))}
          </select>
          <button
            className="button"
            onClick={handleAddDepartment}
            disabled={loading}
          >
            {loading ? "Adding..." : "Add Department"}
          </button>
        </div>
      </div>

      <table className="table">
        <thead>
          <tr>
            <th>ID</th>
            <th>Name</th>
            <th>Type</th>
            <th style={{ width: "200px" }}>Actions</th>
          </tr>
        </thead>
        <tbody>
          {departments.map((dept) => (
            <tr key={dept.id}>
              <td>{dept.id}</td>
              <td>
                {editingId === dept.id ? (
                  <input
                    type="text"
                    value={editData.name}
                    onChange={(e) =>
                      setEditData({ ...editData, name: e.target.value })
                    }
                  />
                ) : (
                  dept.name
                )}
              </td>
              <td>
                {editingId === dept.id ? (
                  <select
                    value={editData.type}
                    onChange={(e) =>
                      setEditData({ ...editData, type: e.target.value })
                    }
                  >
                    <option value="">Select Type</option>
                    {DEPARTMENT_TYPES.map((type) => (
                      <option key={type} value={type}>
                        {type}
                      </option>
                    ))}
                  </select>
                ) : (
                  dept.type || "-"
                )}
              </td>
              <td>
                {editingId === dept.id ? (
                  <>
                    <button
                      className="button"
                      style={{ marginRight: "8px" }}
                      onClick={() => handleUpdateDepartment(dept.id)}
                      disabled={loading}
                    >
                      Save
                    </button>
                    <button
                      className="button secondary"
                      onClick={() => setEditingId(null)}
                    >
                      Cancel
                    </button>
                  </>
                ) : (
                  <>
                    <button
                      className="button"
                      style={{ marginRight: "8px" }}
                      onClick={() => {
                        setEditingId(dept.id);
                        setEditData({ name: dept.name, type: dept.type || "" });
                      }}
                    >
                      Edit
                    </button>
                    <button
                      className="button secondary"
                      onClick={() => handleDeleteDepartment(dept.id)}
                    >
                      Delete
                    </button>
                  </>
                )}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
