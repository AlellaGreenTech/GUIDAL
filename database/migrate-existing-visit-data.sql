-- =====================================================
-- GUIDAL Visit Data Migration Script
-- Migrate existing visit data to normalized schema
-- =====================================================

-- This script safely migrates existing visit data to use the new normalized schema
-- It extracts contact and school information from existing visits and creates
-- proper relationships while preserving all existing data

BEGIN;

-- =====================================================
-- PHASE 1: EXTRACT AND CREATE SCHOOL RECORDS
-- =====================================================

-- Create schools from existing visit data
INSERT INTO schools (name, city, country, created_at)
SELECT DISTINCT
    TRIM(v.school_name) as name,
    TRIM(v.city) as city,
    TRIM(v.country_of_origin) as country,
    MIN(v.created_at) as created_at
FROM visits v
WHERE v.school_name IS NOT NULL
    AND TRIM(v.school_name) != ''
    AND NOT EXISTS (
        SELECT 1 FROM schools s
        WHERE LOWER(TRIM(s.name)) = LOWER(TRIM(v.school_name))
        AND (
            s.city IS NULL OR v.city IS NULL OR
            LOWER(TRIM(s.city)) = LOWER(TRIM(v.city))
        )
        AND (
            s.country IS NULL OR v.country_of_origin IS NULL OR
            LOWER(TRIM(s.country)) = LOWER(TRIM(v.country_of_origin))
        )
    )
GROUP BY TRIM(v.school_name), TRIM(v.city), TRIM(v.country_of_origin);

-- =====================================================
-- PHASE 2: EXTRACT AND CREATE CONTACT RECORDS
-- =====================================================

-- Create lead teacher contacts from existing visit data
INSERT INTO contacts (name, email, phone, position, type, school_id, created_at)
SELECT DISTINCT
    COALESCE(TRIM(v.lead_teacher_contact), 'Unknown Teacher') as name,
    TRIM(v.contact_email) as email,
    NULL as phone, -- Phone not captured in old schema
    'Lead Teacher' as position,
    'lead_teacher' as type,
    s.id as school_id,
    MIN(v.created_at) as created_at
FROM visits v
LEFT JOIN schools s ON (
    LOWER(TRIM(s.name)) = LOWER(TRIM(v.school_name))
    AND (
        s.city IS NULL OR v.city IS NULL OR
        LOWER(TRIM(s.city)) = LOWER(TRIM(v.city))
    )
    AND (
        s.country IS NULL OR v.country_of_origin IS NULL OR
        LOWER(TRIM(s.country)) = LOWER(TRIM(v.country_of_origin))
    )
)
WHERE v.contact_email IS NOT NULL
    AND TRIM(v.contact_email) != ''
    AND v.contact_email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
    AND NOT EXISTS (
        SELECT 1 FROM contacts c
        WHERE LOWER(TRIM(c.email)) = LOWER(TRIM(v.contact_email))
        AND c.type = 'lead_teacher'
        AND (c.school_id = s.id OR (c.school_id IS NULL AND s.id IS NULL))
    )
GROUP BY v.lead_teacher_contact, v.contact_email, s.id;

-- =====================================================
-- PHASE 3: UPDATE VISITS WITH FOREIGN KEY RELATIONSHIPS
-- =====================================================

-- Update visits table with school_id references
UPDATE visits
SET school_id = s.id
FROM schools s
WHERE visits.school_id IS NULL
    AND LOWER(TRIM(s.name)) = LOWER(TRIM(visits.school_name))
    AND (
        s.city IS NULL OR visits.city IS NULL OR
        LOWER(TRIM(s.city)) = LOWER(TRIM(visits.city))
    )
    AND (
        s.country IS NULL OR visits.country_of_origin IS NULL OR
        LOWER(TRIM(s.country)) = LOWER(TRIM(visits.country_of_origin))
    );

-- Update visits table with lead_teacher_contact_id references
UPDATE visits
SET lead_teacher_contact_id = c.id
FROM contacts c
JOIN schools s ON s.id = c.school_id
WHERE visits.lead_teacher_contact_id IS NULL
    AND LOWER(TRIM(c.email)) = LOWER(TRIM(visits.contact_email))
    AND c.type = 'lead_teacher'
    AND visits.school_id = s.id;

-- =====================================================
-- PHASE 4: SET DEFAULT VALUES FOR NEW FIELDS
-- =====================================================

-- Set visit_type for existing records (assume day trips unless otherwise indicated)
UPDATE visits
SET visit_type = CASE
    WHEN accommodation_selection IS NOT NULL OR number_of_nights > 0 THEN 'school_overnight'
    ELSE 'school_day_trip'
END
WHERE visit_type IS NULL;

-- Set source for existing records
UPDATE visits
SET source = 'legacy_data'
WHERE source IS NULL;

