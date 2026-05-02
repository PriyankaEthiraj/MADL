import dotenv from 'dotenv';
import pg from 'pg';

dotenv.config();
const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });

try {
  const res = await pool.query(
    "SELECT complaint_id, remark FROM status_logs WHERE remark LIKE 'RESOLUTION_PROOF:%' ORDER BY complaint_id DESC"
  );
  
  console.log('Resolution Proofs in Database:\n');
  
  res.rows.forEach(row => {
    try {
      const proof = JSON.parse(row.remark.replace('RESOLUTION_PROOF:', ''));
      console.log(`Complaint ${row.complaint_id}:`);
      console.log(`  Main proof URL: ${proof.proof_url}`);
      
      if (proof.proofs && Array.isArray(proof.proofs)) {
        console.log(`  Additional proofs (${proof.proofs.length}):`);
        proof.proofs.forEach((p, i) => {
          console.log(`    [${i}] ${p}`);
        });
      }
      console.log();
    } catch (e) {
      console.log(`Complaint ${row.complaint_id}: Error parsing JSON\n`);
    }
  });
  
  if (res.rows.length === 0) {
    console.log('No resolution proofs found in database.');
  }
  
} finally {
  await pool.end();
}
