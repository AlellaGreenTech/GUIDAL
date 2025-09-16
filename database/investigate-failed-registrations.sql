-- Investigate the 6 unconfirmed/failed registrations
-- Run this to understand why they failed

-- 1. Look at the failed registrations in detail
SELECT
    email,
    created_at,
    email_confirmed_at,
    confirmation_sent_at,
    last_sign_in_at,
    CASE
        WHEN confirmation_sent_at IS NULL THEN 'No confirmation email sent'
        WHEN email_confirmed_at IS NULL AND confirmation_sent_at IS NOT NULL THEN 'Email sent but not confirmed'
        ELSE 'Other issue'
    END as failure_reason
FROM auth.users
WHERE DATE(created_at) = CURRENT_DATE
  AND email_confirmed_at IS NULL
ORDER BY created_at;

-- 2. Time pattern of failed vs successful registrations
SELECT
    DATE_TRUNC('hour', created_at) as hour,
    COUNT(*) as total,
    COUNT(CASE WHEN email_confirmed_at IS NOT NULL THEN 1 END) as confirmed,
    COUNT(CASE WHEN email_confirmed_at IS NULL THEN 1 END) as failed,
    STRING_AGG(
        CASE WHEN email_confirmed_at IS NULL THEN
            SUBSTRING(email FROM 1 FOR POSITION('@' IN email) - 1) || '@...'
        END,
        ', '
    ) as failed_users
FROM auth.users
WHERE DATE(created_at) = CURRENT_DATE
GROUP BY DATE_TRUNC('hour', created_at)
ORDER BY hour;

-- 3. Check if they tried to sign in anyway
SELECT
    'Failed Registration Analysis' as analysis,
    COUNT(*) as total_failed,
    COUNT(CASE WHEN last_sign_in_at IS NOT NULL THEN 1 END) as tried_to_login,
    COUNT(CASE WHEN confirmation_sent_at IS NULL THEN 1 END) as no_email_sent,
    COUNT(CASE WHEN confirmation_sent_at IS NOT NULL AND email_confirmed_at IS NULL THEN 1 END) as email_not_confirmed
FROM auth.users
WHERE DATE(created_at) = CURRENT_DATE
  AND email_confirmed_at IS NULL;