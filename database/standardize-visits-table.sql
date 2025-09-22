-- Standardize on 'visits' terminology and add missing fields
-- This renames trip_requests to visits and adds Type of Visit field

-- Step 1: Add missing columns to existing trip_requests table
ALTER TABLE trip_requests ADD COLUMN IF NOT EXISTS visit_type TEXT;
ALTER TABLE trip_requests ADD COLUMN IF NOT EXISTS visit_format TEXT;
ALTER TABLE trip_requests ADD COLUMN IF NOT EXISTS educational_focus TEXT;

-- Step 2: Create the properly named 'visits' table
CREATE TABLE IF NOT EXISTS visits (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,

    -- Entity/School Information
    school_name TEXT NOT NULL,
    contact_name TEXT NOT NULL,
    contact_email TEXT NOT NULL,
    contact_phone TEXT,
    school_location TEXT,
    country_of_origin TEXT,

    -- Visit Classification
    visit_type TEXT DEFAULT 'school-visit' CHECK (visit_type IN (
        'school-visit',
        'corporate-visit',
        'family-visit',
        'individual-visit',
        'homeschool-visit',
        'university-visit',
        'other'
    )),
    visit_format TEXT CHECK (visit_format IN (
        'full-day-with-lunch',
        'morning-with-lunch',
        'morning-no-lunch',
        'afternoon-session',
        'custom'
    )),
    educational_focus TEXT CHECK (educational_focus IN (
        'hands-on-permaculture',
        'real-world-science',
        'balanced-mix',
        'iot-automation',
        'sustainability',
        'other'
    )),

    -- Group Details
    student_count INTEGER NOT NULL CHECK (student_count > 0),
    teacher_count INTEGER DEFAULT 2,
    adult_count INTEGER DEFAULT 0,
    grade_level TEXT NOT NULL,
    age_range TEXT,
    special_needs TEXT,

    -- Visit Preferences
    preferred_date DATE NOT NULL,
    alternate_date DATE,
    visit_duration TEXT NOT NULL,
    arrival_time TIME,
    lunch_needs TEXT DEFAULT 'none' CHECK (lunch_needs IN ('none', 'pizza', 'bbq', 'own_lunch', 'required')),

    -- Learning Objectives
    primary_subjects TEXT[] DEFAULT '{}',
    learning_goals TEXT,
    topics_of_interest TEXT,

    -- Workshop Selection
    selected_workshops UUID[] DEFAULT '{}',
    workshop_details JSONB DEFAULT '[]',

    -- Transportation
    transportation TEXT,
    parking_needs TEXT,

    -- Additional Information
    previous_visit BOOLEAN DEFAULT FALSE,
    additional_requests TEXT,
    special_dietary_requirements TEXT,

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
    estimated_cost NUMERIC(10,2),

    -- Invoice tracking
    invoice_id UUID,
    invoice_status TEXT DEFAULT 'not-invoiced' CHECK (invoice_status IN ('not-invoiced', 'invoiced', 'paid'))
);

