-- Insert Halloween Events directly
-- Run this in Supabase SQL Editor

INSERT INTO public.scheduled_visits (
  title,
  description,
  visit_type,
  scheduled_date,
  duration_minutes,
  max_participants,
  current_participants,
  min_participants,
  booking_type,
  status
) VALUES
(
  'Halloween Party 2025 🎃👻',
  'Join us for a family-friendly Halloween celebration featuring pumpkin picking, carving, wood-fired pizza, wine tasting, and festive fun at our educational farm. Activities include: pumpkin patch, pumpkin carving, wood fire pizza, wine tasting, and Halloween parties. Family-friendly event, costumes encouraged!',
  'public_event',
  '2025-10-25T12:30:00+00:00',
  360,
  100,
  0,
  1,
  'admin_scheduled',
  'confirmed'
),
(
  'Halloween Party 2025 🎃👻',
  'Join us for a family-friendly Halloween celebration featuring pumpkin picking, carving, wood-fired pizza, wine tasting, and festive fun at our educational farm. Activities include: pumpkin patch, pumpkin carving, wood fire pizza, wine tasting, and Halloween parties. Family-friendly event, costumes encouraged!',
  'public_event',
  '2025-11-01T12:30:00+00:00',
  360,
  100,
  0,
  1,
  'admin_scheduled',
  'confirmed'
);
