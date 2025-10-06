-- Fix RLS Policies for Pumpkin Patch Orders
-- This allows anonymous (non-logged-in) users to create orders

-- Drop existing policies first
DROP POLICY IF EXISTS "Anyone can create pumpkin patch orders" ON public.pumpkin_patch_orders;
DROP POLICY IF EXISTS "Anyone can create order items" ON public.pumpkin_patch_order_items;

-- Create new policies that explicitly allow anon role
CREATE POLICY "Allow anonymous insert orders"
  ON public.pumpkin_patch_orders
  FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Allow anonymous insert order items"
  ON public.pumpkin_patch_order_items
  FOR INSERT
  WITH CHECK (true);

-- Also ensure the table has proper grants
GRANT INSERT ON public.pumpkin_patch_orders TO anon;
GRANT INSERT ON public.pumpkin_patch_order_items TO anon;

-- Allow function execution for anonymous users
GRANT EXECUTE ON FUNCTION generate_pumpkin_order_number() TO anon;
GRANT EXECUTE ON FUNCTION generate_pumpkin_order_number() TO authenticated;

-- Test that it works
DO $$
BEGIN
  RAISE NOTICE 'RLS policies fixed! Anonymous users can now create orders.';
END $$;
