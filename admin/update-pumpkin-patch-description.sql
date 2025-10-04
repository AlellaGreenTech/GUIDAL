-- Update SCARY PUMPKIN PATCH description to show date range
-- Run this in Supabase SQL Editor

UPDATE scheduled_visits
SET description = 'Pick your own pumpkin at our SCARY PUMPKIN PATCH! Your terrifying kids can come select their orange beauty - if our monsters let them! Also enjoy playing on our natural grass soccer field and pizza and drinks. Available October 10-31 by prior appointment. Join the WhatsApp group for all the info!: https://chat.whatsapp.com/GYQmIVwu3fID0VcW4QmUM2'
WHERE title LIKE '%SCARY PUMPKIN PATCH%';
