-- ============================================================================
-- SAFE MIGRATION: Add Account & GREENS System to Existing Database
-- This script safely adds/modifies tables without destroying existing data
-- Run check-current-schema.sql FIRST to see what will be changed
-- ============================================================================

\echo '===================================================================================='
\echo 'STARTING SAFE MIGRATION TO ACCOUNTS & GREENS SYSTEM'
\echo '===================================================================================='
\echo ''

-- ============================================================================
-- 1. MIGRATE PROFILES TABLE
-- ============================================================================
\echo '1. Migrating profiles table...'

-- Add missing columns to profiles table (if it exists)
DO $$
BEGIN
    -- Add qr_code column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'profiles'
        AND column_name = 'qr_code'
    ) THEN
        ALTER TABLE profiles ADD COLUMN qr_code TEXT UNIQUE NOT NULL DEFAULT 'TEMP-' || gen_random_uuid()::text;
        RAISE NOTICE '✓ Added qr_code column to profiles';
    ELSE
        RAISE NOTICE '  qr_code column already exists';
    END IF;

    -- Add greens_balance column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'profiles'
        AND column_name = 'greens_balance'
    ) THEN
        ALTER TABLE profiles ADD COLUMN greens_balance DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (greens_balance >= 0);
        RAISE NOTICE '✓ Added greens_balance column to profiles';
    ELSE
        RAISE NOTICE '  greens_balance column already exists';
    END IF;

    -- Add account_status column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'profiles'
        AND column_name = 'account_status'
    ) THEN
        ALTER TABLE profiles ADD COLUMN account_status TEXT NOT NULL DEFAULT 'active' CHECK (account_status IN ('pending', 'active', 'suspended', 'closed'));
        RAISE NOTICE '✓ Added account_status column to profiles';
    ELSE
        RAISE NOTICE '  account_status column already exists';
    END IF;

    -- Add activated_at column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'profiles'
        AND column_name = 'activated_at'
    ) THEN
        ALTER TABLE profiles ADD COLUMN activated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
        RAISE NOTICE '✓ Added activated_at column to profiles';
    ELSE
        RAISE NOTICE '  activated_at column already exists';
    END IF;

    -- Add last_login_at column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'profiles'
        AND column_name = 'last_login_at'
    ) THEN
        ALTER TABLE profiles ADD COLUMN last_login_at TIMESTAMP WITH TIME ZONE;
        RAISE NOTICE '✓ Added last_login_at column to profiles';
    ELSE
        RAISE NOTICE '  last_login_at column already exists';
    END IF;

    -- Ensure first_name column exists
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'profiles'
        AND column_name = 'first_name'
    ) THEN
        ALTER TABLE profiles ADD COLUMN first_name TEXT NOT NULL DEFAULT 'Unknown';
        RAISE NOTICE '✓ Added first_name column to profiles';
    ELSE
        RAISE NOTICE '  first_name column already exists';
    END IF;

    -- Ensure last_name column exists
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'profiles'
        AND column_name = 'last_name'
    ) THEN
        ALTER TABLE profiles ADD COLUMN last_name TEXT NOT NULL DEFAULT 'Unknown';
        RAISE NOTICE '✓ Added last_name column to profiles';
    ELSE
        RAISE NOTICE '  last_name column already exists';
    END IF;

    -- Ensure phone column exists
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'profiles'
        AND column_name = 'phone'
    ) THEN
        ALTER TABLE profiles ADD COLUMN phone TEXT;
        RAISE NOTICE '✓ Added phone column to profiles';
    ELSE
        RAISE NOTICE '  phone column already exists';
    END IF;
END $$;

-- Create indexes on profiles (only if columns exist)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'qr_code') THEN
        CREATE INDEX IF NOT EXISTS idx_profiles_qr_code ON profiles(qr_code);
        RAISE NOTICE '✓ Created index on qr_code';
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'account_status') THEN
        CREATE INDEX IF NOT EXISTS idx_profiles_status ON profiles(account_status);
        RAISE NOTICE '✓ Created index on account_status';
    END IF;

    CREATE INDEX IF NOT EXISTS idx_profiles_email ON profiles(email);
    RAISE NOTICE '✓ Created index on email';
END $$;

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_profiles_updated_at ON profiles;
CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

\echo '✓ Profiles table migration complete'
\echo ''

-- ============================================================================
-- 2. CREATE PENDING_ACCOUNTS TABLE
-- ============================================================================
\echo '2. Creating pending_accounts table...'

CREATE TABLE IF NOT EXISTS pending_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE NOT NULL,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    phone TEXT,
    qr_code TEXT UNIQUE NOT NULL,
    initial_greens_balance DECIMAL(10,2) NOT NULL DEFAULT 0,
    order_id UUID REFERENCES pumpkin_patch_orders(id),
    activation_token TEXT UNIQUE NOT NULL,
    token_expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    activated BOOLEAN NOT NULL DEFAULT FALSE,
    activated_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX IF NOT EXISTS idx_pending_accounts_email ON pending_accounts(email);
