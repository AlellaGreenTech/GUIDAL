-- Remove duplicate scheduled_visits entries by title matching
-- Keep the ones with scheduled dates when available, or better titles

DO $$
DECLARE
    keeper_id UUID;
    dup_id UUID;
BEGIN
    -- 1. Composting: Keep the one with scheduled date (Composting Workshop Session), delete the NULL date one
    SELECT id INTO keeper_id FROM scheduled_visits WHERE title = 'Composting Workshop Session' AND scheduled_date IS NOT NULL LIMIT 1;
    SELECT id INTO dup_id FROM scheduled_visits WHERE title = 'Composting & Soil Science' AND scheduled_date IS NULL LIMIT 1;
    IF dup_id IS NOT NULL THEN
        DELETE FROM scheduled_visits WHERE id = dup_id;
        RAISE NOTICE 'Deleted duplicate: Composting & Soil Science (NULL date)';
    END IF;

    -- 2. Erosion: Keep the one with scheduled date (Erosion Control Workshop), delete the NULL date one
    SELECT id INTO keeper_id FROM scheduled_visits WHERE title = 'Erosion Control Workshop' AND scheduled_date IS NOT NULL LIMIT 1;
    SELECT id INTO dup_id FROM scheduled_visits WHERE title = 'Erosion Challenge' AND scheduled_date IS NULL LIMIT 1;
    IF dup_id IS NOT NULL THEN
        DELETE FROM scheduled_visits WHERE id = dup_id;
        RAISE NOTICE 'Deleted duplicate: Erosion Challenge (NULL date)';
    END IF;

    -- 3. Planting: Keep the one with scheduled date (Planting Workshop Session), delete the NULL date one
    SELECT id INTO keeper_id FROM scheduled_visits WHERE title = 'Planting Workshop Session' AND scheduled_date IS NOT NULL LIMIT 1;
    SELECT id INTO dup_id FROM scheduled_visits WHERE title = 'Planting & Growing' AND scheduled_date IS NULL LIMIT 1;
    IF dup_id IS NOT NULL THEN
        DELETE FROM scheduled_visits WHERE id = dup_id;
        RAISE NOTICE 'Deleted duplicate: Planting & Growing (NULL date)';
    END IF;

    -- 4. Robotic Gardening: Keep "Robotic Gardening Session", delete "Robotic Gardening"
    SELECT id INTO keeper_id FROM scheduled_visits WHERE title = 'Robotic Gardening Session' LIMIT 1;
    SELECT id INTO dup_id FROM scheduled_visits WHERE title = 'Robotic Gardening' LIMIT 1;
    IF dup_id IS NOT NULL THEN
        DELETE FROM scheduled_visits WHERE id = dup_id;
        RAISE NOTICE 'Deleted duplicate: Robotic Gardening';
    END IF;

    -- 5. Wattle & Daub: Keep "Wattle & Daub Construction Workshop", delete "Wattle and Daub Construction"
    SELECT id INTO keeper_id FROM scheduled_visits WHERE title = 'Wattle & Daub Construction Workshop' LIMIT 1;
    SELECT id INTO dup_id FROM scheduled_visits WHERE title = 'Wattle and Daub Construction' LIMIT 1;
    IF dup_id IS NOT NULL THEN
        DELETE FROM scheduled_visits WHERE id = dup_id;
        RAISE NOTICE 'Deleted duplicate: Wattle and Daub Construction';
    END IF;

    -- 6. Hydraulic Ram Pumps: Keep "Hydraulic Ram Pumps", delete "Ram Pumps Workshop Session"
    SELECT id INTO keeper_id FROM scheduled_visits WHERE title = 'Hydraulic Ram Pumps' LIMIT 1;
    SELECT id INTO dup_id FROM scheduled_visits WHERE title = 'Ram Pumps Workshop Session' LIMIT 1;
    IF dup_id IS NOT NULL THEN
        DELETE FROM scheduled_visits WHERE id = dup_id;
        RAISE NOTICE 'Deleted duplicate: Ram Pumps Workshop Session';
    END IF;

    RAISE NOTICE 'Successfully removed duplicate scheduled_visits';
END $$;

-- Verify no duplicates remain
SELECT
    a.title as activity_title,
    COUNT(*) as count
FROM scheduled_visits sv
LEFT JOIN activities a ON sv.activity_id = a.id
WHERE sv.visit_type = 'individual_workshop'
GROUP BY a.title
HAVING COUNT(*) > 1
ORDER BY a.title;

-- Show remaining workshops
SELECT COUNT(*) as total_workshops FROM scheduled_visits WHERE visit_type = 'individual_workshop';
