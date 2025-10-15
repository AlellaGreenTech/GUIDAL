-- Fix Halloween party scheduled_visits entries

-- First, let's see what we have
SELECT 'BEFORE CLEANUP:' as step;
SELECT
    sv.id,
    sv.title,
    sv.activity_id,
    sv.scheduled_date
FROM scheduled_visits sv
WHERE sv.title LIKE '%Halloween%Party%'
ORDER BY sv.scheduled_date;

-- Delete scheduled_visits entries that have NULL activity_id (orphaned entries)
DELETE FROM scheduled_visits
WHERE title LIKE '%Halloween%Party%'
  AND activity_id IS NULL;

-- Verify cleanup
SELECT 'AFTER CLEANUP:' as step;
SELECT
    sv.id as scheduled_visit_id,
    sv.activity_id,
    sv.title as sv_title,
    sv.scheduled_date,
    a.title as activity_title,
    RIGHT(a.description, 80) as description_end
FROM scheduled_visits sv
LEFT JOIN activities a ON sv.activity_id = a.id
WHERE sv.title LIKE '%Halloween%Party%'
ORDER BY sv.scheduled_date;
