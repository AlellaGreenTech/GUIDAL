-- Insert SCARY PUMPKIN PATCH Event
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
  'SCARY PUMPKIN PATCH - Pick Your Own Pumpkin 👻🎃',
  'Pick your own pumpkin at our SCARY PUMPKIN PATCH! Your terrifying kids can come select their orange beauty - if our monsters let them! Also enjoy playing on our natural grass soccer field and pizza and drinks. Available any day in October by prior appointment. Join the WhatsApp group for all the info!: https://chat.whatsapp.com/GYQmIVwu3fID0VcW4QmUM2',
  'public_event',
  '2025-10-10T10:00:00+00:00',
  180,
  50,
  0,
  1,
  'admin_scheduled',
  'confirmed'
);
