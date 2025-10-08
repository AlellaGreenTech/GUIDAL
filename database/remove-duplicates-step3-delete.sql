-- STEP 3: Delete the duplicates
-- Run this AFTER step 2 to delete duplicate records

DELETE FROM scheduled_visits
WHERE id IN (SELECT id FROM duplicates);

-- Show how many were deleted
SELECT COUNT(*) as remaining_workshops
FROM scheduled_visits
WHERE visit_type = 'individual_workshop'
  AND scheduled_date IS NULL;
