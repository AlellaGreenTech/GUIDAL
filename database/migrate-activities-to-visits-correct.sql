-- Correct migration script using actual visits table schema
-- Moving visit records from activities table to visits table

-- Step 1: Insert school visits (max_participants = student count)
INSERT INTO visits (
    school_name,
    contact_email,
    contact_name,
    country_of_origin,
    visit_type,
    visit_format,
    educational_focus,
    student_count,
    teacher_count,
    grade_level,
    preferred_date,
    visit_duration,
    lunch_needs,
    learning_goals,
    topics_of_interest,
    additional_requests,
    status,
    submitted_at,
    created_at,
    updated_at,
    internal_notes,
    confirmed_date,
    estimated_cost
)
SELECT
    CASE
        WHEN a.title LIKE '%-%' THEN TRIM(SPLIT_PART(a.title, '-', 1))
        ELSE a.title
    END as school_name,
    'migrated@example.com' as contact_email,
    'Migrated from activities table' as contact_name,
    CASE
        WHEN LOWER(a.title) LIKE '%spain%' OR LOWER(a.title) LIKE '%barcelona%' OR LOWER(a.title) LIKE '%montessori%' THEN 'Spain'
        WHEN LOWER(a.title) LIKE '%usa%' THEN 'USA'
        WHEN LOWER(a.title) LIKE '%italy%' OR LOWER(a.title) LIKE '%h-farm%' THEN 'Italy'
        WHEN LOWER(a.title) LIKE '%switzerland%' OR LOWER(a.title) LIKE '%zurich%' THEN 'Switzerland'
        WHEN LOWER(a.title) LIKE '%saudi%' THEN 'Saudi Arabia'
        WHEN LOWER(a.title) LIKE '%prague%' THEN 'Czechia'
        ELSE 'Unknown'
    END as country_of_origin,
    'school-visit' as visit_type,
    'full-day-with-lunch' as visit_format,
    'real-world-science' as educational_focus,
    a.max_participants as student_count,
    CASE
        WHEN a.max_participants IS NOT NULL THEN GREATEST(CEIL(a.max_participants::float / 15) + 1, 2)
        ELSE 2
    END as teacher_count,
    'Mixed grades' as grade_level,
    a.date_time::date as preferred_date,
    '6 hours' as visit_duration,
    'pizza' as lunch_needs,
    COALESCE(a.description, 'Educational visit migrated from activities table') as learning_goals,
    COALESCE(a.description, 'Various hands-on activities') as topics_of_interest,
    'Migrated from activities table - details may need updating' as additional_requests,
    CASE
        WHEN a.date_time < NOW() THEN 'completed'
        WHEN a.date_time > NOW() THEN 'scheduled'
        ELSE 'pending'
    END as status,
    COALESCE(a.created_at, NOW()) as submitted_at,
    COALESCE(a.created_at, NOW()) as created_at,
    NOW() as updated_at,
    'Migrated from activities table (School Visits). Original ID: ' || a.id || '. Original max_participants: ' || COALESCE(a.max_participants, 0) as internal_notes,
    a.date_time::date as confirmed_date,
    a.price as estimated_cost
FROM activities a
JOIN activity_types at ON a.activity_type_id = at.id
WHERE at.name = 'School Visits';

-- Step 2: Insert annual events (max_participants = adult count, 20% more children)
INSERT INTO visits (
    school_name,
    contact_email,
    contact_name,
    country_of_origin,
    visit_type,
    visit_format,
    educational_focus,
    student_count,
    teacher_count,
    adult_count,
    grade_level,
    preferred_date,
    visit_duration,
    lunch_needs,
    learning_goals,
    topics_of_interest,
    additional_requests,
    status,
    submitted_at,
    created_at,
    updated_at,
    internal_notes,
    confirmed_date,
    estimated_cost
)
SELECT
    a.title as school_name,
    'migrated@example.com' as contact_email,
    'Migrated from activities table' as contact_name,
    'Spain' as country_of_origin, -- Most events are local
    'school-visit' as visit_type,
    'full-day-with-lunch' as visit_format,
    'real-world-science' as educational_focus,
    GREATEST(1, ROUND(COALESCE(a.max_participants, 0) * 0.2)) as student_count, -- 20% more children than adults, minimum 1
    0 as teacher_count, -- Events don't have teachers
    a.max_participants as adult_count, -- adults
    'All ages' as grade_level,
    a.date_time::date as preferred_date,
    '6 hours' as visit_duration,
    'pizza' as lunch_needs,
    COALESCE(a.description, 'Community event migrated from activities table') as learning_goals,
    COALESCE(a.description, 'Community activities and workshops') as topics_of_interest,
    'Annual community event - details may need updating' as additional_requests,
    CASE
        WHEN a.date_time < NOW() THEN 'completed'
        WHEN a.date_time > NOW() THEN 'scheduled'
        ELSE 'pending'
    END as status,
    COALESCE(a.created_at, NOW()) as submitted_at,
    COALESCE(a.created_at, NOW()) as created_at,
    NOW() as updated_at,
    'Migrated from activities table (Annual Events). Original ID: ' || a.id || '. Original max_participants: ' || COALESCE(a.max_participants, 0) || '. Total visitors (2.2x): ' || ROUND(COALESCE(a.max_participants, 0) * 2.2) as internal_notes,
    a.date_time::date as confirmed_date,
    a.price as estimated_cost