CREATE INDEX IF NOT EXISTS idx_pending_accounts_token ON pending_accounts(activation_token);
CREATE INDEX IF NOT EXISTS idx_pending_accounts_activated ON pending_accounts(activated);

\echo '✓ pending_accounts table created'
\echo ''

-- ============================================================================
-- 3. CREATE GREENS_TRANSACTIONS TABLE
-- ============================================================================
\echo '3. Creating greens_transactions table...'

CREATE TABLE IF NOT EXISTS greens_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    amount DECIMAL(10,2) NOT NULL,
    transaction_type TEXT NOT NULL CHECK (transaction_type IN ('purchase', 'topup', 'debit', 'refund', 'adjustment')),
    balance_before DECIMAL(10,2) NOT NULL,
    balance_after DECIMAL(10,2) NOT NULL,
    description TEXT NOT NULL,
    order_id UUID REFERENCES pumpkin_patch_orders(id),
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES profiles(id)
);

CREATE INDEX IF NOT EXISTS idx_greens_transactions_user_id ON greens_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_greens_transactions_created_at ON greens_transactions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_greens_transactions_type ON greens_transactions(transaction_type);
CREATE INDEX IF NOT EXISTS idx_greens_transactions_order_id ON greens_transactions(order_id);
CREATE INDEX IF NOT EXISTS idx_greens_transactions_user_date ON greens_transactions(user_id, created_at DESC);

\echo '✓ greens_transactions table created'
\echo ''

-- ============================================================================
-- 4. CREATE FUNCTIONS
-- ============================================================================
\echo '4. Creating functions...'

-- Generate unique QR code
CREATE OR REPLACE FUNCTION generate_unique_qr_code()
RETURNS TEXT AS $$
DECLARE
    qr_code TEXT;
    exists BOOLEAN;
BEGIN
    LOOP
        qr_code := 'AGT-' ||
                   TO_CHAR(NOW(), 'YYYYMMDD') || '-' ||
                   LPAD(FLOOR(RANDOM() * 10000)::TEXT, 4, '0');

        SELECT EXISTS(
            SELECT 1 FROM profiles WHERE qr_code = qr_code
            UNION
            SELECT 1 FROM pending_accounts WHERE qr_code = qr_code
        ) INTO exists;

        EXIT WHEN NOT exists;
    END LOOP;

    RETURN qr_code;
END;
$$ LANGUAGE plpgsql;

\echo '✓ generate_unique_qr_code function created'

