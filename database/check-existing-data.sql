-- Check what data already exists for Benjamin Franklin visit
-- Run this in your Supabase SQL editor to see existing data

-- Check schools
SELECT 'Existing schools:' as info;
SELECT id, name, contact_email FROM public.schools
WHERE name ILIKE '%benjamin%' OR name ILIKE '%bfis%';

-- Check activities
SELECT 'Existing activities:' as info;
SELECT id, title, slug, status, date_time FROM public.activities
WHERE slug = 'benjamin-franklin-sept-2025' OR title ILIKE '%benjamin%';

-- Check school visits
SELECT 'Existing school visits:' as info;
SELECT
  sv.id,
  sv.access_code,
  sv.student_count,
  sv.grade_level,
  s.name as school_name,
  a.title as activity_title
FROM public.school_visits sv
LEFT JOIN public.schools s ON sv.school_id = s.id
LEFT JOIN public.activities a ON sv.activity_id = a.id
WHERE sv.access_code = 'bfis-sept-2025' OR s.name ILIKE '%benjamin%';