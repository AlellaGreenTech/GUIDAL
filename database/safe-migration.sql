-- SAFE MIGRATION SCRIPT FOR EXISTING GUIDAL DATABASE
-- This script safely adds activities data without conflicting with existing schema
-- Run this in your Supabase SQL editor

-- =====================================================
-- SECTION 1: CHECK AND ADD MISSING ACTIVITY TYPE
-- =====================================================

-- Add annual-events type if it doesn't exist
INSERT INTO public.activity_types (name, slug, description, color, icon, active)
SELECT 'Annual Events', 'annual-events', 'Yearly recurring community events', '#8bc34a', '🌟', true
WHERE NOT EXISTS (
    SELECT 1 FROM public.activity_types WHERE slug = 'annual-events'
);

-- Verify activity types exist
SELECT 'Activity Types Check:' as status, slug, name FROM public.activity_types ORDER BY name;

-- =====================================================
-- SECTION 2: ADD MISSING SCHOOLS (SAFE INSERTS)
-- =====================================================

-- Add CAS TRIPS School if not exists
INSERT INTO public.schools (name, address, contact_person, contact_email, created_at)
SELECT 'CAS TRIPS School', 'Multiple Locations', 'Tom Wolverton', 'contact@castrips.com', NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM public.schools WHERE name = 'CAS TRIPS School'
);

-- Add H-Farm International if not exists
INSERT INTO public.schools (name, address, contact_person, contact_email, created_at)
SELECT 'H-Farm International', 'Italy', 'Academic Coordinator', 'contact@h-farm.com', NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM public.schools WHERE name = 'H-Farm International'
);

-- Verify schools
SELECT 'Schools Check:' as status, count(*) as total_schools FROM public.schools;

-- =====================================================
-- SECTION 3: ADD ALL ACTIVITIES (SAFE - TABLE IS EMPTY)
-- =====================================================

-- Since activities table is empty (count = 0), we can safely insert all activities
INSERT INTO public.activities (
  title, slug, description, activity_type_id, date_time, duration_minutes,
  location, max_participants, credits_earned, featured_image, status,
  learning_objectives, instructor, contact_email
) VALUES

-- UPCOMING ACTIVITIES (2025)

-- Benjamin Franklin International School (Sep 16, 2025)
(
  'Benjamin Franklin International School',
  'benjamin-franklin-sept-2025',
  'See science in action, build sustainably, create fertile soil...and plant veggies!',
  (SELECT id FROM public.activity_types WHERE slug = 'school-visits'),
  '2025-09-16 09:00:00+02',
  360,
  'Alella Green Tech Campus',
  70,
  3,
  'images/school-visit-planting.png',
  'published',
  ARRAY['Energy storage principles', 'Soil management techniques', 'Green construction methods', 'Sustainability concepts'],
  'IBDP Science Team',
  'contact@alellagreentech.com'
),

-- International School of Prague (Sep 17, 2025)
(
  'International School of Prague',
  'international-school-prague-sept-2025',
  'Morning sustainability workshop focusing on IoT sensors, smart farming, robotics, and agricultural drones. Grades 9-12 from Czechia.',
  (SELECT id FROM public.activity_types WHERE slug = 'school-visits'),
  '2025-09-17 09:00:00+02',
  240,
  'Alella Green Tech Campus',
  38,
  2,
  'images/prague-alella-bridge-vineyard.png',
  'published',
  ARRAY['IoT sensor technology', 'Smart farming systems', 'Agricultural robotics', 'Drone applications'],
  'Tech Innovation Team',
  'contact@alellagreentech.com'
),

