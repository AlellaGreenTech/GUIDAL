-- Enable RLS with proper policies for pumpkin patch tables
-- This fixes the security warnings while keeping guest checkout working

-- Re-enable RLS
ALTER TABLE public.pumpkin_patch_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pumpkin_patch_order_items ENABLE ROW LEVEL SECURITY;

-- Drop all existing policies
DROP POLICY IF EXISTS "Allow anonymous insert orders" ON public.pumpkin_patch_orders;
DROP POLICY IF EXISTS "Allow anonymous insert order items" ON public.pumpkin_patch_order_items;
DROP POLICY IF EXISTS "Anyone can create pumpkin patch orders" ON public.pumpkin_patch_orders;
DROP POLICY IF EXISTS "Anyone can create order items" ON public.pumpkin_patch_order_items;
DROP POLICY IF EXISTS "Admins can view all pumpkin patch orders" ON public.pumpkin_patch_orders;
DROP POLICY IF EXISTS "Admins can view all order items" ON public.pumpkin_patch_order_items;
DROP POLICY IF EXISTS "Admins can update pumpkin patch orders" ON public.pumpkin_patch_orders;

-- CREATE POLICIES FOR INSERTS (Guest checkout)
CREATE POLICY "Enable insert for all users"
  ON public.pumpkin_patch_orders
  FOR INSERT
  TO public
  WITH CHECK (true);

CREATE POLICY "Enable insert for all users"
  ON public.pumpkin_patch_order_items
  FOR INSERT
  TO public
  WITH CHECK (true);

-- CREATE POLICIES FOR SELECT (Viewing orders)
-- Anyone can view all orders (for admin reports)
CREATE POLICY "Enable read access for all users"
  ON public.pumpkin_patch_orders
  FOR SELECT
  TO public
  USING (true);

CREATE POLICY "Enable read access for all users"
  ON public.pumpkin_patch_order_items
  FOR SELECT
  TO public
  USING (true);

-- CREATE POLICIES FOR UPDATE (Admin only)
CREATE POLICY "Enable update for admins only"
  ON public.pumpkin_patch_orders
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.user_type = 'admin'
    )
  );

-- Ensure necessary grants
GRANT ALL ON public.pumpkin_patch_orders TO anon, authenticated, postgres;
GRANT ALL ON public.pumpkin_patch_order_items TO anon, authenticated, postgres;
GRANT EXECUTE ON FUNCTION generate_pumpkin_order_number() TO anon, authenticated, postgres;

-- Verify policies are in place
SELECT
  tablename,
  policyname,
  cmd as operation,
  roles
FROM pg_policies
WHERE tablename IN ('pumpkin_patch_orders', 'pumpkin_patch_order_items')
ORDER BY tablename, policyname;

-- Test query
SELECT
  order_number,
  first_name,
  last_name,
  email,
  total_amount,
  created_at
FROM public.pumpkin_patch_orders
ORDER BY created_at DESC;
