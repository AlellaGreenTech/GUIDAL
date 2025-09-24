-- Drop visit_requests table and all related objects
-- Safe to run since table is empty

-- Drop dependent views first
DROP VIEW IF EXISTS pending_visit_requests CASCADE;
DROP VIEW IF EXISTS visit_requests_with_workshops CASCADE;

-- Drop the table
DROP TABLE IF EXISTS visit_requests CASCADE;

-- Drop related functions
DROP FUNCTION IF EXISTS update_visit_requests_updated_at() CASCADE;

-- Clean up any remaining policies or triggers
DROP POLICY IF EXISTS "Anyone can submit visit requests" ON visit_requests;
DROP POLICY IF EXISTS "Users can view own visit requests" ON visit_requests;
DROP POLICY IF EXISTS "Admins can manage all visit requests" ON visit_requests;

-- Verification query (should fail if cleanup worked)
-- SELECT COUNT(*) FROM visit_requests;