-- Step 3: Copy all data from trip_requests to visits table
INSERT INTO visits (
    id, school_name, contact_name, contact_email, contact_phone, school_location,
    student_count, teacher_count, grade_level, preferred_date, visit_duration,
    lunch_needs, primary_subjects, learning_goals, selected_workshops, workshop_details,
    transportation, additional_requests, previous_visit, status, submitted_at,
    created_at, updated_at, scheduled_activity_id, internal_notes,
    response_sent_at, confirmed_date, confirmed_duration, estimated_cost,
    -- Set visit_type based on school name patterns
    visit_type,
    -- Set visit_format based on lunch_needs and duration
    visit_format,
    -- Set educational_focus based on learning goals
    educational_focus
)
SELECT
    id, school_name, contact_name, contact_email, contact_phone, school_location,
    student_count, teacher_count, grade_level, preferred_date, visit_duration,
    lunch_needs, primary_subjects, learning_goals, selected_workshops, workshop_details,
    transportation, additional_requests, previous_visit, status, submitted_at,
    created_at, updated_at, scheduled_activity_id, internal_notes,
    response_sent_at, confirmed_date, confirmed_duration, estimated_cost,
    -- Determine visit_type from school name
    CASE
        WHEN school_name ILIKE '%homeschool%' THEN 'homeschool-visit'
        WHEN school_name ILIKE '%university%' OR school_name ILIKE '%college%' THEN 'university-visit'
        WHEN school_name ILIKE '%individual%' OR school_name ILIKE '%person%' THEN 'individual-visit'
        WHEN school_name ILIKE '%company%' OR school_name ILIKE '%corp%' THEN 'corporate-visit'
        WHEN school_name ILIKE '%school%' OR school_name ILIKE '%international%' THEN 'school-visit'
        ELSE 'school-visit'
    END as visit_type,
    -- Determine visit_format from lunch_needs and duration
    CASE
        WHEN lunch_needs = 'none' AND visit_duration ILIKE '%morning%' THEN 'morning-no-lunch'
        WHEN lunch_needs IN ('pizza', 'bbq', 'required') AND visit_duration ILIKE '%morning%' THEN 'morning-with-lunch'
        WHEN lunch_needs IN ('pizza', 'bbq', 'required') AND visit_duration ILIKE '%full%' THEN 'full-day-with-lunch'
        WHEN visit_duration ILIKE '%afternoon%' THEN 'afternoon-session'
        ELSE 'full-day-with-lunch'
    END as visit_format,
    -- Determine educational_focus from learning goals
    CASE
        WHEN learning_goals ILIKE '%hands%on%permaculture%' THEN 'hands-on-permaculture'
        WHEN learning_goals ILIKE '%real%world%science%' THEN 'real-world-science'
        WHEN learning_goals ILIKE '%iot%' OR learning_goals ILIKE '%automation%' THEN 'iot-automation'
        WHEN learning_goals ILIKE '%sustainability%' THEN 'sustainability'
        WHEN learning_goals ILIKE '%balanced%mix%' THEN 'balanced-mix'
        ELSE 'balanced-mix'
    END as educational_focus
FROM trip_requests
ON CONFLICT (id) DO NOTHING;

-- Step 4: Add RLS policies to visits table
ALTER TABLE visits ENABLE ROW LEVEL SECURITY;

-- Allow public to insert visits (for form submissions)
CREATE POLICY "Anyone can submit visits" ON visits
    FOR INSERT WITH CHECK (true);

-- Allow authenticated users to view their own visits
CREATE POLICY "Users can view own visits" ON visits
    FOR SELECT USING (contact_email = auth.jwt() ->> 'email');

-- Allow admin users to view and manage all visits
CREATE POLICY "Admins can manage all visits" ON visits
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM user_profiles
            WHERE user_profiles.user_id = auth.uid()
            AND user_profiles.role IN ('admin', 'staff')
        )
    );

-- Step 5: Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_visits_status ON visits(status);
CREATE INDEX IF NOT EXISTS idx_visits_preferred_date ON visits(preferred_date);
CREATE INDEX IF NOT EXISTS idx_visits_school_name ON visits(school_name);
CREATE INDEX IF NOT EXISTS idx_visits_submitted_at ON visits(submitted_at);
CREATE INDEX IF NOT EXISTS idx_visits_contact_email ON visits(contact_email);
CREATE INDEX IF NOT EXISTS idx_visits_visit_type ON visits(visit_type);
CREATE INDEX IF NOT EXISTS idx_visits_visit_format ON visits(visit_format);
CREATE INDEX IF NOT EXISTS idx_visits_invoice_status ON visits(invoice_status);

-- Step 6: Create trigger to update updated_at timestamp
CREATE TRIGGER update_visits_updated_at
    BEFORE UPDATE ON visits
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Step 7: Grant permissions
GRANT SELECT, INSERT, UPDATE ON visits TO anon;
GRANT ALL ON visits TO authenticated;

-- Step 8: Update pricing management table reference
-- (This will be done in the application code)

-- Show summary
SELECT 'Visits table standardization completed!' as info;

SELECT
    'Visit Types Summary' as category,
    visit_type,
    COUNT(*) as count
FROM visits
GROUP BY visit_type
UNION ALL
SELECT
    'Visit Formats Summary' as category,
    visit_format,
    COUNT(*) as count
FROM visits
GROUP BY visit_format
UNION ALL
SELECT
    'Status Summary' as category,
    status,
    COUNT(*) as count
FROM visits
GROUP BY status;

-- Note: After running this, update all application code to use 'visits' table instead of 'trip_requests'