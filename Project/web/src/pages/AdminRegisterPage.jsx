import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { api } from "../services/api.js";
import "../styles/authForm.css";

export default function AdminRegisterPage() {
  const navigate = useNavigate();
  const [formData, setFormData] = useState({
    name: "",
    email: "",
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
      setError("Full name is required.");
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
        role: "admin",
      });
      navigate("/admin");
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
        <div className="auth-header admin-header">
          <div className="auth-icon">🛡️</div>
          <h1>Admin Registration</h1>
          <p>Create Admin Account</p>
        </div>

        <form className="auth-form" onSubmit={handleSubmit}>
          <div className="form-group">
            <input
              type="text"
              name="name"
              placeholder="Full Name"
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
            className="button admin-button"
            disabled={loading}
          >
            {loading ? "Registering..." : "Register as Admin"}
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
