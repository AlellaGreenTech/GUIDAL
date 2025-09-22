-- Visit Requests Table
-- Simplified schema based on actual Google Form requirements
-- Stores educational visit planning requests from schools

CREATE TABLE IF NOT EXISTS visit_requests (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,

    -- Contact Information
    contact_email TEXT NOT NULL,
    lead_teacher_contact TEXT NOT NULL,
    school_name TEXT NOT NULL,
    country_of_origin TEXT NOT NULL,

    -- Visit Planning
    potential_visit_dates TEXT, -- Free text field for flexible date entry
    preferred_language TEXT,
    number_of_students INTEGER NOT NULL CHECK (number_of_students > 0),
    number_of_adults INTEGER,

    -- Visit Format (single choice from the form)
    visit_format TEXT CHECK (visit_format IN (
        'full_day_pizza_lunch',     -- Full day with pizza lunch included. Usually 10am to 3:30pm
        'morning_no_lunch',         -- Just the morning with no lunch (visit ends 1300 or 1330)
        'morning_with_lunch',       -- Just the morning with lunch. We depart right after lunch (1400 or 1430)
        'other'                     -- Other option with custom text
    )),
    visit_format_other TEXT,        -- For "Other" option

    -- Educational Focus (single choice)
    educational_focus TEXT CHECK (educational_focus IN (
        'seeing_real_world_science',    -- We prefer seeing real world examples that relate to things learnt about at school/homeschooling
        'hands_on_permaculture',        -- We prefer a very hands on visit where kids work with the land, water, plants, & soil following permaculture
        'balanced_mix',                 -- We prefer a balanced mix of seeing things and doing things
        'other'                         -- Other option
    )),
    educational_focus_other TEXT,   -- For "Other" option

    -- Selected Workshops/Stations (multiple choice - checkboxes)
    -- We'll reference the existing activities table for workshop options
    selected_workshops UUID[] DEFAULT '{}', -- Array of activity IDs

    -- Food Preferences/Requirements
    food_preferences TEXT[] DEFAULT '{}', -- Can include multiple options like dietary restrictions

    -- Additional Comments
    additional_comments TEXT,

    -- Status and Metadata
    status TEXT DEFAULT 'pending' CHECK (status IN (
        'pending', 'reviewing', 'approved', 'scheduled', 'completed', 'cancelled'
    )),
    submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Admin fields
    internal_notes TEXT,
    response_sent_at TIMESTAMP WITH TIME ZONE,
    confirmed_date DATE,
    confirmed_format TEXT,
    estimated_cost NUMERIC(10,2)
);

-- Add RLS (Row Level Security) policies
ALTER TABLE visit_requests ENABLE ROW LEVEL SECURITY;

-- Allow public to insert visit requests (for form submissions)
CREATE POLICY "Anyone can submit visit requests" ON visit_requests
    FOR INSERT WITH CHECK (true);

-- Allow users to view their own requests by email
CREATE POLICY "Users can view own visit requests" ON visit_requests
    FOR SELECT USING (contact_email = auth.jwt() ->> 'email');

-- Allow admin users to view and manage all visit requests
CREATE POLICY "Admins can manage all visit requests" ON visit_requests
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM user_profiles
            WHERE user_profiles.user_id = auth.uid()
            AND user_profiles.role IN ('admin', 'staff')
        )
    );

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_visit_requests_status ON visit_requests(status);
CREATE INDEX IF NOT EXISTS idx_visit_requests_submitted_at ON visit_requests(submitted_at);
CREATE INDEX IF NOT EXISTS idx_visit_requests_school_name ON visit_requests(school_name);
CREATE INDEX IF NOT EXISTS idx_visit_requests_contact_email ON visit_requests(contact_email);
CREATE INDEX IF NOT EXISTS idx_visit_requests_potential_dates ON visit_requests USING gin(to_tsvector('english', potential_visit_dates));

-- Create trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_visit_requests_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_visit_requests_updated_at
    BEFORE UPDATE ON visit_requests
    FOR EACH ROW
    EXECUTE FUNCTION update_visit_requests_updated_at();

-- Helpful views for common queries

-- View for pending visit requests with urgency
CREATE OR REPLACE VIEW pending_visit_requests AS
SELECT
    vr.*,
    CASE
        WHEN vr.potential_visit_dates IS NULL THEN 'no_date'
        WHEN vr.potential_visit_dates ILIKE '%urgent%' OR vr.potential_visit_dates ILIKE '%asap%' THEN 'urgent'
        WHEN vr.potential_visit_dates ILIKE '%next week%' OR vr.potential_visit_dates ILIKE '%soon%' THEN 'upcoming'
        ELSE 'future'
    END AS urgency_level
FROM visit_requests vr
WHERE vr.status = 'pending'
ORDER BY vr.submitted_at DESC;

-- View for visit requests with workshop details
CREATE OR REPLACE VIEW visit_requests_with_workshops AS
SELECT
    vr.*,
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
FROM visit_requests vr
LEFT JOIN UNNEST(vr.selected_workshops) AS workshop_id ON true
LEFT JOIN activities a ON a.id = workshop_id::uuid
LEFT JOIN activity_types at ON at.id = a.activity_type_id
GROUP BY vr.id, vr.contact_email, vr.lead_teacher_contact, vr.school_name,
         vr.country_of_origin, vr.potential_visit_dates, vr.preferred_language,
         vr.number_of_students, vr.number_of_adults, vr.visit_format,
         vr.visit_format_other, vr.educational_focus, vr.educational_focus_other,
         vr.selected_workshops, vr.food_preferences, vr.additional_comments,
         vr.status, vr.submitted_at, vr.created_at, vr.updated_at,
         vr.internal_notes, vr.response_sent_at, vr.confirmed_date,
         vr.confirmed_format, vr.estimated_cost;

-- Grant necessary permissions
GRANT SELECT, INSERT ON visit_requests TO anon;
GRANT ALL ON visit_requests TO authenticated;
GRANT SELECT ON pending_visit_requests TO anon, authenticated;
GRANT SELECT ON visit_requests_with_workshops TO anon, authenticated;

-- Sample data for testing (commented out)
/*
INSERT INTO visit_requests (
    contact_email,
    lead_teacher_contact,
    school_name,
    country_of_origin,
    number_of_students,
    number_of_adults,
    visit_format,
    educational_focus,
    potential_visit_dates,
    additional_comments
) VALUES
(
    'teacher@barcelonaschool.edu',
    'Maria Garcia - Science Teacher',
    'Barcelona International School',
    'Spain',
    25,
    3,
    'full_day_pizza_lunch',
    'balanced_mix',
    'Any time in March 2025, preferably mid-month',
    'Students are studying renewable energy and would love to see real applications'
);
*/