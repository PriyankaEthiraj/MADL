export default function StatsCards({ stats }) {
  const statusLabel = (status) => {
    const value = `${status || ""}`.toLowerCase();
    if (value === "resolved" || value === "solved") return "Solved";
    if (value === "closed") return "Solved";
    if (value === "in progress" || value === "in_progress") return "In Progress";
    if (value === "pending citizen verification") return "Pending Citizen Verification";
    return status || "Unknown";
  };

  const items = [
    {
      label: "By Status",
      data: stats?.byStatus || [],
      icon: (
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
          <circle cx="12" cy="12" r="10"/>
          <path d="M12 6v6l4 2"/>
        </svg>
      ),
      accent: false
    },
    {
      label: "By Department",
      data: stats?.byDepartment || [],
      icon: (
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
          <path d="M3 9l9-7 9 7v11a2 2 0 01-2 2H5a2 2 0 01-2-2z"/>
          <polyline points="9 22 9 12 15 12 15 22"/>
        </svg>
      ),
      accent: true
    }
  ];

  return (
    <div className="grid grid-2 stats-grid">
      {items.map((item) => (
        <div className="card stats-card" key={item.label}>
          <div className="card-head">
            <h4>{item.label}</h4>
            <div className={`icon-box ${item.accent ? "icon-accent" : "icon-primary"}`}>
              {item.icon}
            </div>
          </div>
          <ul className="stats-list">
            {item.data.length === 0 ? (
              <li style={{ color: 'var(--gray-400)', fontStyle: 'italic' }}>No data available</li>
            ) : (
              item.data.map((row) => (
                <li key={row.type || row.status || row.department} className="stats-list-item">
                  <span style={{ fontWeight: 500 }}>
                    {row.type ? row.type : row.status ? statusLabel(row.status) : row.department}
                  </span>
                  <span className={`count-pill ${item.accent ? "accent" : ""}`}>
                    {row.count}
                  </span>
                </li>
              ))
            )}
          </ul>
        </div>
      ))}
    </div>
  );
}
