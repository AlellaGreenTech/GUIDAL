-- Add featured_image column to scheduled_visits table
-- Run this in Supabase SQL Editor

-- Add the column
ALTER TABLE scheduled_visits
ADD COLUMN IF NOT EXISTS featured_image TEXT;

-- Update existing workshop sessions with their correct images
UPDATE scheduled_visits
SET featured_image = 'images/composting-farm-scene.png'
WHERE title LIKE '%Composting Workshop%';

UPDATE scheduled_visits
SET featured_image = 'images/school-visit-planting.png'
WHERE title LIKE '%Planting Workshop%';

UPDATE scheduled_visits
SET featured_image = 'images/swales.jpg'
WHERE title LIKE '%Erosion%';

UPDATE scheduled_visits
SET featured_image = 'images/hydraulic-ram-pump-system.png'
WHERE title LIKE '%Ram Pump%';

UPDATE scheduled_visits
SET featured_image = 'images/robotic-gardening-system.png'
WHERE title LIKE '%Robotic Gardening%';

UPDATE scheduled_visits
SET featured_image = 'images/wattle-daub-construction.png'
WHERE title LIKE '%Wattle%' OR title LIKE '%Daub%';

UPDATE scheduled_visits
SET featured_image = 'images/smart-irrigation-demo.png'
WHERE title LIKE '%Irrigation%';

-- Update Halloween events with their images
UPDATE scheduled_visits
SET featured_image = 'images/pumpkin-patch.jpg'
WHERE title LIKE '%SCARY PUMPKIN PATCH%';

UPDATE scheduled_visits
SET featured_image = 'images/halloween-party.png'
WHERE title LIKE '%Halloween Party%';
