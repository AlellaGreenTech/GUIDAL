-- =====================================================
-- GUIDAL Visit Planning Schema Fix
-- Professional, Scalable, Normalized Database Design
-- =====================================================

-- This script fixes the visit planning form database issues:
-- 1. Normalizes contact information into separate table
-- 2. Properly utilizes schools table
-- 3. Adds all missing form fields
-- 4. Creates proper relationships and constraints
-- 5. Optimizes for performance and scalability

-- =====================================================
-- PHASE 1: CREATE NORMALIZED CONTACT SYSTEM
-- =====================================================

-- First, ensure schools table exists and is properly structured
CREATE TABLE IF NOT EXISTS schools (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    address TEXT,
    city TEXT,
    country TEXT,
    website TEXT,
    phone TEXT,
    email TEXT,
    type TEXT CHECK (type IN ('public', 'private', 'international', 'charter', 'homeschool', 'university', 'other')) DEFAULT 'other',
    student_count_range TEXT CHECK (student_count_range IN ('1-50', '51-200', '201-500', '501-1000', '1000+')),

    -- Metadata
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Ensure school names are unique per city/country combination
    UNIQUE(name, city, country)
);

-- Create contacts table for all contact types
CREATE TABLE IF NOT EXISTS contacts (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,

    -- Contact Information
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    phone TEXT,
    position TEXT, -- e.g., "Science Teacher", "Trip Organizer", "Principal"

    -- Contact Type and Classification
    type TEXT NOT NULL CHECK (type IN ('organizer', 'lead_teacher', 'teacher', 'admin', 'parent', 'other')),
    is_primary BOOLEAN DEFAULT false, -- Is this the primary contact for the school?

    -- Relationships
    school_id UUID REFERENCES schools(id) ON DELETE SET NULL,

    -- Additional Information
    preferred_language TEXT,
    communication_preferences TEXT[], -- e.g., ['email', 'phone', 'whatsapp']
    notes TEXT,

    -- Metadata
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Business Rules
    CONSTRAINT valid_email CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT unique_email_per_school UNIQUE(email, school_id)
);

-- =====================================================
-- PHASE 2: EXTEND VISITS TABLE WITH MISSING FIELDS
-- =====================================================

-- Add missing columns to visits table
ALTER TABLE visits ADD COLUMN IF NOT EXISTS visit_type TEXT
    CHECK (visit_type IN ('school_day_trip', 'school_overnight', 'individual_workshops', 'event', 'special_lunch'))
    DEFAULT 'school_day_trip';

ALTER TABLE visits ADD COLUMN IF NOT EXISTS proposed_visit_date DATE;
ALTER TABLE visits ADD COLUMN IF NOT EXISTS city TEXT;

-- Overnight-specific fields
ALTER TABLE visits ADD COLUMN IF NOT EXISTS number_of_nights INTEGER CHECK (number_of_nights >= 0) DEFAULT 0;
ALTER TABLE visits ADD COLUMN IF NOT EXISTS arrival_date_time TIMESTAMP WITH TIME ZONE;
ALTER TABLE visits ADD COLUMN IF NOT EXISTS departure_date_time TIMESTAMP WITH TIME ZONE;
ALTER TABLE visits ADD COLUMN IF NOT EXISTS accommodation_selection TEXT
    CHECK (accommodation_selection IN ('fort_flappy', 'liberation_lodge', 'dirt_cheap_cabin', 'your_tent', 'no_preference'));
ALTER TABLE visits ADD COLUMN IF NOT EXISTS accommodation_needs TEXT;

-- Contact relationship fields
ALTER TABLE visits ADD COLUMN IF NOT EXISTS organizer_contact_id UUID REFERENCES contacts(id) ON DELETE SET NULL;
ALTER TABLE visits ADD COLUMN IF NOT EXISTS lead_teacher_contact_id UUID REFERENCES contacts(id) ON DELETE SET NULL;
ALTER TABLE visits ADD COLUMN IF NOT EXISTS school_id UUID REFERENCES schools(id) ON DELETE SET NULL;

-- Enhanced metadata
ALTER TABLE visits ADD COLUMN IF NOT EXISTS source TEXT DEFAULT 'website_form'; -- Track where the visit request came from
ALTER TABLE visits ADD COLUMN IF NOT EXISTS priority_level TEXT CHECK (priority_level IN ('low', 'normal', 'high', 'urgent')) DEFAULT 'normal';

-- Business logic constraints (with safe execution)
DO $$
BEGIN
    -- Add overnight data validation constraint
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'valid_overnight_data') THEN
        ALTER TABLE visits ADD CONSTRAINT valid_overnight_data
            CHECK (
                (visit_type != 'school_overnight') OR
                (visit_type = 'school_overnight' AND number_of_nights > 0)
            );
    END IF;

    -- Add date range validation constraint
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'valid_date_range') THEN
        ALTER TABLE visits ADD CONSTRAINT valid_date_range
            CHECK (
                (arrival_date_time IS NULL OR departure_date_time IS NULL) OR
                (departure_date_time > arrival_date_time)
            );
    END IF;
END $$;

-- =====================================================
-- PHASE 3: PERFORMANCE OPTIMIZATION
-- =====================================================

-- Indexes for schools table
CREATE INDEX IF NOT EXISTS idx_schools_name ON schools(name);
CREATE INDEX IF NOT EXISTS idx_schools_city_country ON schools(city, country);
CREATE INDEX IF NOT EXISTS idx_schools_active ON schools(active);

