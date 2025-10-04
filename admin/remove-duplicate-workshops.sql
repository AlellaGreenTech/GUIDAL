-- Remove TRUE duplicate workshops from scheduled_visits table
-- TRUE duplicates = same title AND same scheduled_date (including both NULL)
-- This KEEPS scheduled vs on-request versions (different scheduled_date values)
-- Run this in Supabase SQL Editor

-- Find and remove duplicates with same title AND same scheduled_date
-- Keep the one with details_page_url if available, otherwise keep newest
DELETE FROM scheduled_visits
WHERE id IN (
  SELECT id FROM (
    SELECT id, ROW_NUMBER() OVER (
      PARTITION BY title, scheduled_date
      ORDER BY
        CASE WHEN details_page_url IS NOT NULL THEN 0 ELSE 1 END,
        created_at DESC NULLS LAST
    ) as rn
    FROM scheduled_visits
    WHERE visit_type = 'individual_workshop'
  ) t
  WHERE rn > 1
);

-- Show what remains - you should see both scheduled and on-request versions
SELECT
  title,
  CASE
    WHEN scheduled_date IS NULL THEN 'On Request'
    ELSE TO_CHAR(scheduled_date, 'YYYY-MM-DD')
  END as date,
  details_page_url
FROM scheduled_visits
WHERE visit_type = 'individual_workshop'
ORDER BY title, scheduled_date NULLS FIRST;
