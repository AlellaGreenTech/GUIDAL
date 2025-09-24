-- =====================================================
-- GUIDAL Visit Planning Schema Fix - SAFE VERSION
-- Professional, Scalable, Normalized Database Design
-- =====================================================

-- This script safely fixes the visit planning form database issues
-- It checks for existing columns and constraints before making changes

BEGIN;

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
    type TEXT DEFAULT 'other',
    student_count_range TEXT,
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add unique constraint for schools if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'schools_name_city_country_key') THEN
        ALTER TABLE schools ADD CONSTRAINT schools_name_city_country_key UNIQUE(name, city, country);
    END IF;
EXCEPTION
    WHEN duplicate_table THEN NULL;
END $$;

-- Create contacts table for all contact types
CREATE TABLE IF NOT EXISTS contacts (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    phone TEXT,
    position TEXT,
    type TEXT NOT NULL DEFAULT 'other',
    is_primary BOOLEAN DEFAULT false,
    school_id UUID,
    preferred_language TEXT,
    communication_preferences TEXT[],
    notes TEXT,
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add foreign key for contacts if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'contacts_school_id_fkey') THEN
        ALTER TABLE contacts ADD CONSTRAINT contacts_school_id_fkey
            FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE SET NULL;
    END IF;
EXCEPTION
    WHEN duplicate_table THEN NULL;
END $$;

-- =====================================================
-- PHASE 2: SAFELY ADD MISSING COLUMNS TO VISITS TABLE
-- =====================================================

-- Function to safely add columns
CREATE OR REPLACE FUNCTION safe_add_column(
    table_name TEXT,
    column_name TEXT,
    column_definition TEXT
) RETURNS VOID AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = safe_add_column.table_name
        AND column_name = safe_add_column.column_name
    ) THEN
        EXECUTE format('ALTER TABLE %I ADD COLUMN %I %s', table_name, column_name, column_definition);
        RAISE NOTICE 'Added column %.%', table_name, column_name;
    ELSE
        RAISE NOTICE 'Column %.% already exists, skipping', table_name, column_name;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Add missing columns to visits table
SELECT safe_add_column('visits', 'visit_type', 'TEXT DEFAULT ''school_day_trip''');
SELECT safe_add_column('visits', 'proposed_visit_date', 'DATE');
SELECT safe_add_column('visits', 'city', 'TEXT');
SELECT safe_add_column('visits', 'number_of_nights', 'INTEGER DEFAULT 0');
SELECT safe_add_column('visits', 'arrival_date_time', 'TIMESTAMP WITH TIME ZONE');
SELECT safe_add_column('visits', 'departure_date_time', 'TIMESTAMP WITH TIME ZONE');
SELECT safe_add_column('visits', 'accommodation_selection', 'TEXT');
SELECT safe_add_column('visits', 'accommodation_needs', 'TEXT');
SELECT safe_add_column('visits', 'organizer_contact_id', 'UUID');
SELECT safe_add_column('visits', 'lead_teacher_contact_id', 'UUID');
SELECT safe_add_column('visits', 'school_id', 'UUID');
SELECT safe_add_column('visits', 'source', 'TEXT DEFAULT ''website_form''');
SELECT safe_add_column('visits', 'priority_level', 'TEXT DEFAULT ''normal''');

-- =====================================================
-- PHASE 3: SAFELY ADD FOREIGN KEY CONSTRAINTS
-- =====================================================

-- Add foreign key constraints if they don't exist
DO $$
BEGIN
    -- Add organizer contact foreign key
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'visits_organizer_contact_id_fkey') THEN
        ALTER TABLE visits ADD CONSTRAINT visits_organizer_contact_id_fkey
            FOREIGN KEY (organizer_contact_id) REFERENCES contacts(id) ON DELETE SET NULL;
        RAISE NOTICE 'Added organizer contact foreign key';
    END IF;

    -- Add lead teacher contact foreign key
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'visits_lead_teacher_contact_id_fkey') THEN
        ALTER TABLE visits ADD CONSTRAINT visits_lead_teacher_contact_id_fkey
            FOREIGN KEY (lead_teacher_contact_id) REFERENCES contacts(id) ON DELETE SET NULL;
        RAISE NOTICE 'Added lead teacher contact foreign key';
    END IF;

    -- Add school foreign key
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'visits_school_id_fkey') THEN
        ALTER TABLE visits ADD CONSTRAINT visits_school_id_fkey
            FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE SET NULL;
        RAISE NOTICE 'Added school foreign key';
    END IF;
