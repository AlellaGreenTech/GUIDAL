-- Fix RLS to allow anonymous users to read pumpkin_patch_orders for email lookup
-- This is needed so the checkout page can detect returning customers

-- Drop existing SELECT policies
DROP POLICY IF EXISTS "Enable read access for all users" ON public.pumpkin_patch_orders;
DROP POLICY IF EXISTS "Anyone can view orders" ON public.pumpkin_patch_orders;

-- Create new SELECT policy that explicitly allows anon role
CREATE POLICY "Allow anon and authenticated to read orders"
  ON public.pumpkin_patch_orders
  FOR SELECT
  TO anon, authenticated
  USING (true);

-- Verify the policy
SELECT
    tablename,
    policyname,
    cmd as operation,
    roles
FROM pg_policies
WHERE tablename = 'pumpkin_patch_orders'
ORDER BY policyname;

-- Test that anon can read (run this as anon user in Supabase)
-- SET ROLE anon;
-- SELECT email FROM pumpkin_patch_orders LIMIT 1;
