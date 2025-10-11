-- Verify INSERT policy exists and is correct
SELECT
    schemaname,
    tablename,
    policyname,
    cmd as operation,
    roles,
    CASE
        WHEN with_check = 'true' THEN 'ALLOWS ALL'
        ELSE 'RESTRICTED: ' || with_check
    END as check_clause
FROM pg_policies
WHERE tablename = 'pumpkin_patch_orders'
  AND cmd = 'INSERT'
ORDER BY policyname;

-- Test if RLS is actually blocking (returns count of policies)
SELECT COUNT(*) as insert_policies_count
FROM pg_policies
WHERE tablename = 'pumpkin_patch_orders'
  AND cmd = 'INSERT'
  AND 'anon' = ANY(roles);

-- Check if RLS is enabled but no policies exist for anon
SELECT
    rowsecurity as rls_enabled,
    CASE
        WHEN rowsecurity = true THEN 'RLS IS ENABLED - Policies must allow access'
        ELSE 'RLS IS DISABLED - All access allowed'
    END as status
FROM pg_tables
WHERE tablename = 'pumpkin_patch_orders';
