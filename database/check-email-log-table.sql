-- Check if pumpkin_patch_email_log table exists
SELECT table_name, column_name, data_type
FROM information_schema.columns
WHERE table_name = 'pumpkin_patch_email_log'
ORDER BY ordinal_position;

-- Check RLS policies on the table
SELECT
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE tablename = 'pumpkin_patch_email_log';

-- Check if RLS is enabled
SELECT tablename, rowsecurity
FROM pg_tables
WHERE tablename = 'pumpkin_patch_email_log';