-- Create GREENS transaction
CREATE OR REPLACE FUNCTION create_greens_transaction(
    p_user_id UUID,
    p_amount DECIMAL,
    p_transaction_type TEXT,
    p_description TEXT,
    p_order_id UUID DEFAULT NULL,
    p_metadata JSONB DEFAULT NULL,
    p_created_by UUID DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_transaction_id UUID;
    v_balance_before DECIMAL;
    v_balance_after DECIMAL;
BEGIN
    SELECT greens_balance INTO v_balance_before
    FROM profiles
    WHERE id = p_user_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'User not found: %', p_user_id;
    END IF;

    v_balance_after := v_balance_before + p_amount;

    IF v_balance_after < 0 THEN
        RAISE EXCEPTION 'Insufficient GREENS balance. Current: %, Required: %',
            v_balance_before, ABS(p_amount);
    END IF;

    INSERT INTO greens_transactions (
        user_id, amount, transaction_type, balance_before, balance_after,
        description, order_id, metadata, created_by
    ) VALUES (
        p_user_id, p_amount, p_transaction_type, v_balance_before, v_balance_after,
        p_description, p_order_id, p_metadata, p_created_by
    )
    RETURNING id INTO v_transaction_id;

    UPDATE profiles
    SET greens_balance = v_balance_after,
        updated_at = NOW()
    WHERE id = p_user_id;

    RETURN v_transaction_id;
END;
$$ LANGUAGE plpgsql;

\echo '✓ create_greens_transaction function created'

-- Activate pending account
CREATE OR REPLACE FUNCTION activate_pending_account(
    p_activation_token TEXT,
    p_auth_user_id UUID
)
RETURNS UUID AS $$
DECLARE
    v_pending_account RECORD;
    v_profile_id UUID;
BEGIN
    SELECT * INTO v_pending_account
    FROM pending_accounts
    WHERE activation_token = p_activation_token
        AND NOT activated
        AND token_expires_at > NOW()
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Invalid or expired activation token';
    END IF;

    INSERT INTO profiles (
        id, email, first_name, last_name, phone, qr_code,
        greens_balance, account_status, activated_at
    ) VALUES (
        p_auth_user_id,
        v_pending_account.email,
        v_pending_account.first_name,
        v_pending_account.last_name,
        v_pending_account.phone,
        v_pending_account.qr_code,
        v_pending_account.initial_greens_balance,
        'active',
        NOW()
    )
    RETURNING id INTO v_profile_id;

    IF v_pending_account.initial_greens_balance > 0 THEN
        PERFORM create_greens_transaction(
            v_profile_id,
            v_pending_account.initial_greens_balance,
            'topup',
            'Initial GREENS from order #' || COALESCE(v_pending_account.order_id::TEXT, 'unknown'),
            v_pending_account.order_id,
            jsonb_build_object('source', 'account_activation'),
            NULL
        );
    END IF;

    UPDATE pending_accounts
    SET activated = TRUE,
        activated_at = NOW()
    WHERE id = v_pending_account.id;

    RETURN v_profile_id;
END;
$$ LANGUAGE plpgsql;

\echo '✓ activate_pending_account function created'

-- Get user by QR code
CREATE OR REPLACE FUNCTION get_user_by_qr_code(p_qr_code TEXT)
RETURNS TABLE (
    id UUID,
    email TEXT,
    first_name TEXT,
    last_name TEXT,
    greens_balance DECIMAL,
    account_status TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT p.id, p.email, p.first_name, p.last_name, p.greens_balance, p.account_status
    FROM profiles p
    WHERE p.qr_code = p_qr_code
        AND p.account_status = 'active';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

\echo '✓ get_user_by_qr_code function created'

-- Get transaction history
CREATE OR REPLACE FUNCTION get_transaction_history(
    p_user_id UUID,
    p_limit INT DEFAULT 50
)
RETURNS TABLE (
    id UUID,
    amount DECIMAL,
    transaction_type TEXT,
    balance_after DECIMAL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        gt.id,
        gt.amount,
        gt.transaction_type,
        gt.balance_after,
        gt.description,
        gt.created_at
    FROM greens_transactions gt
    WHERE gt.user_id = p_user_id
    ORDER BY gt.created_at DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

\echo '✓ get_transaction_history function created'
\echo ''

-- ============================================================================
-- 5. CREATE VIEW
-- ============================================================================
\echo '5. Creating views...'

CREATE OR REPLACE VIEW user_balance_summary AS
SELECT
    p.id,
    p.email,
    p.first_name,
    p.last_name,
    p.qr_code,
    p.greens_balance AS current_balance,
    COALESCE(SUM(CASE WHEN gt.transaction_type = 'topup' THEN gt.amount ELSE 0 END), 0) AS total_topped_up,
    COALESCE(SUM(CASE WHEN gt.transaction_type = 'debit' THEN ABS(gt.amount) ELSE 0 END), 0) AS total_spent,
    COUNT(gt.id) AS transaction_count,
    p.created_at AS account_created_at,
    p.last_login_at
FROM profiles p
LEFT JOIN greens_transactions gt ON gt.user_id = p.id
WHERE p.account_status = 'active'
GROUP BY p.id, p.email, p.first_name, p.last_name, p.qr_code, p.greens_balance, p.created_at, p.last_login_at;

GRANT SELECT ON user_balance_summary TO authenticated, service_role;

\echo '✓ user_balance_summary view created'
\echo ''

-- ============================================================================
-- 6. ENABLE ROW LEVEL SECURITY
-- ============================================================================
\echo '6. Setting up Row Level Security...'

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE pending_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE greens_transactions ENABLE ROW LEVEL SECURITY;

-- Drop existing policies (if any) and recreate
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Service role has full access to profiles" ON profiles;

CREATE POLICY "Users can view own profile"
ON profiles FOR SELECT
TO authenticated
USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
ON profiles FOR UPDATE
TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

CREATE POLICY "Service role has full access to profiles"
ON profiles FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- Pending accounts policies
DROP POLICY IF EXISTS "Service role has full access to pending_accounts" ON pending_accounts;
DROP POLICY IF EXISTS "Anyone can read pending account by token" ON pending_accounts;

CREATE POLICY "Service role has full access to pending_accounts"
ON pending_accounts FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

CREATE POLICY "Anyone can read pending account by token"
ON pending_accounts FOR SELECT
TO anon, authenticated
USING (token_expires_at > NOW() AND NOT activated);

-- GREENS transactions policies
DROP POLICY IF EXISTS "Users can view own transactions" ON greens_transactions;
DROP POLICY IF EXISTS "Service role has full access to greens_transactions" ON greens_transactions;

CREATE POLICY "Users can view own transactions"
ON greens_transactions FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

CREATE POLICY "Service role has full access to greens_transactions"
ON greens_transactions FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

\echo '✓ Row Level Security policies created'
\echo ''

-- ============================================================================
-- 7. SUMMARY
-- ============================================================================
\echo '===================================================================================='
\echo 'MIGRATION COMPLETE!'
\echo '===================================================================================='
\echo ''
\echo 'Summary:'
\echo '  ✓ Profiles table migrated with new columns'
\echo '  ✓ pending_accounts table created'
\echo '  ✓ greens_transactions table created'
\echo '  ✓ All functions created'
\echo '  ✓ Views created'
\echo '  ✓ Indexes created'
\echo '  ✓ RLS policies enabled'
\echo ''
\echo 'Next steps:'
\echo '  1. Deploy Edge Functions:'
\echo '     - send-welcome-account-email'
\echo '     - send-scheduled-welcome-emails'
\echo '  2. Set up cron job for scheduled emails'
\echo '  3. Test account creation flow'
\echo ''
\echo 'For rollback, run: database/rollback-accounts-migration.sql'
\echo '===================================================================================='
