-- Delete duplicate activities by matching titles
-- This approach doesn't need exact UUIDs

DO $$
DECLARE
    keeper_id UUID;
    dup_id UUID;
BEGIN
    -- 1. Composting: Keep "Composting & Soil Science", remove "Composting"
    SELECT id INTO keeper_id FROM activities WHERE title = 'Composting & Soil Science' LIMIT 1;
    SELECT id INTO dup_id FROM activities WHERE title = 'Composting' LIMIT 1;
    UPDATE scheduled_visits SET activity_id = keeper_id WHERE activity_id = dup_id;
    UPDATE activity_category_links SET activity_id = keeper_id WHERE activity_id = dup_id;
    DELETE FROM activities WHERE id = dup_id;
    RAISE NOTICE 'Deleted Composting, kept Composting & Soil Science';

    -- 2. Erosion: Keep "Erosion Control challenge Workshop", remove "Erosion Challenge"
    SELECT id INTO keeper_id FROM activities WHERE title = 'Erosion Control challenge Workshop' LIMIT 1;
    SELECT id INTO dup_id FROM activities WHERE title = 'Erosion Challenge' LIMIT 1;
    UPDATE scheduled_visits SET activity_id = keeper_id WHERE activity_id = dup_id;
    UPDATE activity_category_links SET activity_id = keeper_id WHERE activity_id = dup_id;
    DELETE FROM activities WHERE id = dup_id;
    RAISE NOTICE 'Deleted Erosion Challenge, kept Erosion Control challenge Workshop';

    -- 3. Planting: Keep "Planting & Growing", remove "No til Planting"
    SELECT id INTO keeper_id FROM activities WHERE title = 'Planting & Growing' LIMIT 1;
    SELECT id INTO dup_id FROM activities WHERE title = 'No til Planting' LIMIT 1;
    UPDATE scheduled_visits SET activity_id = keeper_id WHERE activity_id = dup_id;
    UPDATE activity_category_links SET activity_id = keeper_id WHERE activity_id = dup_id;
    DELETE FROM activities WHERE id = dup_id;
    RAISE NOTICE 'Deleted No til Planting, kept Planting & Growing';

    -- 4. Robotic Gardening: Keep "Robotic Gardening Session", remove "Robotic Gardening"
    SELECT id INTO keeper_id FROM activities WHERE title = 'Robotic Gardening Session' LIMIT 1;
    SELECT id INTO dup_id FROM activities WHERE title = 'Robotic Gardening' LIMIT 1;
    UPDATE scheduled_visits SET activity_id = keeper_id WHERE activity_id = dup_id;
    UPDATE activity_category_links SET activity_id = keeper_id WHERE activity_id = dup_id;
    DELETE FROM activities WHERE id = dup_id;
    RAISE NOTICE 'Deleted Robotic Gardening, kept Robotic Gardening Session';

    -- 5. Wattle & Daub: Keep "Wattle & Daub Construction Workshop", remove "Wattle and Daub Construction"
    SELECT id INTO keeper_id FROM activities WHERE title = 'Wattle & Daub Construction Workshop' LIMIT 1;
    SELECT id INTO dup_id FROM activities WHERE title = 'Wattle and Daub Construction' LIMIT 1;
    UPDATE scheduled_visits SET activity_id = keeper_id WHERE activity_id = dup_id;
    UPDATE activity_category_links SET activity_id = keeper_id WHERE activity_id = dup_id;
    DELETE FROM activities WHERE id = dup_id;
    RAISE NOTICE 'Deleted Wattle and Daub Construction, kept Wattle & Daub Construction Workshop';

    RAISE NOTICE 'Successfully removed 5 duplicate activities';
END $$;

-- Verify no duplicates remain
SELECT title, COUNT(*) as count
FROM activities
GROUP BY title
HAVING COUNT(*) > 1;

-- Show remaining activities count
SELECT COUNT(*) as total_activities FROM activities;