EXCEPTION
    WHEN undefined_table THEN
        RAISE NOTICE 'Tables not ready for foreign keys yet';
END $$;

-- =====================================================
-- PHASE 4: SAFELY ADD CHECK CONSTRAINTS
-- =====================================================

-- Add check constraints if they don't exist and columns exist
DO $$
BEGIN
    -- Check if visit_type column exists before adding constraint
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'visits' AND column_name = 'visit_type') THEN
        IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'valid_visit_type') THEN
            ALTER TABLE visits ADD CONSTRAINT valid_visit_type
                CHECK (visit_type IN ('school_day_trip', 'school_overnight', 'individual_workshops', 'event', 'special_lunch'));
            RAISE NOTICE 'Added visit_type constraint';
        END IF;
    END IF;

    -- Check if accommodation_selection column exists before adding constraint
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'visits' AND column_name = 'accommodation_selection') THEN
        IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'valid_accommodation') THEN
            ALTER TABLE visits ADD CONSTRAINT valid_accommodation
                CHECK (accommodation_selection IN ('fort_flappy', 'liberation_lodge', 'dirt_cheap_cabin', 'your_tent', 'no_preference') OR accommodation_selection IS NULL);
            RAISE NOTICE 'Added accommodation constraint';
        END IF;
    END IF;

    -- Check if priority_level column exists before adding constraint
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'visits' AND column_name = 'priority_level') THEN
        IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'valid_priority') THEN
            ALTER TABLE visits ADD CONSTRAINT valid_priority
                CHECK (priority_level IN ('low', 'normal', 'high', 'urgent'));
            RAISE NOTICE 'Added priority constraint';
        END IF;
    END IF;

    -- Check if number_of_nights column exists before adding constraint
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'visits' AND column_name = 'number_of_nights') THEN
        IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'valid_nights') THEN
            ALTER TABLE visits ADD CONSTRAINT valid_nights
                CHECK (number_of_nights >= 0);
            RAISE NOTICE 'Added nights constraint';
        END IF;
    END IF;

    -- Check if both visit_type and number_of_nights exist before adding business logic constraint
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'visits' AND column_name = 'visit_type')
       AND EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'visits' AND column_name = 'number_of_nights') THEN
        IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'valid_overnight_data') THEN
            ALTER TABLE visits ADD CONSTRAINT valid_overnight_data
                CHECK (
                    (visit_type != 'school_overnight') OR
                    (visit_type = 'school_overnight' AND number_of_nights > 0)
                );
            RAISE NOTICE 'Added overnight data constraint';
        END IF;
    END IF;

    -- Check if both arrival and departure columns exist before adding date range constraint
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'visits' AND column_name = 'arrival_date_time')
       AND EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'visits' AND column_name = 'departure_date_time') THEN
        IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'valid_date_range') THEN
            ALTER TABLE visits ADD CONSTRAINT valid_date_range
                CHECK (
                    (arrival_date_time IS NULL OR departure_date_time IS NULL) OR
                    (departure_date_time > arrival_date_time)
                );
            RAISE NOTICE 'Added date range constraint';
        END IF;
    END IF;
EXCEPTION
    WHEN undefined_table THEN
        RAISE NOTICE 'Visits table not ready for constraints yet';
END $$;

-- =====================================================
-- PHASE 5: ADD TABLE CONSTRAINTS FOR NEW TABLES
-- =====================================================

-- Add constraints for schools table
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'schools_type_check') THEN
        ALTER TABLE schools ADD CONSTRAINT schools_type_check
            CHECK (type IN ('public', 'private', 'international', 'charter', 'homeschool', 'university', 'other'));
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'schools_student_count_check') THEN
        ALTER TABLE schools ADD CONSTRAINT schools_student_count_check
            CHECK (student_count_range IN ('1-50', '51-200', '201-500', '501-1000', '1000+'));
    END IF;
EXCEPTION
    WHEN undefined_table THEN NULL;
END $$;

-- Add constraints for contacts table
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'contacts_type_check') THEN
        ALTER TABLE contacts ADD CONSTRAINT contacts_type_check
            CHECK (type IN ('organizer', 'lead_teacher', 'teacher', 'admin', 'parent', 'other'));
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'contacts_email_check') THEN
        ALTER TABLE contacts ADD CONSTRAINT contacts_email_check
            CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');
    END IF;
