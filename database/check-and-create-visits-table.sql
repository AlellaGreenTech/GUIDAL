-- Check existing tables and create visits table if needed

-- First, let's see what tables exist
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_type = 'BASE TABLE'
AND table_name LIKE '%visit%'
ORDER BY table_name;

-- Create visits table if it doesn't exist
CREATE TABLE IF NOT EXISTS visits (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,

    -- Basic info
    status TEXT DEFAULT 'pending',
    visit_type TEXT DEFAULT 'school_day_trip',
    proposed_visit_date DATE,

    -- School information
    school_name TEXT,
    school_id UUID,
    city TEXT,
    country TEXT DEFAULT 'Spain',

    -- Contact information
    organizer_name TEXT,
    organizer_email TEXT,
    organizer_phone TEXT,
    organizer_contact_id UUID,

    lead_teacher_name TEXT,
    lead_teacher_email TEXT,
    lead_teacher_phone TEXT,
    lead_teacher_contact_id UUID,

    -- Visit details
    number_of_students INTEGER,
    student_age_range TEXT,
    number_of_adults INTEGER,
    special_needs TEXT,
    dietary_requirements TEXT,

    -- Overnight visit details
    number_of_nights INTEGER DEFAULT 0,
    arrival_date_time TIMESTAMP WITH TIME ZONE,
    departure_date_time TIMESTAMP WITH TIME ZONE,
    accommodation_selection TEXT,
    accommodation_needs TEXT,

    -- Additional info
    visit_goals TEXT,
    previous_visits BOOLEAN DEFAULT false,
    how_heard_about_us TEXT,
    additional_info TEXT,
    schedule_preferences TEXT,

    -- Metadata
    source TEXT DEFAULT 'website_form',
    priority_level TEXT DEFAULT 'normal',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE visits ENABLE ROW LEVEL SECURITY;

-- Create simple policies to allow anonymous inserts
DROP POLICY IF EXISTS "allow_anonymous_visit_insert" ON visits;
CREATE POLICY "allow_anonymous_visit_insert" ON visits
    FOR INSERT
    TO anon, authenticated
    WITH CHECK (true);

DROP POLICY IF EXISTS "allow_view_own_visits" ON visits;
CREATE POLICY "allow_view_own_visits" ON visits
    FOR SELECT
    TO authenticated
    USING (user_id = auth.uid() OR auth.uid() IS NOT NULL);

-- Grant permissions
GRANT INSERT, SELECT ON visits TO anon, authenticated;
GRANT ALL ON visits TO service_role;

-- Grant sequence usage
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;

-- Verify the setup
SELECT
    'Table exists: ' || EXISTS(SELECT 1 FROM information_schema.tables WHERE table_name = 'visits')::TEXT as visits_table,
    'Policies count: ' || COUNT(*)::TEXT as policy_count
FROM pg_policies
WHERE tablename = 'visits';
