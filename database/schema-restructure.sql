-- GUIDAL Schema Restructure
-- Clean separation of activity templates vs scheduled visits
-- This file creates the new cleaner schema structure

-- =====================================================
-- STEP 1: BACKUP EXISTING DATA
-- =====================================================

-- Create backup tables before restructuring
CREATE TABLE IF NOT EXISTS activities_backup AS SELECT * FROM activities;
CREATE TABLE IF NOT EXISTS visits_backup AS SELECT * FROM visits;
CREATE TABLE IF NOT EXISTS activity_registrations_backup AS SELECT * FROM activity_registrations;

-- =====================================================
-- STEP 2: NEW CLEAN SCHEMA
-- =====================================================

-- 1. Rename current visits table to past_visits
-- This stores completed visits/events from the past
ALTER TABLE visits RENAME TO past_visits;

-- Add visit_type to past_visits for better classification
ALTER TABLE past_visits ADD COLUMN IF NOT EXISTS visit_type TEXT DEFAULT 'school_group'
CHECK (visit_type IN ('school_group', 'individual', 'public_event', 'workshop', 'other'));

-- Add activities_completed to track which activities were done during the visit
ALTER TABLE past_visits ADD COLUMN IF NOT EXISTS activities_completed UUID[] DEFAULT '{}';

