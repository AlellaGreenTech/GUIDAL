-- STEP 2: Update foreign key references
-- Run this to point activity_category_links from duplicates to keepers

-- Create temp table with keeper IDs
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

-- Show what was updated
SELECT COUNT(*) as updated_links FROM activity_category_links;
