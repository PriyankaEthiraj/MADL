import dotenv from 'dotenv';
import pg from 'pg';

dotenv.config();

const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });

try {
  const res = await pool.query('SELECT id, photo_url, video_url, status FROM complaints ORDER BY id');
  console.log('=== Active Complaints ===');
  res.rows.forEach(row => {
    console.log('ID', row.id, '| Status:', row.status);
    console.log('  Photo:', row.photo_url || 'N/A');
    console.log('  Video:', row.video_url || 'N/A');
  });
  
  const logsRes = await pool.query(
    "SELECT complaint_id, status, remark FROM status_logs WHERE remark LIKE 'RESOLUTION_PROOF:%' ORDER BY complaint_id, updated_at DESC LIMIT 5"
  );
  console.log('\n=== Recent Resolution Proofs ===');
  logsRes.rows.forEach(row => {
    console.log('Complaint', row.complaint_id, '| Status:', row.status);
    if (row.remark.length > 100) {
      console.log('  Proof (truncated):', row.remark.substring(0, 100) + '...');
    }
  });
} finally {
  await pool.end();
}
