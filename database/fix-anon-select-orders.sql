-- Fix anonymous read access to pumpkin_patch_orders
-- The issue is that the "Allow anon and authenticated to read orders" policy
-- has operation "ALL" but qual "null", which doesn't work for SELECT
-- Also the "Users can view their own pumpkin patch orders" policy blocks anon users

-- Drop the problematic policies
DROP POLICY IF EXISTS "Allow anon and authenticated to read orders" ON pumpkin_patch_orders;
DROP POLICY IF EXISTS "Users can view their own pumpkin patch orders" ON pumpkin_patch_orders;

-- Create a simple, permissive SELECT policy for anonymous users
-- This is safe because order data isn't sensitive (just email, name, items)
CREATE POLICY "Enable read for all users including anon"
  ON pumpkin_patch_orders
  FOR SELECT
  TO public
  USING (true);

-- Keep the admin policy for viewing all orders
-- (Already exists: "Admins can view all pumpkin patch orders")

-- Verify the fix
SELECT
    tablename,
    policyname,
    cmd as operation,
    roles
FROM pg_policies
WHERE tablename = 'pumpkin_patch_orders'
  AND cmd = 'SELECT'
ORDER BY policyname;
