-- Add Workshops category to activity_categories table
-- This will appear in the carousel right after Events

-- First, check what display_order Events has
SELECT name, slug, display_order FROM activity_categories WHERE slug = 'events';

-- Insert Workshops category
-- Assuming Events is display_order 1, we'll make Workshops display_order 2
-- and shift others down if needed
INSERT INTO activity_categories (
    name,
    slug,
    description,
    display_order,
    image_url,
    active
) VALUES (
    'Workshops',
    'workshops',
    'Hands-on workshops and interactive learning experiences',
    2,
    'images/wattle-daub-construction.png',
    true
)
ON CONFLICT (slug) DO UPDATE SET
    display_order = 2,
    active = true;

-- Verify the category was added
SELECT id, name, slug, display_order, active
FROM activity_categories
ORDER BY display_order;
