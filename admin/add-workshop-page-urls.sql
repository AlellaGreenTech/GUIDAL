-- Add page URL columns to scheduled_visits table for three-level workshop pages
-- Run this in Supabase SQL Editor

-- Add columns for the three workshop page types
ALTER TABLE scheduled_visits
ADD COLUMN IF NOT EXISTS details_page_url TEXT,
ADD COLUMN IF NOT EXISTS tutorial_page_url TEXT,
ADD COLUMN IF NOT EXISTS teacher_notes_url TEXT;

-- Add comments for clarity
COMMENT ON COLUMN scheduled_visits.details_page_url IS 'Public overview page (anyone can view)';
COMMENT ON COLUMN scheduled_visits.tutorial_page_url IS 'Full tutorial page (requires booking confirmation)';
COMMENT ON COLUMN scheduled_visits.teacher_notes_url IS 'Teacher preparation guide (requires school visit booking)';

-- Update Ram Pumps workshop with the new page URLs
UPDATE scheduled_visits
SET
  details_page_url = 'workshops/ram-pumps-details.html',
  tutorial_page_url = 'workshops/ram-pumps-tutorial.html',
  teacher_notes_url = 'workshops/ram-pumps-teacher-notes.html'
WHERE title LIKE '%Ram Pump%';

-- You can add other workshops as you create their pages:
-- UPDATE scheduled_visits
-- SET
--   details_page_url = 'workshops/composting-details.html',
--   tutorial_page_url = 'workshops/composting-tutorial.html',
--   teacher_notes_url = 'workshops/composting-teacher-notes.html'
-- WHERE title LIKE '%Composting%';
