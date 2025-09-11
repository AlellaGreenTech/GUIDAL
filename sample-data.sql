-- Sample data for GUIDAL database
-- Run this after setting up the main schema

-- Insert sample schools
INSERT INTO public.schools (name, address, contact_person, contact_email, contact_phone) VALUES
('Benjamin Franklin International School', 'Carrer de la Muntanya, 08034 Barcelona, Spain', 'Sarah Johnson', 'sarah.johnson@bfis.edu', '+34 93 203 4016'),
('St. George International School', 'Carrer de la Rabassada, 08035 Barcelona, Spain', 'Michael Thompson', 'm.thompson@stgeorge.edu', '+34 93 254 7693'),
('International Academy of Barcelona', 'Carrer del Castell, 08017 Barcelona, Spain', 'Dr. Maria Rodriguez', 'maria.rodriguez@iab.edu', '+34 93 417 5829'),
('Sant Cugat International School', 'Carrer de Vallbona, 08195 Sant Cugat del Vallès, Spain', 'James Wilson', 'j.wilson@scis.edu', '+34 93 675 8394');

-- Insert sample activities
INSERT INTO public.activities (
  title, 
  slug, 
  description, 
  activity_type_id, 
  date_time, 
  duration_minutes, 
  location,
  max_participants,
  credits_earned,
  learning_objectives,
  instructor,
  status
) VALUES 
(
  'Benjamin Franklin International School Visit',
  'benjamin-franklin-sept-2025',
  'Comprehensive sustainability workshop covering energy storage, soil management, and green construction techniques.',
  (SELECT id FROM public.activity_types WHERE slug = 'school-visits'),
  '2025-09-16 09:00:00+02',
  360,
  'Alella Green Tech Campus',
  28,
  5,
  ARRAY['Understand renewable energy storage systems', 'Learn sustainable soil management', 'Explore water conservation techniques', 'Experience natural building methods'],
  'Maria Gonzalez',
  'published'
),
(
  'St. George International School Visit',
  'st-george-sept-2025',
  'Focus on water management systems and sustainable construction. Hands-on experience with ram pumps and natural building.',
  (SELECT id FROM public.activity_types WHERE slug = 'school-visits'),
  '2025-09-17 09:30:00+02',
  300,
  'Alella Green Tech Campus',
  22,
  5,
  ARRAY['Master water management principles', 'Build working ram pump systems', 'Learn natural construction techniques', 'Apply physics to environmental solutions'],
  'Carlos Mendez',
  'published'
),
(
  'Brainstorming Lunch',
  'brainstorming-lunch-sept-2025',
  'Guest speaker session featuring our chef''s local menu and our own vino. Network with sustainability experts and innovators.',
  (SELECT id FROM public.activity_types WHERE slug = 'lunches'),
  '2025-09-20 12:00:00+02',
  180,
  'Alella Green Tech Pavilion',
  15,
  0,
  ARRAY['Network with sustainability professionals', 'Learn about local food systems', 'Discover wine and sustainability connections'],
  'Chef Antonio & Guest Speaker',
  'published'
),
(
  'Build Your Own Ram Pump Workshop',
  'ram-pump-workshop-sept-2025',
  'Hands-on workshop to construct a working ram pump system. Take home your creation and learn water hammer physics.',
  (SELECT id FROM public.activity_types WHERE slug = 'workshops'),
  '2025-09-25 10:00:00+02',
  240,
  'Workshop Building',
  12,
  3,
  ARRAY['Understand water hammer physics', 'Build functional ram pump', 'Calculate system efficiency', 'Apply engineering principles'],
  'Dr. Elena Vasquez',
  'published'
),
(
  'Sustainability Fair',
  'sustainability-fair-tbd',
  'Community fair featuring local sustainable businesses, food vendors, and interactive demonstrations of green technologies.',
  (SELECT id FROM public.activity_types WHERE slug = 'events'),
  NULL,
  480,
  'Main Campus Grounds',
  200,
  2,
  ARRAY['Explore local sustainability initiatives', 'Connect with green businesses', 'Learn about community solutions'],
  'Event Team',
  'published'
);

-- Insert school visits with access codes
INSERT INTO public.school_visits (
  activity_id,
  school_id,
  teacher_name,
  teacher_email,
  teacher_phone,
  student_count,
  grade_level,
  access_code,
  lunch_required,
  visit_coordinator
) VALUES 
(
  (SELECT id FROM public.activities WHERE slug = 'benjamin-franklin-sept-2025'),
  (SELECT id FROM public.schools WHERE name = 'Benjamin Franklin International School'),
  'Sarah Johnson',
  'sarah.johnson@bfis.edu',
  '+34 93 203 4016',
  28,
  'Grade 10-11',
  'BFI-2025-SEP',
  true,
  NULL
),
(
  (SELECT id FROM public.activities WHERE slug = 'st-george-sept-2025'),
  (SELECT id FROM public.schools WHERE name = 'St. George International School'),
  'Michael Thompson',
  'm.thompson@stgeorge.edu',
  '+34 93 254 7693',
  22,
  'Grade 9-10',
  'SGS-2025-SEP',
  true,
  NULL
);

