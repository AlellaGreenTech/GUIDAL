-- Simple test to verify database connection and current state
-- Run this first to check your current setup

-- Check if visits table exists and what columns it has
SELECT
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'visits'
ORDER BY ordinal_position;

-- Check if schools table exists
SELECT COUNT(*) as schools_table_exists
FROM information_schema.tables
WHERE table_name = 'schools';

-- Check if contacts table exists
SELECT COUNT(*) as contacts_table_exists
FROM information_schema.tables
WHERE table_name = 'contacts';

-- Check current visits table structure
SELECT COUNT(*) as total_visits FROM visits;

-- Show a sample visit record to understand current structure
SELECT * FROM visits LIMIT 1;