-- Indexes for contacts table
CREATE INDEX IF NOT EXISTS idx_contacts_email ON contacts(email);
CREATE INDEX IF NOT EXISTS idx_contacts_school_id ON contacts(school_id);
CREATE INDEX IF NOT EXISTS idx_contacts_type ON contacts(type);
CREATE INDEX IF NOT EXISTS idx_contacts_active ON contacts(active);
CREATE INDEX IF NOT EXISTS idx_contacts_primary ON contacts(school_id, is_primary) WHERE is_primary = true;

-- Additional indexes for visits table
CREATE INDEX IF NOT EXISTS idx_visits_visit_type ON visits(visit_type);
CREATE INDEX IF NOT EXISTS idx_visits_proposed_date ON visits(proposed_visit_date);
CREATE INDEX IF NOT EXISTS idx_visits_city ON visits(city);
CREATE INDEX IF NOT EXISTS idx_visits_school_id ON visits(school_id);
CREATE INDEX IF NOT EXISTS idx_visits_organizer_contact ON visits(organizer_contact_id);
CREATE INDEX IF NOT EXISTS idx_visits_teacher_contact ON visits(lead_teacher_contact_id);
CREATE INDEX IF NOT EXISTS idx_visits_accommodation ON visits(accommodation_selection);
CREATE INDEX IF NOT EXISTS idx_visits_priority ON visits(priority_level);

-- Composite indexes for common queries
CREATE INDEX IF NOT EXISTS idx_visits_status_date ON visits(status, proposed_visit_date);
CREATE INDEX IF NOT EXISTS idx_visits_type_status ON visits(visit_type, status);

-- =====================================================
-- PHASE 4: ROW LEVEL SECURITY POLICIES
-- =====================================================

-- Enable RLS on new tables
ALTER TABLE schools ENABLE ROW LEVEL SECURITY;
ALTER TABLE contacts ENABLE ROW LEVEL SECURITY;

-- Schools policies
CREATE POLICY "Anyone can view active schools" ON schools
    FOR SELECT USING (active = true);

CREATE POLICY "Admins can manage schools" ON schools
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.user_type IN ('admin', 'staff')
        )
    );

-- Contacts policies
CREATE POLICY "Contacts can view own records" ON contacts
    FOR SELECT USING (
        email = auth.jwt() ->> 'email' OR
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.user_type IN ('admin', 'staff')
        )
    );

CREATE POLICY "Anyone can create contacts" ON contacts
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Admins can manage contacts" ON contacts
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.user_type IN ('admin', 'staff')
        )
    );

-- =====================================================
-- PHASE 5: UTILITY FUNCTIONS
-- =====================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply updated_at triggers
CREATE TRIGGER update_schools_updated_at
    BEFORE UPDATE ON schools
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_contacts_updated_at
    BEFORE UPDATE ON contacts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Function to find or create school
CREATE OR REPLACE FUNCTION find_or_create_school(
    school_name TEXT,
    school_city TEXT DEFAULT NULL,
    school_country TEXT DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
    school_id UUID;
BEGIN
    -- Try to find existing school
    SELECT id INTO school_id
    FROM schools
    WHERE name ILIKE school_name
    AND (school_city IS NULL OR city ILIKE school_city)
    AND (school_country IS NULL OR country ILIKE school_country)
    LIMIT 1;

    -- If not found, create new school
    IF school_id IS NULL THEN
        INSERT INTO schools (name, city, country)
        VALUES (school_name, school_city, school_country)
        RETURNING id INTO school_id;
    END IF;

    RETURN school_id;
END;
$$ LANGUAGE plpgsql;

-- Function to find or create contact
CREATE OR REPLACE FUNCTION find_or_create_contact(
    contact_name TEXT,
    contact_email TEXT,
    contact_phone TEXT DEFAULT NULL,
    contact_position TEXT DEFAULT NULL,
    contact_type TEXT DEFAULT 'teacher',
    contact_school_id UUID DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
    contact_id UUID;
BEGIN
    -- Try to find existing contact
    SELECT id INTO contact_id
    FROM contacts
    WHERE email = contact_email
    AND (contact_school_id IS NULL OR school_id = contact_school_id)
    LIMIT 1;

    -- If not found, create new contact
    IF contact_id IS NULL THEN
        INSERT INTO contacts (name, email, phone, position, type, school_id)
        VALUES (contact_name, contact_email, contact_phone, contact_position, contact_type, contact_school_id)
        RETURNING id INTO contact_id;
    ELSE
        -- Update existing contact with any new information
        UPDATE contacts
        SET
            name = COALESCE(contact_name, name),
            phone = COALESCE(contact_phone, phone),
            position = COALESCE(contact_position, position),
            updated_at = NOW()
        WHERE id = contact_id;
    END IF;

    RETURN contact_id;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- PHASE 6: GRANT PERMISSIONS
-- =====================================================

-- Grant permissions for public access
GRANT SELECT, INSERT ON schools TO anon, authenticated;
GRANT SELECT, INSERT ON contacts TO anon, authenticated;
GRANT ALL ON schools TO service_role;
GRANT ALL ON contacts TO service_role;

-- Grant access to utility functions
GRANT EXECUTE ON FUNCTION find_or_create_school TO anon, authenticated;
GRANT EXECUTE ON FUNCTION find_or_create_contact TO anon, authenticated;

-- =====================================================
-- SCHEMA FIX COMPLETE
-- =====================================================

-- Summary of changes:
-- ✅ Created normalized schools table
-- ✅ Created normalized contacts table with proper relationships
-- ✅ Added all missing fields to visits table
-- ✅ Created proper foreign key relationships
-- ✅ Added business logic constraints
-- ✅ Created performance indexes
-- ✅ Set up Row Level Security
-- ✅ Created utility functions for data management
-- ✅ Granted appropriate permissions

-- Next step: Update JavaScript code to use new schema