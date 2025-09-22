-- Simple Trip Requests Table Creation
-- Execute this in Supabase SQL Editor

-- Create the trip_requests table
CREATE TABLE IF NOT EXISTS trip_requests (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,

    -- Entity/School Information
    school_name TEXT NOT NULL,
    contact_name TEXT NOT NULL,
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
    scheduled_activity_id UUID,

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

-- Insert sample data with various statuses
INSERT INTO trip_requests (
    school_name,
    contact_name,
    contact_email,
    student_count,
    grade_level,
    preferred_date,
    visit_duration,
    status
) VALUES
-- Pending visits
(
    'Barcelona International School',
    'Maria Garcia',
    'maria.garcia@bis.edu',
    25,
    'Grade 6-8',
    CURRENT_DATE + INTERVAL '30 days',
    '6 hours',
    'pending'
),
(
    'International School of Catalunya',
    'David Smith',
    'david.smith@isc.es',
    18,
    'Grade 9-12',
    CURRENT_DATE + INTERVAL '45 days',
    '4 hours',
    'pending'
),
-- Completed visits
(
    'American School of Barcelona',
    'Jennifer Rodriguez',
    'j.rodriguez@asb.es',
    22,
    'Grade 4-5',
    CURRENT_DATE - INTERVAL '10 days',
    '3 hours',
    'completed'
),
(
    'Individual Visitor',
    'John Smith',
    'john.smith@gmail.com',
    1,
    'Adult',
    CURRENT_DATE - INTERVAL '15 days',
    '2 hours',
    'completed'
),
(
    'Green Tech Company',
    'Sarah Johnson',
    'sarah@greentech.com',
    12,
    'Corporate Group',
    CURRENT_DATE - INTERVAL '5 days',
    '4 hours',
    'completed'
),
-- Approved/Scheduled visits
(
    'Zurich International School',
    'Hans Mueller',
    'h.mueller@zis.ch',
    20,
    'Grade 7-9',
    CURRENT_DATE + INTERVAL '15 days',
    '5 hours',
    'approved'
),
(
    'Benjamin Franklin International School',
    'Robert Wilson',
    'r.wilson@bfis.cat',
    30,
    'Grade 10-12',
    CURRENT_DATE + INTERVAL '20 days',
    '6 hours',
    'scheduled'
);

-- Grant necessary permissions
GRANT SELECT, INSERT, UPDATE ON trip_requests TO anon;
GRANT ALL ON trip_requests TO authenticated;