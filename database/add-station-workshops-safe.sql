-- Add Station-Based Workshops (SAFE VERSION - handles duplicates)
-- This creates workshop versions of all stations for individual booking

-- Add workshop activities based on existing stations
INSERT INTO public.activities (
  title, slug, description, activity_type_id, date_time, duration_minutes,
  location, max_participants, credits_required, credits_earned, featured_image, status,
  learning_objectives, instructor, contact_email
) VALUES

-- Composting Workshop
(
  'Composting Workshop',
  'composting-workshop',
  'Learn the essential ingredients for good soil. Master different composting methods and create rich, fertile soil for sustainable gardening.',
  (SELECT id FROM public.activity_types WHERE slug = 'workshops'),
  '2025-10-15 10:00:00+02',
  180,
  'Composting Area',
  15,
  2,
  0,
  'images/composting-station.png',
  'published',
  ARRAY['Composting methods', 'Soil biology', 'Organic matter management', 'Sustainable gardening'],
  'Maria Santos',
  'contact@alellagreentech.com'
),

-- Erosion Challenge Workshop
(
  'Erosion Challenge Workshop',
  'erosion-challenge-workshop',
  'Stop erosion, retain water, create fertile hillsides. Master natural engineering solutions to combat soil erosion and transform barren slopes.',
  (SELECT id FROM public.activity_types WHERE slug = 'workshops'),
  '2025-10-20 10:00:00+02',
  120,
  'Hillside Demo Area',
  12,
  2,
  0,
  'images/erosion-control.png',
  'published',
  ARRAY['Erosion control', 'Water retention', 'Natural engineering', 'Slope stabilization'],
  'Dr. James Rodriguez',
  'contact@alellagreentech.com'
),

-- Planting Workshop
(
  'Planting Workshop',
  'planting-workshop',
  'Seeds being planted today! Learn optimal planting techniques, soil preparation, and sustainable growing methods for productive gardens.',
  (SELECT id FROM public.activity_types WHERE slug = 'workshops'),
  '2025-10-25 09:00:00+02',
  150,
  'Garden Beds',
  20,
  1,
  0,
  'images/school-visit-planting.png',
  'published',
  ARRAY['Planting techniques', 'Soil preparation', 'Seed selection', 'Garden planning'],
  'Elena Martinez',
  'contact@alellagreentech.com'
),

-- Pumped Hydro Workshop
(
  'Pumped Hydro Workshop',
  'pumped-hydro-workshop',
  'Electrical energy from water! Discover how pumped hydro storage systems work as the worlds largest form of grid energy storage.',
  (SELECT id FROM public.activity_types WHERE slug = 'workshops'),
  '2025-11-02 10:00:00+02',
  180,
  'Energy Systems Lab',
  10,
  3,
  0,
  'images/pumped-hydro-simulation.png',
  'published',
  ARRAY['Energy storage', 'Hydroelectric principles', 'Grid systems', 'Renewable energy'],
  'Dr. Elena Vasquez',
  'contact@alellagreentech.com'
),

-- Ram Pumps Workshop
(
  'Ram Pumps Workshop',
  'ram-pumps-workshop',
  'Move water MUCH higher with NO electrical energy! Learn Joseph-Michel Montgolfiers ingenious 1796 invention using water hammer principles.',
  (SELECT id FROM public.activity_types WHERE slug = 'workshops'),
  '2025-11-08 10:00:00+02',
  240,
  'Workshop Building',
  12,
  3,
  0,
  'images/hydraulic-ram-pump-system.png',
  'published',
  ARRAY['Water hammer physics', 'Pump construction', 'Historical engineering', 'Mechanical principles'],
  'Dr. Elena Vasquez',
  'contact@alellagreentech.com'
),

-- Robotic Gardening Workshop
(
  'Robotic Gardening Workshop',
  'robotic-gardening-workshop',
  'Tend your garden from 1,000km away! Explore automated agriculture systems with monitoring, maintenance, and harvesting capabilities.',
  (SELECT id FROM public.activity_types WHERE slug = 'workshops'),
  '2025-11-12 10:00:00+02',
  200,
  'Robotics Lab',
  8,
  4,
  0,
  'images/robotic-gardening-system.png',
  'published',
  ARRAY['Automation systems', 'Agricultural robotics', 'Remote monitoring', 'AI in farming'],
  'Alex Thompson',
  'contact@alellagreentech.com'
),

-- Wattle and Daub Workshop
(
  'Wattle and Daub Workshop',
  'wattle-daub-workshop',
  'Harvest clay, build a home with mud, hay, and sticks! Master one of humanitys oldest and most sustainable building techniques.',
  (SELECT id FROM public.activity_types WHERE slug = 'workshops'),
  '2025-11-15 09:00:00+02',
  300,
  'Construction Area',
  16,
  2,
  0,
  'images/wattle-daub-construction.png',
  'published',
  ARRAY['Traditional construction', 'Natural materials', 'Building techniques', 'Sustainable architecture'],
  'Roberto Silva',
  'contact@alellagreentech.com'
)
ON CONFLICT (slug) DO NOTHING;

-- Verify the workshop activities were created
SELECT
  title,
  slug,
  activity_type_id,
  date_time,
  max_participants,
  credits_required,
  status
FROM public.activities
WHERE slug LIKE '%-workshop'
ORDER BY date_time;