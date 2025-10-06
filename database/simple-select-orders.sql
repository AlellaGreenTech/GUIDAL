-- Simple select without any special permissions
-- Just try to see if the tables exist and have data

-- Check table exists
SELECT tablename
FROM pg_tables
WHERE schemaname = 'public'
AND tablename = 'pumpkin_patch_orders';

-- Try direct select (if you're logged in as superuser this should work)
SELECT * FROM pumpkin_patch_orders;

-- Alternative: Check with information schema
SELECT
  table_name,
  table_type,
  (SELECT COUNT(*) FROM pumpkin_patch_orders) as row_count
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name = 'pumpkin_patch_orders';
