import { useNavigate } from "react-router-dom";
import "../styles/roleSelection.css";

export default function RoleSelectionPage() {
  const navigate = useNavigate();

  return (
    <div className="smartcity-container">
      <div className="role-selection-wrapper">
        <div className="role-header">
          <h1>🌆 Smart City</h1>
          <p>Select Your Role to Register</p>
        </div>

        <div className="role-grid">
          
          {/* Admin Card */}
          <div
            className="role-card admin-card"
            onClick={() => navigate("/register/admin")}
          >
            <div className="role-icon admin-icon">🛡️</div>
            <h2>Admin</h2>
            <p>Manage system and users</p>
            <button className="role-button">
              Register as Admin
            </button>
          </div>

          {/* Department Card */}
          <div
            className="role-card department-card"
            onClick={() => navigate("/register/department")}
          >
            <div className="role-icon department-icon">🏢</div>
            <h2>Department</h2>
            <p>Handle department complaints</p>
            <button className="role-button">
              Register Department
            </button>
          </div>

        </div>

        <div className="role-footer">
          <p>
            Already have an account?{" "}
            <span onClick={() => navigate("/login")} className="login-link">
              Login
            </span>
          </p>
        </div>
      </div>
    </div>
  );
}