-- 2. Create new scheduled_visits table for future planned visits
CREATE TABLE IF NOT EXISTS scheduled_visits (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,

  -- Visit details
  title TEXT NOT NULL,
  description TEXT,
  visit_type TEXT NOT NULL DEFAULT 'individual_workshop' CHECK (visit_type IN (
    'individual_workshop',    -- Individual booking a workshop
    'school_group',          -- School group visit
    'public_event',          -- Public event with registration
    'private_group',         -- Private group booking
    'other'
  )),

  -- Scheduling
  scheduled_date TIMESTAMP WITH TIME ZONE NOT NULL,
  duration_minutes INTEGER,
  max_participants INTEGER,
  current_participants INTEGER DEFAULT 0,

  -- Contact and logistics
  contact_email TEXT,
  contact_name TEXT,
  contact_phone TEXT,
  school_name TEXT,           -- For school visits
  group_size INTEGER,
  special_requirements TEXT,

  -- Pricing and status
  price_per_person NUMERIC(10,2) DEFAULT 0,
  total_cost NUMERIC(10,2),
  status TEXT DEFAULT 'pending' CHECK (status IN (
    'pending', 'confirmed', 'in_progress', 'completed', 'cancelled'
  )),

  -- Metadata
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Clean up activities table - remove scheduling fields, keep only templates
-- First save the scheduled activities data
CREATE TABLE IF NOT EXISTS scheduled_activities_temp AS
SELECT * FROM activities WHERE date_time IS NOT NULL AND status IN ('published', 'active', 'upcoming');

-- Remove scheduling-specific columns from activities (make it pure templates)
ALTER TABLE activities DROP COLUMN IF EXISTS date_time;
ALTER TABLE activities DROP COLUMN IF EXISTS current_participants;
ALTER TABLE activities DROP COLUMN IF EXISTS max_participants;
ALTER TABLE activities DROP COLUMN IF EXISTS credits_required;
ALTER TABLE activities DROP COLUMN IF EXISTS credits_earned;
ALTER TABLE activities DROP COLUMN IF EXISTS price;
ALTER TABLE activities DROP COLUMN IF EXISTS contact_email;
ALTER TABLE activities DROP COLUMN IF EXISTS contact_phone;

-- Add fields that make sense for activity templates
ALTER TABLE activities ADD COLUMN IF NOT EXISTS suggested_duration_minutes INTEGER;
ALTER TABLE activities ADD COLUMN IF NOT EXISTS recommended_group_size TEXT;
ALTER TABLE activities ADD COLUMN IF NOT EXISTS equipment_needed TEXT[];
ALTER TABLE activities ADD COLUMN IF NOT EXISTS preparation_time_minutes INTEGER;

-- Update status options for activity templates
ALTER TABLE activities DROP CONSTRAINT IF EXISTS activities_status_check;
ALTER TABLE activities ADD CONSTRAINT activities_status_check
CHECK (status IN ('draft', 'published', 'archived'));

-- 4. Create junction table for visit-activity relationships
CREATE TABLE IF NOT EXISTS visit_activities (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,

  -- Can link to either scheduled_visits or past_visits
  scheduled_visit_id UUID REFERENCES scheduled_visits(id) ON DELETE CASCADE,
  past_visit_id UUID REFERENCES past_visits(id) ON DELETE CASCADE,

  activity_id UUID REFERENCES activities(id) NOT NULL,

  -- Activity-specific details for this visit
  duration_minutes INTEGER,
  participants_count INTEGER,
  instructor TEXT,
  completed BOOLEAN DEFAULT FALSE,
  completion_notes TEXT,
  satisfaction_rating INTEGER CHECK (satisfaction_rating >= 1 AND satisfaction_rating <= 5),

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  -- Ensure we link to exactly one visit type
  CHECK (
    (scheduled_visit_id IS NOT NULL AND past_visit_id IS NULL) OR
    (scheduled_visit_id IS NULL AND past_visit_id IS NOT NULL)
  )
);

-- 5. Update activity_registrations to work with new schema
-- Add reference to scheduled_visits
ALTER TABLE activity_registrations ADD COLUMN IF NOT EXISTS scheduled_visit_id UUID REFERENCES scheduled_visits(id);

-- For individual workshop bookings, we'll create a scheduled_visit and link the registration
-- Group bookings will have multiple registrations linked to the same scheduled_visit

-- =====================================================
-- STEP 3: MIGRATE EXISTING DATA
-- =====================================================

-- Migrate scheduled activities to scheduled_visits
INSERT INTO scheduled_visits (
  title,
  description,
  visit_type,
  scheduled_date,
  duration_minutes,
  max_participants,
  current_participants,
  price_per_person,
  status,
  created_at
)
SELECT
  title,
  description,
  CASE
    WHEN activity_type_id = (SELECT id FROM activity_types WHERE slug = 'school-visits') THEN 'school_group'
    WHEN activity_type_id = (SELECT id FROM activity_types WHERE slug = 'workshops') THEN 'individual_workshop'
    WHEN activity_type_id = (SELECT id FROM activity_types WHERE slug = 'events') THEN 'public_event'
    ELSE 'other'
  END as visit_type,
  date_time,
  duration_minutes,
  max_participants,
  current_participants,
  price,
  CASE status
    WHEN 'published' THEN 'confirmed'
    WHEN 'active' THEN 'confirmed'
    WHEN 'upcoming' THEN 'pending'
    WHEN 'completed' THEN 'completed'
    ELSE 'pending'
  END as status,
  created_at
FROM scheduled_activities_temp;

-- Create visit_activities entries for the migrated scheduled visits
INSERT INTO visit_activities (scheduled_visit_id, activity_id, participants_count)
SELECT
  sv.id as scheduled_visit_id,
  sat.id as activity_id,
  sat.current_participants
FROM scheduled_visits sv
JOIN scheduled_activities_temp sat ON (
  sv.title = sat.title AND
  sv.scheduled_date = sat.date_time
);

-- Update activity_registrations to reference scheduled_visits
UPDATE activity_registrations ar
SET scheduled_visit_id = sv.id
FROM scheduled_visits sv
JOIN scheduled_activities_temp sat ON (
  sv.title = sat.title AND
  sv.scheduled_date = sat.date_time
)
WHERE ar.activity_id = sat.id;

-- =====================================================
-- STEP 4: INDEXES AND CONSTRAINTS
-- =====================================================

-- Indexes for scheduled_visits
CREATE INDEX IF NOT EXISTS idx_scheduled_visits_date ON scheduled_visits(scheduled_date);
CREATE INDEX IF NOT EXISTS idx_scheduled_visits_type ON scheduled_visits(visit_type);
CREATE INDEX IF NOT EXISTS idx_scheduled_visits_status ON scheduled_visits(status);
CREATE INDEX IF NOT EXISTS idx_scheduled_visits_school ON scheduled_visits(school_name);

-- Indexes for past_visits
CREATE INDEX IF NOT EXISTS idx_past_visits_type ON past_visits(visit_type);
CREATE INDEX IF NOT EXISTS idx_past_visits_school ON past_visits(school_name);

-- Indexes for visit_activities
CREATE INDEX IF NOT EXISTS idx_visit_activities_scheduled ON visit_activities(scheduled_visit_id);
CREATE INDEX IF NOT EXISTS idx_visit_activities_past ON visit_activities(past_visit_id);
CREATE INDEX IF NOT EXISTS idx_visit_activities_activity ON visit_activities(activity_id);

-- =====================================================
-- STEP 5: UPDATE TRIGGERS
-- =====================================================

-- Add updated_at triggers for new tables
CREATE TRIGGER handle_scheduled_visits_updated_at
  BEFORE UPDATE ON scheduled_visits
  FOR EACH ROW EXECUTE PROCEDURE handle_updated_at();

CREATE TRIGGER handle_visit_activities_updated_at
  BEFORE UPDATE ON visit_activities
  FOR EACH ROW EXECUTE PROCEDURE handle_updated_at();

-- =====================================================
-- STEP 6: RLS POLICIES
-- =====================================================

-- Enable RLS on new tables
ALTER TABLE scheduled_visits ENABLE ROW LEVEL SECURITY;
ALTER TABLE visit_activities ENABLE ROW LEVEL SECURITY;

-- Scheduled visits policies
CREATE POLICY "Public can view confirmed scheduled visits" ON scheduled_visits
  FOR SELECT USING (status = 'confirmed');

CREATE POLICY "Users can view their own scheduled visits" ON scheduled_visits
  FOR SELECT USING (contact_email = auth.jwt() ->> 'email');

CREATE POLICY "Admins can manage all scheduled visits" ON scheduled_visits
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.user_type = 'admin'
    )
  );

