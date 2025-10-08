-- Remove duplicate scheduled_visits entries
-- Keep the ones with more descriptive titles or scheduled dates

DO $$
BEGIN
    -- 1. Composting: Keep the one with scheduled date (Composting Workshop Session 2025-10-15)
    DELETE FROM scheduled_visits WHERE id = 'e615e48e-26f6-47d6-a1e4-85292d6d';
    RAISE NOTICE 'Deleted duplicate Composting & Soil Science (NULL date)';

    -- 2. Erosion: Keep the one with scheduled date (Erosion Control Workshop 2025-11-05)
    DELETE FROM scheduled_visits WHERE id = '89ab4e0a-8fc6-4908-9898-c065d2a2';
    RAISE NOTICE 'Deleted duplicate Erosion Challenge (NULL date)';

    -- 3. Planting: Keep the one with scheduled date (Planting Workshop Session 2025-10-22)
    DELETE FROM scheduled_visits WHERE id = 'b24ddd97-f3e4-4986-95a0-25ede349';
    RAISE NOTICE 'Deleted duplicate Planting & Growing (NULL date)';

    -- 4. Robotic Gardening: Keep "Robotic Gardening Session", delete "Robotic Gardening"
    DELETE FROM scheduled_visits WHERE id = 'bd4847e6-0a5f-421c-9ab9-7d63deeb';
    RAISE NOTICE 'Deleted duplicate Robotic Gardening (NULL date)';

    -- 5. Wattle & Daub: Keep "Wattle & Daub Construction Workshop", delete "Wattle and Daub Construction"
    DELETE FROM scheduled_visits WHERE id = 'b39db692-d19f-4669-bba3-a140e292';
    RAISE NOTICE 'Deleted duplicate Wattle and Daub Construction (NULL date)';

    -- 6. Hydraulic Ram Pumps: Keep just one, delete the duplicate
    DELETE FROM scheduled_visits WHERE id = '53161860-6771-4a1e-9ae5-1e93a59f';
    RAISE NOTICE 'Deleted duplicate Ram Pumps Workshop Session (NULL date)';

    RAISE NOTICE 'Successfully removed 6 duplicate scheduled_visits';
END $$;

-- Verify no duplicates remain
SELECT
    a.title as activity_title,
    COUNT(*) as count
FROM scheduled_visits sv
LEFT JOIN activities a ON sv.activity_id = a.id
WHERE sv.visit_type = 'individual_workshop'
GROUP BY a.title
HAVING COUNT(*) > 1;
