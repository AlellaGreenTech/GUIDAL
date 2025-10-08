-- Remove specific duplicate activities manually
-- Keep the more descriptive titles

DO $$
DECLARE
    v_updated_sv INTEGER;
    v_updated_acl INTEGER;
    v_deleted INTEGER;
BEGIN
    -- Define which duplicates to remove and which to keep
    -- Format: UPDATE references from duplicate_id to keeper_id, then DELETE duplicate_id

    -- Composting: Keep "Composting & Soil Science", remove "Composting"
    UPDATE scheduled_visits SET activity_id = 'bb99d4a8-0e65-4df2-a055-6f4903d8'
    WHERE activity_id = '3f55fc02-1c07-47cb-90cb-edde0966';

    UPDATE activity_category_links SET activity_id = 'bb99d4a8-0e65-4df2-a055-6f4903d8'
    WHERE activity_id = '3f55fc02-1c07-47cb-90cb-edde0966';

    -- Erosion: Keep "Erosion Control challenge Workshop", remove "Erosion Challenge"
    UPDATE scheduled_visits SET activity_id = '3ddf28d8-4c9a-4eb8-89c2-b7730ce2'
    WHERE activity_id = 'c42112df-bb76-44a1-b8f3-1228262d';

    UPDATE activity_category_links SET activity_id = '3ddf28d8-4c9a-4eb8-89c2-b7730ce2'
    WHERE activity_id = 'c42112df-bb76-44a1-b8f3-1228262d';

    -- Planting: Keep "Planting & Growing", remove "No til Planting"
    UPDATE scheduled_visits SET activity_id = 'd21e07be-56cb-4701-afc7-39f130c3'
    WHERE activity_id = '03a307d3-4419-4b14-a33a-305c1127';

    UPDATE activity_category_links SET activity_id = 'd21e07be-56cb-4701-afc7-39f130c3'
    WHERE activity_id = '03a307d3-4419-4b14-a33a-305c1127';

    -- Robotic Gardening: Keep "Robotic Gardening Session", remove "Robotic Gardening"
    UPDATE scheduled_visits SET activity_id = '9bff5d1a-3c59-409d-a692-b055431a'
    WHERE activity_id = 'fcebee64-16c0-4189-9ec6-e2c00823';

    UPDATE activity_category_links SET activity_id = '9bff5d1a-3c59-409d-a692-b055431a'
    WHERE activity_id = 'fcebee64-16c0-4189-9ec6-e2c00823';

    -- Wattle & Daub: Keep "Wattle & Daub Construction Workshop", remove "Wattle and Daub Construction"
    UPDATE scheduled_visits SET activity_id = '579e5d67-5afb-4975-a26f-6b8ee1b8'
    WHERE activity_id = '3c597730-cd83-45f8-bef2-4842e9eb';

    UPDATE activity_category_links SET activity_id = '579e5d67-5afb-4975-a26f-6b8ee1b8'
    WHERE activity_id = '3c597730-cd83-45f8-bef2-4842e9eb';

    GET DIAGNOSTICS v_updated_sv = ROW_COUNT;

    -- Now delete the duplicates
    DELETE FROM activities WHERE id IN (
        '3f55fc02-1c07-47cb-90cb-edde0966',  -- Composting
        'c42112df-bb76-44a1-b8f3-1228262d',  -- Erosion Challenge
        '03a307d3-4419-4b14-a33a-305c1127',  -- No til Planting
        'fcebee64-16c0-4189-9ec6-e2c00823',  -- Robotic Gardening
        '3c597730-cd83-45f8-bef2-4842e9eb'   -- Wattle and Daub Construction
    );

    GET DIAGNOSTICS v_deleted = ROW_COUNT;

    RAISE NOTICE 'Deleted % duplicate activities', v_deleted;
    RAISE NOTICE 'Updated foreign key references';
END $$;

-- Verify no duplicates remain
SELECT title, COUNT(*) as count
FROM activities
GROUP BY title
ORDER BY title;
