-- Fix RLS policies for admin_notification_settings table
-- This allows the checkout process to read admin email settings

-- Allow anonymous users to read admin notification settings
-- (needed to send admin notifications during checkout)
DROP POLICY IF EXISTS "Allow all to read admin settings" ON admin_notification_settings;

CREATE POLICY "Allow all to read admin settings"
  ON admin_notification_settings
  FOR SELECT
  TO anon, authenticated
  USING (true);

-- Verify the policy was created
SELECT
    tablename,
    policyname,
    cmd,
    roles,
    CASE
        WHEN qual IS NULL THEN 'ALLOWS ALL'
        ELSE 'RESTRICTED'
    END as access_level
FROM pg_policies
WHERE tablename = 'admin_notification_settings'
ORDER BY cmd, policyname;
