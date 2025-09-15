-- Comprehensive fix for all table permissions
-- Run this in your Supabase SQL editor

-- Drop existing policies that might be conflicting
DROP POLICY IF EXISTS "Allow anonymous read access to school_visits" ON public.school_visits;
DROP POLICY IF EXISTS "Allow anonymous read access to schools" ON public.schools;
DROP POLICY IF EXISTS "Allow anonymous read access to activities" ON public.activities;

-- Disable RLS temporarily to reset
ALTER TABLE public.school_visits DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.schools DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.activities DISABLE ROW LEVEL SECURITY;

-- Re-enable RLS and create proper policies
ALTER TABLE public.school_visits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.schools ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activities ENABLE ROW LEVEL SECURITY;

-- Create comprehensive policies for all roles
CREATE POLICY "Enable read access for all users" ON public.school_visits FOR SELECT USING (true);
CREATE POLICY "Enable read access for all users" ON public.schools FOR SELECT USING (true);
CREATE POLICY "Enable read access for all users" ON public.activities FOR SELECT USING (true);

-- Grant table permissions to anon role
GRANT USAGE ON SCHEMA public TO anon;
GRANT SELECT ON public.school_visits TO anon;
GRANT SELECT ON public.schools TO anon;
GRANT SELECT ON public.activities TO anon;

-- Verify permissions
SELECT 'Table permissions check:' as info;
SELECT schemaname, tablename, policyname, roles, cmd
FROM pg_policies
WHERE tablename IN ('school_visits', 'schools', 'activities')
ORDER BY tablename;