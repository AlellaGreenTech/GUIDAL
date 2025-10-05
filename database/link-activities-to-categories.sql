-- Link Activities to Categories
-- This script links existing activities to their appropriate categories
-- Run this after activity-categories-schema.sql

-- First, let's see what activities we have
-- SELECT id, title FROM public.activities ORDER BY title;

-- Link activities to categories based on their content
-- Note: You'll need to replace the activity IDs with actual IDs from your database

-- Example links (update these with your actual activity IDs):

-- Permaculture activities
-- INSERT INTO public.activity_category_links (activity_id, category_id)
-- SELECT a.id, c.id
-- FROM public.activities a, public.activity_categories c
-- WHERE a.title ILIKE '%permaculture%' AND c.slug = 'permaculture'
-- ON CONFLICT DO NOTHING;

-- Robotics & Gardening
INSERT INTO public.activity_category_links (activity_id, category_id)
SELECT a.id, c.id
FROM public.activities a, public.activity_categories c
WHERE (a.title ILIKE '%robot%' OR a.title ILIKE '%gardening%' OR a.title ILIKE '%drone%')
  AND c.slug = 'robotics'
ON CONFLICT DO NOTHING;

-- Renewable Energy
INSERT INTO public.activity_category_links (activity_id, category_id)
SELECT a.id, c.id
FROM public.activities a, public.activity_categories c
WHERE (a.title ILIKE '%solar%' OR a.title ILIKE '%wind%' OR a.title ILIKE '%energy%' OR a.title ILIKE '%hydraulic%')
  AND c.slug = 'renewable-energy'
ON CONFLICT DO NOTHING;

-- Sustainable Construction
INSERT INTO public.activity_category_links (activity_id, category_id)
SELECT a.id, c.id
FROM public.activities a, public.activity_categories c
WHERE (a.title ILIKE '%construction%' OR a.title ILIKE '%wattle%' OR a.title ILIKE '%daub%' OR a.title ILIKE '%building%')
  AND c.slug = 'construction'
ON CONFLICT DO NOTHING;

-- Citizen Science
INSERT INTO public.activity_category_links (activity_id, category_id)
SELECT a.id, c.id
FROM public.activities a, public.activity_categories c
WHERE (a.title ILIKE '%science%' OR a.title ILIKE '%research%' OR a.title ILIKE '%data%' OR a.title ILIKE '%monitoring%')
  AND c.slug = 'citizen-science'
ON CONFLICT DO NOTHING;

-- Green Crafts
INSERT INTO public.activity_category_links (activity_id, category_id)
SELECT a.id, c.id
FROM public.activities a, public.activity_categories c
WHERE (a.title ILIKE '%craft%' OR a.title ILIKE '%art%' OR a.title ILIKE '%making%' OR a.title ILIKE '%pumpkin%' OR a.title ILIKE '%halloween%')
  AND c.slug = 'green-crafts'
ON CONFLICT DO NOTHING;

-- Wine & Produce
INSERT INTO public.activity_category_links (activity_id, category_id)
SELECT a.id, c.id
FROM public.activities a, public.activity_categories c
WHERE (a.title ILIKE '%wine%' OR a.title ILIKE '%vineyard%' OR a.title ILIKE '%harvest%' OR a.title ILIKE '%produce%' OR a.title ILIKE '%food%')
  AND c.slug = 'wine-produce'
ON CONFLICT DO NOTHING;

-- Volunteering
INSERT INTO public.activity_category_links (activity_id, category_id)
SELECT a.id, c.id
FROM public.activities a, public.activity_categories c
WHERE (a.title ILIKE '%volunteer%' OR a.title ILIKE '%community%' OR a.title ILIKE '%service%')
  AND c.slug = 'volunteering'
ON CONFLICT DO NOTHING;

-- Electronics for Sustainability
INSERT INTO public.activity_category_links (activity_id, category_id)
SELECT a.id, c.id
FROM public.activities a, public.activity_categories c
WHERE (a.title ILIKE '%electronic%' OR a.title ILIKE '%circuit%' OR a.title ILIKE '%sensor%' OR a.title ILIKE '%arduino%' OR a.title ILIKE '%iot%' OR a.title ILIKE '%smart%' OR a.title ILIKE '%irrigation%')
  AND c.slug = 'electronics'
ON CONFLICT DO NOTHING;

-- Permaculture (broader match)
INSERT INTO public.activity_category_links (activity_id, category_id)
SELECT a.id, c.id
FROM public.activities a, public.activity_categories c
WHERE (a.title ILIKE '%permaculture%' OR a.title ILIKE '%erosion%' OR a.title ILIKE '%swale%' OR a.title ILIKE '%water%' OR a.title ILIKE '%soil%' OR a.title ILIKE '%compost%')
  AND c.slug = 'permaculture'
ON CONFLICT DO NOTHING;

-- Green Engineering
INSERT INTO public.activity_category_links (activity_id, category_id)
SELECT a.id, c.id
FROM public.activities a, public.activity_categories c
WHERE (a.title ILIKE '%engineering%' OR a.title ILIKE '%system%' OR a.title ILIKE '%design%' OR a.title ILIKE '%pump%')
  AND c.slug = 'green-engineering'
ON CONFLICT DO NOTHING;

-- Show results
SELECT
  c.name as category,
  COUNT(acl.activity_id) as activity_count
FROM public.activity_categories c
LEFT JOIN public.activity_category_links acl ON c.id = acl.category_id
GROUP BY c.id, c.name, c.display_order
ORDER BY c.display_order;
