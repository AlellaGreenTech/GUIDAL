-- Update max participants for specific workshops
-- Run this in Supabase SQL Editor

UPDATE activities
SET max_participants = CASE
    WHEN slug = 'erosion-challenge' THEN 30
    WHEN slug = 'schoolair-iot' THEN 10
    WHEN slug = 'composting' THEN 20
    WHEN slug = 'planting' THEN 30
    WHEN slug = 'pumped-hydro' THEN 8
    ELSE max_participants
END,
updated_at = NOW()
WHERE slug IN ('erosion-challenge', 'schoolair-iot', 'composting', 'planting', 'pumped-hydro');

-- Verify the updates
SELECT
    title,
    slug,
    max_participants,
    duration_minutes
FROM activities
WHERE slug IN ('erosion-challenge', 'schoolair-iot', 'composting', 'planting', 'pumped-hydro')
ORDER BY title;