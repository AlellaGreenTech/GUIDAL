-- Delete the test user to start fresh with new email setup
-- Run this in your Supabase SQL editor

DELETE FROM auth.users
WHERE email = 'mwpicard@gmail.com';

-- Verify deletion
SELECT COUNT(*) as remaining_users
FROM auth.users
WHERE email = 'mwpicard@gmail.com';