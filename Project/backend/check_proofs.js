import dotenv from 'dotenv';
import pg from 'pg';

dotenv.config();
const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });

try {
  const res = await pool.query(
    "SELECT complaint_id, remark FROM status_logs WHERE remark LIKE 'RESOLUTION_PROOF:%' ORDER BY complaint_id DESC LIMIT 10"
  );
  
  res.rows.forEach((row) => {
    try {
      const jsonStr = row.remark.replace('RESOLUTION_PROOF:', '');
      const data = JSON.parse(jsonStr);
      console.log('Complaint ' + row.complaint_id + ':');
      console.log('  Proof URL:', data.proof_url || 'N/A');
      if (data.proofs && Array.isArray(data.proofs)) {
        console.log('  Proofs array length:', data.proofs.length);
        data.proofs.forEach((p, i) => {
          console.log('    [' + i + '] Type:', p.type, 'URL:', p.url);
        });
      }
    } catch (e) {
      console.log('Complaint ' + row.complaint_id + ': Parse error -', e.message);
    }
  });
} finally {
  await pool.end();
}
