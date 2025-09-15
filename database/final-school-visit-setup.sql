-- Final setup: Add only the missing school_visits record for Benjamin Franklin
-- This assumes the activity already exists (which it does based on your duplicate error)
-- Run this in Supabase SQL editor

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
  (SELECT id FROM public.schools WHERE name ILIKE '%benjamin%' LIMIT 1),
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

-- Verify the school visit was created
SELECT
  sv.access_code,
  sv.student_count,
  sv.grade_level,
  s.name as school_name,
  a.title as activity_title,
  a.date_time
FROM public.school_visits sv
LEFT JOIN public.schools s ON sv.school_id = s.id
LEFT JOIN public.activities a ON sv.activity_id = a.id
WHERE sv.access_code = 'bfis-sept-2025';