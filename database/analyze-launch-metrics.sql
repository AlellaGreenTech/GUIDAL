-- Analyze launch day metrics: registrations, failures, and successful logins
-- Run this in Supabase SQL Editor to get launch day statistics

-- 1. Total registration attempts (users created in auth.users)
SELECT
    'Total Registration Attempts' as metric,
    COUNT(*) as count,
    MIN(created_at) as first_attempt,
    MAX(created_at) as last_attempt
FROM auth.users
WHERE DATE(created_at) = CURRENT_DATE; -- Today's registrations

-- 2. Successful vs Failed registrations
SELECT
    'Registration Status' as category,
    CASE
        WHEN email_confirmed_at IS NOT NULL THEN 'Confirmed/Successful'
        ELSE 'Unconfirmed/Pending'
    END as status,
    COUNT(*) as count
FROM auth.users
WHERE DATE(created_at) = CURRENT_DATE
GROUP BY CASE
    WHEN email_confirmed_at IS NOT NULL THEN 'Confirmed/Successful'
    ELSE 'Unconfirmed/Pending'
END;

-- 3. Login attempts (successful sign-ins)
SELECT
    'Successful Logins Today' as metric,
    COUNT(*) as count,
    COUNT(DISTINCT payload->>'user_id') as unique_users
FROM auth.audit_log_entries
WHERE DATE(created_at) = CURRENT_DATE
  AND event_type ILIKE '%login%';

-- 4. Users with profiles created (successful full registration)
-- Note: This will fail if public.users table doesn't exist
SELECT
    'Complete Profiles Created' as metric,
    CASE
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users' AND table_schema = 'public')
        THEN (SELECT COUNT(*) FROM public.users WHERE DATE(created_at) = CURRENT_DATE)
        ELSE 0
    END as count;

-- 5. Recent registrations by hour (to see the spike/failure patterns)
SELECT
    DATE_TRUNC('hour', created_at) as hour,
    COUNT(*) as registrations,
    COUNT(CASE WHEN email_confirmed_at IS NOT NULL THEN 1 END) as confirmed,
    COUNT(CASE WHEN email_confirmed_at IS NULL THEN 1 END) as pending
FROM auth.users
WHERE DATE(created_at) = CURRENT_DATE
GROUP BY DATE_TRUNC('hour', created_at)
ORDER BY hour;

-- 6. Error patterns (if available in logs)
SELECT
    'Authentication Errors' as metric,
    COUNT(*) as count
FROM auth.audit_log_entries
WHERE DATE(created_at) = CURRENT_DATE
  AND event_type IN ('user_signedup_failed', 'login_failed', 'signup_failed');

-- 7. School breakdown (which schools had students register)
-- Note: This will show 0 if public.users or public.schools tables don't exist
SELECT
    'School Breakdown' as category,
    CASE
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users' AND table_schema = 'public')
             AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'schools' AND table_schema = 'public')
        THEN 'Available - run separate query'
        ELSE 'Tables not available'
    END as status;

-- 8. Summary statistics
SELECT
    'Launch Day Summary' as summary,
    (SELECT COUNT(*) FROM auth.users WHERE DATE(created_at) = CURRENT_DATE) as total_attempts,
    (SELECT COUNT(*) FROM auth.users WHERE DATE(created_at) = CURRENT_DATE AND email_confirmed_at IS NOT NULL) as successful_registrations,
    (SELECT COUNT(*) FROM public.users WHERE DATE(created_at) = CURRENT_DATE) as complete_profiles,
    ROUND(
        (SELECT COUNT(*) FROM auth.users WHERE DATE(created_at) = CURRENT_DATE AND email_confirmed_at IS NOT NULL)::float /
        NULLIF((SELECT COUNT(*) FROM auth.users WHERE DATE(created_at) = CURRENT_DATE), 0) * 100,
        2
    ) as success_rate_percent;