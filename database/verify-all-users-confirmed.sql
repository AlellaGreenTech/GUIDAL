-- Verify all 51 users are now confirmed and can login
-- Run this to confirm the fix worked

-- 1. Updated success rate after manual confirmation
SELECT
    'Updated Launch Day Results' as summary,
    COUNT(*) as total_attempts,
    COUNT(CASE WHEN email_confirmed_at IS NOT NULL THEN 1 END) as confirmed_users,
    COUNT(CASE WHEN email_confirmed_at IS NULL THEN 1 END) as still_unconfirmed,
    ROUND(
        (COUNT(CASE WHEN email_confirmed_at IS NOT NULL THEN 1 END)::numeric /
        COUNT(*)::numeric * 100), 1
    ) as success_rate_percent
FROM auth.users
WHERE DATE(created_at) = CURRENT_DATE;

-- 2. Show recent confirmations (the ones we just fixed)
SELECT
    'Recently Confirmed Users' as category,
    COUNT(*) as count,
    MIN(email_confirmed_at) as first_confirmation,
    MAX(email_confirmed_at) as last_confirmation
FROM auth.users
WHERE DATE(created_at) = CURRENT_DATE
  AND email_confirmed_at IS NOT NULL
  AND email_confirmed_at > created_at + INTERVAL '30 minutes';

-- 3. All users from today should now be able to login
SELECT
    email,
    created_at,
    email_confirmed_at IS NOT NULL as can_login,
    CASE
        WHEN email_confirmed_at IS NOT NULL THEN '✅ Ready to login'
        ELSE '❌ Still cannot login'
    END as status
FROM auth.users
WHERE DATE(created_at) = CURRENT_DATE
ORDER BY created_at
LIMIT 10;

-- 4. Final verification - should be 0 unconfirmed users
SELECT
    CASE
        WHEN COUNT(*) = 0 THEN '🎉 SUCCESS: All users confirmed!'
        ELSE '⚠️ WARNING: ' || COUNT(*) || ' users still unconfirmed'
    END as final_status
FROM auth.users
WHERE DATE(created_at) = CURRENT_DATE
  AND email_confirmed_at IS NULL;