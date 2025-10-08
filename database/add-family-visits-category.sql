-- Add Family Farm Visits category to activity_categories table
-- This will appear in the carousel after Workshops

INSERT INTO activity_categories (
    name,
    slug,
    description,
    display_order,
    image_url,
    active
) VALUES (
    'Family Farm Visits',
    'family-visits',
    'Plan a fun and educational farm visit for your family',
    3,
    'images/family-farm-visit.jpg',
    true
)
ON CONFLICT (slug) DO UPDATE SET
    display_order = 3,
    active = true;

-- Verify the category was added
SELECT id, name, slug, display_order, active
FROM activity_categories
ORDER BY display_order;
