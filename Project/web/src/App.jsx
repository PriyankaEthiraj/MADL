import { Routes, Route, Navigate } from "react-router-dom";
import AuthLanding from "./pages/AuthLanding.jsx";
import Login from "./pages/Login.jsx";
import Register from "./pages/Register.jsx";
import AdminDashboard from "./pages/AdminDashboard.jsx";
import DepartmentDashboard from "./pages/DepartmentDashboard.jsx";
import ResolutionVerificationPage from "./pages/ResolutionVerificationPage.jsx";
import NotFound from "./pages/NotFound.jsx";
import { useAuth } from "./contexts/AuthContext.jsx";

const Protected = ({ children, roles }) => {
  const { user, loading } = useAuth();
  
  if (loading) {
    return (
      <div style={{ display: "flex", justifyContent: "center", alignItems: "center", minHeight: "100vh" }}>
        <p>Loading...</p>
      </div>
    );
  }
  
  if (!user) return <Navigate to="/login" replace />;
  if (roles && !roles.includes(user.role)) return <Navigate to="/login" replace />;
  return children;
};

const HomeRedirect = () => {
  const { user, loading } = useAuth();
  
  if (loading) {
    return (
      <div style={{ display: "flex", justifyContent: "center", alignItems: "center", minHeight: "100vh" }}>
        <p>Loading...</p>
      </div>
    );
  }
  
  if (!user) return <Navigate to="/" replace />;
  return user.role === "admin" ? (
    <Navigate to="/admin/dashboard" replace />
  ) : (
    <Navigate to="/department/dashboard" replace />
  );
};

export default function App() {
  return (
    <Routes>
      {/* Landing Page with Entry Icons */}
      <Route path="/" element={<AuthLanding />} />
      
      {/* Admin Authentication Routes */}
      <Route path="/admin/login" element={<Login userType="admin" />} />
      <Route path="/admin/register" element={<Register userType="admin" />} />
      
      {/* Department Authentication Routes */}
      <Route path="/department/login" element={<Login userType="department" />} />
      <Route path="/department/register" element={<Register userType="department" />} />
      
      {/* Protected Dashboard Routes */}
      <Route
        path="/admin/dashboard"
        element={
          <Protected roles={["admin"]}>
            <AdminDashboard />
          </Protected>
        }
      />
      <Route
        path="/department/dashboard"
        element={
          <Protected roles={["department"]}>
            <DepartmentDashboard />
          </Protected>
        }
      />
      <Route
        path="/resolve/:id"
        element={
          <Protected roles={["admin", "department"]}>
            <ResolutionVerificationPage />
          </Protected>
        }
      />
      
      {/* Legacy Routes - Redirect to new structure */}
      <Route path="/admin" element={<Navigate to="/admin/dashboard" replace />} />
      <Route path="/department" element={<Navigate to="/department/dashboard" replace />} />
      <Route path="/login" element={<Navigate to="/" replace />} />
      <Route path="/register" element={<Navigate to="/" replace />} />
      
      {/* 404 Not Found */}
      <Route path="*" element={<NotFound />} />
    </Routes>
  );
}
