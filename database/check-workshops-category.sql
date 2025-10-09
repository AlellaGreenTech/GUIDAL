-- Check if Workshops category exists and is active
SELECT
    id,
    name,
    slug,
    display_order,
    image_url,
    active,
    created_at
FROM activity_categories
ORDER BY display_order;