EXCEPTION
    WHEN undefined_table THEN NULL;
END $$;

-- =====================================================
-- PHASE 6: CREATE INDEXES FOR PERFORMANCE
-- =====================================================

-- Create indexes if they don't exist
DO $$
BEGIN
    -- Schools indexes
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_schools_name') THEN
        CREATE INDEX idx_schools_name ON schools(name);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_schools_city_country') THEN
        CREATE INDEX idx_schools_city_country ON schools(city, country);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_schools_active') THEN
        CREATE INDEX idx_schools_active ON schools(active);
    END IF;

    -- Contacts indexes
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_contacts_email') THEN
        CREATE INDEX idx_contacts_email ON contacts(email);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_contacts_school_id') THEN
        CREATE INDEX idx_contacts_school_id ON contacts(school_id);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_contacts_type') THEN
        CREATE INDEX idx_contacts_type ON contacts(type);
    END IF;

    -- Visits indexes (only if columns exist)
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'visits' AND column_name = 'visit_type') THEN
        IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_visits_visit_type') THEN
            CREATE INDEX idx_visits_visit_type ON visits(visit_type);
        END IF;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'visits' AND column_name = 'proposed_visit_date') THEN
        IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_visits_proposed_date') THEN
            CREATE INDEX idx_visits_proposed_date ON visits(proposed_visit_date);
        END IF;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'visits' AND column_name = 'school_id') THEN
        IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_visits_school_id') THEN
            CREATE INDEX idx_visits_school_id ON visits(school_id);
        END IF;
    END IF;
EXCEPTION
    WHEN undefined_table THEN NULL;
END $$;

-- =====================================================
-- PHASE 7: ROW LEVEL SECURITY
-- =====================================================

-- Enable RLS on new tables
ALTER TABLE schools ENABLE ROW LEVEL SECURITY;
ALTER TABLE contacts ENABLE ROW LEVEL SECURITY;

-- Create policies
DO $$
BEGIN
    -- Schools policies
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'anyone_can_view_active_schools') THEN
        CREATE POLICY anyone_can_view_active_schools ON schools
            FOR SELECT USING (active = true);
    END IF;

    -- Contacts policies
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'anyone_can_create_contacts') THEN
        CREATE POLICY anyone_can_create_contacts ON contacts
            FOR INSERT WITH CHECK (true);
    END IF;
EXCEPTION
    WHEN undefined_table THEN NULL;
END $$;

-- =====================================================
-- PHASE 8: UTILITY FUNCTIONS
-- =====================================================

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
-- PHASE 9: GRANT PERMISSIONS
-- =====================================================

-- Grant permissions
GRANT SELECT, INSERT ON schools TO anon, authenticated;
GRANT SELECT, INSERT ON contacts TO anon, authenticated;
GRANT ALL ON schools TO service_role;
GRANT ALL ON contacts TO service_role;
GRANT EXECUTE ON FUNCTION find_or_create_school TO anon, authenticated;
GRANT EXECUTE ON FUNCTION find_or_create_contact TO anon, authenticated;

-- Clean up the helper function
DROP FUNCTION IF EXISTS safe_add_column;

-- =====================================================
-- COMPLETION REPORT
-- =====================================================

DO $$
DECLARE
    schools_count INTEGER;
    contacts_count INTEGER;
    visits_columns INTEGER;
BEGIN
    SELECT COUNT(*) INTO schools_count FROM schools;
    SELECT COUNT(*) INTO contacts_count FROM contacts;
    SELECT COUNT(*) INTO visits_columns
    FROM information_schema.columns
    WHERE table_name = 'visits'
    AND column_name IN ('visit_type', 'proposed_visit_date', 'city', 'accommodation_selection');

    RAISE NOTICE '=================================================';
    RAISE NOTICE 'GUIDAL Visit Planning Schema Fix Complete';
    RAISE NOTICE '=================================================';
    RAISE NOTICE 'Schools table: % records', schools_count;
    RAISE NOTICE 'Contacts table: % records', contacts_count;
    RAISE NOTICE 'Visits table: % new columns added', visits_columns;
    RAISE NOTICE 'Schema upgrade successful!';
    RAISE NOTICE '=================================================';
END $$;

COMMIT;

-- Schema fix complete! Next steps:
-- 1. Run: database/create-visit-views.sql
-- 2. Run: database/migrate-existing-visit-data.sql (if you have existing data)
-- 3. Test the visit planning form