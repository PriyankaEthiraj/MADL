-- Create wards table with geolocation boundaries
CREATE TABLE IF NOT EXISTS wards (
  id SERIAL PRIMARY KEY,
  ward_number INTEGER NOT NULL UNIQUE,
  name TEXT,
  lat_min DECIMAL(10, 8) NOT NULL,
  lat_max DECIMAL(10, 8) NOT NULL,
  lon_min DECIMAL(11, 8) NOT NULL,
  lon_max DECIMAL(11, 8) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Create officers table
CREATE TABLE IF NOT EXISTS officers (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT UNIQUE,
  phone TEXT,
  department_id INTEGER NOT NULL REFERENCES departments(id) ON DELETE CASCADE,
  ward_id INTEGER NOT NULL REFERENCES wards(id) ON DELETE CASCADE,
  status TEXT NOT NULL CHECK (status IN ('Active', 'Inactive')) DEFAULT 'Active',
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  UNIQUE(department_id, ward_id)
);

-- Add new columns to complaints table for auto-assignment
ALTER TABLE complaints ADD COLUMN IF NOT EXISTS predicted_department TEXT;
ALTER TABLE complaints ADD COLUMN IF NOT EXISTS ward_id INTEGER REFERENCES wards(id) ON DELETE SET NULL;
ALTER TABLE complaints ADD COLUMN IF NOT EXISTS assigned_officer_id INTEGER REFERENCES officers(id) ON DELETE SET NULL;

-- Create indices for performance
CREATE INDEX IF NOT EXISTS idx_wards_geolocation ON wards(lat_min, lat_max, lon_min, lon_max);
CREATE INDEX IF NOT EXISTS idx_officers_department_ward ON officers(department_id, ward_id);
CREATE INDEX IF NOT EXISTS idx_officers_status ON officers(status);
CREATE INDEX IF NOT EXISTS idx_complaints_ward ON complaints(ward_id);
CREATE INDEX IF NOT EXISTS idx_complaints_assigned_officer ON complaints(assigned_officer_id);
CREATE INDEX IF NOT EXISTS idx_complaints_predicted_department ON complaints(predicted_department);

-- Insert sample wards (Bangalore example with lat/lon boundaries)
INSERT INTO wards (ward_number, name, lat_min, lat_max, lon_min, lon_max) VALUES
(1, 'Basavanagudi', 12.939, 12.952, 77.558, 77.571),
(2, 'Fort Ward', 12.954, 12.968, 77.586, 77.599),
(3, 'Chickpet', 12.968, 12.982, 77.604, 77.617),
(4, 'KR Market', 12.952, 12.965, 77.645, 77.658),
(5, 'Malleswaram', 13.003, 13.017, 77.601, 77.614),
(6, 'Frazer Town', 12.985, 12.999, 77.615, 77.628),
(7, 'CV Raman Nagar', 12.978, 12.992, 77.632, 77.645),
(8, 'Indiranagar', 12.993, 13.007, 77.647, 77.660),
(9, 'Whitefield', 12.961, 12.975, 77.737, 77.750),
(10, 'RMZ EcoSpace', 12.950, 12.964, 77.747, 77.760),
(11, 'Hebbal', 13.040, 13.054, 77.599, 77.612),
(12, 'Bangalore South', 12.900, 12.950, 77.600, 77.650);

-- Create audit log for admin overrides
CREATE TABLE IF NOT EXISTS complaint_override_logs (
  id SERIAL PRIMARY KEY,
  complaint_id INTEGER NOT NULL REFERENCES complaints(id) ON DELETE CASCADE,
  admin_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  old_department_id INTEGER REFERENCES departments(id),
  new_department_id INTEGER REFERENCES departments(id),
  old_officer_id INTEGER REFERENCES officers(id),
  new_officer_id INTEGER REFERENCES officers(id),
  reason TEXT,
  changed_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_complaint_override_logs_complaint ON complaint_override_logs(complaint_id);
CREATE INDEX IF NOT EXISTS idx_complaint_override_logs_admin ON complaint_override_logs(admin_id);
