const statusClass = (status) => status ? status.replace(" ", "_") : "unknown";

const statusLabel = (status) => {
  const value = `${status || ""}`.toLowerCase();
  if (value === "resolved") return "Solved";
  if (value === "solved") return "Solved";
  if (value === "closed") return "Solved";
  if (value === "in progress" || value === "in_progress") return "In Progress";
  if (value === "pending citizen verification") return "Pending Citizen Verification";
  return status || "Unknown";
};

export default function ComplaintTable({ complaints, onSelectComplaint, renderActions }) {
  const hasActions = typeof renderActions === "function";

  return (
    <div className="card table-shell">
      {!complaints || complaints.length === 0 ? (
        <div className="empty-state">
          <div className="empty-state-icon">
            <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <path d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"/>
            </svg>
          </div>
          <p style={{ fontSize: '1.125rem', marginBottom: 'var(--space-2)', fontWeight: 600, color: 'var(--gray-700)' }}>
            No complaints found
          </p>
          <p style={{ fontSize: '0.9375rem' }}>
            Complaints submitted by citizens will appear here
          </p>
        </div>
      ) : (
        <table className="table">
          <thead>
            <tr>
              <th style={{ paddingLeft: 'var(--space-6)' }}>ID</th>
              <th>Type</th>
              <th>Citizen</th>
              <th>Department</th>
              <th>Location</th>
              <th>Status</th>
              {hasActions && <th>Actions</th>}
              <th style={{ paddingRight: 'var(--space-6)' }}>Created</th>
            </tr>
          </thead>
          <tbody>
            {complaints.map((c) => (
              <tr
                key={c.id}
                onClick={() => onSelectComplaint?.(c)}
                style={{ cursor: onSelectComplaint ? "pointer" : "default" }}
                title={onSelectComplaint ? "Click to view full details" : undefined}
              >
                <td style={{ paddingLeft: 'var(--space-6)' }}>
                  <span className="row-id">#{c.id}</span>
                </td>
                <td>
                  <span style={{ fontWeight: 600 }}>{c.type || "N/A"}</span>
                </td>
                <td>{c.citizen_name || "Unknown"}</td>
                <td>
                  <span style={{ color: c.department_name ? 'var(--gray-700)' : 'var(--gray-400)', fontStyle: c.department_name ? 'normal' : 'italic' }}>
                    {c.department_name || "Unassigned"}
                  </span>
                </td>
                <td style={{ maxWidth: '200px' }}>
                  <span className="table-location">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                      <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/>
                      <circle cx="12" cy="10" r="3"/>
                    </svg>
                    {c.location || "N/A"}
                  </span>
                </td>
                <td>
                  <span className={`badge ${statusClass(c.status)}`}>
                    {statusLabel(c.status)}
                  </span>
                </td>
                {hasActions && (
                  <td onClick={(e) => e.stopPropagation()}>
                    {renderActions(c)}
                  </td>
                )}
                <td style={{ paddingRight: 'var(--space-6)', fontSize: '0.875rem' }}>
                  {c.created_at ? new Date(c.created_at).toLocaleString('en-US', {
                    month: 'short',
                    day: 'numeric',
                    year: 'numeric',
                    hour: '2-digit',
                    minute: '2-digit'
                  }) : "N/A"}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
}
