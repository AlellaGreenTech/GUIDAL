-- Refactor to proper two-table architecture:
-- activities = catalog/templates (what you offer)
-- scheduled_visits = instances (when it's scheduled)
-- Run this in Supabase SQL Editor

-- STEP 1: Add activity_id foreign key to scheduled_visits
ALTER TABLE scheduled_visits
ADD COLUMN IF NOT EXISTS activity_id UUID REFERENCES activities(id);

COMMENT ON COLUMN scheduled_visits.activity_id IS 'References the activity template this visit is based on';

-- STEP 2: Add necessary columns to activities table (templates)
-- These fields should live in activities, not scheduled_visits:
-- - title, description (already there)
-- - featured_image, details_page_url, tutorial_page_url, teacher_notes_url
-- - duration_minutes (already there), max_participants, min_participants

ALTER TABLE activities
ADD COLUMN IF NOT EXISTS featured_image TEXT,
ADD COLUMN IF NOT EXISTS details_page_url TEXT,
ADD COLUMN IF NOT EXISTS tutorial_page_url TEXT,
ADD COLUMN IF NOT EXISTS teacher_notes_url TEXT,
ADD COLUMN IF NOT EXISTS max_participants INTEGER,
ADD COLUMN IF NOT EXISTS min_participants INTEGER;

-- STEP 3: Ensure 'workshops' activity type exists
INSERT INTO activity_types (name, slug, color, icon)
VALUES ('Workshops', 'workshops', '#ff9800', '🔧')
ON CONFLICT (slug) DO NOTHING;

-- STEP 4: Create activity templates from unique workshops in scheduled_visits
-- This groups all "Ram Pumps Workshop Session" entries into one template

INSERT INTO activities (
  id,
  title,
  slug,
  description,
  activity_type_id,
  duration_minutes,
  max_participants,
  min_participants,
  status,
  featured_image,
  details_page_url,
  tutorial_page_url,
  teacher_notes_url
)
SELECT
  gen_random_uuid() as id,
  -- Use the base title (strip "Workshop Session" if present for cleaner template names)
  REGEXP_REPLACE(title, ' Workshop Session$', '') as title,
  -- Generate slug from title
  LOWER(REGEXP_REPLACE(REGEXP_REPLACE(title, ' Workshop Session$', ''), '[^a-zA-Z0-9]+', '-', 'g')) as slug,
  description,
  -- Get workshop activity_type_id
  (SELECT id FROM activity_types WHERE slug = 'workshops') as activity_type_id,
  duration_minutes,
  max_participants,
  min_participants,
  'published' as status,
  featured_image,
  details_page_url,
  tutorial_page_url,
  teacher_notes_url
FROM (
  -- Get unique workshops (distinct by title)
  SELECT DISTINCT ON (title)
    title,
    description,
    duration_minutes,
    max_participants,
    min_participants,
    featured_image,
    details_page_url,
    tutorial_page_url,
    teacher_notes_url
  FROM scheduled_visits
  WHERE visit_type = 'individual_workshop'
  ORDER BY title,
    CASE WHEN details_page_url IS NOT NULL THEN 0 ELSE 1 END,
    created_at DESC
) unique_workshops
ON CONFLICT (slug) DO NOTHING;

-- STEP 4: Link scheduled_visits back to their activity templates
UPDATE scheduled_visits sv
SET activity_id = a.id
FROM activities a
WHERE sv.visit_type = 'individual_workshop'
  AND (
    sv.title = a.title
    OR sv.title = a.title || ' Workshop Session'
    OR REGEXP_REPLACE(sv.title, ' Workshop Session$', '') = a.title
  );

-- STEP 5: Ensure 'events' activity type exists
INSERT INTO activity_types (name, slug, color, icon)
VALUES ('Events', 'events', '#17a2b8', '🎉')
ON CONFLICT (slug) DO NOTHING;

-- STEP 6: For events, create templates too
INSERT INTO activities (
  id,
  title,
  slug,
  description,
  activity_type_id,
  status
)
SELECT DISTINCT ON (title)
  gen_random_uuid(),
  title,
  LOWER(REGEXP_REPLACE(title, '[^a-zA-Z0-9]+', '-', 'g')),
  description,
  (SELECT id FROM activity_types WHERE slug = 'events'),
  'published'
FROM scheduled_visits
WHERE visit_type = 'public_event'
ON CONFLICT (slug) DO NOTHING;

-- Link events to templates
UPDATE scheduled_visits sv
SET activity_id = a.id
FROM activities a
WHERE sv.visit_type = 'public_event'
  AND sv.title = a.title;

-- STEP 7: Verify the relationships
SELECT
  a.title as activity_template,
  COUNT(sv.id) as scheduled_instances,
  COUNT(CASE WHEN sv.scheduled_date IS NULL THEN 1 END) as on_request_instances,
  COUNT(CASE WHEN sv.scheduled_date IS NOT NULL THEN 1 END) as scheduled_instances_count
FROM activities a
LEFT JOIN scheduled_visits sv ON sv.activity_id = a.id
WHERE a.status = 'published'
GROUP BY a.id, a.title
ORDER BY a.title;

-- STEP 8: (Future) Make activity_id NOT NULL and remove duplicate content from scheduled_visits
-- Don't run these yet - verify the migration first!
-- ALTER TABLE scheduled_visits ALTER COLUMN activity_id SET NOT NULL;
-- ALTER TABLE scheduled_visits DROP COLUMN title, DROP COLUMN description, etc.
