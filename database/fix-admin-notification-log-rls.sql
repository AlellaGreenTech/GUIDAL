-- Fix RLS policies for admin_notification_log table
-- This table is used by the send-admin-notification Edge Function

-- Enable RLS
ALTER TABLE admin_notification_log ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any
DROP POLICY IF EXISTS "Allow all to insert admin notification log" ON admin_notification_log;
DROP POLICY IF EXISTS "Allow all to read admin notification log" ON admin_notification_log;

-- Grant table permissions
GRANT SELECT, INSERT ON admin_notification_log TO anon, authenticated;

-- Create policies
CREATE POLICY "Allow all to insert admin notification log"
  ON admin_notification_log
  FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);

CREATE POLICY "Allow all to read admin notification log"
  ON admin_notification_log
  FOR SELECT
  TO anon, authenticated
  USING (true);

-- Verify policies were created
SELECT
    tablename,
    policyname,
    cmd,
    roles,
    CASE
        WHEN cmd = 'SELECT' AND qual IS NULL THEN '✅ ALLOWS ALL'
        WHEN cmd = 'INSERT' AND with_check = 'true' THEN '✅ ALLOWS ALL'
        ELSE '⚠️ CHECK CONFIG'
    END as status
FROM pg_policies
WHERE tablename = 'admin_notification_log'
ORDER BY cmd, policyname;
