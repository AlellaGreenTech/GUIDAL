-- Show all scheduled_visits entries for Halloween parties

SELECT
    sv.id as scheduled_visit_id,
    sv.activity_id,
    sv.title as sv_title,
    sv.visit_type,
    sv.scheduled_date,
    sv.status,
    a.title as activity_title,
    RIGHT(a.description, 80) as description_end
FROM scheduled_visits sv
LEFT JOIN activities a ON sv.activity_id = a.id
WHERE sv.title LIKE '%Halloween%Party%'
   OR a.title LIKE '%Halloween%Party%'
ORDER BY sv.scheduled_date;
