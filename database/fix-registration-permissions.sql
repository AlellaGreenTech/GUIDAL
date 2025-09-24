-- Fix permissions for activity registrations
-- Run this in Supabase SQL Editor with admin permissions

-- Grant INSERT permission to anonymous users for activity_registrations table
GRANT INSERT ON activity_registrations TO anon;

-- Create or update RLS policy to allow anonymous users to register for activities
DROP POLICY IF EXISTS "Allow anonymous registration" ON activity_registrations;
CREATE POLICY "Allow anonymous registration" ON activity_registrations
    FOR INSERT
    TO anon
    WITH CHECK (true);

-- Also allow authenticated users to register
DROP POLICY IF EXISTS "Allow authenticated users to register" ON activity_registrations;
CREATE POLICY "Allow authenticated users to register" ON activity_registrations
    FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- Allow users to view their own registrations
DROP POLICY IF EXISTS "Users can view own registrations" ON activity_registrations;
CREATE POLICY "Users can view own registrations" ON activity_registrations
    FOR SELECT
    TO authenticated
    USING (user_id = auth.uid());

-- Allow anonymous users to view registrations (for counting purposes)
DROP POLICY IF EXISTS "Anonymous can view registrations" ON activity_registrations;
CREATE POLICY "Anonymous can view registrations" ON activity_registrations
    FOR SELECT
    TO anon
    USING (true);

-- Verify the policies
SELECT
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE tablename = 'activity_registrations';

-- Test the permissions
SELECT
    grantee,
    privilege_type
FROM information_schema.role_table_grants
WHERE table_name = 'activity_registrations';