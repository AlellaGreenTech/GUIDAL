-- Update "Pick Your Own Pumpkins" activity to add "Any Day!" to hero text

UPDATE scheduled_activities
SET hero_text = CONCAT(hero_text, ' Any Day!')
WHERE title ILIKE '%Pick Your Own Pumpkin%'
  AND (hero_text IS NULL OR hero_text NOT LIKE '%Any Day%');

-- Also update if it exists in activities table
UPDATE activities
SET hero_text = CONCAT(hero_text, ' Any Day!')
WHERE title ILIKE '%Pick Your Own Pumpkin%'
  AND (hero_text IS NULL OR hero_text NOT LIKE '%Any Day%');

-- Verify the update
SELECT id, title, hero_text, description
FROM scheduled_activities
WHERE title ILIKE '%Pick Your Own Pumpkin%';

SELECT id, title, hero_text, description
FROM activities
WHERE title ILIKE '%Pick Your Own Pumpkin%';
