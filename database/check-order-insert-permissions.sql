-- Check RLS policies on pumpkin_patch_orders for INSERT
SELECT
    tablename,
    policyname,
    cmd as operation,
    roles,
    qual,
    with_check
FROM pg_policies
WHERE tablename = 'pumpkin_patch_orders'
  AND cmd = 'INSERT'
ORDER BY policyname;

-- Check if RLS is enabled
SELECT
    tablename,
    rowsecurity
FROM pg_tables
WHERE tablename = 'pumpkin_patch_orders';

-- Check recent orders to see if any were created
SELECT
    id,
    order_number,
    email,
    payment_status,
    created_at
FROM pumpkin_patch_orders
ORDER BY created_at DESC
LIMIT 5;
