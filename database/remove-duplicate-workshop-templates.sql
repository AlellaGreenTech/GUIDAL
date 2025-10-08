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

-- Update activity_category_links to point to the kept record
UPDATE activity_category_links acl
SET activity_id = keeper.id
FROM (
    SELECT DISTINCT ON (sv.activity_id)
        sv.id,
        sv.activity_id
    FROM scheduled_visits sv
    WHERE sv.visit_type = 'individual_workshop'
      AND sv.scheduled_date IS NULL
    ORDER BY sv.activity_id, sv.created_at ASC
) keeper
WHERE acl.activity_id IN (
    -- Get IDs of duplicates to be deleted
    SELECT id
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
    WHERE rn > 1
)
AND keeper.activity_id = (
    SELECT activity_id FROM scheduled_visits WHERE id = acl.activity_id
);

-- Step 3: Now delete the duplicates
DELETE FROM scheduled_visits
WHERE id IN (
    SELECT id
    FROM (
        SELECT id,
               ROW_NUMBER() OVER (
                   PARTITION BY activity_id, visit_type
                   ORDER BY created_at ASC
               ) as rn
        FROM scheduled_visits
        WHERE visit_type = 'individual_workshop'
          AND scheduled_date IS NULL
    ) t
    WHERE rn > 1
);

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
