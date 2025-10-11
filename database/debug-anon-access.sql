-- Debug why anonymous users can't read orders

-- 1. Check all policies
SELECT
    tablename,
    policyname,
    cmd as operation,
    roles,
    qual
FROM pg_policies
WHERE tablename = 'pumpkin_patch_orders'
ORDER BY cmd, policyname;

-- 2. Check grants
SELECT
    grantee,
    privilege_type
FROM information_schema.role_table_grants
WHERE table_name = 'pumpkin_patch_orders'
ORDER BY grantee, privilege_type;

-- 3. Check if RLS is enabled
SELECT
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
AND tablename = 'pumpkin_patch_orders';

-- 4. Test query as service role (should work)
SELECT COUNT(*) as total_orders,
       COUNT(DISTINCT email) as unique_emails
FROM pumpkin_patch_orders;

-- 5. Check for the specific email
SELECT
    id,
    order_number,
    email,
    first_name,
    last_name,
    payment_status,
    created_at
FROM pumpkin_patch_orders
WHERE email = 'mwpicard@gmail.com'
ORDER BY created_at DESC
LIMIT 3;
