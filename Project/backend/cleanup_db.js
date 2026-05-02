import dotenv from 'dotenv';
import pg from 'pg';

dotenv.config();
const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });

try {
  // Clear resolution proofs so you can re-submit
  await pool.query(
    "DELETE FROM status_logs WHERE remark LIKE 'RESOLUTION_PROOF:%'"
  );
  
  // Reset complaint status so you can submit fresh proofs
  await pool.query(
    "UPDATE complaints SET status = 'In Progress' WHERE status IN ('Pending Citizen Verification', 'Resolving Verification', 'Reopened')"
  );
  
  console.log('Database cleaned up:');
  console.log('- Deleted all resolution proof log entries');
  console.log('- Reset complaint statuses to "In Progress"');
  
  const res = await pool.query('SELECT id, status FROM complaints ORDER BY id');
  console.log('\nCurrent complaint statuses:');
  res.rows.forEach(row => console.log('  ID ' + row.id + ': ' + row.status));
  
} finally {
  await pool.end();
}
