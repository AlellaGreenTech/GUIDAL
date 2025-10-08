-- Remove duplicate workshop templates in scheduled_visits
-- Keep only one template per activity_id where visit_type = 'individual_workshop'

-- First, let's see what duplicates we have
SELECT
    activity_id,
    title,
    COUNT(*) as count
FROM scheduled_visits
WHERE visit_type = 'individual_workshop'
  AND scheduled_date IS NULL
GROUP BY activity_id, title
HAVING COUNT(*) > 1
ORDER BY count DESC;

-- Delete duplicates, keeping only the oldest record for each activity_id
DELETE FROM scheduled_visits
WHERE id IN (
    SELECT id
    FROM (
        SELECT id,
               ROW_NUMBER() OVER (
                   PARTITION BY activity_id, visit_type
                   ORDER BY created_at ASC
               ) as rn
        FROM scheduled_visits
        WHERE visit_type = 'individual_workshop'
          AND scheduled_date IS NULL
    ) t
    WHERE rn > 1
);

-- Verify - should show no duplicates now
SELECT
    activity_id,
    title,
    visit_type,
    COUNT(*) as count
FROM scheduled_visits
WHERE visit_type = 'individual_workshop'
  AND scheduled_date IS NULL
GROUP BY activity_id, title, visit_type
ORDER BY title;
