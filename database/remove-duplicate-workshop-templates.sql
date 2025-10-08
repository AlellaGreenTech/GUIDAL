-- Remove duplicate workshop templates in scheduled_visits
-- Keep only one template per activity_id where visit_type = 'individual_workshop'

-- Step 1: See what duplicates we have
SELECT
    activity_id,
    title,
    id,
    created_at,
    ROW_NUMBER() OVER (PARTITION BY activity_id, visit_type ORDER BY created_at ASC) as rn
FROM scheduled_visits
WHERE visit_type = 'individual_workshop'
  AND scheduled_date IS NULL
ORDER BY activity_id, created_at;

-- Step 2: For each duplicate group, update foreign key references
-- to point to the record we're keeping (the oldest one)

-- First, create a temp table with keeper IDs
CREATE TEMP TABLE keepers AS
SELECT
    sv.id as keeper_id,
    sv.activity_id as orig_activity_id
FROM (
    SELECT id,
           activity_id,
           ROW_NUMBER() OVER (
               PARTITION BY activity_id, visit_type
               ORDER BY created_at ASC
           ) as rn
    FROM scheduled_visits
    WHERE visit_type = 'individual_workshop'
      AND scheduled_date IS NULL
) sv
WHERE sv.rn = 1;

-- Create temp table with duplicate IDs to be deleted
CREATE TEMP TABLE duplicates AS
SELECT id, activity_id
FROM (
    SELECT id,
           activity_id,
           ROW_NUMBER() OVER (
               PARTITION BY activity_id, visit_type
               ORDER BY created_at ASC
           ) as rn
    FROM scheduled_visits
    WHERE visit_type = 'individual_workshop'
      AND scheduled_date IS NULL
) t
WHERE rn > 1;

-- Update activity_category_links
UPDATE activity_category_links acl
SET activity_id = k.keeper_id
FROM duplicates d
JOIN keepers k ON d.activity_id = k.orig_activity_id
WHERE acl.activity_id = d.id;

-- Step 3: Now delete the duplicates
DELETE FROM scheduled_visits
WHERE id IN (SELECT id FROM duplicates);

-- Clean up temp tables
DROP TABLE IF EXISTS keepers;
DROP TABLE IF EXISTS duplicates;

-- Step 4: Verify - should show no duplicates now
SELECT
    activity_id,
    title,
    visit_type,
    COUNT(*) as count
FROM scheduled_visits
WHERE visit_type = 'individual_workshop'
  AND scheduled_date IS NULL
GROUP BY activity_id, title, visit_type
ORDER BY title;
