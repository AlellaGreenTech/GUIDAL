-- Add Halloween parties to scheduled_visits table so they appear on the activities page

-- Insert Halloween Maxi-Party (Oct 25, 2025)
INSERT INTO scheduled_visits (
    activity_id,
    title,
    visit_type,
    scheduled_date,
    status
)
SELECT
    id,
    title,
    'public_event',
    date_time,
    'confirmed'
FROM activities
WHERE title LIKE '%Halloween%Party 2025%'
  AND title NOT LIKE '%Mini%'
  AND NOT EXISTS (
    SELECT 1 FROM scheduled_visits sv WHERE sv.activity_id = activities.id
  );

-- Insert Halloween Mini-Party (Nov 1, 2025)
INSERT INTO scheduled_visits (
    activity_id,
    title,
    visit_type,
    scheduled_date,
    status
)
SELECT
    id,
    title,
    'public_event',
    date_time,
    'confirmed'
FROM activities
WHERE title LIKE '%Halloween Mini-Party%'
  AND NOT EXISTS (
    SELECT 1 FROM scheduled_visits sv WHERE sv.activity_id = activities.id
  );

-- Verify the inserts
SELECT
    sv.id as scheduled_visit_id,
    sv.visit_type,
    sv.scheduled_date,
    a.title,
    RIGHT(a.description, 60) as description_end
FROM scheduled_visits sv
JOIN activities a ON sv.activity_id = a.id
WHERE a.title LIKE '%Halloween%Party%'
ORDER BY sv.scheduled_date;