FROM activities a
JOIN activity_types at ON a.activity_type_id = at.id
WHERE at.name = 'Annual Events';

-- Step 3: Insert workshops and lunches (max_participants = student count since adults participate as learners)
INSERT INTO visits (
    school_name,
    contact_email,
    contact_name,
    country_of_origin,
    visit_type,
    visit_format,
    educational_focus,
    student_count,
    teacher_count,
    grade_level,
    preferred_date,
    visit_duration,
    lunch_needs,
    learning_goals,
    topics_of_interest,
    additional_requests,
    status,
    submitted_at,
    created_at,
    updated_at,
    internal_notes,
    confirmed_date,
    estimated_cost
)
SELECT
    a.title as school_name,
    'migrated@example.com' as contact_email,
    'Migrated from activities table' as contact_name,
    'Spain' as country_of_origin, -- Most workshops are local
    CASE
        WHEN at.name = 'Special Lunches' THEN 'school-visit'
        ELSE 'school-visit'
    END as visit_type,
    CASE
        WHEN at.name = 'Special Lunches' THEN 'full-day-with-lunch'
        ELSE 'full-day-with-lunch'
    END as visit_format,
    'hands-on-permaculture' as educational_focus,
    GREATEST(1, COALESCE(a.max_participants, 1)) as student_count, -- Workshops: treat participants as students
    0 as teacher_count, -- No teachers for workshops
    'Adult' as grade_level,
    a.date_time::date as preferred_date,
    CASE
        WHEN at.name = 'Special Lunches' THEN '2 hours'
        ELSE '4 hours'
    END as visit_duration,
    CASE
        WHEN at.name = 'Special Lunches' THEN 'pizza'
        ELSE 'pizza'
    END as lunch_needs,
    COALESCE(a.description, 'Workshop migrated from activities table') as learning_goals,
    COALESCE(a.description, 'Hands-on workshop activities') as topics_of_interest,
    'Workshop or special lunch - details may need updating' as additional_requests,
    CASE
        WHEN a.date_time < NOW() THEN 'completed'
        WHEN a.date_time > NOW() THEN 'scheduled'
        ELSE 'pending'
    END as status,
    COALESCE(a.created_at, NOW()) as submitted_at,
    COALESCE(a.created_at, NOW()) as created_at,
    NOW() as updated_at,
    'Migrated from activities table (' || at.name || '). Original ID: ' || a.id || '. Original max_participants: ' || COALESCE(a.max_participants, 0) as internal_notes,
    a.date_time::date as confirmed_date,
    a.price as estimated_cost
FROM activities a
JOIN activity_types at ON a.activity_type_id = at.id
WHERE at.name IN ('Workshops', 'Special Lunches');

-- Step 4: Remove the migrated records from activities table
DELETE FROM activities
WHERE activity_type_id IN (
    SELECT id FROM activity_types
    WHERE name IN ('School Visits', 'Annual Events', 'Workshops', 'Special Lunches')
);

-- Step 5: Verification queries (uncomment to check results)
-- SELECT COUNT(*) as remaining_activities FROM activities;
-- SELECT COUNT(*) as total_visits FROM visits;
-- SELECT COUNT(*) as completed_visits FROM visits WHERE status = 'completed';
-- SELECT SUM(COALESCE(student_count, 0) + COALESCE(teacher_count, 0) + COALESCE(adult_count, 0)) as total_visitors FROM visits;