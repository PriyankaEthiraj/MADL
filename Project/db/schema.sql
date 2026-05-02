CREATE TABLE IF NOT EXISTS departments (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  type TEXT
);

CREATE TABLE IF NOT EXISTS users (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  phone TEXT UNIQUE,
  address TEXT,
  password TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('citizen', 'admin', 'department')),
  department_id INTEGER REFERENCES departments(id) ON DELETE SET NULL,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

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

CREATE TABLE IF NOT EXISTS complaints (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  department_id INTEGER REFERENCES departments(id) ON DELETE SET NULL,
  type TEXT NOT NULL,
  description TEXT NOT NULL,
  location TEXT NOT NULL,
  photo_url TEXT,
  video_url TEXT,
  photo_latitude DECIMAL(10, 8),
  photo_longitude DECIMAL(11, 8),
  photo_timestamp TIMESTAMP,
  photo_location_name TEXT,
  video_latitude DECIMAL(10, 8),
  video_longitude DECIMAL(11, 8),
  video_timestamp TIMESTAMP,
  video_location_name TEXT,
  predicted_department TEXT,
  ward_id INTEGER REFERENCES wards(id) ON DELETE SET NULL,
  assigned_officer_id INTEGER REFERENCES officers(id) ON DELETE SET NULL,
  status TEXT NOT NULL CHECK (status IN ('Pending', 'In Progress', 'Pending Citizen Verification', 'Resolved', 'Reopened', 'Solved', 'Closed')),
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

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

CREATE TABLE IF NOT EXISTS status_logs (
  id SERIAL PRIMARY KEY,
  complaint_id INTEGER NOT NULL REFERENCES complaints(id) ON DELETE CASCADE,
  status TEXT NOT NULL,
  updated_by INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  remark TEXT,
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS feedback (
  id SERIAL PRIMARY KEY,
  complaint_id INTEGER NOT NULL REFERENCES complaints(id) ON DELETE CASCADE,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  rating INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_complaints_user ON complaints(user_id);
CREATE INDEX IF NOT EXISTS idx_complaints_department ON complaints(department_id);
CREATE INDEX IF NOT EXISTS idx_complaints_status ON complaints(status);
CREATE INDEX IF NOT EXISTS idx_wards_geolocation ON wards(lat_min, lat_max, lon_min, lon_max);
CREATE INDEX IF NOT EXISTS idx_officers_department_ward ON officers(department_id, ward_id);
CREATE INDEX IF NOT EXISTS idx_officers_status ON officers(status);
CREATE INDEX IF NOT EXISTS idx_complaints_ward ON complaints(ward_id);
CREATE INDEX IF NOT EXISTS idx_complaints_assigned_officer ON complaints(assigned_officer_id);
CREATE INDEX IF NOT EXISTS idx_complaints_predicted_department ON complaints(predicted_department);
CREATE INDEX IF NOT EXISTS idx_complaint_override_logs_complaint ON complaint_override_logs(complaint_id);
CREATE INDEX IF NOT EXISTS idx_complaint_override_logs_admin ON complaint_override_logs(admin_id);
