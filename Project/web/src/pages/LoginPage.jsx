import { useState } from "react";
import { useAuth } from "../contexts/AuthContext.jsx";
import { useNavigate } from "react-router-dom";
import "../styles/authForm.css";

const emailRegex = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;

export default function LoginPage() {
  const { login } = useAuth();
  const navigate = useNavigate();
  const [emailOrPhone, setEmailOrPhone] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState(null);
  const [loading, setLoading] = useState(false);

  const validate = () => {
    const trimmed = emailOrPhone.trim();
    if (!trimmed) return "Email or phone number is required";

    if (trimmed.includes("@")) {
      if (!emailRegex.test(trimmed)) return "Enter a valid email address";
    } else if (/^\d+$/.test(trimmed)) {
      if (trimmed.length < 10) return "Enter a valid phone number";
    } else {
      return "Enter a valid email address or phone number";
    }

    if (!password.trim()) return "Password is required";
    return null;
  };

  const handleSubmit = async (event) => {
    event.preventDefault();
    const validationError = validate();
    if (validationError) {
      setError(validationError);
      return;
    }

    setError(null);
    setLoading(true);
    try {
      await login(emailOrPhone.trim(), password);
      navigate("/");
    } catch (err) {
      const message = err.response?.data?.message || err.message || "Login failed";
      setError(message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="auth-page">
      <div className="auth-container">
        <div className="auth-header">
          <div className="auth-icon" style={{ background: "linear-gradient(135deg, #0b8de0 0%, #11bddc 100%)" }}>🔒</div>
          <h1>Admin/Department Login</h1>
          <p>Sign in to your account</p>
        </div>

        <form className="auth-form" onSubmit={handleSubmit}>
          <div className="form-group">
            <label htmlFor="emailOrPhone" className="input-label">Email or Phone Number</label>
            <input
              id="emailOrPhone"
              type="text"
              placeholder="Enter your email address or phone number"
              value={emailOrPhone}
              onChange={(e) => {
                setEmailOrPhone(e.target.value);
                if (error) setError(null);
              }}
              autoComplete="username"
              disabled={loading}
            />
          </div>

          <div className="form-group">
            <label htmlFor="password" className="input-label">Password</label>
            <div className="password-input">
              <input
                id="password"
                type={showPassword ? "text" : "password"}
                placeholder="Enter your password"
                value={password}
                onChange={(e) => {
                  setPassword(e.target.value);
                  if (error) setError(null);
                }}
                autoComplete="current-password"
                disabled={loading}
              />
              <button
                type="button"
                className="password-toggle"
                onClick={() => setShowPassword((prev) => !prev)}
                aria-label={showPassword ? "Hide password" : "Show password"}
                disabled={loading}
              >
                {showPassword ? "👁️" : "👁️‍🗨️"}
              </button>
            </div>
          </div>

          {error && <div className="error-message">{error}</div>}

          <button type="submit" className="button" style={{ background: "linear-gradient(135deg, #0b8de0 0%, #11bddc 100%)" }} disabled={loading}>
            {loading ? "Logging in..." : "Login"}
          </button>
        </form>

        <div className="auth-footer">
          <p style={{ margin: "16px 0 0 0", fontSize: "14px", color: "#4a5f7d" }}>
            Don't have an account?{" "}
            <button
              type="button"
              className="link-button"
              onClick={() => navigate("/register")}
            >
              Register
            </button>
          </p>
        </div>
      </div>
    </div>
  );
}
