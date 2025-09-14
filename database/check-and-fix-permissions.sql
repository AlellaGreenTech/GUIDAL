-- COMPREHENSIVE PERMISSION CHECK AND FIX
-- Run this step by step in Supabase SQL editor

-- =====================================================
-- STEP 1: CHECK CURRENT TABLE PERMISSIONS AND RLS STATUS
-- =====================================================

-- Check if tables exist and their RLS status
SELECT
  schemaname,
  tablename,
  rowsecurity as rls_enabled,
  hasindexes,
  hasrules
FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN ('activities', 'activity_types', 'schools')
ORDER BY tablename;

-- Check what policies exist
SELECT
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies
WHERE tablename IN ('activities', 'activity_types', 'schools')
ORDER BY tablename, policyname;

-- =====================================================
-- STEP 2: COMPLETELY RESET RLS FOR THESE TABLES
-- =====================================================

-- For activity_types: Completely disable RLS
DROP POLICY IF EXISTS "Activity types are viewable by everyone" ON public.activity_types;
DROP POLICY IF EXISTS "All activity types viewable" ON public.activity_types;
ALTER TABLE public.activity_types DISABLE ROW LEVEL SECURITY;

-- For schools: Completely disable RLS
DROP POLICY IF EXISTS "Schools are viewable by everyone" ON public.schools;
ALTER TABLE public.schools DISABLE ROW LEVEL SECURITY;

-- For activities: Reset and create proper policy
DROP POLICY IF EXISTS "Activities are viewable by everyone" ON public.activities;
DROP POLICY IF EXISTS "Published activities are viewable by everyone" ON public.activities;
DROP POLICY IF EXISTS "Allow public read of published activities" ON public.activities;
DROP POLICY IF EXISTS "Admins can insert activities" ON public.activities;
DROP POLICY IF EXISTS "Admins can update activities" ON public.activities;
DROP POLICY IF EXISTS "Admins can delete activities" ON public.activities;
DROP POLICY IF EXISTS "Admins can manage activities" ON public.activities;

-- Disable RLS for activities too (simplest approach)
ALTER TABLE public.activities DISABLE ROW LEVEL SECURITY;

-- =====================================================
-- STEP 3: VERIFY ACCESS WORKS
-- =====================================================

-- Test basic queries
SELECT 'Testing activity_types access:' as test;
SELECT COUNT(*) as count FROM public.activity_types;

SELECT 'Testing schools access:' as test;
SELECT COUNT(*) as count FROM public.schools;

SELECT 'Testing activities access:' as test;
SELECT COUNT(*) as count FROM public.activities;

-- Show sample data
SELECT 'Sample activity_types:' as info;
SELECT id, name, slug FROM public.activity_types;

SELECT 'Sample schools:' as info;
SELECT id, name FROM public.schools LIMIT 5;

SELECT 'Sample activities:' as info;
SELECT id, title, status FROM public.activities LIMIT 5;

-- Final verification
SELECT
  'Final RLS Status:' as info,
  schemaname,
  tablename,
  CASE WHEN rowsecurity THEN 'ENABLED' ELSE 'DISABLED' END as rls_status
FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN ('activities', 'activity_types', 'schools')
ORDER BY tablename;