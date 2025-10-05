-- Move "All Events" to be the first category in the carousel

UPDATE public.activity_categories
SET display_order = -10
WHERE slug = 'all-events';

-- Show all categories ordered
SELECT name, slug, display_order
FROM public.activity_categories
ORDER BY display_order;
