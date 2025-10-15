-- Check if Halloween parties exist in scheduled_visits table

SELECT
    sv.id as scheduled_visit_id,
    sv.activity_id,
    sv.visit_type,
    sv.scheduled_date,
    a.title,
    LEFT(a.description, 150) as description_preview,
    CASE
        WHEN a.description LIKE '%Tony''s From New York%' THEN '✅ Has Tony''s text'
        ELSE '❌ Missing Tony''s text'
    END as tony_check
FROM scheduled_visits sv
JOIN activities a ON sv.activity_id = a.id
WHERE a.title LIKE '%Halloween%Party%'
ORDER BY sv.scheduled_date;

-- Also check activities table directly
SELECT
    id,
    title,
    date_time,
    LEFT(description, 150) as description_preview,
    CASE
        WHEN description LIKE '%Tony''s From New York%' THEN '✅ Has Tony''s text'
        ELSE '❌ Missing Tony''s text'
    END as tony_check
FROM activities
WHERE title LIKE '%Halloween%Party%'
ORDER BY date_time;
