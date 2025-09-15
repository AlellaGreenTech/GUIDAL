-- Fix RLS policies for school_visits table to allow anonymous access
-- Run this in your Supabase SQL editor

-- Enable RLS on school_visits if not already enabled
ALTER TABLE public.school_visits ENABLE ROW LEVEL SECURITY;

-- Allow anonymous read access to school_visits
CREATE POLICY "Allow anonymous read access to school_visits"
ON public.school_visits
FOR SELECT
TO anon
USING (true);

-- Allow anonymous read access to schools table (in case it's missing)
ALTER TABLE public.schools ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow anonymous read access to schools"
ON public.schools
FOR SELECT
TO anon
USING (true);

-- Verify the policies exist
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies
WHERE tablename IN ('school_visits', 'schools')
ORDER BY tablename, policyname;