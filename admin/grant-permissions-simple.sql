-- Simple permissions for scheduled_visits table
-- Run this in Supabase SQL Editor

-- First, drop existing policies that might be blocking
DROP POLICY IF EXISTS "Allow authenticated users to read scheduled visits" ON public.scheduled_visits;
DROP POLICY IF EXISTS "Allow admins to manage scheduled visits" ON public.scheduled_visits;
DROP POLICY IF EXISTS "Allow anonymous users to read scheduled visits" ON public.scheduled_visits;

-- Grant basic permissions
GRANT SELECT ON public.scheduled_visits TO authenticated;
GRANT SELECT ON public.scheduled_visits TO anon;
GRANT INSERT ON public.scheduled_visits TO authenticated;
GRANT UPDATE ON public.scheduled_visits TO authenticated;
GRANT DELETE ON public.scheduled_visits TO authenticated;
GRANT ALL ON public.scheduled_visits TO service_role;

-- Enable RLS
ALTER TABLE public.scheduled_visits ENABLE ROW LEVEL SECURITY;

-- Allow everyone to read (for public event listings)
CREATE POLICY "Public read access"
ON public.scheduled_visits
FOR SELECT
USING (true);

-- Allow martin@guidal.be or admins to insert/update/delete
CREATE POLICY "Admin full access"
ON public.scheduled_visits
FOR ALL
USING (
  auth.email() = 'martin@guidal.be'
  OR
  EXISTS (
    SELECT 1 FROM public.user_profiles
    WHERE user_profiles.user_id = auth.uid()
    AND user_profiles.role = 'admin'
  )
)
WITH CHECK (
  auth.email() = 'martin@guidal.be'
  OR
  EXISTS (
    SELECT 1 FROM public.user_profiles
    WHERE user_profiles.user_id = auth.uid()
    AND user_profiles.role = 'admin'
  )
);
