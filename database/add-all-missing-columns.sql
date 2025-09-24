-- =====================================================
-- Add ALL Missing Columns to Visits Table
-- Run this in your Supabase SQL Editor
-- =====================================================

-- Add all missing columns that the form needs
ALTER TABLE visits ADD COLUMN IF NOT EXISTS potential_visit_dates TEXT;
ALTER TABLE visits ADD COLUMN IF NOT EXISTS preferred_language TEXT DEFAULT 'english';
ALTER TABLE visits ADD COLUMN IF NOT EXISTS visit_format TEXT;
ALTER TABLE visits ADD COLUMN IF NOT EXISTS visit_format_other TEXT;
ALTER TABLE visits ADD COLUMN IF NOT EXISTS educational_focus TEXT;
ALTER TABLE visits ADD COLUMN IF NOT EXISTS educational_focus_other TEXT;
ALTER TABLE visits ADD COLUMN IF NOT EXISTS selected_workshops TEXT[];
ALTER TABLE visits ADD COLUMN IF NOT EXISTS food_preferences TEXT[];
ALTER TABLE visits ADD COLUMN IF NOT EXISTS additional_comments TEXT;

-- Verify all columns were added
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'visits'
AND column_name IN (
    'potential_visit_dates',
    'preferred_language',
    'visit_format',
    'visit_format_other',
    'educational_focus',
    'educational_focus_other',
    'selected_workshops',
    'food_preferences',
    'additional_comments'
)
ORDER BY column_name;