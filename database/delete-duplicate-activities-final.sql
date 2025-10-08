-- Delete duplicate activities
-- Keep the more descriptive titles and update all references

DO $$
BEGIN
    -- 1. Composting: Keep "Composting & Soil Science", remove "Composting"
    UPDATE scheduled_visits SET activity_id = 'bb99d4a8-0e65-4d72-a055-6f4903d856c4' WHERE activity_id = '3f55fc02-1c07-47cb-90cb-edde09662788';
    UPDATE activity_category_links SET activity_id = 'bb99d4a8-0e65-4d72-a055-6f4903d856c4' WHERE activity_id = '3f55fc02-1c07-47cb-90cb-edde09662788';
    DELETE FROM activities WHERE id = '3f55fc02-1c07-47cb-90cb-edde09662788';

    -- 2. Erosion: Keep "Erosion Control challenge Workshop", remove "Erosion Challenge"
    UPDATE scheduled_visits SET activity_id = '3ddf28d8-4c9a-4eb8-89c2-b7730ce25f02' WHERE activity_id = 'c42112df-bb76-44a1-b8f3-1228262dbdb9';
    UPDATE activity_category_links SET activity_id = '3ddf28d8-4c9a-4eb8-89c2-b7730ce25f02' WHERE activity_id = 'c42112df-bb76-44a1-b8f3-1228262dbdb9';
    DELETE FROM activities WHERE id = 'c42112df-bb76-44a1-b8f3-1228262dbdb9';

    -- 3. Planting: Keep "Planting & Growing", remove "No til Planting"
    UPDATE scheduled_visits SET activity_id = 'e0bf187e-56cb-4701-afc7-39f130c36f12' WHERE activity_id = '033a07d3-4419-4b14-a33a-305c122ffd00';
    UPDATE activity_category_links SET activity_id = 'e0bf187e-56cb-4701-afc7-39f130c36f12' WHERE activity_id = '033a07d3-4419-4b14-a33a-305c122ffd00';
    DELETE FROM activities WHERE id = '033a07d3-4419-4b14-a33a-305c122ffd00';

    -- 4. Robotic Gardening: Keep "Robotic Gardening Session", remove "Robotic Gardening"
    UPDATE scheduled_visits SET activity_id = '9bff5d1a-3c59-409d-a692-b055431aead5' WHERE activity_id = 'fcebee64-16c0-4189-9ec6-e2c008232f0e';
    UPDATE activity_category_links SET activity_id = '9bff5d1a-3c59-409d-a692-b055431aead5' WHERE activity_id = 'fcebee64-16c0-4189-9ec6-e2c008232f0e';
    DELETE FROM activities WHERE id = 'fcebee64-16c0-4189-9ec6-e2c008232f0e';

    -- 5. Wattle & Daub: Keep "Wattle & Daub Construction Workshop", remove "Wattle and Daub Construction"
    UPDATE scheduled_visits SET activity_id = '579e5d67-5afb-4975-a26f-6b8ee1b85136' WHERE activity_id = '3c597730-cd83-45f8-bef2-4842e9ebac4f';
    UPDATE activity_category_links SET activity_id = '579e5d67-5afb-4975-a26f-6b8ee1b85136' WHERE activity_id = '3c597730-cd83-45f8-bef2-4842e9ebac4f';
    DELETE FROM activities WHERE id = '3c597730-cd83-45f8-bef2-4842e9ebac4f';

    RAISE NOTICE 'Successfully removed 5 duplicate activities';
END $$;

-- Verify no duplicates remain
SELECT title, COUNT(*) as count
FROM activities
GROUP BY title
HAVING COUNT(*) > 1;

-- Show remaining activities count
SELECT COUNT(*) as total_activities FROM activities;
