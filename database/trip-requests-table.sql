-- Trip Requests Table
-- Stores educational visit planning requests from schools

CREATE TABLE IF NOT EXISTS trip_requests (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,

    -- School Information
    school_name TEXT NOT NULL,
    contact_name TEXT NOT NULL,
    contact_title TEXT,
    contact_email TEXT NOT NULL,
    contact_phone TEXT,
    school_location TEXT,

    -- Group Details
    student_count INTEGER NOT NULL CHECK (student_count > 0),
    teacher_count INTEGER DEFAULT 2,
    grade_level TEXT NOT NULL,
    age_range TEXT,
    special_needs TEXT,

    -- Visit Preferences
    preferred_date DATE NOT NULL,
    alternate_date DATE,
    visit_duration TEXT NOT NULL,
    arrival_time TIME,
    lunch_needs TEXT DEFAULT 'none',

    -- Learning Objectives
    primary_subjects TEXT[] DEFAULT '{}',
    learning_goals TEXT,

    -- Workshop Selection
    selected_workshops UUID[] DEFAULT '{}',
    workshop_details JSONB DEFAULT '[]',

    -- Transportation
    transportation TEXT,
    parking_needs TEXT,

    -- Additional Information
    previous_visit BOOLEAN DEFAULT FALSE,
    additional_requests TEXT,

    -- Status and Metadata
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'reviewing', 'approved', 'scheduled', 'completed', 'cancelled')),
    submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Optional: Link to created school visit activity
    scheduled_activity_id UUID REFERENCES activities(id),

    -- Notes from AGT staff
    internal_notes TEXT,
    response_sent_at TIMESTAMP WITH TIME ZONE,
    confirmed_date DATE,
    confirmed_duration INTEGER, -- in minutes
    estimated_cost NUMERIC(10,2)
);

-- Add RLS (Row Level Security) policies
ALTER TABLE trip_requests ENABLE ROW LEVEL SECURITY;

-- Allow public to insert trip requests (for form submissions)
CREATE POLICY "Anyone can submit trip requests" ON trip_requests
    FOR INSERT WITH CHECK (true);

-- Allow authenticated users to view their own requests (if we add user auth later)
CREATE POLICY "Users can view own trip requests" ON trip_requests
    FOR SELECT USING (contact_email = auth.jwt() ->> 'email');

-- Allow admin users to view and manage all trip requests
CREATE POLICY "Admins can manage all trip requests" ON trip_requests
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM user_profiles
            WHERE user_profiles.user_id = auth.uid()
            AND user_profiles.role IN ('admin', 'staff')
        )
    );

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_trip_requests_status ON trip_requests(status);
CREATE INDEX IF NOT EXISTS idx_trip_requests_preferred_date ON trip_requests(preferred_date);
CREATE INDEX IF NOT EXISTS idx_trip_requests_school_name ON trip_requests(school_name);
CREATE INDEX IF NOT EXISTS idx_trip_requests_submitted_at ON trip_requests(submitted_at);
CREATE INDEX IF NOT EXISTS idx_trip_requests_contact_email ON trip_requests(contact_email);

-- Create trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_trip_requests_updated_at
    BEFORE UPDATE ON trip_requests
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Add some helpful views for common queries

-- View for pending trip requests
CREATE OR REPLACE VIEW pending_trip_requests AS
SELECT
    tr.*,
    EXTRACT(DAYS FROM (tr.preferred_date - CURRENT_DATE)) AS days_until_visit,
    CASE
        WHEN tr.preferred_date < CURRENT_DATE THEN 'overdue'
        WHEN tr.preferred_date - CURRENT_DATE <= INTERVAL '7 days' THEN 'urgent'
        WHEN tr.preferred_date - CURRENT_DATE <= INTERVAL '30 days' THEN 'upcoming'
        ELSE 'future'
    END AS urgency_level
FROM trip_requests tr
WHERE tr.status = 'pending'
ORDER BY tr.preferred_date ASC;

-- View for trip requests with workshop details
CREATE OR REPLACE VIEW trip_requests_with_workshops AS
SELECT
    tr.*,
    COALESCE(
        json_agg(
            json_build_object(
                'id', a.id,
                'title', a.title,
                'duration_minutes', a.duration_minutes,
                'max_participants', a.max_participants,
                'activity_type', at.name
            )
        ) FILTER (WHERE a.id IS NOT NULL),
        '[]'::json
    ) AS workshop_details_full
FROM trip_requests tr
LEFT JOIN UNNEST(tr.selected_workshops) AS workshop_id ON true
LEFT JOIN activities a ON a.id = workshop_id::uuid
LEFT JOIN activity_types at ON at.id = a.activity_type_id
GROUP BY tr.id;

-- Sample data for testing (optional)
-- Uncomment the following if you want some test data

/*
INSERT INTO trip_requests (
    school_name,
    contact_name,
    contact_email,
    student_count,
    grade_level,
    preferred_date,
    visit_duration,
    primary_subjects,
    learning_goals,
    status
) VALUES
(
    'Barcelona International School',
    'Maria Garcia',
    'maria.garcia@bis.edu',
    25,
    'middle-6-8',
    CURRENT_DATE + INTERVAL '30 days',
    '6-hours',
    ARRAY['environmental-science', 'physics'],
    'Students should learn about renewable energy and water management systems.',
    'pending'
),
(
    'Zurich International School',
    'Hans Mueller',
    'h.mueller@zis.ch',
    18,
    'high-9-12',
    CURRENT_DATE + INTERVAL '45 days',
    '4-hours',
    ARRAY['engineering', 'technology'],
    'Focus on IoT applications in agriculture and data collection methods.',
    'pending'
);
*/

-- Grant necessary permissions
GRANT SELECT, INSERT ON trip_requests TO anon;
GRANT ALL ON trip_requests TO authenticated;
GRANT SELECT ON pending_trip_requests TO anon, authenticated;
GRANT SELECT ON trip_requests_with_workshops TO anon, authenticated;