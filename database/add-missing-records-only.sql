-- Add only the missing records for Benjamin Franklin visit
-- Skip the activity since it already exists

-- Add the school if it doesn't exist
INSERT INTO public.schools (id, name, address, contact_person, contact_email, active)
VALUES (
  '550e8400-e29b-41d4-a716-446655440001',
  'Benjamin Franklin International School',
  'Barcelona, Spain',
  'School Coordinator',
  'coordinator@bfis.edu',
  true
) ON CONFLICT (id) DO NOTHING;

-- Add the school visit record with access code (linking to existing activity)
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
  (SELECT id FROM public.activities WHERE slug = 'benjamin-franklin-sept-2025' LIMIT 1),
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

-- Verify everything is connected properly
SELECT 'Final verification:' as info;
SELECT
  sv.access_code,
  sv.student_count,
  sv.grade_level,
  s.name as school_name,
  a.title as activity_title,
  a.slug as activity_slug,
  a.date_time
FROM public.school_visits sv
JOIN public.schools s ON sv.school_id = s.id
JOIN public.activities a ON sv.activity_id = a.id
WHERE sv.access_code = 'bfis-sept-2025';