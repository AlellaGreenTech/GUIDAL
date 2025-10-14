-- Fix RLS policies for visits table to allow anonymous inserts
-- This allows the visit planning form to work for non-logged-in users

BEGIN;

-- Drop existing restrictive policies if they exist
DROP POLICY IF EXISTS "anyone_can_create_visits" ON visits;
DROP POLICY IF EXISTS "anon_can_insert_visits" ON visits;
DROP POLICY IF EXISTS "public_can_insert_visits" ON visits;

-- Create a permissive policy for anonymous users to insert visits
CREATE POLICY "allow_anonymous_visit_insert" ON visits
    FOR INSERT
    TO anon, authenticated
    WITH CHECK (true);

-- Also allow viewing visits for authenticated users
DROP POLICY IF EXISTS "users_can_view_own_visits" ON visits;
CREATE POLICY "authenticated_can_view_visits" ON visits
    FOR SELECT
    TO authenticated
    USING (true);

-- Grant necessary permissions
GRANT INSERT ON visits TO anon, authenticated;
GRANT SELECT ON visits TO authenticated;
GRANT ALL ON visits TO service_role;

-- Ensure contacts and schools tables also allow anonymous inserts
DROP POLICY IF EXISTS "allow_anonymous_contact_insert" ON contacts;
CREATE POLICY "allow_anonymous_contact_insert" ON contacts
    FOR INSERT
    TO anon, authenticated
    WITH CHECK (true);

DROP POLICY IF EXISTS "allow_anonymous_school_insert" ON schools;
CREATE POLICY "allow_anonymous_school_insert" ON schools
    FOR INSERT
    TO anon, authenticated
    WITH CHECK (true);

GRANT INSERT ON contacts TO anon, authenticated;
GRANT INSERT ON schools TO anon, authenticated;

-- Grant sequence usage for ID generation
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;

COMMIT;

-- Verification queries
SELECT
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd
FROM pg_policies
WHERE tablename IN ('visits', 'contacts', 'schools')
ORDER BY tablename, policyname;
