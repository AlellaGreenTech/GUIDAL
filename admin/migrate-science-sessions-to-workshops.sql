-- Migrate science sessions from activities table to scheduled_visits as unscheduled workshops
-- This consolidates all workshops into one table with scheduled_date = NULL for "on request" workshops
-- Run this in Supabase SQL Editor

-- Insert science session templates as unscheduled workshops (available on request)
INSERT INTO scheduled_visits (
  title,
  description,
  visit_type,
  scheduled_date,
  duration_minutes,
  max_participants,
  min_participants,
  status,
  featured_image
)
SELECT
  title,
  description,
  'individual_workshop' as visit_type,
  NULL as scheduled_date,  -- NULL = available on request, not scheduled
  suggested_duration_minutes as duration_minutes,
  15 as max_participants,  -- Default max
  1 as min_participants,
  'confirmed' as status,
  featured_image
FROM activities
WHERE status = 'published'
  AND title NOT IN (
    -- Don't duplicate if workshop already exists in scheduled_visits
    SELECT title FROM scheduled_visits WHERE visit_type = 'individual_workshop'
  );

-- Optional: After verifying the migration worked, you can archive the old activities
-- UPDATE activities SET status = 'archived' WHERE status = 'published';
