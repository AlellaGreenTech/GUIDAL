-- Link scheduled visits to carousel categories
-- This links activities based on their activity type to the appropriate carousel categories

-- First, let's see what we have
SELECT
    ac.name as category_name,
    ac.id as category_id,
    ac.slug
FROM activity_categories ac
WHERE ac.active = true
ORDER BY ac.display_order;

-- Link school visits to "School Field Trip" category
INSERT INTO activity_category_links (activity_id, category_id)
SELECT DISTINCT
    sv.activity_id,
    ac.id as category_id
FROM scheduled_visits sv
JOIN activity_categories ac ON ac.slug = 'school-field-trips'
WHERE sv.visit_type = 'school_group'
  AND sv.activity_id IS NOT NULL
  -- Don't insert duplicates
  AND NOT EXISTS (
    SELECT 1 FROM activity_category_links acl
    WHERE acl.activity_id = sv.activity_id
    AND acl.category_id = ac.id
  );

-- Link public events to "Events" category
INSERT INTO activity_category_links (activity_id, category_id)
SELECT DISTINCT
    sv.activity_id,
    ac.id as category_id
FROM scheduled_visits sv
JOIN activity_categories ac ON ac.slug = 'events'
WHERE sv.visit_type = 'public_event'
  AND sv.activity_id IS NOT NULL
  -- Don't insert duplicates
  AND NOT EXISTS (
    SELECT 1 FROM activity_category_links acl
    WHERE acl.activity_id = sv.activity_id
    AND acl.category_id = ac.id
  );

-- Link individual workshops to appropriate categories based on activity title/type
-- (You'll need to add more specific mappings based on your workshop types)

-- Verify the links were created
SELECT
    ac.name as category_name,
    a.title as activity_title,
    COUNT(*) as link_count
FROM activity_category_links acl
JOIN activity_categories ac ON ac.id = acl.category_id
JOIN activities a ON a.id = acl.activity_id
GROUP BY ac.name, a.title
ORDER BY ac.name, a.title;

-- Show count per category
SELECT
    ac.name as category_name,
    COUNT(acl.id) as linked_activities
FROM activity_categories ac
LEFT JOIN activity_category_links acl ON acl.category_id = ac.id
WHERE ac.active = true
GROUP BY ac.id, ac.name
ORDER BY ac.display_order;
