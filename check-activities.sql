-- Quick check of activities in database
-- Run this in Supabase SQL editor to see what we have

-- Check activities count and status
SELECT
  status,
  COUNT(*) as count
FROM activities
GROUP BY status;

-- Check first few activities
SELECT
  id,
  title,
  status,
  date_time,
  activity_type_id
FROM activities
ORDER BY created_at
LIMIT 5;

-- Check if activity_types table has data and join works
SELECT
  a.title,
  a.status,
  at.name as activity_type_name,
  at.slug as activity_type_slug
FROM activities a
LEFT JOIN activity_types at ON a.activity_type_id = at.id
LIMIT 5;

-- Check RLS policies on activities table
SELECT
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies
WHERE tablename = 'activities';