import { useAuth } from "../contexts/AuthContext.jsx";

export default function Layout({ title, children }) {
  const { user, logout } = useAuth();

  return (
    <div className="dashboard-shell">
      <header className="dashboard-header">
        <div className="container dashboard-header-inner">
          <div>
            <h1 className="dashboard-title">{title}</h1>
            <p className="dashboard-subtitle">
              <span className="user-initial">
                {user?.name?.charAt(0).toUpperCase()}
              </span>
              <span className="user-name">{user?.name}</span>
              <span className="user-role">
                {user?.role}
              </span>
            </p>
          </div>
          <button className="button secondary" onClick={logout}>
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4M16 17l5-5-5-5M21 12H9"/>
            </svg>
            Logout
          </button>
        </div>
      </header>
      <main className="container">{children}</main>
    </div>
  );
}
