-- Fix RLS policies for pumpkin_patch_email_log table
-- Allow inserts from the application

-- Drop existing policies if any
DROP POLICY IF EXISTS "Allow public insert email logs" ON pumpkin_patch_email_log;
DROP POLICY IF EXISTS "Allow public read email logs" ON pumpkin_patch_email_log;
DROP POLICY IF EXISTS "Allow insert email logs" ON pumpkin_patch_email_log;
DROP POLICY IF EXISTS "Allow read email logs" ON pumpkin_patch_email_log;

-- Enable RLS
ALTER TABLE pumpkin_patch_email_log ENABLE ROW LEVEL SECURITY;

-- Allow anyone to insert email logs (for logging purposes)
CREATE POLICY "Allow public insert email logs"
ON pumpkin_patch_email_log
FOR INSERT
TO public
WITH CHECK (true);

-- Allow anyone to read email logs (admin dashboard needs this)
CREATE POLICY "Allow public read email logs"
ON pumpkin_patch_email_log
FOR SELECT
TO public
USING (true);

-- Verify policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies
WHERE tablename = 'pumpkin_patch_email_log';
