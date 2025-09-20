-- Remove Duplicate Ram Pump Workshop
-- Delete the September 25th Ram Pump workshop, keep the November 8th one as standard

-- First, let's see what Ram Pump workshops exist
SELECT
  id,
  title,
  slug,
  date_time,
  location,
  max_participants,
  credits_required
FROM public.activities
WHERE title LIKE '%Ram Pump%'
ORDER BY date_time;

-- Delete the September 25th Ram Pump workshop
DELETE FROM public.activities
WHERE slug = 'ram-pump-workshop-sept-2025'
  AND date_time::date = '2025-09-25';

-- Verify the deletion - should only show the November 8th workshop now
SELECT
  id,
  title,
  slug,
  date_time,
  location,
  max_participants,
  credits_required,
  instructor
FROM public.activities
WHERE title LIKE '%Ram Pump%'
ORDER BY date_time;