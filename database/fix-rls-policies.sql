-- FIX RLS POLICIES FOR GUIDAL DATABASE
-- This script fixes Row Level Security issues preventing data access
-- Run this in your Supabase SQL editor

-- =====================================================
-- SECTION 1: FIX ACTIVITY_TYPES TABLE ACCESS
-- =====================================================

-- Enable RLS on activity_types if not already enabled
ALTER TABLE public.activity_types ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Activity types are viewable by everyone" ON public.activity_types;

-- Create policy to allow everyone to view activity types
CREATE POLICY "Activity types are viewable by everyone"
  ON public.activity_types FOR SELECT
  USING (active = true);

-- Also allow viewing inactive types (for admin purposes)
CREATE POLICY "All activity types viewable"
  ON public.activity_types FOR SELECT
  USING (true);

-- =====================================================
-- SECTION 2: FIX ACTIVITIES TABLE ACCESS
-- =====================================================

-- The activities table already has RLS enabled, but let's update the policy

-- Drop the existing restrictive policy
DROP POLICY IF EXISTS "Activities are viewable by everyone" ON public.activities;

-- Create a new, more permissive policy for published activities
CREATE POLICY "Published activities are viewable by everyone"
  ON public.activities FOR SELECT
  USING (status = 'published');

-- =====================================================
-- SECTION 3: FIX SCHOOLS TABLE ACCESS
-- =====================================================

-- Enable RLS on schools and allow public read access
ALTER TABLE public.schools ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Schools are viewable by everyone" ON public.schools;

-- Create policy to allow everyone to view active schools
CREATE POLICY "Schools are viewable by everyone"
  ON public.schools FOR SELECT
  USING (active = true);

-- =====================================================
-- SECTION 4: VERIFICATION QUERIES
-- =====================================================

-- Test the policies
SELECT 'Testing activity_types access...' as test;
SELECT id, name, slug FROM public.activity_types LIMIT 3;

SELECT 'Testing activities access...' as test;
SELECT id, title, status FROM public.activities LIMIT 3;

SELECT 'Testing schools access...' as test;
SELECT id, name FROM public.schools LIMIT 3;

-- Show all policies
SELECT
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd
FROM pg_policies
WHERE tablename IN ('activities', 'activity_types', 'schools')
ORDER BY tablename, policyname;

SELECT '✅ RLS POLICIES UPDATED!' as result;