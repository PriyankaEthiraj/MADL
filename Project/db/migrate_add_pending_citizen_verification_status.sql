-- Update complaint status check constraint to support citizen verification workflow
ALTER TABLE complaints
  DROP CONSTRAINT IF EXISTS complaints_status_check;

ALTER TABLE complaints
  ADD CONSTRAINT complaints_status_check
  CHECK (status IN ('Pending', 'In Progress', 'Pending Citizen Verification', 'Resolved', 'Reopened', 'Solved', 'Closed'));