-- Add Tony's pizza text to Halloween party descriptions

-- Update Halloween Maxi-Party (Oct 25)
UPDATE activities
SET description = description || ' Pizzas hand crafted and served by Tony''s From New York!'
WHERE title LIKE '%Halloween Maxi-Party%'
  OR title LIKE '%Halloween Party 2025%';

-- Update Halloween Mini-Party (Nov 1)
UPDATE activities
SET description = description || ' Pizzas hand crafted and served by Tony''s From New York!'
WHERE title LIKE '%Halloween Mini-Party%';

-- Verify the updates
SELECT title, description
FROM activities
WHERE title LIKE '%Halloween%Party%'
ORDER BY date_time;
