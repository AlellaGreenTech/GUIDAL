-- Fix Halloween Party 2025 scheduled_date (should be October 25, 2025)

-- First check current dates
SELECT
    sv.id,
    sv.title,
    sv.scheduled_date,
    a.date_time as activity_date_time
FROM scheduled_visits sv
JOIN activities a ON sv.activity_id = a.id
WHERE sv.title LIKE '%Halloween Party 2025%';

-- Update scheduled_date from activities.date_time
UPDATE scheduled_visits sv
SET scheduled_date = a.date_time
FROM activities a
WHERE sv.activity_id = a.id
  AND sv.title LIKE '%Halloween Party 2025%'
  AND sv.scheduled_date IS NULL;

-- Verify the update
SELECT
    sv.id,
    sv.title,
    sv.scheduled_date,
    sv.status,
    a.title as activity_title
FROM scheduled_visits sv
JOIN activities a ON sv.activity_id = a.id
WHERE sv.title LIKE '%Halloween%Party%'
ORDER BY sv.scheduled_date;
