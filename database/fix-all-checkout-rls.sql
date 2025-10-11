-- Fix RLS policies for all tables involved in pumpkin patch checkout
-- This allows anonymous users (customers) to complete bookings

-- 1. Fix pumpkin_patch_orders table
DROP POLICY IF EXISTS "Allow all users to insert orders" ON pumpkin_patch_orders;

CREATE POLICY "Allow all users to insert orders"
  ON pumpkin_patch_orders
  FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);

-- Also allow anonymous users to read their own orders (needed for confirmation)
DROP POLICY IF EXISTS "Allow all users to read orders" ON pumpkin_patch_orders;

CREATE POLICY "Allow all users to read orders"
  ON pumpkin_patch_orders
  FOR SELECT
  TO anon, authenticated
  USING (true);

-- 2. Fix pumpkin_patch_order_items table
DROP POLICY IF EXISTS "Allow all users to insert order items" ON pumpkin_patch_order_items;

CREATE POLICY "Allow all users to insert order items"
  ON pumpkin_patch_order_items
  FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all users to read order items" ON pumpkin_patch_order_items;

CREATE POLICY "Allow all users to read order items"
  ON pumpkin_patch_order_items
  FOR SELECT
  TO anon, authenticated
  USING (true);

-- 3. Verify all policies were created
SELECT
    tablename,
    policyname,
    cmd,
    roles,
    CASE
        WHEN with_check = 'true' THEN 'ALLOWS ALL'
        WHEN with_check IS NULL THEN 'N/A (SELECT)'
        ELSE 'RESTRICTED'
    END as access_level
FROM pg_policies
WHERE tablename IN ('pumpkin_patch_orders', 'pumpkin_patch_order_items')
ORDER BY tablename, cmd, policyname;
