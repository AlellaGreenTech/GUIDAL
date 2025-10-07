-- Add Halloween Mini-Party for November 1st, 2025
-- This is similar to the Halloween Party 2025 but for Nov 1st and called "Mini-party"

INSERT INTO activities (
    title,
    description,
    date_time,
    activity_type,
    status,
    image_url,
    details_page_url,
    requires_login
) VALUES (
    'Halloween Mini-Party 2025 🎃👻',
    'Join us for a family-friendly Halloween mini-celebration featuring pumpkin picking, carving, wood-fired pizza, wine tasting, and festive fun at our educational farm. Activities include: pumpkin patch, pumpkin carving, wood fire pizza, wine tasting, and Halloween parties. Family-friendly event, costumes encouraged!',
    '2025-11-01 16:00:00+00',  -- November 1st, 2025 at 4 PM
    'events',
    'upcoming',
    'images/halloween-party.png',
    '/events/pumpkin-patch-checkout.html',
    false  -- Does not require login - guest checkout
);

-- Link to Halloween/Fall Events category
-- First get the category ID
DO $$
DECLARE
    category_id UUID;
    activity_id UUID;
BEGIN
    -- Get the Halloween/Fall Events category ID
    SELECT id INTO category_id
    FROM activity_categories
    WHERE name = 'Halloween & Fall Events' OR slug = 'halloween-fall-events'
    LIMIT 1;

    -- Get the newly created activity ID
    SELECT id INTO activity_id
    FROM activities
    WHERE title = 'Halloween Mini-Party 2025 🎃👻'
    LIMIT 1;

    -- Link activity to category if both exist
    IF category_id IS NOT NULL AND activity_id IS NOT NULL THEN
        INSERT INTO activity_category_junction (activity_id, category_id)
        VALUES (activity_id, category_id)
        ON CONFLICT (activity_id, category_id) DO NOTHING;

        RAISE NOTICE 'Halloween Mini-Party linked to category successfully';
    ELSE
        RAISE NOTICE 'Category or Activity not found. Category ID: %, Activity ID: %', category_id, activity_id;
    END IF;
END $$;
