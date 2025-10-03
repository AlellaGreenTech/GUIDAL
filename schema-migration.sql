-- Phase 3: Schema Migration - Fix Activities Data
-- Run this to properly fix the database schema

-- Step 1: Get activity type IDs
DO $$
DECLARE
    workshop_type_id UUID;
    science_stations_type_id UUID;
BEGIN
    -- Get the IDs we found earlier
    workshop_type_id := '82a8f989-ddff-495c-928a-b330e4eadd11'::uuid;
    science_stations_type_id := '9c1654b1-c897-4a7f-923d-727cdcaa181e'::uuid;

    -- Step 2: Update activity types (only templates, not scheduled activities)
    UPDATE activities
    SET activity_type_id = science_stations_type_id
    WHERE activity_type_id = workshop_type_id
    AND date_time IS NULL;

    -- Step 3: Update titles, descriptions, and images for each activity
    UPDATE activities SET
        title = 'Hydraulic Ram Pumps',
        description = 'Moving water up high without electricity! Discover genius inventions of the past that use water pressure to pump water uphill.',
        featured_image = 'images/hydraulic-ram-pump-system.png',
        slug = 'hydraulic-ram-pumps'
    WHERE title = 'Ram Pumps Workshop' AND date_time IS NULL;

    UPDATE activities SET
        title = 'Wattle & Daub Construction',
        description = 'Harvest clay, then build a home with mud, hay, and sticks - 6,000-year-old sustainable construction techniques that still work today!',
        featured_image = 'images/wattle-daub-construction.png',
        slug = 'wattle-daub-construction'
    WHERE title = 'Wattle and Daub Construction' AND date_time IS NULL;

    UPDATE activities SET
        title = 'SchoolAIR IoT Sensors',
        description = 'Build and program IoT environmental monitoring stations that collect real-time air quality and weather data.',
        featured_image = 'images/school-visit-pond-canoe.png',
        slug = 'schoolair-iot-sensors'
    WHERE title = 'SchoolAir IoT Monitoring' AND date_time IS NULL;

    UPDATE activities SET
        title = 'Composting & Soil Science',
        description = 'Discover the science of decomposition, nutrient cycles, and soil health through hands-on composting and soil analysis.',
        featured_image = 'images/composting-farm-scene.png',
        slug = 'composting-soil-science'
    WHERE title = 'Composting Workshop' AND date_time IS NULL;

    UPDATE activities SET
        title = 'Planting & Growing',
        description = 'Plant seeds, track growth, and discover the science of plant biology through hands-on gardening and data collection.',
        featured_image = 'images/school-visit-planting.png',
        slug = 'planting-growing'
    WHERE title = 'Planting Workshop' AND date_time IS NULL;

    UPDATE activities SET
        title = 'Erosion Challenge',
        description = 'Stop erosion, retain water and create a fertile hillside through natural engineering solutions and permaculture techniques.',
        featured_image = 'images/swales.jpg',
        slug = 'erosion-challenge'
    WHERE title = 'Pumped Hydro Storage' AND date_time IS NULL;

    UPDATE activities SET
        title = 'Robotic Gardening',
        description = 'Tend your garden from 1,000km away - or let the bot do it! Explore automated agriculture and precision farming with real robotic systems.',
        featured_image = 'images/robotic-gardening-system.png',
        slug = 'robotic-gardening'
    WHERE title = 'Robotic Gardening Workshop' AND date_time IS NULL;

    -- Step 4: Insert missing science stations if they don't exist
    INSERT INTO activities (
        title, slug, description, featured_image, duration_minutes, location,
        status, activity_type_id, date_time, current_participants,
        credits_required, credits_earned, price, requires_login
    )
    SELECT
        'Agricultural Drones & Vineyard',
        'agricultural-drones-vineyard',
        'Discover how drones monitor crop health, detect diseases early, and optimize vineyard management through aerial technology.',
        'images/agricultural-drone-vineyard.png',
        60,
        'Alella Green Tech Center',
        'published',
        science_stations_type_id,
        NULL,
        0, 0, 0, 0,
        false
    WHERE NOT EXISTS (
        SELECT 1 FROM activities WHERE title = 'Agricultural Drones & Vineyard'
    );

    INSERT INTO activities (
        title, slug, description, featured_image, duration_minutes, location,
        status, activity_type_id, date_time, current_participants,
        credits_required, credits_earned, price, requires_login
    )
    SELECT
        'Smart Irrigation Demo',
        'smart-irrigation-demo',
        'Visit the smartest automatic irrigation plant in the Maresme - see precision water management and automated watering systems in action.',
        'images/smart-irrigation-demo.png',
        45,
        'Alella Green Tech Center',
        'published',
        science_stations_type_id,
        NULL,
        0, 0, 0, 0,
        false
    WHERE NOT EXISTS (
        SELECT 1 FROM activities WHERE title = 'Smart Irrigation Demo'
    );

    RAISE NOTICE 'Schema migration completed successfully!';

END $$;

-- Step 5: Verify the migration worked
SELECT
    title,
    featured_image,
    activity_types.name as activity_type
FROM activities
JOIN activity_types ON activities.activity_type_id = activity_types.id
WHERE activity_types.slug = 'science-stations'
AND date_time IS NULL
ORDER BY title;