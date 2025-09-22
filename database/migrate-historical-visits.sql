-- Migration Script: Historical Visits to trip_requests
-- Execute this in Supabase SQL Editor to migrate your historical visit data

-- First, let's see what historical data we have
SELECT 'Current data summary:' as info;

SELECT
    'schools' as table_name,
    COUNT(*) as record_count
FROM schools
UNION ALL
SELECT
    'activities' as table_name,
    COUNT(*) as record_count
FROM activities
UNION ALL
SELECT
    'activity_types' as table_name,
    COUNT(*) as record_count
FROM activity_types
UNION ALL
SELECT
    'school_visits' as table_name,
    COUNT(*) as record_count
FROM school_visits;

-- Show a preview of the data we'll be migrating
SELECT 'Preview of historical visits to migrate:' as info;

SELECT
    sv.id as visit_id,
    s.name as school_name,
    sv.teacher_name,
    sv.teacher_email,
    sv.student_count,
    sv.grade_level,
    a.date_time as visit_date,
    a.title as activity_title,
    at.name as activity_type,
    sv.access_code,
    CASE
        WHEN a.date_time < NOW() THEN 'completed'
        WHEN a.status = 'published' THEN 'scheduled'
        ELSE 'approved'
    END as proposed_status
FROM school_visits sv
LEFT JOIN schools s ON sv.school_id = s.id
LEFT JOIN activities a ON sv.activity_id = a.id
LEFT JOIN activity_types at ON a.activity_type_id = at.id
ORDER BY a.date_time DESC;

-- Clear existing sample data (optional - comment out if you want to keep it)
-- DELETE FROM trip_requests WHERE school_name IN (
--     'Barcelona International School',
--     'International School of Catalunya',
--     'American School of Barcelona',
--     'Individual Visitor',
--     'Green Tech Company',
--     'Zurich International School',
--     'Benjamin Franklin International School'
-- );

-- Now migrate the historical data
INSERT INTO trip_requests (
    school_name,
    contact_name,
    contact_email,
    contact_phone,
    student_count,
    teacher_count,
    grade_level,
    preferred_date,
    visit_duration,
    status,
    additional_requests,
    lunch_needs,
    transportation,
    internal_notes,
    submitted_at,
    created_at,
    updated_at
)
SELECT
    COALESCE(s.name, 'Unknown School') as school_name,
    COALESCE(sv.teacher_name, s.contact_person, 'Unknown Contact') as contact_name,
    COALESCE(sv.teacher_email, s.contact_email, 'unknown@email.com') as contact_email,
    sv.teacher_phone as contact_phone,
    COALESCE(sv.student_count, 1) as student_count,
    2 as teacher_count, -- Default
    COALESCE(sv.grade_level, 'Unknown') as grade_level,
    COALESCE(a.date_time::date, CURRENT_DATE) as preferred_date,
    CASE
        WHEN a.duration_minutes IS NOT NULL AND a.duration_minutes > 0
        THEN CONCAT(ROUND(a.duration_minutes / 60.0), ' hours')
        ELSE '4 hours'
    END as visit_duration,
    CASE
        WHEN a.date_time < NOW() THEN 'completed'
        WHEN a.status = 'published' THEN 'scheduled'
        ELSE 'approved'
    END as status,
    sv.special_instructions as additional_requests,
    CASE
        WHEN sv.lunch_required = true THEN 'required'
        ELSE 'none'
    END as lunch_needs,
    sv.transport_details as transportation,
    CONCAT(
        'Migrated from historical data. ',
        'Activity Type: ', COALESCE(at.name, 'Unknown'), '. ',
        'Access Code: ', COALESCE(sv.access_code, 'N/A'), '. ',
        'Original Activity: ', COALESCE(a.title, 'Unknown')
    ) as internal_notes,
    COALESCE(sv.created_at, a.created_at, NOW()) as submitted_at,
    COALESCE(sv.created_at, a.created_at, NOW()) as created_at,
    NOW() as updated_at
FROM school_visits sv
LEFT JOIN schools s ON sv.school_id = s.id
LEFT JOIN activities a ON sv.activity_id = a.id
LEFT JOIN activity_types at ON a.activity_type_id = at.id;

-- Show the results
SELECT 'Migration completed! Summary:' as info;

SELECT
    status,
    COUNT(*) as count,
    STRING_AGG(school_name, ', ') as schools
FROM trip_requests
GROUP BY status
ORDER BY
    CASE status
        WHEN 'completed' THEN 1
        WHEN 'scheduled' THEN 2
        WHEN 'approved' THEN 3
        WHEN 'pending' THEN 4
        ELSE 5
    END;

-- Final verification
SELECT 'Total visits in trip_requests table:' as info;
SELECT COUNT(*) as total_visits FROM trip_requests;

SELECT 'Recent migrated visits:' as info;
SELECT
    school_name,
    contact_name,
    student_count,
    preferred_date,
    status,
    LEFT(internal_notes, 50) || '...' as notes_preview
FROM trip_requests
WHERE internal_notes LIKE 'Migrated from historical data%'
ORDER BY preferred_date DESC
LIMIT 10;