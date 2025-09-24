-- Fixed migration script to move visit records from activities table to visits table
-- Using correct column names from the visits table schema

-- Step 1: Insert school visits (max_participants = student count)
INSERT INTO visits (
    school_name,
    number_of_students,
    number_of_adults,
    contact_email,
    lead_teacher_contact,
    country_of_origin,
    preferred_language,
    visit_format,
    educational_focus,
    status,
    confirmed_date,
    submitted_at,
    additional_comments,
    internal_notes,
    estimated_cost
)
SELECT
    CASE
        WHEN title LIKE '%-%' THEN TRIM(SPLIT_PART(title, '-', 1))
        ELSE title
    END as school_name,
    max_participants as number_of_students,
    CASE
        WHEN max_participants IS NOT NULL THEN GREATEST(CEIL(max_participants::float / 15) + 1, 2)
        ELSE 2
    END as number_of_adults,
    'migrated@example.com' as contact_email,
    'Migrated from activities table' as lead_teacher_contact,
    CASE
        WHEN LOWER(title) LIKE '%spain%' OR LOWER(title) LIKE '%barcelona%' OR LOWER(title) LIKE '%montessori%' THEN 'Spain'
        WHEN LOWER(title) LIKE '%usa%' THEN 'USA'
        WHEN LOWER(title) LIKE '%italy%' OR LOWER(title) LIKE '%h-farm%' THEN 'Italy'
        WHEN LOWER(title) LIKE '%switzerland%' OR LOWER(title) LIKE '%zurich%' THEN 'Switzerland'
        WHEN LOWER(title) LIKE '%saudi%' THEN 'Saudi Arabia'
        WHEN LOWER(title) LIKE '%prague%' THEN 'Czechia'
        ELSE 'Unknown'
    END as country_of_origin,
    'English' as preferred_language,
    'full_day_pizza_lunch' as visit_format,
    'balanced_mix' as educational_focus,
    CASE
        WHEN date_time < NOW() THEN 'completed'
        WHEN date_time > NOW() THEN 'scheduled'
        ELSE 'pending'
    END as status,
    date_time::date as confirmed_date,
    COALESCE(created_at, NOW()) as submitted_at,
    COALESCE(description, '') as additional_comments,
    'Migrated from activities table (School Visits). Original ID: ' || id || '. Original max_participants: ' || COALESCE(max_participants, 0) as internal_notes,
    price as estimated_cost
FROM activities a
JOIN activity_types at ON a.activity_type_id = at.id
WHERE at.name = 'School Visits';

-- Step 2: Insert annual events (max_participants = adult count, 20% more children)
INSERT INTO visits (
    school_name,
    number_of_students,
    number_of_adults,
    contact_email,
    lead_teacher_contact,
    country_of_origin,
    preferred_language,
    visit_format,
    educational_focus,
    status,
    confirmed_date,
    submitted_at,
    additional_comments,
    internal_notes,
    estimated_cost
)
SELECT
    CASE
        WHEN title LIKE '%-%' THEN TRIM(SPLIT_PART(title, '-', 1))
        ELSE title
    END as school_name,
    ROUND(COALESCE(max_participants, 0) * 0.2) as number_of_students, -- 20% more children than adults
    max_participants as number_of_adults, -- adults
    'migrated@example.com' as contact_email,
    'Migrated from activities table' as lead_teacher_contact,
    'Spain' as country_of_origin, -- Most events are local
    'English' as preferred_language,
    'other' as visit_format,
    'balanced_mix' as educational_focus,
    CASE
        WHEN date_time < NOW() THEN 'completed'
        WHEN date_time > NOW() THEN 'scheduled'
        ELSE 'pending'
    END as status,
    date_time::date as confirmed_date,
    COALESCE(created_at, NOW()) as submitted_at,
    COALESCE(description, '') as additional_comments,
    'Migrated from activities table (Annual Events). Original ID: ' || id || '. Original max_participants: ' || COALESCE(max_participants, 0) || '. Total visitors (2.2x): ' || ROUND(COALESCE(max_participants, 0) * 2.2) as internal_notes,
    price as estimated_cost
FROM activities a
JOIN activity_types at ON a.activity_type_id = at.id
WHERE at.name = 'Annual Events';

-- Step 3: Insert workshops and lunches (max_participants = adult count)
INSERT INTO visits (
    school_name,
    number_of_students,
    number_of_adults,
    contact_email,
    lead_teacher_contact,
    country_of_origin,
    preferred_language,
    visit_format,
    educational_focus,
    status,
    confirmed_date,
    submitted_at,
    additional_comments,
    internal_notes,
    estimated_cost
)
SELECT
    CASE
        WHEN title LIKE '%-%' THEN TRIM(SPLIT_PART(title, '-', 1))
        ELSE title
    END as school_name,
    0 as number_of_students, -- Workshops typically don't have students
    max_participants as number_of_adults, -- adults
    'migrated@example.com' as contact_email,
    'Migrated from activities table' as lead_teacher_contact,
    'Spain' as country_of_origin, -- Most workshops are local
    'English' as preferred_language,
    'other' as visit_format,
    'balanced_mix' as educational_focus,
    CASE
        WHEN date_time < NOW() THEN 'completed'
        WHEN date_time > NOW() THEN 'scheduled'
        ELSE 'pending'
    END as status,
    date_time::date as confirmed_date,
    COALESCE(created_at, NOW()) as submitted_at,
    COALESCE(description, '') as additional_comments,
    'Migrated from activities table (' || at.name || '). Original ID: ' || id || '. Original max_participants: ' || COALESCE(max_participants, 0) as internal_notes,
    price as estimated_cost
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
-- SELECT SUM(number_of_students + number_of_adults) as total_visitors FROM visits;