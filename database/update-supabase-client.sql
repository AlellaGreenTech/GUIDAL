-- Update for Supabase Client to work with new schema
-- This adds necessary activity types and updates existing data

-- Add science-stations activity type for science-in-action activities
INSERT INTO activity_types (name, slug, description, color, icon)
SELECT * FROM (VALUES
  ('Science Stations', 'science-stations', 'Hands-on science learning stations and experiments', '#e91e63', '🔬')
) as t(name, slug, description, color, icon)
WHERE NOT EXISTS (SELECT 1 FROM activity_types WHERE slug = 'science-stations');

-- Update any existing science-in-action activities to use the science-stations type
UPDATE activities
SET activity_type_id = (SELECT id FROM activity_types WHERE slug = 'science-stations')
WHERE title IN (
  'Robotic Gardening',
  'Agricultural Drones & Vineyard',
  'Smart Irrigation Demo',
  'Erosion Challenge',
  'Hydraulic Ram Pumps',
  'Wattle & Daub Construction',
  'Composting & Soil Science',
  'Planting & Growing',
  'SchoolAIR IoT Sensors'
);

-- Make sure these activities are published templates (no dates)
UPDATE activities
SET
  status = 'published',
  date_time = NULL
WHERE title IN (
  'Robotic Gardening',
  'Agricultural Drones & Vineyard',
  'Smart Irrigation Demo',
  'Erosion Challenge',
  'Hydraulic Ram Pumps',
  'Wattle & Daub Construction',
  'Composting & Soil Science',
  'Planting & Growing',
  'SchoolAIR IoT Sensors'
);