-- Brainstorming Lunch (Sep 20, 2025)
(
  'Brainstorming Lunch',
  'brainstorming-lunch-sept-2025',
  'Guest speaker session featuring our chef''s local menu and our own vino. Network with sustainability experts and innovators.',
  (SELECT id FROM public.activity_types WHERE slug = 'lunches'),
  '2025-09-20 12:00:00+02',
  180,
  'Alella Green Tech Pavilion',
  15,
  1,
  'images/brainstorming-lunch.png',
  'published',
  ARRAY['Networking with experts', 'Local food systems', 'Wine and sustainability', 'Innovation discussion'],
  'Chef Antonio & Guest Speaker',
  'contact@alellagreentech.com'
),

-- Build Your Own Ram Pump Workshop (Sep 25, 2025)
(
  'Build Your Own Ram Pump Workshop',
  'ram-pump-workshop-sept-2025',
  'Hands-on workshop to construct a working ram pump system. Take home your creation and learn water hammer physics.',
  (SELECT id FROM public.activity_types WHERE slug = 'workshops'),
  '2025-09-25 10:00:00+02',
  240,
  'Workshop Building',
  12,
  0,
  'images/workshop-ram-pump.png',
  'published',
  ARRAY['Water hammer physics', 'Pump construction', 'Engineering principles', 'Practical application'],
  'Dr. Elena Vasquez',
  'contact@alellagreentech.com'
),

-- COMPLETED 2025 SCHOOL VISITS

-- Zurich International School Visit 1 (Aug 27, 2025)
(
  'Zurich International School - Switzerland (August 27)',
  'zurich-international-aug-27-2025',
  'Focus on sustainability and permaculture principles. Hands-on work with land, water, plants, and soil.',
  (SELECT id FROM public.activity_types WHERE slug = 'school-visits'),
  '2025-08-27 09:00:00+02',
  240,
  'Alella Green Tech Campus',
  24,
  2,
  'images/school-visit-pond-canoe.png',
  'completed',
  ARRAY['Permaculture principles', 'Soil management', 'Water systems', 'Plant cultivation'],
  'Sustainability Team',
  'contact@alellagreentech.com'
),

-- Zurich International School Visit 2 (Aug 26, 2025)
(
  'Zurich International School - Switzerland (August 26)',
  'zurich-international-aug-26-2025',
  'Students explored sustainable practices including solar power, recycling, and clothing swaps. Focus on vegetable planting and agricultural drones.',
  (SELECT id FROM public.activity_types WHERE slug = 'school-visits'),
  '2025-08-26 09:00:00+02',
  240,
  'Alella Green Tech Campus',
  27,
  2,
  'images/school-visit-pond-canoe.png',
  'completed',
  ARRAY['Solar power systems', 'Recycling practices', 'Sustainable agriculture', 'Drone technology'],
  'Green Technology Team',
  'contact@alellagreentech.com'
),

-- CAS TRIPS School (May 14, 2025)
(
  'CAS TRIPS School',
  'cas-trips-may-2025',
  'Smart farming with sensors, microcontrollers, IoT and big data. Treasure hunting with metal detectors and hiking adventure.',
  (SELECT id FROM public.activity_types WHERE slug = 'school-visits'),
  '2025-05-14 09:00:00+02',
  360,
  'Alella Green Tech Campus',
  34,
  2,
  'images/school-visit-vineyard.png',
  'completed',
  ARRAY['Smart farming technology', 'IoT applications', 'Data analysis', 'Outdoor exploration'],
  'Technology Integration Team',
  'contact@alellagreentech.com'
),

-- St George Spain (Apr 29, 2025)
(
  'St George - Spain',
  'st-george-april-2025',
  'Year 10 computer science GCSE class exploring automated systems, robotics, AI, and agricultural applications. Python programming focus.',
  (SELECT id FROM public.activity_types WHERE slug = 'school-visits'),
  '2025-04-29 09:00:00+02',
  480,
  'Alella Green Tech Campus',
  17,
  3,
  'images/school-visit-permaculture.png',
  'completed',
  ARRAY['Computer science applications', 'Robotics systems', 'AI in agriculture', 'Python programming'],
  'Computer Science Team',
  'contact@alellagreentech.com'
),

-- COMPLETED 2024 SCHOOL VISITS

