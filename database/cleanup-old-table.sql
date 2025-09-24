-- Cleanup script to remove old visit_requests table
-- Only run this after confirming all data is properly migrated to visits table

-- Step 1: Check if visit_requests table exists and has data
-- SELECT COUNT(*) FROM visit_requests; -- Uncomment to check data count

-- Step 2: Backup any data from visit_requests if needed (optional)
-- CREATE TABLE visit_requests_backup AS SELECT * FROM visit_requests;

-- Step 3: Drop the old table and related objects
DROP VIEW IF EXISTS pending_visit_requests;
DROP VIEW IF EXISTS visit_requests_with_workshops;
DROP TABLE IF EXISTS visit_requests CASCADE;

-- Step 4: Drop any orphaned functions
DROP FUNCTION IF EXISTS update_visit_requests_updated_at() CASCADE;

-- Verification: Check that only visits table remains
-- SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' AND table_name LIKE '%visit%';