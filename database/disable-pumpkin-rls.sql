-- Temporarily disable RLS for pumpkin patch tables
-- This allows guest checkout to work immediately
-- You can re-enable and configure proper policies later

-- Disable RLS on both tables
ALTER TABLE public.pumpkin_patch_orders DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.pumpkin_patch_order_items DISABLE ROW LEVEL SECURITY;

-- Grant necessary permissions
GRANT ALL ON public.pumpkin_patch_orders TO anon, authenticated;
GRANT ALL ON public.pumpkin_patch_order_items TO anon, authenticated;
GRANT EXECUTE ON FUNCTION generate_pumpkin_order_number() TO anon, authenticated;

-- Verify the tables are accessible
SELECT
  tablename,
  rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename LIKE 'pumpkin%';

-- Success message
DO $$
BEGIN
  RAISE NOTICE 'RLS disabled for pumpkin patch tables. Guest checkout should work now!';
END $$;
