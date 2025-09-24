-- Migration script to rename visit_requests table to visits
-- This ensures consistency with the admin interface expectations

-- Step 1: Rename the table
ALTER TABLE IF EXISTS visit_requests RENAME TO visits;

-- Step 2: Update function name for trigger
DROP TRIGGER IF EXISTS update_visit_requests_updated_at ON visits;
DROP FUNCTION IF EXISTS update_visit_requests_updated_at();

-- Step 3: Update indexes (they should be renamed automatically, but let's be explicit)
DROP INDEX IF EXISTS idx_visit_requests_status;
DROP INDEX IF EXISTS idx_visit_requests_submitted_at;
DROP INDEX IF EXISTS idx_visit_requests_school_name;
DROP INDEX IF EXISTS idx_visit_requests_contact_email;
DROP INDEX IF EXISTS idx_visit_requests_potential_dates;

-- Step 4: Create new indexes with correct names
CREATE INDEX IF NOT EXISTS idx_visits_status ON visits(status);
CREATE INDEX IF NOT EXISTS idx_visits_submitted_at ON visits(submitted_at);
CREATE INDEX IF NOT EXISTS idx_visits_school_name ON visits(school_name);
CREATE INDEX IF NOT EXISTS idx_visits_contact_email ON visits(contact_email);
CREATE INDEX IF NOT EXISTS idx_visits_potential_dates ON visits USING gin(to_tsvector('english', potential_visit_dates));

-- Step 5: Update RLS policies
DROP POLICY IF EXISTS "Anyone can submit visit requests" ON visits;
DROP POLICY IF EXISTS "Users can view own visit requests" ON visits;
DROP POLICY IF EXISTS "Admins can manage all visit requests" ON visits;

-- Create new policies with correct names
CREATE POLICY "Anyone can submit visits" ON visits
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can view own visits" ON visits
    FOR SELECT USING (contact_email = auth.jwt() ->> 'email');

CREATE POLICY "Admins can manage all visits" ON visits
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM user_profiles
            WHERE user_profiles.user_id = auth.uid()
            AND user_profiles.role IN ('admin', 'staff')
        )
    );

-- Step 6: Create the updated trigger function and trigger
CREATE OR REPLACE FUNCTION update_visits_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_visits_updated_at
    BEFORE UPDATE ON visits
    FOR EACH ROW
    EXECUTE FUNCTION update_visits_updated_at();

-- Step 7: Update views
DROP VIEW IF EXISTS pending_visit_requests;
DROP VIEW IF EXISTS visit_requests_with_workshops;

-- Create new views with correct table references
CREATE OR REPLACE VIEW pending_visits AS
SELECT
    v.*,
    CASE
        WHEN v.potential_visit_dates IS NULL THEN 'no_date'
        WHEN v.potential_visit_dates ILIKE '%urgent%' OR v.potential_visit_dates ILIKE '%asap%' THEN 'urgent'
        WHEN v.potential_visit_dates ILIKE '%next week%' OR v.potential_visit_dates ILIKE '%soon%' THEN 'upcoming'
        ELSE 'future'
    END AS urgency_level
FROM visits v
WHERE v.status = 'pending'
ORDER BY v.submitted_at DESC;

CREATE OR REPLACE VIEW visits_with_workshops AS
SELECT
    v.*,
    COALESCE(
        json_agg(
            json_build_object(
                'id', a.id,
                'title', a.title,
                'description', a.description,
                'duration_minutes', a.duration_minutes,
                'max_participants', a.max_participants,
                'activity_type', at.name
            )
        ) FILTER (WHERE a.id IS NOT NULL),
        '[]'::json
    ) AS selected_workshops_details
FROM visits v
LEFT JOIN UNNEST(v.selected_workshops) AS workshop_id ON true
LEFT JOIN activities a ON a.id = workshop_id::uuid
LEFT JOIN activity_types at ON at.id = a.activity_type_id
GROUP BY v.id, v.contact_email, v.lead_teacher_contact, v.school_name,
         v.country_of_origin, v.potential_visit_dates, v.preferred_language,
         v.number_of_students, v.number_of_adults, v.visit_format,
         v.visit_format_other, v.educational_focus, v.educational_focus_other,
         v.selected_workshops, v.food_preferences, v.additional_comments,
         v.status, v.submitted_at, v.created_at, v.updated_at,
         v.internal_notes, v.response_sent_at, v.confirmed_date,
         v.confirmed_format, v.estimated_cost;

-- Step 8: Update permissions
REVOKE ALL ON visit_requests FROM anon, authenticated;
GRANT SELECT, INSERT ON visits TO anon;
GRANT ALL ON visits TO authenticated;
GRANT SELECT ON pending_visits TO anon, authenticated;
GRANT SELECT ON visits_with_workshops TO anon, authenticated;

-- Verification query to check if migration was successful
-- SELECT COUNT(*) as total_visits FROM visits;