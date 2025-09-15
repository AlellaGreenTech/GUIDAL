-- Manually confirm email for testing purposes
-- Run this in your Supabase SQL editor to bypass email confirmation

UPDATE auth.users
SET
  email_confirmed_at = NOW(),
  confirmed_at = NOW()
WHERE email = 'mwpicard@gmail.com';

-- Verify the update
SELECT
  id,
  email,
  email_confirmed_at,
  confirmed_at,
  raw_user_meta_data->>'full_name' as full_name
FROM auth.users
WHERE email = 'mwpicard@gmail.com';