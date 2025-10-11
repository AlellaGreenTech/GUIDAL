-- Fix RLS for both possible admin notification table names
-- The error shows "admin_notifications_settings" but code uses "admin_notification_settings"

-- ========================================================================
-- Option 1: admin_notification_settings (singular - what code expects)
-- ========================================================================

-- Enable RLS
ALTER TABLE IF EXISTS admin_notification_settings ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "Allow all to read admin settings" ON admin_notification_settings;

-- Grant permissions
GRANT SELECT ON admin_notification_settings TO anon, authenticated;

-- Create policy
CREATE POLICY "Allow all to read admin settings"
  ON admin_notification_settings
  FOR SELECT
  TO anon, authenticated
  USING (true);

-- ========================================================================
-- Option 2: admin_notifications_settings (plural - what error shows)
-- ========================================================================

-- Enable RLS
ALTER TABLE IF EXISTS admin_notifications_settings ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "Allow all to read admin settings" ON admin_notifications_settings;

-- Grant permissions
GRANT SELECT ON admin_notifications_settings TO anon, authenticated;

-- Create policy
CREATE POLICY "Allow all to read admin settings"
  ON admin_notifications_settings
  FOR SELECT
  TO anon, authenticated
  USING (true);

-- ========================================================================
-- Verify which table exists and has policies
-- ========================================================================

SELECT
  t.tablename,
  t.rowsecurity as rls_enabled,
  COUNT(p.policyname) as policy_count
FROM pg_tables t
LEFT JOIN pg_policies p ON p.tablename = t.tablename
WHERE t.schemaname = 'public'
  AND t.tablename LIKE '%admin%notification%'
GROUP BY t.tablename, t.rowsecurity
ORDER BY t.tablename;

-- Show the policies
SELECT
  tablename,
  policyname,
  cmd,
  roles
FROM pg_policies
WHERE tablename LIKE '%admin%notification%'
ORDER BY tablename, cmd;