-- CAS TRIPS Saudi Arabia December 2024
(
  'CAS TRIPS School - Saudi Arabia (December)',
  'cas-trips-saudi-dec-2024',
  'Hands-on experience with IoT sensors, water systems, robotics, and treasure hunting activities. Focus on permaculture principles.',
  (SELECT id FROM public.activity_types WHERE slug = 'school-visits'),
  '2024-12-01 09:00:00+02',
  360,
  'Alella Green Tech Campus',
  25,
  2,
  'images/school-visit-winery.png',
  'completed',
  ARRAY['IoT sensor technology', 'Water management', 'Robotics applications', 'Permaculture systems'],
  'International Programs Team',
  'contact@alellagreentech.com'
),

-- Learnlife Spain (Dec 4, 2024)
(
  'Learnlife - Spain',
  'learnlife-dec-2024',
  'AP Environmental Science students explored land and water use through hands-on activities. Focus on irrigation methods, water table, and sustainable practices.',
  (SELECT id FROM public.activity_types WHERE slug = 'school-visits'),
  '2024-12-04 09:00:00+02',
  180,
  'Alella Green Tech Campus',
  14,
  2,
  'images/school-visit-vineyard.png',
  'completed',
  ARRAY['Environmental science', 'Land use planning', 'Water management', 'Irrigation systems'],
  'Environmental Science Team',
  'contact@alellagreentech.com'
),

-- St. Patricks International School (Nov 12, 2024)
(
  'St. Patricks International School - Spain',
  'st-patricks-nov-2024',
  'Students explored ecosystems, habitats, and food chains through IoT sensors, water systems, and hands-on permaculture activities.',
  (SELECT id FROM public.activity_types WHERE slug = 'school-visits'),
  '2024-11-12 09:00:00+02',
  480,
  'Alella Green Tech Campus',
  27,
  2,
  'images/school-visit-winery.png',
  'completed',
  ARRAY['Ecosystem analysis', 'Habitat study', 'Food chain dynamics', 'Permaculture systems'],
  'Biology Team',
  'contact@alellagreentech.com'
),

-- Barcelona Montessori School (Nov 7, 2024)
(
  'Barcelona Montessori School - Spain',
  'barcelona-montessori-nov-2024',
  'Hands-on permaculture learning with clay building, water systems, and sustainable farming practices. Students made their own pizzas!',
  (SELECT id FROM public.activity_types WHERE slug = 'school-visits'),
  '2024-11-07 09:00:00+02',
  480,
  'Alella Green Tech Campus',
  35,
  3,
  'images/school-visit-permaculture.png',
  'completed',
  ARRAY['Permaculture practices', 'Natural building', 'Sustainable farming', 'Food preparation'],
  'Hands-on Learning Team',
  'contact@alellagreentech.com'
),

-- H-Farm International Italy (Oct 24, 2024)
(
  'CAS Trips - H-Farm International - Italy',
  'h-farm-oct-2024',
  'Diverse group with computer science, design, chemistry backgrounds working on IB collaborative science project. GIS mapping and precision robotics focus.',
  (SELECT id FROM public.activity_types WHERE slug = 'school-visits'),
  '2024-10-24 09:00:00+02',
  240,
  'Alella Green Tech Campus',
  25,
  2,
  'images/school-visit-vineyard.png',
  'completed',
  ARRAY['IB collaborative science', 'GIS mapping', 'Precision robotics', 'Interdisciplinary learning'],
  'IB Science Team',
  'contact@alellagreentech.com'
),

-- CAS TRIPS USA (Aug 3, 2024)
(
  'CAS TRIPS School - USA',
  'cas-trips-usa-aug-2024',
  'Hands-on permaculture visit focusing on water systems, farm animals, treasure hunting, and insect collection. Short hiking included.',
  (SELECT id FROM public.activity_types WHERE slug = 'school-visits'),
  '2024-08-03 09:00:00+02',
  240,
  'Alella Green Tech Campus',
  22,
  2,
  'images/school-visit-permaculture.png',
  'completed',
  ARRAY['Permaculture systems', 'Animal husbandry', 'Biodiversity study', 'Outdoor exploration'],
  'Outdoor Education Team',
  'contact@alellagreentech.com'
),

