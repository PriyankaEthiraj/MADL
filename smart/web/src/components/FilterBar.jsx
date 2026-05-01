export default function FilterBar({ filters, setFilters, onApply }) {
  return (
    <div className="card" style={{ marginBottom: 'var(--space-6)' }}>
      <div className="card-head">
        <div className="icon-box icon-primary">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
            <path d="M22 3H2l8 9.46V19l4 2v-8.54L22 3z"/>
          </svg>
        </div>
        <div>
          <h3 style={{ margin: 0, fontSize: '1.1rem' }}>Filter Complaints</h3>
          <p style={{ margin: 0, color: 'var(--gray-500)' }}>Refine your search results</p>
        </div>
      </div>
      
      <div className="filter-grid">
        <input
          placeholder="Search by type..."
          value={filters.type}
          onChange={(e) => setFilters({ ...filters, type: e.target.value })}
        />
        <input
          placeholder="Search by area..."
          value={filters.area}
          onChange={(e) => setFilters({ ...filters, area: e.target.value })}
        />
        <select
          value={filters.status}
          onChange={(e) => setFilters({ ...filters, status: e.target.value })}
        >
          <option value="">All Status</option>
          <option value="Pending">Pending</option>
          <option value="In Progress">In Progress</option>
          <option value="Solved">Solved</option>
        </select>
      </div>
      
      <div className="date-row">
        <input
          type="date"
          value={filters.fromDate}
          onChange={(e) => setFilters({ ...filters, fromDate: e.target.value })}
        />
        <input
          type="date"
          value={filters.toDate}
          onChange={(e) => setFilters({ ...filters, toDate: e.target.value })}
        />
        <button className="button" onClick={onApply}>
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
            <circle cx="11" cy="11" r="8"/>
            <path d="m21 21-4.35-4.35"/>
          </svg>
          Apply Filters
        </button>
      </div>
    </div>
  );
}
