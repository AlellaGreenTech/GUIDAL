-- ============================================================================
-- DIAGNOSTIC SCRIPT: Check Current Database Schema
-- Run this FIRST to understand what already exists in your database
-- ============================================================================

\echo '===================================================================================='
\echo 'CHECKING CURRENT DATABASE SCHEMA'
\echo '===================================================================================='
\echo ''

-- ============================================================================
-- 1. CHECK PROFILES TABLE
-- ============================================================================
\echo '1. PROFILES TABLE'
\echo '----------------------------'

DO $$
BEGIN
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'profiles') THEN
        RAISE NOTICE '✓ profiles table EXISTS';
    ELSE
        RAISE NOTICE '✗ profiles table DOES NOT EXIST';
    END IF;
END $$;

\echo ''
\echo 'Current profiles table structure:'
SELECT
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'profiles'
ORDER BY ordinal_position;

\echo ''
\echo 'Profiles table indexes:'
SELECT
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename = 'profiles';

\echo ''
\echo '===================================================================================='

-- ============================================================================
-- 2. CHECK PENDING_ACCOUNTS TABLE
-- ============================================================================
\echo '2. PENDING_ACCOUNTS TABLE'
\echo '----------------------------'

DO $$
BEGIN
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'pending_accounts') THEN
        RAISE NOTICE '✓ pending_accounts table EXISTS';
    ELSE
        RAISE NOTICE '✗ pending_accounts table DOES NOT EXIST';
    END IF;
END $$;

\echo ''
\echo 'Current pending_accounts table structure:'
SELECT
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'pending_accounts'
ORDER BY ordinal_position;

\echo ''
\echo '===================================================================================='

-- ============================================================================
-- 3. CHECK GREENS_TRANSACTIONS TABLE
-- ============================================================================
\echo '3. GREENS_TRANSACTIONS TABLE'
\echo '----------------------------'

DO $$
BEGIN
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'greens_transactions') THEN
        RAISE NOTICE '✓ greens_transactions table EXISTS';
    ELSE
        RAISE NOTICE '✗ greens_transactions table DOES NOT EXIST';
    END IF;
END $$;

\echo ''
\echo 'Current greens_transactions table structure:'
SELECT
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'greens_transactions'
ORDER BY ordinal_position;

\echo ''
\echo '===================================================================================='

-- ============================================================================
-- 4. CHECK SCHEDULED_WELCOME_EMAILS TABLE
-- ============================================================================
\echo '4. SCHEDULED_WELCOME_EMAILS TABLE'
\echo '----------------------------'

DO $$
BEGIN
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'scheduled_welcome_emails') THEN
        RAISE NOTICE '✓ scheduled_welcome_emails table EXISTS';
    ELSE
        RAISE NOTICE '✗ scheduled_welcome_emails table DOES NOT EXIST';
    END IF;
END $$;

\echo ''
\echo 'Current scheduled_welcome_emails table structure:'
SELECT
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'scheduled_welcome_emails'
ORDER BY ordinal_position;

\echo ''
\echo '===================================================================================='

-- ============================================================================
-- 5. CHECK FUNCTIONS
-- ============================================================================
\echo '5. RELEVANT FUNCTIONS'
\echo '----------------------------'

SELECT
    routine_name,
    routine_type
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name IN (
    'generate_unique_qr_code',
    'create_greens_transaction',
    'activate_pending_account',
    'get_user_by_qr_code',
    'get_transaction_history',
    'update_updated_at_column'
  )
ORDER BY routine_name;

\echo ''
\echo '===================================================================================='

-- ============================================================================
-- 6. CHECK TRIGGERS
-- ============================================================================
\echo '6. TRIGGERS ON PROFILES TABLE'
\echo '----------------------------'

SELECT
    trigger_name,
    event_manipulation,
    action_timing
FROM information_schema.triggers
WHERE event_object_schema = 'public'
  AND event_object_table = 'profiles'
ORDER BY trigger_name;

\echo ''
\echo '===================================================================================='

-- ============================================================================
-- 7. CHECK RLS POLICIES
-- ============================================================================
\echo '7. ROW LEVEL SECURITY POLICIES'
\echo '----------------------------'

SELECT
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN ('profiles', 'pending_accounts', 'greens_transactions')
ORDER BY tablename, policyname;

\echo ''
\echo '===================================================================================='

-- ============================================================================
-- 8. CHECK VIEWS
-- ============================================================================
\echo '8. RELEVANT VIEWS'
\echo '----------------------------'

SELECT
    table_name,
    view_definition
FROM information_schema.views
WHERE table_schema = 'public'
  AND table_name = 'user_balance_summary';

\echo ''
\echo '===================================================================================='

-- ============================================================================
-- 9. SUMMARY
-- ============================================================================
\echo '9. SUMMARY'
\echo '----------------------------'

DO $$
DECLARE
    profiles_exists BOOLEAN;
    pending_accounts_exists BOOLEAN;
    greens_transactions_exists BOOLEAN;
    scheduled_emails_exists BOOLEAN;
BEGIN
    SELECT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'profiles') INTO profiles_exists;
    SELECT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'pending_accounts') INTO pending_accounts_exists;
    SELECT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'greens_transactions') INTO greens_transactions_exists;
    SELECT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'scheduled_welcome_emails') INTO scheduled_emails_exists;

    RAISE NOTICE '';
    RAISE NOTICE 'TABLES STATUS:';
    RAISE NOTICE '  profiles: %', CASE WHEN profiles_exists THEN '✓ EXISTS' ELSE '✗ MISSING' END;
    RAISE NOTICE '  pending_accounts: %', CASE WHEN pending_accounts_exists THEN '✓ EXISTS' ELSE '✗ MISSING' END;
    RAISE NOTICE '  greens_transactions: %', CASE WHEN greens_transactions_exists THEN '✓ EXISTS' ELSE '✗ MISSING' END;
    RAISE NOTICE '  scheduled_welcome_emails: %', CASE WHEN scheduled_emails_exists THEN '✓ EXISTS' ELSE '✗ MISSING' END;
    RAISE NOTICE '';

    IF profiles_exists AND NOT pending_accounts_exists THEN
        RAISE NOTICE 'RECOMMENDATION: Run migrate-to-accounts-system.sql to add missing tables and columns';
    ELSIF NOT profiles_exists THEN
        RAISE NOTICE 'RECOMMENDATION: Run create-accounts-and-greens-system.sql (clean install)';
    ELSIF profiles_exists AND pending_accounts_exists AND greens_transactions_exists THEN
        RAISE NOTICE 'RECOMMENDATION: System appears complete. Check column differences above.';
    END IF;
END $$;

\echo ''
\echo '===================================================================================='
\echo 'DIAGNOSTIC COMPLETE'
\echo 'Review the output above to understand your current schema.'
\echo 'Then run the appropriate migration script.'
\echo '===================================================================================='