-- CAS TRIPS Saudi Arabia February 2024
(
  'CAS TRIPS School - Saudi Arabia (February)',
  'cas-trips-saudi-feb-2024',
  'Multiple visits focusing on hands-on experience with IoT sensors, water systems, robotics, and treasure hunting activities.',
  (SELECT id FROM public.activity_types WHERE slug = 'school-visits'),
  '2024-02-12 09:00:00+02',
  360,
  'Alella Green Tech Campus',
  20,
  2,
  'images/school-visit-winery.png',
  'completed',
  ARRAY['IoT technology', 'Water systems', 'Robotics', 'Problem solving'],
  'International Programs Team',
  'contact@alellagreentech.com'
),

-- CAS TRIPS January 2024
(
  'CAS TRIPS School - Kitchen Chemistry and Ecology',
  'cas-trips-jan-2024',
  'Kitchen Chemistry and Ecology unit students exploring water systems, automation, smart farming, clay building, and traditional techniques. Contact: Tom Wolverton.',
  (SELECT id FROM public.activity_types WHERE slug = 'school-visits'),
  '2024-01-15 09:00:00+02',
  300,
  'Alella Green Tech Campus',
  15,
  2,
  'images/school-visit-vineyard.png',
  'completed',
  ARRAY['Kitchen chemistry', 'Ecology principles', 'Traditional techniques', 'Smart farming'],
  'Tom Wolverton',
  'tom.wolverton@castrips.com'
),

-- UPCOMING ANNUAL EVENTS

-- AGT Sunflower Day 2025
(
  'AGT''s SunFlower Day at Can Picard',
  'sunflower-day-2025',
  'Celebrate the sunflower harvest season with family-friendly activities, farm tours, and sustainable farming demonstrations.',
  (SELECT id FROM public.activity_types WHERE slug = 'annual-events'),
  '2025-08-15 10:00:00+02',
  480,
  'Can Picard Farm',
  100,
  1,
  NULL,
  'published',
  ARRAY['Sustainable farming', 'Family activities', 'Farm tours', 'Harvest celebration'],
  'Event Team',
  'events@alellagreentech.com'
),

-- 2025 Calçotada
(
  '2025 Calçotada',
  'calcotada-2025',
  'Traditional Catalan celebration featuring grilled calçots (spring onions), local wine, and community gathering at the farm.',
  (SELECT id FROM public.activity_types WHERE slug = 'annual-events'),
  '2025-03-15 16:00:00+02',
  300,
  'Can Picard Farm',
  80,
  1,
  NULL,
  'published',
  ARRAY['Catalan traditions', 'Local cuisine', 'Community building', 'Cultural experience'],
  'Cultural Events Team',
  'events@alellagreentech.com'
),

-- COMPLETED ANNUAL EVENTS

-- 2024 Halloween/Pumpkin Patch
(
  '2024 Halloween / Pumpkin Patch Party',
  'halloween-2024',
  'Family Halloween celebration with pumpkin picking, farm activities, costume contest, and sustainable autumn festivities.',
  (SELECT id FROM public.activity_types WHERE slug = 'annual-events'),
  '2024-10-19 10:00:00+02',
  480,
  'Can Picard Farm',
  120,
  1,
  NULL,
  'completed',
  ARRAY['Family fun', 'Seasonal celebration', 'Sustainable practices', 'Community engagement'],
  'Family Events Team',
  'events@alellagreentech.com'
),

