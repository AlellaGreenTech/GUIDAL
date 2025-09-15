-- Sample data for Benjamin Franklin International School visit
-- Run this in your Supabase SQL editor after running the complete schema

-- First, let's make sure we have a sample school
INSERT INTO public.schools (id, name, address, contact_person, contact_email, active)
VALUES (
  '550e8400-e29b-41d4-a716-446655440001',
  'Benjamin Franklin International School',
  'Barcelona, Spain',
  'School Coordinator',
  'coordinator@bfis.edu',
  true
) ON CONFLICT (id) DO NOTHING;

-- Create a sample activity for the school visit
INSERT INTO public.activities (id, title, slug, description, activity_type_id, date_time, location, max_participants, status, credits_earned)
VALUES (
  '550e8400-e29b-41d4-a716-446655440002',
  'Benjamin Franklin International School Visit - September 16, 2025',
  'benjamin-franklin-sept-2025',
  'Comprehensive sustainability workshop with 6 stations covering energy storage, soil management, water systems, automation, and natural construction.',
  (SELECT id FROM public.activity_types WHERE slug = 'school-visits' LIMIT 1),
  '2025-09-16 09:00:00+00',
  'Alella Green Tech Farm',
  70,
  'published',
  10
) ON CONFLICT (id) DO NOTHING;

-- Create the school visit record with access code
INSERT INTO public.school_visits (
  id,
  activity_id,
  school_id,
  teacher_name,
  teacher_email,
  teacher_phone,
  student_count,
  grade_level,
  access_code,
  special_instructions,
  lunch_required,
  transport_details,
  confirmation_sent
) VALUES (
  '550e8400-e29b-41d4-a716-446655440003',
  '550e8400-e29b-41d4-a716-446655440002',
  '550e8400-e29b-41d4-a716-446655440001',
  'BFIS Coordinator',
  'coordinator@bfis.edu',
  '+34 123 456 789',
  70,
  'Grade 11-12',
  'bfis-sept-2025',
  'Focus on IBDP Collaborative Sciences Projects. Students organized in 6 groups.',
  true,
  'Bus departure at 9:00 AM from BFIS cafeteria',
  true
) ON CONFLICT (access_code) DO NOTHING;

-- Verify the data was inserted
SELECT 'School visits data:' as info;
SELECT
  sv.access_code,
  sv.student_count,
  sv.grade_level,
  s.name as school_name,
  a.title as activity_title,
  a.date_time
FROM public.school_visits sv
JOIN public.schools s ON sv.school_id = s.id
JOIN public.activities a ON sv.activity_id = a.id
WHERE sv.access_code = 'bfis-sept-2025';