-- Add Halloween Mini-Party for November 1st, 2025
-- This is similar to the Halloween Party 2025 but for Nov 1st and called "Mini-party"

-- Add Halloween Mini-Party with proper activity_type_id and category linking
DO $$
DECLARE
    events_type_id UUID;
    new_activity_id UUID;
    category_id UUID;
BEGIN
    -- Get the events activity type ID
    SELECT id INTO events_type_id
    FROM activity_types
    WHERE name = 'Events' OR slug = 'events' OR name ILIKE '%event%'
    LIMIT 1;

    -- Insert the new activity with required columns including slug
    INSERT INTO activities (
        title,
        slug,
        description,
        date_time,
        activity_type_id,
        status,
        max_participants
    ) VALUES (
        'Halloween Mini-Party 2025 🎃👻',
        'halloween-mini-party-2025',
        'Join us for a family-friendly Halloween mini-celebration featuring pumpkin picking, carving, wood-fired pizza, wine tasting, and festive fun at our educational farm. Activities include: pumpkin patch, pumpkin carving, wood fire pizza, wine tasting, and Halloween parties. Family-friendly event, costumes encouraged!',
        '2025-11-01 16:00:00+00',  -- November 1st, 2025 at 4 PM
        events_type_id,
        'confirmed',
        200
    )
    RETURNING id INTO new_activity_id;

    -- Get the Halloween/Fall Events category ID
    SELECT id INTO category_id
    FROM activity_categories
    WHERE name = 'Halloween & Fall Events' OR slug = 'halloween-fall-events'
    LIMIT 1;

    -- Link activity to category if both exist
    IF category_id IS NOT NULL AND new_activity_id IS NOT NULL THEN
        INSERT INTO activity_category_junction (activity_id, category_id)
        VALUES (new_activity_id, category_id)
        ON CONFLICT (activity_id, category_id) DO NOTHING;

        RAISE NOTICE 'Halloween Mini-Party created and linked to category successfully. Activity ID: %', new_activity_id;
    ELSE
        RAISE NOTICE 'Could not link to category. Category ID: %, Activity ID: %', category_id, new_activity_id;
    END IF;
END $$;
