-- =====================================================
-- GUIDAL Minimal Schema Update
-- Only adds missing fields needed for the form
-- =====================================================

-- Based on the database analysis, this script only adds
-- the specific missing fields needed for the enhanced form

BEGIN;

-- Check what's missing and add only what we need
DO $$
BEGIN
    -- Add proposed_visit_date if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'visits' AND column_name = 'proposed_visit_date'
    ) THEN
        ALTER TABLE visits ADD COLUMN proposed_visit_date DATE;
        RAISE NOTICE 'Added proposed_visit_date column';
    ELSE
        RAISE NOTICE 'proposed_visit_date already exists';
    END IF;

    -- Add city if missing (separate from country_of_origin)
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'visits' AND column_name = 'city'
    ) THEN
        ALTER TABLE visits ADD COLUMN city TEXT;
        RAISE NOTICE 'Added city column';
    ELSE
        RAISE NOTICE 'city already exists';
    END IF;

    -- Add accommodation_selection if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'visits' AND column_name = 'accommodation_selection'
    ) THEN
        ALTER TABLE visits ADD COLUMN accommodation_selection TEXT;
        RAISE NOTICE 'Added accommodation_selection column';
    ELSE
        RAISE NOTICE 'accommodation_selection already exists';
    END IF;

    -- Add accommodation_needs if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'visits' AND column_name = 'accommodation_needs'
    ) THEN
        ALTER TABLE visits ADD COLUMN accommodation_needs TEXT;
        RAISE NOTICE 'Added accommodation_needs column';
    ELSE
        RAISE NOTICE 'accommodation_needs already exists';
    END IF;

    -- Add organizer contact fields if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'visits' AND column_name = 'organizer_name'
    ) THEN
        ALTER TABLE visits ADD COLUMN organizer_name TEXT;
        RAISE NOTICE 'Added organizer_name column';
    ELSE
        RAISE NOTICE 'organizer_name already exists';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'visits' AND column_name = 'organizer_email'
    ) THEN
        ALTER TABLE visits ADD COLUMN organizer_email TEXT;
        RAISE NOTICE 'Added organizer_email column';
    ELSE
        RAISE NOTICE 'organizer_email already exists';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'visits' AND column_name = 'organizer_phone'
    ) THEN
        ALTER TABLE visits ADD COLUMN organizer_phone TEXT;
        RAISE NOTICE 'Added organizer_phone column';
    ELSE
        RAISE NOTICE 'organizer_phone already exists';
    END IF;

    -- Add lead teacher phone if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'visits' AND column_name = 'lead_teacher_phone'
    ) THEN
        ALTER TABLE visits ADD COLUMN lead_teacher_phone TEXT;
        RAISE NOTICE 'Added lead_teacher_phone column';
    ELSE
        RAISE NOTICE 'lead_teacher_phone already exists';
    END IF;

    -- Add visit planning fields if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'visits' AND column_name = 'potential_visit_dates'
    ) THEN
        ALTER TABLE visits ADD COLUMN potential_visit_dates TEXT;
        RAISE NOTICE 'Added potential_visit_dates column';
    ELSE
        RAISE NOTICE 'potential_visit_dates already exists';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'visits' AND column_name = 'preferred_language'
    ) THEN
        ALTER TABLE visits ADD COLUMN preferred_language TEXT DEFAULT 'english';
        RAISE NOTICE 'Added preferred_language column';
    ELSE
        RAISE NOTICE 'preferred_language already exists';
    END IF;

    -- Add visit format and educational focus fields if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'visits' AND column_name = 'visit_format'
    ) THEN
        ALTER TABLE visits ADD COLUMN visit_format TEXT;
        RAISE NOTICE 'Added visit_format column';
    ELSE
        RAISE NOTICE 'visit_format already exists';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'visits' AND column_name = 'visit_format_other'
    ) THEN
        ALTER TABLE visits ADD COLUMN visit_format_other TEXT;
        RAISE NOTICE 'Added visit_format_other column';
    ELSE
        RAISE NOTICE 'visit_format_other already exists';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'visits' AND column_name = 'educational_focus'
    ) THEN
        ALTER TABLE visits ADD COLUMN educational_focus TEXT;
        RAISE NOTICE 'Added educational_focus column';
    ELSE
        RAISE NOTICE 'educational_focus already exists';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'visits' AND column_name = 'educational_focus_other'
    ) THEN
        ALTER TABLE visits ADD COLUMN educational_focus_other TEXT;
        RAISE NOTICE 'Added educational_focus_other column';
    ELSE
        RAISE NOTICE 'educational_focus_other already exists';
    END IF;

    -- Add workshop and food preference fields if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'visits' AND column_name = 'selected_workshops'
    ) THEN
        ALTER TABLE visits ADD COLUMN selected_workshops TEXT[];
        RAISE NOTICE 'Added selected_workshops column';
    ELSE
        RAISE NOTICE 'selected_workshops already exists';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'visits' AND column_name = 'food_preferences'
    ) THEN
        ALTER TABLE visits ADD COLUMN food_preferences TEXT[];
        RAISE NOTICE 'Added food_preferences column';
    ELSE
        RAISE NOTICE 'food_preferences already exists';
    END IF;

    -- Add overnight specific fields if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'visits' AND column_name = 'number_of_nights'
    ) THEN
        ALTER TABLE visits ADD COLUMN number_of_nights INTEGER DEFAULT 0;
        RAISE NOTICE 'Added number_of_nights column';
    ELSE
        RAISE NOTICE 'number_of_nights already exists';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'visits' AND column_name = 'arrival_date_time'
    ) THEN
        ALTER TABLE visits ADD COLUMN arrival_date_time TIMESTAMP WITH TIME ZONE;
        RAISE NOTICE 'Added arrival_date_time column';
    ELSE
        RAISE NOTICE 'arrival_date_time already exists';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'visits' AND column_name = 'departure_date_time'
    ) THEN
        ALTER TABLE visits ADD COLUMN departure_date_time TIMESTAMP WITH TIME ZONE;
        RAISE NOTICE 'Added departure_date_time column';
    ELSE
        RAISE NOTICE 'departure_date_time already exists';
    END IF;

END $$;

-- Create find_or_create_school function (simple version for compatibility)
CREATE OR REPLACE FUNCTION find_or_create_school(
    school_name TEXT,
    school_city TEXT DEFAULT NULL,
    school_country TEXT DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
    school_id UUID;
BEGIN
    -- For now, just generate a UUID since we're keeping it simple
    -- This can be enhanced later when we implement full normalization
    RETURN gen_random_uuid();
END;
$$ LANGUAGE plpgsql;

-- Create find_or_create_contact function (simple version for compatibility)
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
    -- For now, just generate a UUID since we're keeping it simple
    -- This can be enhanced later when we implement full normalization
    RETURN gen_random_uuid();
END;
$$ LANGUAGE plpgsql;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION find_or_create_school TO anon, authenticated;
GRANT EXECUTE ON FUNCTION find_or_create_contact TO anon, authenticated;

-- Summary
DO $$
BEGIN
    RAISE NOTICE '=================================================';
    RAISE NOTICE 'GUIDAL Minimal Schema Update Complete';
    RAISE NOTICE '=================================================';
    RAISE NOTICE 'Added missing columns needed for enhanced form';
    RAISE NOTICE 'Created compatibility functions for form submission';
    RAISE NOTICE 'Your form should now work with all fields!';
    RAISE NOTICE '=================================================';
END $$;

COMMIT;

-- Next step: Test the visit planning form!