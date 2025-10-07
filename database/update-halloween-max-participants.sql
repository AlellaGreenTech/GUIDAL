-- Update Halloween Party events to have max_participants = 200

UPDATE activities
SET max_participants = 200
WHERE title LIKE '%Halloween%Party%2025%';

-- Verify the update
SELECT id, title, date_time, max_participants
FROM activities
WHERE title LIKE '%Halloween%'
ORDER BY date_time;
