-- Insert schools from the 2025 visits CSV data
-- This will populate the schools dropdown in the registration form

INSERT INTO schools (name, address, created_at) VALUES
('Benjamin Franklin International School', 'Spain', NOW()),
('CAS Trips - H-Farm International', 'Italy', NOW()),
('St. Patricks International School', 'Spain', NOW()),
('Barcelona Montessori School', 'Barcelona, Spain', NOW()),
('Homeschool Maresme', 'Spain', NOW()),
('Learnlife', 'Spain', NOW()),
('St George', 'Spain', NOW()),
('Zurich International School', 'Switzerland', NOW()),
('International School of Prague', 'Czech Republic', NOW());

-- Schools data added successfully!
-- The schools dropdown in the registration form will now be populated with these schools.
-- Visit/trip data can be added later through the admin interface if needed.