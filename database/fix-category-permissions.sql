-- Fix Activity Categories Permissions
-- This fixes the RLS policies to allow public read access

-- First, grant SELECT permissions to anon and authenticated roles
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT ON public.activity_categories TO anon, authenticated;
GRANT SELECT ON public.activity_category_links TO anon, authenticated;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Activity categories are viewable by everyone" ON public.activity_categories;
DROP POLICY IF EXISTS "Activity category links are viewable by everyone" ON public.activity_category_links;
DROP POLICY IF EXISTS "Only admins can insert activity categories" ON public.activity_categories;
DROP POLICY IF EXISTS "Only admins can update activity categories" ON public.activity_categories;
DROP POLICY IF EXISTS "Only admins can delete activity categories" ON public.activity_categories;
DROP POLICY IF EXISTS "Only admins can manage category links" ON public.activity_category_links;

-- Disable RLS to allow access
ALTER TABLE public.activity_categories DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity_category_links DISABLE ROW LEVEL SECURITY;

-- OR if you want to keep RLS enabled, use these policies instead:
-- Re-enable RLS
-- ALTER TABLE public.activity_categories ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.activity_category_links ENABLE ROW LEVEL SECURITY;

-- Create permissive policies for public read access (anyone can view)
-- CREATE POLICY "Allow public read access to active categories"
--   ON public.activity_categories FOR SELECT
--   TO anon, authenticated
--   USING (active = true);

-- CREATE POLICY "Allow public read access to category links"
--   ON public.activity_category_links FOR SELECT
--   TO anon, authenticated
--   USING (true);

-- Create policies for admin/staff write access
-- CREATE POLICY "Allow admins to manage categories"
--   ON public.activity_categories FOR ALL
--   TO authenticated
--   USING (
--     EXISTS (
--       SELECT 1 FROM public.profiles
--       WHERE id = auth.uid()
--       AND user_type IN ('admin', 'staff')
--     )
--   );

-- CREATE POLICY "Allow admins to manage category links"
--   ON public.activity_category_links FOR ALL
--   TO authenticated
--   USING (
--     EXISTS (
--       SELECT 1 FROM public.profiles
--       WHERE id = auth.uid()
--       AND user_type IN ('admin', 'staff')
--     )
--   );

-- Verify the tables are accessible
SELECT 'Categories:' as info, COUNT(*) as count FROM public.activity_categories;
SELECT 'Category Links:' as info, COUNT(*) as count FROM public.activity_category_links;
