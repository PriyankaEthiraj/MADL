import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { api } from "../services/api.js";
import "../styles/authForm.css";

const DEPARTMENT_TYPES = [
  "Road Maintenance",
  "Street Light",
  "Public Toilet & Sanitation",
  "Public Transport",
  "Water Supply",
  "Garbage & Waste Management",
];

export default function DepartmentRegisterPage() {
  const navigate = useNavigate();
  const [formData, setFormData] = useState({
    name: "",
    email: "",
    departmentName: "",
    departmentType: "",
    password: "",
    confirmPassword: "",
  });
  const [error, setError] = useState(null);
  const [loading, setLoading] = useState(false);

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData((prev) => ({ ...prev, [name]: value }));
    setError(null);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();

    // Validation
    if (!formData.name.trim()) {
      setError("Coordinator name is required.");
      return;
    }
    if (!formData.email.trim()) {
      setError("Email address is required.");
      return;
    }
    if (!formData.email.includes("@")) {
      setError("Please enter a valid email address.");
      return;
    }
    if (!formData.departmentName.trim()) {
      setError("Department name is required.");
      return;
    }
    if (!formData.departmentType) {
      setError("Please select a department type.");
      return;
    }
    if (!formData.password) {
      setError("Password is required.");
      return;
    }
    if (formData.password.length < 8) {
      setError("Password must be at least 8 characters long.");
      return;
    }
    if (formData.password !== formData.confirmPassword) {
      setError("Passwords do not match.");
      return;
    }

    setLoading(true);
    try {
      await api.post("/auth/register", {
        name: formData.name,
        email: formData.email,
        password: formData.password,
        role: "department",
        department_name: formData.departmentName,
        department_type: formData.departmentType,
      });
      navigate("/department");
    } catch (err) {
      setError(
        err.response?.data?.message ||
          "Registration failed. Please try again."
      );
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="auth-page">
      <div className="auth-container">
        <div className="auth-header department-header">
          <div className="auth-icon">🏢</div>
          <h1>Department Registration</h1>
          <p>Register Your Department</p>
        </div>

        <form className="auth-form" onSubmit={handleSubmit}>
          <div className="form-group">
            <input
              type="text"
              name="name"
              placeholder="Coordinator Name"
              value={formData.name}
              onChange={handleChange}
              required
            />
          </div>

          <div className="form-group">
            <input
              type="email"
              name="email"
              placeholder="Email Address"
              value={formData.email}
              onChange={handleChange}
              required
            />
          </div>

          <div className="form-group">
            <input
              type="text"
              name="departmentName"
              placeholder="Department Name"
              value={formData.departmentName}
              onChange={handleChange}
              required
            />
          </div>

          <div className="form-group">
            <select
              name="departmentType"
              value={formData.departmentType}
              onChange={handleChange}
              required
            >
              <option value="">Select Department Type</option>
              {DEPARTMENT_TYPES.map((type) => (
                <option key={type} value={type}>
                  {type}
                </option>
              ))}
            </select>
          </div>

          <div className="form-group">
            <input
              type="password"
              name="password"
              placeholder="Password (min 8 chars)"
              value={formData.password}
              onChange={handleChange}
              required
            />
          </div>

          <div className="form-group">
            <input
              type="password"
              name="confirmPassword"
              placeholder="Confirm Password"
              value={formData.confirmPassword}
              onChange={handleChange}
              required
            />
          </div>

          {error && <div className="error-message">{error}</div>}

          <button
            type="submit"
            className="button department-button"
            disabled={loading}
          >
            {loading ? "Registering..." : "Register Department"}
          </button>
        </form>

        <div className="auth-footer">
          <button
            type="button"
            className="link-button"
            onClick={() => navigate("/register")}
          >
            ← Back
          </button>
        </div>
      </div>
    </div>
  );
}
