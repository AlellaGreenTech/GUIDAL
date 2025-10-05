-- Check what categories exist in the database

-- Show all categories with their display order
SELECT
  name,
  slug,
  display_order,
  active,
  created_at
FROM public.activity_categories
ORDER BY display_order, created_at;

-- Count categories
SELECT COUNT(*) as total_categories FROM public.activity_categories;

-- Check if the new categories exist
SELECT
  CASE
    WHEN EXISTS (SELECT 1 FROM public.activity_categories WHERE slug = 'school-field-trip')
    THEN 'EXISTS'
    ELSE 'MISSING'
  END as school_field_trip,
  CASE
    WHEN EXISTS (SELECT 1 FROM public.activity_categories WHERE slug = 'family-farm-visit')
    THEN 'EXISTS'
    ELSE 'MISSING'
  END as family_farm_visit,
  CASE
    WHEN EXISTS (SELECT 1 FROM public.activity_categories WHERE slug = 'events')
    THEN 'EXISTS'
    ELSE 'MISSING'
  END as events,
  CASE
    WHEN EXISTS (SELECT 1 FROM public.activity_categories WHERE slug = 'special-lunches')
    THEN 'EXISTS'
    ELSE 'MISSING'
  END as special_lunches;
