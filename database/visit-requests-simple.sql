-- Visit Requests Table (Simplified - No user_profiles dependency)
-- Stores educational visit planning requests from schools

CREATE TABLE IF NOT EXISTS visit_requests (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,

    -- Contact Information
    contact_email TEXT NOT NULL,
    lead_teacher_contact TEXT NOT NULL,
    school_name TEXT NOT NULL,
    country_of_origin TEXT NOT NULL,

    -- Visit Planning
    potential_visit_dates TEXT,
    preferred_language TEXT,
    number_of_students INTEGER NOT NULL CHECK (number_of_students > 0),
    number_of_adults INTEGER,

    -- Visit Format
    visit_format TEXT CHECK (visit_format IN (
        'full_day_pizza_lunch',
        'morning_no_lunch',
        'morning_with_lunch',
        'other'
    )),
    visit_format_other TEXT,

    -- Educational Focus
    educational_focus TEXT CHECK (educational_focus IN (
        'seeing_real_world_science',
        'hands_on_permaculture',
        'balanced_mix',
        'other'
    )),
    educational_focus_other TEXT,

    -- Selected Workshops/Stations
    selected_workshops UUID[] DEFAULT '{}',

    -- Food Preferences/Requirements
    food_preferences TEXT,

    -- Additional Comments
    additional_comments TEXT,

    -- Status and Metadata
    status TEXT DEFAULT 'pending' CHECK (status IN (
        'pending', 'reviewing', 'approved', 'scheduled', 'completed', 'cancelled'
    )),
    submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add RLS (Row Level Security) policies
ALTER TABLE visit_requests ENABLE ROW LEVEL SECURITY;

-- Allow public to insert visit requests (for form submissions)
CREATE POLICY "Anyone can submit visit requests" ON visit_requests
    FOR INSERT WITH CHECK (true);

-- Allow users to view their own requests by email
CREATE POLICY "Users can view own visit requests" ON visit_requests
    FOR SELECT USING (contact_email = auth.jwt() ->> 'email');

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_visit_requests_status ON visit_requests(status);
CREATE INDEX IF NOT EXISTS idx_visit_requests_submitted_at ON visit_requests(submitted_at);
CREATE INDEX IF NOT EXISTS idx_visit_requests_school_name ON visit_requests(school_name);
CREATE INDEX IF NOT EXISTS idx_visit_requests_contact_email ON visit_requests(contact_email);

-- Grant necessary permissions
GRANT SELECT, INSERT ON visit_requests TO anon;
GRANT ALL ON visit_requests TO authenticated;
