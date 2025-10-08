-- Simple approach: Just delete the duplicate activities
-- The ones with shorter/less descriptive titles

-- First, let's see what foreign key constraints might block us
SELECT
    a.title,
    (SELECT COUNT(*) FROM scheduled_visits WHERE activity_id = a.id) as scheduled_visits_count,
    (SELECT COUNT(*) FROM activity_category_links WHERE activity_id = a.id) as category_links_count
FROM activities a
WHERE a.title IN (
    'Composting',
    'Erosion Challenge',
    'No til Planting',
    'Robotic Gardening',
    'Wattle and Daub Construction'
)
ORDER BY a.title;
