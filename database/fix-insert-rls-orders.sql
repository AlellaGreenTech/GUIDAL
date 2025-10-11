-- Fix RLS to allow anonymous users to INSERT orders
-- Currently blocking inserts with 400 error

-- Drop old INSERT policies that might be too restrictive
DROP POLICY IF EXISTS "Enable insert for all users" ON pumpkin_patch_orders;
DROP POLICY IF EXISTS "Allow anonymous insert orders" ON pumpkin_patch_orders;
DROP POLICY IF EXISTS "Anyone can create pumpkin patch orders" ON pumpkin_patch_orders;
DROP POLICY IF EXISTS "Allow all users to insert orders" ON pumpkin_patch_orders;

-- Create new permissive INSERT policy for anonymous and authenticated users
CREATE POLICY "Allow all users to insert orders"
  ON pumpkin_patch_orders
  FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);
