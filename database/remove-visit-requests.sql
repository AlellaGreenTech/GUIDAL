-- Manual cleanup script to remove visit_requests table
-- Run this in Supabase SQL Editor

-- Remove views that depend on visit_requests
DROP VIEW IF EXISTS pending_visit_requests CASCADE;
DROP VIEW IF EXISTS visit_requests_with_workshops CASCADE;

-- Remove the table
DROP TABLE IF EXISTS visit_requests CASCADE;

-- Remove related functions
DROP FUNCTION IF EXISTS update_visit_requests_updated_at() CASCADE;

-- Verify cleanup (this should return an error saying table doesn't exist)
-- SELECT COUNT(*) FROM visit_requests;