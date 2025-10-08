-- STEP 2 & 3 COMBINED: Update references and delete duplicates
-- Must run together in same session so temp tables persist

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

-- Update activity_category_links to point to keepers
UPDATE activity_category_links acl
SET activity_id = k.keeper_id
FROM duplicates d
JOIN keepers k ON d.activity_id = k.orig_activity_id
WHERE acl.activity_id = d.id;

-- Delete the duplicates
DELETE FROM scheduled_visits
WHERE id IN (SELECT id FROM duplicates);

-- Show results
SELECT
    'Remaining workshops' as status,
    COUNT(*) as count
FROM scheduled_visits
WHERE visit_type = 'individual_workshop'
  AND scheduled_date IS NULL;

-- Clean up temp tables
DROP TABLE IF EXISTS keepers;
DROP TABLE IF EXISTS duplicates;
