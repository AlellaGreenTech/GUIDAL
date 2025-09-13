-- Update activities with proper image paths stored in database
-- Run this after setting up the main GREENs schema

UPDATE public.activities 
SET featured_image = 'images/school-visit-planting.png'
WHERE title = 'Benjamin Franklin International School'
   OR slug = 'station-1-planting-workshop';

UPDATE public.activities 
SET featured_image = 'images/school-visit-prague.png'
WHERE title = 'International School of Prague'
   OR slug = 'station-2-composting';

UPDATE public.activities 
SET featured_image = 'images/workshop-construction.png'
WHERE title LIKE '%Ram Pump%'
   OR slug = 'ram-pump-construction';

UPDATE public.activities 
SET featured_image = 'images/sustainability-fair.png'
WHERE title LIKE '%Sustainability Fair%'
   OR slug = 'community-sustainability-fair';

UPDATE public.activities 
SET featured_image = 'images/lunch-event.png'
WHERE title LIKE '%Lunch%'
   OR activity_type_id = (SELECT id FROM activity_types WHERE slug = 'event');

-- For activities without specific images, set a default
UPDATE public.activities 
SET featured_image = 'images/activity-default.png'
WHERE featured_image IS NULL;

-- Verify the updates
SELECT title, featured_image, gallery_images 
FROM public.activities 
WHERE featured_image IS NOT NULL
ORDER BY title;