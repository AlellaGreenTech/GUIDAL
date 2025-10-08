-- STEP 1: See what duplicates we have
-- Run this first to see which records will be kept (rn=1) and which will be deleted (rn>1)

SELECT
    activity_id,
    title,
    id,
    created_at,
    ROW_NUMBER() OVER (PARTITION BY activity_id, visit_type ORDER BY created_at ASC) as rn
FROM scheduled_visits
WHERE visit_type = 'individual_workshop'
  AND scheduled_date IS NULL
ORDER BY activity_id, created_at;
