-- Check if pumpkin patch tables exist and their structure

-- 1. Check if tables exist
SELECT table_name, table_type
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name LIKE 'pumpkin%'
ORDER BY table_name;

-- 2. Check pumpkin_patch_orders structure
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'pumpkin_patch_orders'
ORDER BY ordinal_position;

-- 3. Check pumpkin_patch_order_items structure
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'pumpkin_patch_order_items'
ORDER BY ordinal_position;

-- 4. Check if the function exists
SELECT routine_name, routine_type
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name = 'generate_pumpkin_order_number';

-- 5. Check RLS policies on pumpkin_patch_orders
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies
WHERE tablename = 'pumpkin_patch_orders';

-- 6. Check RLS policies on pumpkin_patch_order_items
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies
WHERE tablename = 'pumpkin_patch_order_items';

-- 7. Test if we can insert a simple order manually
-- (Run this after checking the above)
-- INSERT INTO public.pumpkin_patch_orders (
--   order_number,
--   first_name,
--   last_name,
--   email,
--   total_amount
-- ) VALUES (
--   'PP-TEST-001',
--   'Test',
--   'User',
--   'test@example.com',
--   25.00
-- );
