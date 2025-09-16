-- Simple launch day metrics - only using auth.users table
-- Run this in Supabase SQL Editor to get basic launch statistics

-- 1. Total registration attempts today
SELECT
    'Total Registration Attempts Today' as metric,
    COUNT(*) as count,
    MIN(created_at) as first_attempt,
    MAX(created_at) as last_attempt
FROM auth.users
WHERE DATE(created_at) = CURRENT_DATE;

-- 2. Success vs failure breakdown
SELECT
    'Registration Status' as category,
    CASE
        WHEN email_confirmed_at IS NOT NULL THEN 'Confirmed/Successful'
        ELSE 'Unconfirmed/Failed'
    END as status,
    COUNT(*) as count
FROM auth.users
WHERE DATE(created_at) = CURRENT_DATE
GROUP BY CASE
    WHEN email_confirmed_at IS NOT NULL THEN 'Confirmed/Successful'
    ELSE 'Unconfirmed/Failed'
END;

-- 3. Hourly registration pattern (to see when the spike/failure occurred)
SELECT
    DATE_TRUNC('hour', created_at) as hour,
    COUNT(*) as total_registrations,
    COUNT(CASE WHEN email_confirmed_at IS NOT NULL THEN 1 END) as confirmed,
    COUNT(CASE WHEN email_confirmed_at IS NULL THEN 1 END) as failed_or_pending,
    ROUND(
        (COUNT(CASE WHEN email_confirmed_at IS NOT NULL THEN 1 END)::numeric /
        COUNT(*)::numeric * 100), 1
    ) as success_rate_percent
FROM auth.users
WHERE DATE(created_at) = CURRENT_DATE
GROUP BY DATE_TRUNC('hour', created_at)
ORDER BY hour;

-- 4. Overall success rate calculation
SELECT
    'Launch Day Summary' as summary,
    COUNT(*) as total_attempts,
    COUNT(CASE WHEN email_confirmed_at IS NOT NULL THEN 1 END) as successful,
    COUNT(CASE WHEN email_confirmed_at IS NULL THEN 1 END) as failed_or_pending,
    ROUND(
        (COUNT(CASE WHEN email_confirmed_at IS NOT NULL THEN 1 END)::numeric /
        COUNT(*)::numeric * 100), 1
    ) as success_rate_percent
FROM auth.users
WHERE DATE(created_at) = CURRENT_DATE;

-- 5. All registrations today (last 10 for details)
SELECT
    email,
    created_at,
    email_confirmed_at IS NOT NULL as is_confirmed,
    last_sign_in_at IS NOT NULL as has_logged_in
FROM auth.users
WHERE DATE(created_at) = CURRENT_DATE
ORDER BY created_at DESC
LIMIT 10;