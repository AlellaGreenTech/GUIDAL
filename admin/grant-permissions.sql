-- Grant permissions for scheduled_visits table
-- Run this in Supabase SQL Editor

-- Grant SELECT permission (for reading)
GRANT SELECT ON public.scheduled_visits TO authenticated;
GRANT SELECT ON public.scheduled_visits TO anon;

-- Grant INSERT permission (for adding new events)
GRANT INSERT ON public.scheduled_visits TO authenticated;

-- Grant UPDATE permission (for editing events)
GRANT UPDATE ON public.scheduled_visits TO authenticated;

-- Grant DELETE permission (for removing events)
GRANT DELETE ON public.scheduled_visits TO authenticated;

-- Grant ALL to service_role (for admin operations)
GRANT ALL ON public.scheduled_visits TO service_role;

-- Also make sure RLS is enabled
ALTER TABLE public.scheduled_visits ENABLE ROW LEVEL SECURITY;

-- Create RLS policy to allow authenticated users to read all scheduled visits
CREATE POLICY "Allow authenticated users to read scheduled visits"
ON public.scheduled_visits
FOR SELECT
TO authenticated
USING (true);

-- Create RLS policy to allow admins to insert/update/delete
CREATE POLICY "Allow admins to manage scheduled visits"
ON public.scheduled_visits
FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.user_profiles
    WHERE user_profiles.user_id = auth.uid()
    AND user_profiles.role = 'admin'
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.user_profiles
    WHERE user_profiles.user_id = auth.uid()
    AND user_profiles.role = 'admin'
  )
);

-- Create RLS policy to allow anonymous users to read scheduled visits (for public display)
CREATE POLICY "Allow anonymous users to read scheduled visits"
ON public.scheduled_visits
FOR SELECT
TO anon
USING (true);
