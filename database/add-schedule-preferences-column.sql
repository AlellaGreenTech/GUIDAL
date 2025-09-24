-- Add schedule_preferences column to visits table for overnight stays
-- This will store free-text scheduling preferences for overnight visits

ALTER TABLE visits
ADD COLUMN IF NOT EXISTS schedule_preferences TEXT;

-- Add comment to the column for clarity
COMMENT ON COLUMN visits.schedule_preferences IS 'Free-text field for overnight visitors to describe how they would like to structure their time at the farm';

-- Update any existing overnight visits with a default comment if needed
-- (This is optional and can be uncommented if you want to add a default for existing records)
-- UPDATE visits
-- SET schedule_preferences = 'No specific scheduling preferences provided'
-- WHERE visit_type = 'school_overnight'
-- AND schedule_preferences IS NULL;