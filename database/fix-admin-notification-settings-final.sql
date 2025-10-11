-- Final fix for admin_notification_settings RLS
-- This is the correct table name (singular)

-- 1. Enable RLS
ALTER TABLE admin_notification_settings ENABLE ROW LEVEL SECURITY;

-- 2. Grant table-level permissions FIRST
GRANT SELECT, INSERT, UPDATE, DELETE ON admin_notification_settings TO anon, authenticated;

-- 3. Drop any existing policies to start fresh
DROP POLICY IF EXISTS "Allow all to read admin settings" ON admin_notification_settings;
DROP POLICY IF EXISTS "Allow all to write admin settings" ON admin_notification_settings;

-- 4. Create SELECT policy for anonymous and authenticated users
CREATE POLICY "Allow all to read admin settings"
  ON admin_notification_settings
  FOR SELECT
  TO anon, authenticated
  USING (true);

-- 5. Create other policies for authenticated users only
CREATE POLICY "Allow authenticated to write admin settings"
  ON admin_notification_settings
  FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- 6. Verify the setup
SELECT
  '✅ RLS Status' as check_type,
  tablename,
  rowsecurity::text as enabled
FROM pg_tables
WHERE tablename = 'admin_notification_settings'

UNION ALL

SELECT
  '✅ Policies' as check_type,
  policyname as tablename,
  cmd::text as enabled
FROM pg_policies
WHERE tablename = 'admin_notification_settings'

UNION ALL

SELECT
  '✅ Grants' as check_type,
  grantee as tablename,
  privilege_type as enabled
FROM information_schema.role_table_grants
WHERE table_name = 'admin_notification_settings'
  AND grantee IN ('anon', 'authenticated')
ORDER BY check_type, tablename;

-- 7. Test as anon
DO $$
DECLARE
  test_count INTEGER;
BEGIN
  SET LOCAL ROLE anon;
  SELECT COUNT(*) INTO test_count FROM admin_notification_settings;
  RESET ROLE;
  RAISE NOTICE '✅ Anon can read admin_notification_settings: % rows', test_count;
EXCEPTION
  WHEN OTHERS THEN
    RESET ROLE;
    RAISE NOTICE '❌ Anon CANNOT read admin_notification_settings: %', SQLERRM;
END $$;
