-- Test Migration Steps
-- Run these one by one to test the migration safely

-- STEP 1: Check current state
SELECT 'Current Activities Count' as check_name, count(*) as count FROM activities;
SELECT 'Current Visits Count' as check_name, count(*) as count FROM visits;
SELECT 'Current Activity Types' as check_name, string_agg(name, ', ') as types FROM activity_types;

-- STEP 2: Check for scheduled activities (activities with dates)
SELECT
    'Scheduled Activities' as check_name,
    count(*) as count
FROM activities
WHERE date_time IS NOT NULL;

-- Show some scheduled activities
SELECT
    title,
    date_time,
    status,
    activity_type_id
FROM activities
WHERE date_time IS NOT NULL
LIMIT 5;

-- STEP 3: Add science-stations activity type (safe to run multiple times)
INSERT INTO activity_types (name, slug, description, color, icon)
SELECT * FROM (VALUES
  ('Science Stations', 'science-stations', 'Hands-on science learning stations and experiments', '#e91e63', '🔬')
) as t(name, slug, description, color, icon)
WHERE NOT EXISTS (SELECT 1 FROM activity_types WHERE slug = 'science-stations');

-- Check if it was added
SELECT * FROM activity_types WHERE slug = 'science-stations';

-- STEP 4: Test creating a backup table (safe operation)
CREATE TABLE IF NOT EXISTS activities_backup_test AS
SELECT * FROM activities LIMIT 0; -- Empty backup for testing

-- Check if backup table was created
SELECT 'Backup table created' as status, count(*) as columns
FROM information_schema.columns
WHERE table_name = 'activities_backup_test';

-- STEP 5: Test if we can create scheduled_visits table structure (without data)
CREATE TABLE IF NOT EXISTS scheduled_visits_test (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  visit_type TEXT NOT NULL DEFAULT 'individual_workshop',
  scheduled_date TIMESTAMP WITH TIME ZONE NOT NULL,
  duration_minutes INTEGER,
  max_participants INTEGER,
  current_participants INTEGER DEFAULT 0,
  status TEXT DEFAULT 'pending',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Check if test table was created
SELECT 'Test scheduled_visits table' as status, count(*) as columns
FROM information_schema.columns
WHERE table_name = 'scheduled_visits_test';

-- STEP 6: Test science-in-action activity updates (dry run)
SELECT
    'Science Activities to Update' as check_name,
    count(*) as count
FROM activities
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

-- Show which ones exist
SELECT
    title,
    status,
    date_time IS NOT NULL as has_date
FROM activities
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

-- STEP 7: Clean up test tables
DROP TABLE IF EXISTS activities_backup_test;
DROP TABLE IF EXISTS scheduled_visits_test;

-- Summary check
SELECT 'Migration Test Complete' as status,
       'Ready for full migration' as next_step;