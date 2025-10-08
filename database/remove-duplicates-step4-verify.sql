-- STEP 4: Verify no duplicates remain
-- Run this to confirm cleanup was successful

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

-- Clean up temp tables
DROP TABLE IF EXISTS keepers;
DROP TABLE IF EXISTS duplicates;
