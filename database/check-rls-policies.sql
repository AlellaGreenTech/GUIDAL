-- Check existing RLS policies and table permissions
-- Run this in your Supabase SQL editor to diagnose the issue

-- Check if RLS is enabled on tables
SELECT schemaname, tablename, rowsecurity
FROM pg_tables
WHERE tablename IN ('school_visits', 'schools', 'activities');

-- Check existing policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies
WHERE tablename IN ('school_visits', 'schools', 'activities')
ORDER BY tablename, policyname;

-- Test direct access to see what data exists
SELECT 'school_visits count:' as info, COUNT(*) as count FROM public.school_visits;
SELECT 'schools count:' as info, COUNT(*) as count FROM public.schools;
SELECT 'activities count:' as info, COUNT(*) as count FROM public.activities;

-- Check if the specific record exists
SELECT 'Benjamin Franklin record check:' as info;
SELECT id, access_code, teacher_name, student_count
FROM public.school_visits
WHERE access_code = 'bfis-sept-2025';