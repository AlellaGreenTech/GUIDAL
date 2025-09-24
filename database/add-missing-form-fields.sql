-- =====================================================
-- GUIDAL Add Missing Form Fields
-- Adds only the missing fields needed by the form
-- =====================================================

BEGIN;

-- Add missing fields that the JavaScript is trying to use
DO $$
BEGIN
    -- Add visit_format if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'visits' AND column_name = 'visit_format'
    ) THEN
        ALTER TABLE visits ADD COLUMN visit_format TEXT;
        RAISE NOTICE 'Added visit_format column';
    ELSE
        RAISE NOTICE 'visit_format already exists';
    END IF;

    -- Add visit_format_other if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'visits' AND column_name = 'visit_format_other'
    ) THEN
        ALTER TABLE visits ADD COLUMN visit_format_other TEXT;
        RAISE NOTICE 'Added visit_format_other column';
    ELSE
        RAISE NOTICE 'visit_format_other already exists';
    END IF;

    -- Add educational_focus if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'visits' AND column_name = 'educational_focus'
    ) THEN
        ALTER TABLE visits ADD COLUMN educational_focus TEXT;
        RAISE NOTICE 'Added educational_focus column';
    ELSE
        RAISE NOTICE 'educational_focus already exists';
    END IF;

    -- Add educational_focus_other if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'visits' AND column_name = 'educational_focus_other'
    ) THEN
        ALTER TABLE visits ADD COLUMN educational_focus_other TEXT;
        RAISE NOTICE 'Added educational_focus_other column';
    ELSE
        RAISE NOTICE 'educational_focus_other already exists';
    END IF;

    -- Add preferred_language if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'visits' AND column_name = 'preferred_language'
    ) THEN
        ALTER TABLE visits ADD COLUMN preferred_language TEXT DEFAULT 'english';
        RAISE NOTICE 'Added preferred_language column';
    ELSE
        RAISE NOTICE 'preferred_language already exists';
    END IF;

END $$;

-- Summary
DO $$
BEGIN
    RAISE NOTICE '================================================';
    RAISE NOTICE 'Missing Form Fields Added Successfully';
    RAISE NOTICE '================================================';
    RAISE NOTICE 'Your visit planning form should now work!';
    RAISE NOTICE '================================================';
END $$;

COMMIT;