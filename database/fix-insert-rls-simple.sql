-- Simple fix: Create INSERT policy for pumpkin_patch_orders
-- This allows anonymous and authenticated users to create orders

-- Drop if exists first
DROP POLICY IF EXISTS "Allow all users to insert orders" ON pumpkin_patch_orders;

-- Create the policy
CREATE POLICY "Allow all users to insert orders"
  ON pumpkin_patch_orders
  FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);

-- Verify it was created
SELECT
    policyname,
    cmd,
    roles,
    with_check
FROM pg_policies
WHERE tablename = 'pumpkin_patch_orders'
  AND cmd = 'INSERT';