-- Set priority_level for existing records
UPDATE visits
SET priority_level = CASE
    WHEN additional_comments ILIKE '%urgent%' OR additional_comments ILIKE '%asap%' THEN 'urgent'
    WHEN additional_comments ILIKE '%important%' OR additional_comments ILIKE '%priority%' THEN 'high'
    ELSE 'normal'
END
WHERE priority_level IS NULL;

-- =====================================================
-- PHASE 5: DATA VALIDATION AND CLEANUP
-- =====================================================

-- Create a temporary table to log any data issues
CREATE TEMP TABLE migration_issues (
    visit_id UUID,
    issue_type TEXT,
    description TEXT,
    severity TEXT
);

-- Log visits without school relationships
INSERT INTO migration_issues (visit_id, issue_type, description, severity)
SELECT
    id,
    'missing_school',
    'Visit has no school_id relationship: ' || COALESCE(school_name, 'No school name'),
    'medium'
FROM visits
WHERE school_id IS NULL AND school_name IS NOT NULL;

-- Log visits without teacher contact relationships
INSERT INTO migration_issues (visit_id, issue_type, description, severity)
SELECT
    id,
    'missing_teacher_contact',
    'Visit has no lead_teacher_contact_id relationship: ' || COALESCE(contact_email, 'No email'),
    'low'
FROM visits
WHERE lead_teacher_contact_id IS NULL AND contact_email IS NOT NULL;

-- Log invalid email addresses
INSERT INTO migration_issues (visit_id, issue_type, description, severity)
SELECT
    id,
    'invalid_email',
    'Invalid email format: ' || contact_email,
    'high'
FROM visits
WHERE contact_email IS NOT NULL
    AND contact_email != ''
    AND contact_email !~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$';

-- =====================================================
-- PHASE 6: CREATE SUMMARY REPORT
-- =====================================================

-- Migration summary
DO $$
DECLARE
    total_visits INTEGER;
    visits_with_school INTEGER;
    visits_with_teacher INTEGER;
    total_schools INTEGER;
    total_contacts INTEGER;
    total_issues INTEGER;
BEGIN
    SELECT COUNT(*) INTO total_visits FROM visits;
    SELECT COUNT(*) INTO visits_with_school FROM visits WHERE school_id IS NOT NULL;
    SELECT COUNT(*) INTO visits_with_teacher FROM visits WHERE lead_teacher_contact_id IS NOT NULL;
    SELECT COUNT(*) INTO total_schools FROM schools;
    SELECT COUNT(*) INTO total_contacts FROM contacts;
    SELECT COUNT(*) INTO total_issues FROM migration_issues;

    RAISE NOTICE '=================================================';
    RAISE NOTICE 'GUIDAL Visit Data Migration Complete';
    RAISE NOTICE '=================================================';
    RAISE NOTICE 'Total visits processed: %', total_visits;
    RAISE NOTICE 'Visits with school relationship: % (%.1f%%)', visits_with_school, (visits_with_school * 100.0 / total_visits);
    RAISE NOTICE 'Visits with teacher contact relationship: % (%.1f%%)', visits_with_teacher, (visits_with_teacher * 100.0 / total_visits);
    RAISE NOTICE 'Total schools created: %', total_schools;
    RAISE NOTICE 'Total contacts created: %', total_contacts;
    RAISE NOTICE 'Issues identified: %', total_issues;
    RAISE NOTICE '=================================================';

    IF total_issues > 0 THEN
        RAISE NOTICE 'Review migration_issues temp table for details on data quality issues.';
    END IF;
END $$;

-- Display issues summary if any exist
SELECT
    issue_type,
    severity,
    COUNT(*) as count,
    array_agg(DISTINCT description ORDER BY description) as examples
FROM migration_issues
GROUP BY issue_type, severity
ORDER BY
    CASE severity
        WHEN 'high' THEN 1
        WHEN 'medium' THEN 2
        WHEN 'low' THEN 3
    END,
    count DESC;

-- =====================================================
-- PHASE 7: OPTIMIZATION
-- =====================================================

-- Update table statistics for better query performance
ANALYZE schools;
ANALYZE contacts;
ANALYZE visits;

-- =====================================================
-- MIGRATION COMPLETE
-- =====================================================

-- If everything looks good, commit the transaction
-- If there are issues, you can ROLLBACK instead

COMMIT;

-- Summary of migration actions:
-- ✅ Extracted school data and created normalized school records
-- ✅ Extracted contact data and created normalized contact records
-- ✅ Updated visits table with proper foreign key relationships
-- ✅ Set default values for new fields in existing records
-- ✅ Validated data quality and logged any issues
-- ✅ Generated migration summary report
-- ✅ Updated database statistics for optimal performance

-- Next steps:
-- 1. Review any issues in migration_issues table
-- 2. Test the new schema with form submissions
-- 3. Update admin dashboard to use new views
-- 4. Consider dropping legacy fields after confirming everything works