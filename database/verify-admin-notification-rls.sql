-- Verify RLS setup for admin_notification_settings

-- 1. Check if RLS is enabled
SELECT
  tablename,
  rowsecurity as rls_enabled
FROM pg_tables
WHERE tablename = 'admin_notification_settings';

-- 2. Check existing policies
SELECT
  policyname,
  cmd,
  roles::text[],
  qual::text as using_clause,
  with_check::text as with_check_clause
FROM pg_policies
WHERE tablename = 'admin_notification_settings';

-- 3. Check table permissions
SELECT
  grantee,
  privilege_type
FROM information_schema.role_table_grants
WHERE table_name = 'admin_notification_settings'
  AND grantee IN ('anon', 'authenticated')
ORDER BY grantee, privilege_type;

-- 4. Test as anon role
SET ROLE anon;
SELECT COUNT(*) as can_read FROM admin_notification_settings;
RESET ROLE;
