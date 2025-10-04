-- Temporarily disable RLS to add events
-- Run this in Supabase SQL Editor

-- Disable RLS temporarily
ALTER TABLE public.scheduled_visits DISABLE ROW LEVEL SECURITY;

-- You can now add the Halloween events using the admin tool

-- After adding events, run this to re-enable RLS:
-- ALTER TABLE public.scheduled_visits ENABLE ROW LEVEL SECURITY;
