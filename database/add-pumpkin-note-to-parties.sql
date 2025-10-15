-- Add "Kids tickets include a pumpkin!" to party descriptions

-- Update Halloween Party 2025 (Oct 25)
UPDATE activities
SET description = REPLACE(
    description,
    'costumes encouraged!',
    'costumes encouraged! Kids tickets include a pumpkin!'
)
WHERE title LIKE '%Halloween Party 2025%'
  AND title NOT LIKE '%Mini%';

-- Update Halloween Mini-Party 2025 (Nov 1)
UPDATE activities
SET description = REPLACE(
    description,
    'costumes encouraged!',
    'costumes encouraged! Kids tickets include a pumpkin!'
)
WHERE title LIKE '%Halloween Mini-Party%';

-- Verify the updates
SELECT
    title,
    RIGHT(description, 120) as description_end
FROM activities
WHERE title LIKE '%Halloween%Party%'
ORDER BY date_time;
