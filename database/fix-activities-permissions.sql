-- Fix RLS policies for activities table to allow anonymous access
-- Run this in your Supabase SQL editor

-- Enable RLS on activities table if not already enabled
ALTER TABLE public.activities ENABLE ROW LEVEL SECURITY;

-- Allow anonymous read access to activities
DROP POLICY IF EXISTS "Allow anonymous read access to activities" ON public.activities;
CREATE POLICY "Allow anonymous read access to activities"
ON public.activities
FOR SELECT
USING (true);

-- Enable RLS on activity_types table
ALTER TABLE public.activity_types ENABLE ROW LEVEL SECURITY;

-- Allow anonymous read access to activity_types
DROP POLICY IF EXISTS "Allow anonymous read access to activity_types" ON public.activity_types;
CREATE POLICY "Allow anonymous read access to activity_types"
ON public.activity_types
FOR SELECT
USING (true);

-- Grant table permissions to anon and authenticated roles
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT ON public.activities TO anon, authenticated;
GRANT SELECT ON public.activity_types TO anon, authenticated;

-- Verify permissions
SELECT 'Activities table permissions check:' as info;
SELECT schemaname, tablename, policyname, roles, cmd
FROM pg_policies
WHERE tablename IN ('activities', 'activity_types')
ORDER BY tablename;