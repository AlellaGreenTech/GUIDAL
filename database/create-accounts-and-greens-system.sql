-- ============================================================================
-- GUIDAL Account & GREENS System Database Schema
-- Best Practices: Foreign keys, constraints, indexes, RLS, triggers
-- ============================================================================

-- ============================================================================
-- 1. PROFILES TABLE (linked to Supabase Auth)
-- ============================================================================
CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    phone TEXT,
    qr_code TEXT UNIQUE NOT NULL,
    greens_balance DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (greens_balance >= 0),
    account_status TEXT NOT NULL DEFAULT 'pending' CHECK (account_status IN ('pending', 'active', 'suspended', 'closed')),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    activated_at TIMESTAMP WITH TIME ZONE,
    last_login_at TIMESTAMP WITH TIME ZONE
);

-- Indexes for profiles
CREATE INDEX IF NOT EXISTS idx_profiles_email ON profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_qr_code ON profiles(qr_code);
CREATE INDEX IF NOT EXISTS idx_profiles_status ON profiles(account_status);

-- Updated_at trigger for profiles
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

-- ============================================================================
-- 2. PENDING ACCOUNTS TABLE (before auth account is created)
-- ============================================================================
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

-- Indexes for pending_accounts
CREATE INDEX IF NOT EXISTS idx_pending_accounts_email ON pending_accounts(email);
CREATE INDEX IF NOT EXISTS idx_pending_accounts_token ON pending_accounts(activation_token);
CREATE INDEX IF NOT EXISTS idx_pending_accounts_activated ON pending_accounts(activated);

-- ============================================================================
-- 3. GREENS TRANSACTIONS TABLE
-- ============================================================================
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

-- Indexes for greens_transactions
CREATE INDEX IF NOT EXISTS idx_greens_transactions_user_id ON greens_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_greens_transactions_created_at ON greens_transactions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_greens_transactions_type ON greens_transactions(transaction_type);
CREATE INDEX IF NOT EXISTS idx_greens_transactions_order_id ON greens_transactions(order_id);

-- Composite index for user transaction history queries
CREATE INDEX IF NOT EXISTS idx_greens_transactions_user_date
ON greens_transactions(user_id, created_at DESC);

-- ============================================================================
-- 4. FUNCTION: Generate unique QR code
-- ============================================================================
CREATE OR REPLACE FUNCTION generate_unique_qr_code()
RETURNS TEXT AS $$
DECLARE
    qr_code TEXT;
    exists BOOLEAN;
BEGIN
    LOOP
        -- Generate QR code in format: AGT-YYYYMMDD-XXXX (where X is random)
        qr_code := 'AGT-' ||
                   TO_CHAR(NOW(), 'YYYYMMDD') || '-' ||
                   LPAD(FLOOR(RANDOM() * 10000)::TEXT, 4, '0');

        -- Check if it exists in either profiles or pending_accounts
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

-- ============================================================================
-- 5. FUNCTION: Create GREENS transaction (with balance update)
-- ============================================================================
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
    -- Get current balance
    SELECT greens_balance INTO v_balance_before
    FROM profiles
    WHERE id = p_user_id
    FOR UPDATE; -- Lock the row to prevent race conditions

    IF NOT FOUND THEN
        RAISE EXCEPTION 'User not found: %', p_user_id;
    END IF;

    -- Calculate new balance
    v_balance_after := v_balance_before + p_amount;

    -- Ensure balance doesn't go negative
    IF v_balance_after < 0 THEN
        RAISE EXCEPTION 'Insufficient GREENS balance. Current: %, Required: %',
            v_balance_before, ABS(p_amount);
    END IF;

    -- Create transaction record
    INSERT INTO greens_transactions (
        user_id, amount, transaction_type, balance_before, balance_after,
        description, order_id, metadata, created_by
    ) VALUES (
        p_user_id, p_amount, p_transaction_type, v_balance_before, v_balance_after,
        p_description, p_order_id, p_metadata, p_created_by
    )
    RETURNING id INTO v_transaction_id;

    -- Update profile balance
    UPDATE profiles
    SET greens_balance = v_balance_after,
        updated_at = NOW()
    WHERE id = p_user_id;

    RETURN v_transaction_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 6. FUNCTION: Activate pending account
-- ============================================================================
CREATE OR REPLACE FUNCTION activate_pending_account(
    p_activation_token TEXT,
    p_auth_user_id UUID
)
RETURNS UUID AS $$
DECLARE
    v_pending_account RECORD;
    v_profile_id UUID;
BEGIN
    -- Get pending account
    SELECT * INTO v_pending_account
    FROM pending_accounts
    WHERE activation_token = p_activation_token
        AND NOT activated
        AND token_expires_at > NOW()
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Invalid or expired activation token';
    END IF;

    -- Create profile
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

    -- Create initial GREENS transaction if there's a balance
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

    -- Mark pending account as activated
    UPDATE pending_accounts
    SET activated = TRUE,
        activated_at = NOW()
    WHERE id = v_pending_account.id;

    RETURN v_profile_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 7. ROW LEVEL SECURITY (RLS)
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE pending_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE greens_transactions ENABLE ROW LEVEL SECURITY;

-- Profiles policies
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
CREATE POLICY "Service role has full access to pending_accounts"
ON pending_accounts FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- Public can read pending accounts by token (for activation)
CREATE POLICY "Anyone can read pending account by token"
ON pending_accounts FOR SELECT
TO anon, authenticated
USING (token_expires_at > NOW() AND NOT activated);

-- GREENS transactions policies
CREATE POLICY "Users can view own transactions"
ON greens_transactions FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

CREATE POLICY "Service role has full access to greens_transactions"
ON greens_transactions FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- ============================================================================
-- 8. VIEWS FOR REPORTING
-- ============================================================================

-- User balance summary
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

-- Grant access to view
GRANT SELECT ON user_balance_summary TO authenticated, service_role;

-- ============================================================================
-- 9. HELPER FUNCTIONS
-- ============================================================================

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

-- ============================================================================
-- 10. VERIFICATION QUERIES
-- ============================================================================

-- Run these to verify the setup:
-- SELECT * FROM profiles LIMIT 5;
-- SELECT * FROM pending_accounts LIMIT 5;
-- SELECT * FROM greens_transactions LIMIT 5;
-- SELECT * FROM user_balance_summary LIMIT 5;
-- SELECT generate_unique_qr_code();

COMMENT ON TABLE profiles IS 'User profiles linked to Supabase Auth. Stores GREENS balance and account status.';
COMMENT ON TABLE pending_accounts IS 'Temporary storage for accounts awaiting activation via email link.';
COMMENT ON TABLE greens_transactions IS 'Complete audit trail of all GREENS transactions with balance snapshots.';
COMMENT ON FUNCTION create_greens_transaction IS 'Atomically creates transaction and updates user balance. Prevents race conditions.';
COMMENT ON FUNCTION activate_pending_account IS 'Activates pending account by creating Auth user and profile record.';
