-- Manually confirm the 6 users who couldn't confirm due to CORS issues
-- Run this in Supabase SQL Editor to fix their accounts

-- 1. First, let's see who we're about to confirm
SELECT
    email,
    created_at,
    'Will be confirmed' as action
FROM auth.users
WHERE email_confirmed_at IS NULL
  AND DATE(created_at) = CURRENT_DATE
ORDER BY created_at;

-- 2. Manually confirm all unconfirmed users from today
-- This sets their email as confirmed so they can login
UPDATE auth.users
SET
    email_confirmed_at = NOW(),
    updated_at = NOW()
WHERE email_confirmed_at IS NULL
  AND DATE(created_at) = CURRENT_DATE;

-- 3. Verify the fix worked
SELECT
    'Confirmation Results' as status,
    COUNT(*) as total_users_today,
    COUNT(CASE WHEN email_confirmed_at IS NOT NULL THEN 1 END) as confirmed_users,
    COUNT(CASE WHEN email_confirmed_at IS NULL THEN 1 END) as still_unconfirmed,
    ROUND(
        (COUNT(CASE WHEN email_confirmed_at IS NOT NULL THEN 1 END)::numeric /
        COUNT(*)::numeric * 100), 1
    ) as success_rate_percent
FROM auth.users
WHERE DATE(created_at) = CURRENT_DATE;

-- 4. Show the newly confirmed users
SELECT
    email,
    created_at,
    email_confirmed_at,
    'Manually confirmed due to CORS issue' as note
FROM auth.users
WHERE DATE(created_at) = CURRENT_DATE
  AND DATE(email_confirmed_at) = CURRENT_DATE
  AND email_confirmed_at > created_at + INTERVAL '1 hour'
ORDER BY email_confirmed_at DESC;