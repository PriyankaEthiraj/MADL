INSERT INTO departments (name, type) VALUES
  ('Road Maintenance', 'Road Maintenance'),
  ('Street Light', 'Street Light'),
  ('Public Toilet & Sanitation', 'Public Toilet & Sanitation'),
  ('Public Transport', 'Public Transport'),
  ('Water Supply', 'Water Supply'),
  ('Garbage & Waste Management', 'Garbage & Waste Management')
ON CONFLICT (name) DO NOTHING;
