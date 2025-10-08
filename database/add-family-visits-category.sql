-- Add or update Family Farm Visits category to activity_categories table
-- This will appear in the carousel after Workshops

-- First, try to update if it exists (by name or slug)
UPDATE activity_categories
SET
    name = 'Family Farm Visits',
    slug = 'family-visits',
    description = 'Plan a fun and educational farm visit for your family',
    display_order = 3,
    image_url = 'images/family-farm-visit.jpg',
    active = true
WHERE slug = 'family-visits' OR name = 'Family Farm Visits';

-- If no rows were updated, insert a new one
INSERT INTO activity_categories (
    name,
    slug,
    description,
    display_order,
    image_url,
    active
)
SELECT
    'Family Farm Visits',
    'family-visits',
    'Plan a fun and educational farm visit for your family',
    3,
    'images/family-farm-visit.jpg',
    true
WHERE NOT EXISTS (
    SELECT 1 FROM activity_categories
    WHERE slug = 'family-visits' OR name = 'Family Farm Visits'
);

-- Verify the category was added
SELECT id, name, slug, display_order, active
FROM activity_categories
ORDER BY display_order;
