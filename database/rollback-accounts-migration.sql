-- ============================================================================
-- ROLLBACK SCRIPT: Undo Account & GREENS System Migration
-- WARNING: This will remove all account and GREENS data!
-- Use only if you need to revert the migration
-- ============================================================================

\echo '===================================================================================='
\echo 'WARNING: ROLLBACK ACCOUNTS & GREENS SYSTEM MIGRATION'
\echo '===================================================================================='
\echo ''
\echo 'This script will:'
\echo '  - Drop greens_transactions table (and ALL transaction data)'
\echo '  - Drop pending_accounts table (and ALL pending accounts)'
\echo '  - Remove new columns from profiles table'
\echo '  - Drop related functions and views'
\echo ''
\echo 'Press Ctrl+C now to cancel, or press Enter to continue...'
\prompt 'Type YES to confirm rollback: ' confirm

DO $$
BEGIN
    IF :'confirm' != 'YES' THEN
        RAISE EXCEPTION 'Rollback cancelled by user';
    END IF;
END $$;

\echo ''
\echo 'Starting rollback...'
\echo ''

-- ============================================================================
-- 1. DROP VIEWS
-- ============================================================================
\echo '1. Dropping views...'

DROP VIEW IF EXISTS user_balance_summary CASCADE;

\echo '✓ Views dropped'
\echo ''

-- ============================================================================
-- 2. DROP FUNCTIONS
-- ============================================================================
\echo '2. Dropping functions...'

DROP FUNCTION IF EXISTS get_transaction_history(UUID, INT) CASCADE;
DROP FUNCTION IF EXISTS get_user_by_qr_code(TEXT) CASCADE;
DROP FUNCTION IF EXISTS activate_pending_account(TEXT, UUID) CASCADE;
DROP FUNCTION IF EXISTS create_greens_transaction(UUID, DECIMAL, TEXT, TEXT, UUID, JSONB, UUID) CASCADE;
DROP FUNCTION IF EXISTS generate_unique_qr_code() CASCADE;

\echo '✓ Functions dropped'
\echo ''

-- ============================================================================
-- 3. DROP TABLES
-- ============================================================================
\echo '3. Dropping tables...'

DROP TABLE IF EXISTS greens_transactions CASCADE;
\echo '  ✓ greens_transactions table dropped'

DROP TABLE IF EXISTS pending_accounts CASCADE;
\echo '  ✓ pending_accounts table dropped'

\echo ''

-- ============================================================================
-- 4. REMOVE COLUMNS FROM PROFILES
-- ============================================================================
\echo '4. Removing columns from profiles table...'

DO $$
BEGIN
    -- Drop trigger first
    DROP TRIGGER IF EXISTS update_profiles_updated_at ON profiles;
    RAISE NOTICE '  ✓ Dropped update trigger';

    -- Remove qr_code column
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'profiles'
        AND column_name = 'qr_code'
    ) THEN
        ALTER TABLE profiles DROP COLUMN IF EXISTS qr_code CASCADE;
        RAISE NOTICE '  ✓ Dropped qr_code column';
    END IF;

    -- Remove greens_balance column
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'profiles'
        AND column_name = 'greens_balance'
    ) THEN
        ALTER TABLE profiles DROP COLUMN IF EXISTS greens_balance CASCADE;
        RAISE NOTICE '  ✓ Dropped greens_balance column';
    END IF;

    -- Remove account_status column
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'profiles'
        AND column_name = 'account_status'
    ) THEN
        ALTER TABLE profiles DROP COLUMN IF EXISTS account_status CASCADE;
        RAISE NOTICE '  ✓ Dropped account_status column';
    END IF;

    -- Remove activated_at column
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'profiles'
        AND column_name = 'activated_at'
    ) THEN
        ALTER TABLE profiles DROP COLUMN IF EXISTS activated_at CASCADE;
        RAISE NOTICE '  ✓ Dropped activated_at column';
    END IF;

    -- Remove last_login_at column
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'profiles'
        AND column_name = 'last_login_at'
    ) THEN
        ALTER TABLE profiles DROP COLUMN IF EXISTS last_login_at CASCADE;
        RAISE NOTICE '  ✓ Dropped last_login_at column';
    END IF;
END $$;

\echo ''

-- ============================================================================
-- 5. DROP INDEXES (if they still exist)
-- ============================================================================
\echo '5. Dropping indexes...'

DROP INDEX IF EXISTS idx_profiles_qr_code;
DROP INDEX IF EXISTS idx_profiles_status;
DROP INDEX IF EXISTS idx_pending_accounts_email;
DROP INDEX IF EXISTS idx_pending_accounts_token;
DROP INDEX IF EXISTS idx_pending_accounts_activated;
DROP INDEX IF EXISTS idx_greens_transactions_user_id;
DROP INDEX IF EXISTS idx_greens_transactions_created_at;
DROP INDEX IF EXISTS idx_greens_transactions_type;
DROP INDEX IF EXISTS idx_greens_transactions_order_id;
DROP INDEX IF EXISTS idx_greens_transactions_user_date;

\echo '✓ Indexes dropped'
\echo ''

-- ============================================================================
-- 6. DROP RLS POLICIES (cleanup)
-- ============================================================================
\echo '6. Cleaning up RLS policies...'

DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Service role has full access to profiles" ON profiles;
DROP POLICY IF EXISTS "Service role has full access to pending_accounts" ON pending_accounts;
DROP POLICY IF EXISTS "Anyone can read pending account by token" ON pending_accounts;
DROP POLICY IF EXISTS "Users can view own transactions" ON greens_transactions;
DROP POLICY IF EXISTS "Service role has full access to greens_transactions" ON greens_transactions;

\echo '✓ RLS policies cleaned up'
\echo ''

-- ============================================================================
-- 7. SUMMARY
-- ============================================================================
\echo '===================================================================================='
\echo 'ROLLBACK COMPLETE'
\echo '===================================================================================='
\echo ''
\echo 'The following have been removed:'
\echo '  ✓ greens_transactions table (ALL transaction data lost)'
\echo '  ✓ pending_accounts table (ALL pending accounts lost)'
\echo '  ✓ qr_code, greens_balance, account_status columns from profiles'
\echo '  ✓ activated_at, last_login_at columns from profiles'
\echo '  ✓ All related functions and views'
\echo '  ✓ All indexes and triggers'
\echo ''
\echo 'Your profiles table has been restored to its previous state.'
\echo ''
\echo 'To re-apply the migration, run:'
\echo '  database/migrate-to-accounts-system.sql'
\echo '===================================================================================='
