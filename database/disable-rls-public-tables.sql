-- DISABLE RLS FOR PUBLIC READ TABLES
-- This script disables RLS for tables that need public read access
-- Run this in your Supabase SQL editor

-- =====================================================
-- SECTION 1: DISABLE RLS FOR ACTIVITY_TYPES (PUBLIC DATA)
-- =====================================================

-- Activity types should be publicly readable (like categories)
ALTER TABLE public.activity_types DISABLE ROW LEVEL SECURITY;

-- =====================================================
-- SECTION 2: DISABLE RLS FOR SCHOOLS (PUBLIC DATA)
-- =====================================================

-- Schools should be publicly readable (for dropdowns)
ALTER TABLE public.schools DISABLE ROW LEVEL SECURITY;

-- =====================================================
-- SECTION 3: FIX ACTIVITIES RLS WITH SIMPLE POLICY
-- =====================================================

-- Keep RLS enabled for activities but make published ones truly public
ALTER TABLE public.activities ENABLE ROW LEVEL SECURITY;

-- Drop all existing policies
DROP POLICY IF EXISTS "Activities are viewable by everyone" ON public.activities;
DROP POLICY IF EXISTS "Published activities are viewable by everyone" ON public.activities;
DROP POLICY IF EXISTS "Admins can insert activities" ON public.activities;
DROP POLICY IF EXISTS "Admins can update activities" ON public.activities;
DROP POLICY IF EXISTS "Admins can delete activities" ON public.activities;

-- Create a simple, permissive policy for viewing published activities
CREATE POLICY "Allow public read of published activities"
  ON public.activities FOR SELECT
  TO public
  USING (status = 'published');

-- Recreate admin policies
CREATE POLICY "Admins can manage activities"
  ON public.activities FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.user_type = 'admin'
    )
  );

-- =====================================================
-- SECTION 4: VERIFICATION TESTS
-- =====================================================

-- Test access to each table
SELECT 'Testing activity_types (should work)...' as test;
SELECT COUNT(*) as activity_types_count FROM public.activity_types;

SELECT 'Testing schools (should work)...' as test;
SELECT COUNT(*) as schools_count FROM public.schools;

SELECT 'Testing activities (should work)...' as test;
SELECT COUNT(*) as activities_count FROM public.activities WHERE status = 'published';

-- Show sample data
SELECT 'Sample activity_types:' as info;
SELECT id, name, slug FROM public.activity_types LIMIT 3;

SELECT 'Sample activities:' as info;
SELECT id, title, status, activity_type_id FROM public.activities LIMIT 3;

-- Check current RLS status
SELECT
  schemaname,
  tablename,
  CASE
    WHEN rowsecurity THEN 'RLS ENABLED'
    ELSE 'RLS DISABLED'
  END as rls_status
FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN ('activities', 'activity_types', 'schools')
ORDER BY tablename;

SELECT '✅ RLS CONFIGURATION UPDATED!' as result;