-- Visit activities policies
CREATE POLICY "Public can view visit activities" ON visit_activities
  FOR SELECT USING (true);

CREATE POLICY "Admins can manage visit activities" ON visit_activities
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.user_type = 'admin'
    )
  );

-- =====================================================
-- STEP 7: HELPFUL VIEWS
-- =====================================================

-- View for upcoming scheduled visits with activities
CREATE OR REPLACE VIEW upcoming_visits_with_activities AS
SELECT
  sv.*,
  json_agg(
    json_build_object(
      'id', a.id,
      'title', a.title,
      'description', a.description,
      'type', at.name,
      'duration', va.duration_minutes
    )
  ) FILTER (WHERE a.id IS NOT NULL) as activities
FROM scheduled_visits sv
LEFT JOIN visit_activities va ON va.scheduled_visit_id = sv.id
LEFT JOIN activities a ON a.id = va.activity_id
LEFT JOIN activity_types at ON at.id = a.activity_type_id
WHERE sv.scheduled_date >= NOW()
GROUP BY sv.id
ORDER BY sv.scheduled_date;

-- View for past visits with completed activities
CREATE OR REPLACE VIEW past_visits_with_activities AS
SELECT
  pv.*,
  json_agg(
    json_build_object(
      'id', a.id,
      'title', a.title,
      'completed', va.completed,
      'rating', va.satisfaction_rating,
      'notes', va.completion_notes
    )
  ) FILTER (WHERE a.id IS NOT NULL) as activities
FROM past_visits pv
LEFT JOIN visit_activities va ON va.past_visit_id = pv.id
LEFT JOIN activities a ON a.id = va.activity_id
GROUP BY pv.id
ORDER BY pv.created_at DESC;

-- View for science-in-action activities (activity templates)
CREATE OR REPLACE VIEW science_in_action_activities AS
SELECT
  a.*,
  at.name as activity_type_name,
  at.slug as activity_type_slug,
  at.icon as activity_type_icon
FROM activities a
JOIN activity_types at ON at.id = a.activity_type_id
WHERE a.status = 'published'
  AND at.slug IN ('workshops', 'science-stations') -- These are our science-in-action activities
ORDER BY a.title;

-- =====================================================
-- STEP 8: CLEANUP TEMPORARY TABLES
-- =====================================================

-- Keep the temp table for now in case we need to reference it
-- DROP TABLE IF EXISTS scheduled_activities_temp;

-- Grant permissions
GRANT SELECT ON upcoming_visits_with_activities TO anon, authenticated;
GRANT SELECT ON past_visits_with_activities TO anon, authenticated;
GRANT SELECT ON science_in_action_activities TO anon, authenticated;
GRANT ALL ON scheduled_visits TO authenticated;
GRANT ALL ON visit_activities TO authenticated;

-- Add helpful comments
COMMENT ON TABLE activities IS 'Activity templates - describes what can be done (science-in-action stations, workshop formats, etc.)';
COMMENT ON TABLE scheduled_visits IS 'Future planned visits and events with specific dates and bookings';
COMMENT ON TABLE past_visits IS 'Historical record of completed visits and events';
COMMENT ON TABLE visit_activities IS 'Junction table linking visits to the activities that were planned/completed';