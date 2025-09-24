-- Create Workshop Activities from Science-in-Action Cards
-- Run this in Supabase SQL Editor with admin permissions

-- First, ensure we have a workshop activity type
INSERT INTO activity_types (name, slug, description, color, icon)
VALUES ('Workshop', 'workshop', 'Hands-on educational workshops', '#4CAF50', '🔬')
ON CONFLICT (slug) DO NOTHING;

-- Get the workshop activity type ID
DO $$
DECLARE
    workshop_type_id UUID;
BEGIN
    SELECT id INTO workshop_type_id FROM activity_types WHERE slug = 'workshop';

    -- Insert all workshop activities
    INSERT INTO activities (
        title,
        slug,
        description,
        activity_type_id,
        duration_minutes,
        location,
        max_participants,
        price,
        status,
        difficulty_level,
        learning_objectives
    ) VALUES
    (
        'Robotic Gardening Workshop',
        'robotic-gardening',
        'Hands-on experience with automated gardening systems, sensors, and plant care technology.',
        workshop_type_id,
        90,
        'Alella Green Tech Center',
        20,
        0,
        'published',
        'intermediate',
        ARRAY['Programming', 'Sensor Technology', 'Plant Biology', 'Automation']
    ),
    (
        'Ram Pumps Workshop',
        'ram-pumps',
        'Build and understand hydraulic ram pumps for sustainable water pumping without electricity.',
        workshop_type_id,
        120,
        'Alella Green Tech Center',
        15,
        0,
        'published',
        'intermediate',
        ARRAY['Hydraulics', 'Engineering Design', 'Sustainable Technology', 'Problem Solving']
    ),
    (
        'Wattle and Daub Construction',
        'wattle-daub',
        'Traditional building techniques using natural materials for sustainable construction.',
        workshop_type_id,
        90,
        'Alella Green Tech Center',
        25,
        0,
        'published',
        'beginner',
        ARRAY['Traditional Crafts', 'Natural Building', 'Cultural Heritage', 'Hands-on Construction']
    ),
    (
        'Erosion Challenge',
        'erosion-challenge',
        'Design and test solutions to prevent soil erosion using engineering principles.',
        workshop_type_id,
        75,
        'Alella Green Tech Center',
        20,
        0,
        'published',
        'intermediate',
        ARRAY['Engineering Design', 'Environmental Protection', 'Critical Thinking', 'Testing']
    ),
    (
        'SchoolAir IoT Monitoring',
        'schoolair-iot',
        'Build IoT sensors to monitor air quality and understand environmental data.',
        workshop_type_id,
        120,
        'Alella Green Tech Center',
        16,
        0,
        'published',
        'advanced',
        ARRAY['IoT Technology', 'Data Analysis', 'Environmental Monitoring', 'Programming']
    ),
    (
        'Composting Workshop',
        'composting',
        'Learn the science of decomposition and create sustainable waste management systems.',
        workshop_type_id,
        60,
        'Alella Green Tech Center',
        30,
        0,
        'published',
        'beginner',
        ARRAY['Waste Management', 'Biological Processes', 'Sustainability', 'Observation']
    ),
    (
        'Planting Workshop',
        'planting',
        'Hands-on gardening with focus on plant biology, growth cycles, and sustainable agriculture.',
        workshop_type_id,
        75,
        'Alella Green Tech Center',
        25,
        0,
        'published',
        'beginner',
        ARRAY['Plant Biology', 'Gardening', 'Sustainable Agriculture', 'Life Cycles']
    ),
    (
        'Pumped Hydro Storage',
        'pumped-hydro',
        'Understand energy storage systems using water and gravity for renewable energy.',
        workshop_type_id,
        90,
        'Alella Green Tech Center',
        18,
        0,
        'published',
        'advanced',
        ARRAY['Energy Systems', 'Physics Principles', 'Renewable Energy', 'Engineering Design']
    )
    ON CONFLICT (slug) DO UPDATE SET
        title = EXCLUDED.title,
        description = EXCLUDED.description,
        duration_minutes = EXCLUDED.duration_minutes,
        max_participants = EXCLUDED.max_participants,
        difficulty_level = EXCLUDED.difficulty_level,
        learning_objectives = EXCLUDED.learning_objectives,
        updated_at = NOW();

END $$;

-- Verify the workshops were created
SELECT
    title,
    slug,
    duration_minutes,
    max_participants,
    difficulty_level,
    status,
    location
FROM activities
WHERE activity_type_id = (SELECT id FROM activity_types WHERE slug = 'workshop')
ORDER BY title;

-- Show summary
SELECT
    COUNT(*) as total_workshops,
    string_agg(title, ', ') as workshop_names
FROM activities
WHERE activity_type_id = (SELECT id FROM activity_types WHERE slug = 'workshop');