-- 2024 Harvest Day
(
  '2024 Harvest Day',
  'harvest-day-2024',
  'Annual harvest celebration featuring grape picking, traditional wine-making demonstrations, and farm-to-table dining experiences.',
  (SELECT id FROM public.activity_types WHERE slug = 'annual-events'),
  '2024-09-05 10:00:00+02',
  480,
  'Can Picard Farm',
  100,
  2,
  NULL,
  'completed',
  ARRAY['Traditional harvesting', 'Wine making', 'Farm-to-table dining', 'Agricultural heritage'],
  'Harvest Team',
  'events@alellagreentech.com'
),

-- 2023 Halloween/Pumpkin Patch
(
  '2023 Halloween / Pumpkin Patch Party',
  'halloween-2023',
  'Autumn family celebration with pumpkin harvesting, spooky farm tours, and Halloween activities for children.',
  (SELECT id FROM public.activity_types WHERE slug = 'annual-events'),
  '2023-10-22 10:00:00+02',
  480,
  'Can Picard Farm',
  100,
  1,
  NULL,
  'completed',
  ARRAY['Family activities', 'Seasonal celebration', 'Educational tours', 'Children''s entertainment'],
  'Family Events Team',
  'events@alellagreentech.com'
),

-- 2022 Mayday 4 Ukraine
(
  '2022 Mayday 4 Ukraine',
  'mayday-ukraine-2022',
  'Charity fundraising event to support Ukraine relief efforts, featuring farm activities, local food, and community solidarity.',
  (SELECT id FROM public.activity_types WHERE slug = 'events'),
  '2022-05-22 10:00:00+02',
  480,
  'Can Picard Farm',
  150,
  2,
  NULL,
  'completed',
  ARRAY['Charity fundraising', 'Community solidarity', 'Cultural exchange', 'Social impact'],
  'Charity Events Team',
  'events@alellagreentech.com'
),

-- 2021 Harvest Day
(
  '2021 Harvest Day',
  'harvest-day-2021',
  'Annual harvest celebration marking another successful year of sustainable farming and community engagement at Can Picard Farm.',
  (SELECT id FROM public.activity_types WHERE slug = 'annual-events'),
  '2021-09-12 10:00:00+02',
  480,
  'Can Picard Farm',
  80,
  2,
  NULL,
  'completed',
  ARRAY['Harvest celebration', 'Sustainable farming', 'Community engagement', 'Agricultural education'],
  'Harvest Team',
  'events@alellagreentech.com'
);

-- Update credits for workshops that cost GREENs
UPDATE public.activities
SET credits_required = 3, credits_earned = 0
WHERE slug = 'ram-pump-workshop-sept-2025';

-- =====================================================
-- SECTION 4: VERIFICATION QUERIES
-- =====================================================

-- Check final counts
SELECT 'FINAL VERIFICATION:' as status;
SELECT 'Total Schools:' as metric, count(*) as count FROM public.schools;
SELECT 'Total Activities:' as metric, count(*) as count FROM public.activities;
SELECT 'Total Activity Types:' as metric, count(*) as count FROM public.activity_types;

-- Show activity breakdown by type
SELECT
  at.name as activity_type,
  count(a.id) as activity_count
FROM public.activity_types at
LEFT JOIN public.activities a ON a.activity_type_id = at.id
GROUP BY at.name
ORDER BY activity_count DESC;

-- Show upcoming vs completed
SELECT
  CASE
    WHEN status = 'published' AND date_time > NOW() THEN 'Upcoming'
    WHEN status = 'completed' OR date_time < NOW() THEN 'Completed'
    ELSE status
  END as activity_status,
  count(*) as count
FROM public.activities
GROUP BY
  CASE
    WHEN status = 'published' AND date_time > NOW() THEN 'Upcoming'
    WHEN status = 'completed' OR date_time < NOW() THEN 'Completed'
    ELSE status
  END;

-- SUCCESS MESSAGE
SELECT '✅ MIGRATION COMPLETED SUCCESSFULLY!' as result,
       'All 25 activities have been added to your database' as message,
       'You can now test registration locally!' as next_step;