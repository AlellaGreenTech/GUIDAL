-- Check for duplicate scheduled_visits entries
SELECT
    sv.id,
    sv.title,
    sv.visit_type,
    sv.scheduled_date,
    a.title as activity_title
FROM scheduled_visits sv
LEFT JOIN activities a ON sv.activity_id = a.id
WHERE sv.visit_type = 'individual_workshop'
ORDER BY sv.title, sv.scheduled_date;
