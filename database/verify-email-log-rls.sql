-- Verify the RLS policies are correctly set for pumpkin_patch_email_log

-- Check if RLS is enabled
SELECT tablename, rowsecurity
FROM pg_tables
WHERE tablename = 'pumpkin_patch_email_log';

-- Check the policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies
WHERE tablename = 'pumpkin_patch_email_log';

-- Test insert permission (this will show if inserts are allowed)
SELECT
    has_table_privilege('public', 'pumpkin_patch_email_log', 'INSERT') as can_insert,
    has_table_privilege('public', 'pumpkin_patch_email_log', 'SELECT') as can_select;