-- Insert visit stations for Benjamin Franklin visit
INSERT INTO public.visit_stations (
  school_visit_id,
  station_name,
  start_time,
  end_time,
  instructor,
  max_students,
  learning_objectives
) VALUES 
(
  (SELECT id FROM public.school_visits WHERE access_code = 'BFI-2025-SEP'),
  'Pumped Hydro',
  '09:30',
  '10:30',
  'Maria Gonzalez',
  14,
  ARRAY['Energy storage principles', 'Gravity and water systems', 'Grid stabilization concepts']
),
(
  (SELECT id FROM public.school_visits WHERE access_code = 'BFI-2025-SEP'),
  'Composting',
  '10:45',
  '11:45',
  'Juan Carlos',
  14,
  ARRAY['Soil biology understanding', 'Composting techniques', 'Waste reduction principles']
),
(
  (SELECT id FROM public.school_visits WHERE access_code = 'BFI-2025-SEP'),
  'Ram Pumps',
  '12:00',
  '13:00',
  'Dr. Elena Vasquez',
  14,
  ARRAY['Water hammer physics', 'Pump construction', 'Energy efficiency calculations']
),
(
  (SELECT id FROM public.school_visits WHERE access_code = 'BFI-2025-SEP'),
  'Erosion Challenge',
  '14:00',
  '14:45',
  'Carlos Mendez',
  14,
  ARRAY['Landscape engineering', 'Water management', 'Natural solutions design']
);

-- Insert sample blog posts
INSERT INTO public.blog_posts (
  title,
  slug,
  excerpt,
  content,
  author_id,
  published,
  published_at,
  tags
) VALUES 
(
  'Welcome to GUIDAL: Your Gateway to Green Technology',
  'welcome-to-guidal',
  'Discover how GUIDAL is revolutionizing sustainability education through hands-on experiences and innovative technology demonstrations.',
  'Welcome to GUIDAL - the comprehensive Guide to All things sustainable at Alella Green Tech! We''re excited to launch this new platform that connects students, educators, and sustainability enthusiasts with cutting-edge green technology demonstrations...',
  NULL, -- Will need to be updated with actual author ID
  true,
  '2024-09-01 10:00:00+02',
  ARRAY['announcement', 'education', 'sustainability', 'technology']
),
(
  'The Science Behind Ram Pumps: Ancient Technology for Modern Challenges',
  'science-behind-ram-pumps',
  'Explore the fascinating physics of water hammer and how Joseph-Michel Montgolfier''s 1796 invention continues to provide sustainable water solutions today.',
  'In 1796, Joseph-Michel Montgolfier invented a remarkable device that could move water to heights much greater than its source using nothing but the energy of flowing water itself. Today, we call this ingenious device a ram pump...',
  NULL, -- Will need to be updated with actual author ID
  true,
  '2024-08-15 14:30:00+02',
  ARRAY['technology', 'water', 'physics', 'history', 'sustainability']
);

-- Insert sample products for the store
INSERT INTO public.products (
  name,
  slug,
  description,
  price,
  category,
  tags,
  stock_quantity
) VALUES 
(
  'DIY Ram Pump Kit',
  'diy-ram-pump-kit',
  'Complete kit to build your own working ram pump. Includes all pipes, valves, and detailed instructions. Perfect for students and educators.',
  89.99,
  'Educational Kits',
  ARRAY['diy', 'water', 'physics', 'educational'],
  25
),
(
  'Composting Starter Set',
  'composting-starter-set',
  'Everything you need to start composting at home. Includes thermometer, pH strips, and comprehensive guide to successful composting.',
  34.99,
  'Gardening',
  ARRAY['composting', 'gardening', 'sustainability', 'beginner'],
  40
),
(
  'Alella Green Tech T-Shirt',
  'agt-t-shirt',
  'Organic cotton t-shirt with our distinctive green logo. Comfortable and sustainable.',
  24.99,
  'Apparel',
  ARRAY['clothing', 'organic', 'logo'],
  100
),
(
  'Sustainability Workshop Guide (Digital)',
  'sustainability-workshop-guide',
  'Comprehensive digital guide for educators wanting to implement sustainability workshops. 150+ pages of activities, lesson plans, and resources.',
  19.99,
  'Educational Resources',
  ARRAY['digital', 'education', 'workshop', 'teachers'],
  999
);

-- Create a function to update user credits (referenced in the client code)
CREATE OR REPLACE FUNCTION public.update_user_credits(user_id uuid, credit_change integer)
RETURNS void AS $$
BEGIN
  UPDATE public.profiles 
  SET credits = GREATEST(0, credits + credit_change),
      updated_at = now()
  WHERE id = user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;