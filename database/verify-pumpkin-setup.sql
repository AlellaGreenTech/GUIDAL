-- Verify Pumpkin Patch Orders Setup
-- Run this to confirm everything is working

-- 1. Check tables exist
SELECT
  'Tables exist' as check_type,
  COUNT(*) as count,
  STRING_AGG(table_name, ', ') as tables
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN ('pumpkin_patch_orders', 'pumpkin_patch_order_items');

-- 2. Check function exists
SELECT
  'Function exists' as check_type,
  COUNT(*) as count
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name = 'generate_pumpkin_order_number';

-- 3. Check RLS policies
SELECT
  'RLS policies' as check_type,
  tablename,
  policyname,
  cmd as operation
FROM pg_policies
WHERE tablename IN ('pumpkin_patch_orders', 'pumpkin_patch_order_items')
ORDER BY tablename, policyname;

-- 4. Test insert (will rollback)
BEGIN;

-- Generate order number
SELECT generate_pumpkin_order_number() as test_order_number;

-- Try to insert a test order
INSERT INTO public.pumpkin_patch_orders (
  order_number,
  first_name,
  last_name,
  email,
  total_amount
) VALUES (
  generate_pumpkin_order_number(),
  'Test',
  'Customer',
  'test@example.com',
  25.00
) RETURNING
  order_number,
  first_name,
  last_name,
  email,
  total_amount,
  'SUCCESS - Test insert worked!' as status;

-- Rollback so we don't keep test data
ROLLBACK;

-- 5. Show all orders (should be empty or show real orders)
SELECT COUNT(*) as total_orders FROM public.pumpkin_patch_orders;
