-- Fix RLS policies for admin notification tables
-- These tables need to be accessible by Edge Functions (service role)

-- 1. Fix admin_notification_settings table
ALTER TABLE admin_notification_settings ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Allow service role full access to admin_notification_settings" ON admin_notification_settings;
DROP POLICY IF EXISTS "Allow authenticated users to read admin_notification_settings" ON admin_notification_settings;
DROP POLICY IF EXISTS "Allow authenticated users to manage admin_notification_settings" ON admin_notification_settings;

-- Allow service role (Edge Functions) to read admin notification settings
CREATE POLICY "Allow service role full access to admin_notification_settings"
ON admin_notification_settings
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- Allow authenticated users (admins) to read and manage their notification settings
CREATE POLICY "Allow authenticated users to manage admin_notification_settings"
ON admin_notification_settings
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

-- 2. Fix admin_notification_log table
ALTER TABLE admin_notification_log ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Allow service role full access to admin_notification_log" ON admin_notification_log;
DROP POLICY IF EXISTS "Allow authenticated users to read admin_notification_log" ON admin_notification_log;

-- Allow service role (Edge Functions) to insert and read notification logs
CREATE POLICY "Allow service role full access to admin_notification_log"
ON admin_notification_log
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- Allow authenticated users (admins) to read notification logs
CREATE POLICY "Allow authenticated users to read admin_notification_log"
ON admin_notification_log
FOR SELECT
TO authenticated
USING (true);

-- Verify policies
SELECT schemaname, tablename, policyname, roles, cmd
FROM pg_policies
WHERE tablename IN ('admin_notification_settings', 'admin_notification_log')
ORDER BY tablename, policyname;
