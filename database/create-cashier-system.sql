-- Cashier Payment System
-- Allows cashiers to scan QR codes, view credits, and process transactions

-- ============================================
-- 1. UPDATE USER ROLES TO INCLUDE CASHIER
-- ============================================

-- Update user_profiles role check to include 'cashier'
ALTER TABLE user_profiles DROP CONSTRAINT IF EXISTS user_profiles_role_check;
ALTER TABLE user_profiles
ADD CONSTRAINT user_profiles_role_check
CHECK (role IN ('user', 'staff', 'admin', 'cashier'));

-- ============================================
-- 2. GUEST CREDITS TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS guest_credits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- Guest Information
    guest_name TEXT NOT NULL,
    guest_email TEXT NOT NULL,
    guest_phone TEXT,

    -- QR Code
    qr_code TEXT UNIQUE NOT NULL, -- The actual QR code value (UUID or encoded string)
    qr_generated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Credit Balance
    credit_balance DECIMAL(10, 2) DEFAULT 0.00 NOT NULL CHECK (credit_balance >= 0),
    initial_credit DECIMAL(10, 2) DEFAULT 0.00 NOT NULL,

    -- Status
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'expired')),

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE, -- Optional expiration date

    -- Link to pumpkin patch order if applicable
    order_id UUID REFERENCES pumpkin_patch_orders(id) ON DELETE SET NULL,

    -- Notes
    notes TEXT
);

-- ============================================
-- 3. CREDIT TRANSACTIONS TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS credit_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- Link to guest credit
    guest_credit_id UUID REFERENCES guest_credits(id) ON DELETE CASCADE NOT NULL,

    -- Transaction details
    transaction_type TEXT NOT NULL CHECK (transaction_type IN ('debit', 'credit', 'refund', 'adjustment')),
    amount DECIMAL(10, 2) NOT NULL,
    balance_before DECIMAL(10, 2) NOT NULL,
    balance_after DECIMAL(10, 2) NOT NULL,

    -- What was purchased
    description TEXT NOT NULL, -- e.g., "Small Pumpkin", "Hot Dog", "Entrance Fee"

    -- Who processed it
    processed_by UUID REFERENCES auth.users(id),
    processed_by_name TEXT, -- Cached name for reporting
    processed_by_role TEXT, -- 'cashier' or 'admin'

    -- When and where
    transaction_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    location TEXT, -- e.g., "Food Stand", "Entrance", "Pumpkin Patch"

    -- Metadata
    metadata JSONB DEFAULT '{}', -- Store additional info like items purchased
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 4. PAYMENT LINK REQUESTS TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS payment_link_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- Guest info
    guest_credit_id UUID REFERENCES guest_credits(id) ON DELETE CASCADE NOT NULL,
    guest_email TEXT NOT NULL,

    -- Request details
    amount_requested DECIMAL(10, 2) NOT NULL,
    reason TEXT,

    -- Payment link
    payment_link TEXT, -- PayPal or Stripe link
    payment_status TEXT DEFAULT 'pending' CHECK (payment_status IN ('pending', 'sent', 'paid', 'failed', 'cancelled')),

    -- Who requested
    requested_by UUID REFERENCES auth.users(id),
    requested_by_name TEXT,

    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    email_sent_at TIMESTAMP WITH TIME ZONE,
    paid_at TIMESTAMP WITH TIME ZONE,

    -- Email tracking
    email_log_id UUID REFERENCES email_logs(id) ON DELETE SET NULL
);

-- ============================================
-- 5. INDEXES FOR PERFORMANCE
-- ============================================

CREATE INDEX IF NOT EXISTS idx_guest_credits_qr_code ON guest_credits(qr_code);
CREATE INDEX IF NOT EXISTS idx_guest_credits_email ON guest_credits(guest_email);
CREATE INDEX IF NOT EXISTS idx_guest_credits_status ON guest_credits(status);
CREATE INDEX IF NOT EXISTS idx_guest_credits_order_id ON guest_credits(order_id);

CREATE INDEX IF NOT EXISTS idx_credit_transactions_guest_credit_id ON credit_transactions(guest_credit_id);
CREATE INDEX IF NOT EXISTS idx_credit_transactions_processed_by ON credit_transactions(processed_by);
CREATE INDEX IF NOT EXISTS idx_credit_transactions_date ON credit_transactions(transaction_date DESC);
CREATE INDEX IF NOT EXISTS idx_credit_transactions_type ON credit_transactions(transaction_type);

CREATE INDEX IF NOT EXISTS idx_payment_link_requests_guest_credit_id ON payment_link_requests(guest_credit_id);
CREATE INDEX IF NOT EXISTS idx_payment_link_requests_status ON payment_link_requests(payment_status);

-- ============================================
-- 6. ROW LEVEL SECURITY
-- ============================================

ALTER TABLE guest_credits ENABLE ROW LEVEL SECURITY;
ALTER TABLE credit_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_link_requests ENABLE ROW LEVEL SECURITY;

-- Admins and cashiers can view all guest credits
CREATE POLICY "Admins and cashiers can view guest credits" ON guest_credits
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM user_profiles
            WHERE user_profiles.user_id = auth.uid()
            AND user_profiles.role IN ('admin', 'cashier')
        )
    );

-- Admins and cashiers can update guest credits
CREATE POLICY "Admins and cashiers can update guest credits" ON guest_credits
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM user_profiles
            WHERE user_profiles.user_id = auth.uid()
            AND user_profiles.role IN ('admin', 'cashier')
        )
    );

-- Only admins can insert guest credits
CREATE POLICY "Admins can insert guest credits" ON guest_credits
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM user_profiles
            WHERE user_profiles.user_id = auth.uid()
            AND user_profiles.role = 'admin'
        )
    );

-- Admins and cashiers can view all transactions
CREATE POLICY "Admins and cashiers can view transactions" ON credit_transactions
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM user_profiles
            WHERE user_profiles.user_id = auth.uid()
            AND user_profiles.role IN ('admin', 'cashier')
        )
    );

-- Admins and cashiers can insert transactions
CREATE POLICY "Admins and cashiers can insert transactions" ON credit_transactions
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM user_profiles
            WHERE user_profiles.user_id = auth.uid()
            AND user_profiles.role IN ('admin', 'cashier')
        )
    );

-- Payment link requests policies
CREATE POLICY "Admins and cashiers can manage payment requests" ON payment_link_requests
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM user_profiles
            WHERE user_profiles.user_id = auth.uid()
            AND user_profiles.role IN ('admin', 'cashier')
        )
    );

-- ============================================
-- 7. FUNCTIONS
-- ============================================

-- Function to generate unique QR code
CREATE OR REPLACE FUNCTION generate_qr_code()
RETURNS TEXT AS $$
BEGIN
    RETURN 'GUIDAL-' || UPPER(SUBSTRING(gen_random_uuid()::TEXT, 1, 8));
END;
$$ LANGUAGE plpgsql;

-- Function to process credit deduction
CREATE OR REPLACE FUNCTION deduct_credit(
    p_qr_code TEXT,
    p_amount DECIMAL,
    p_description TEXT,
    p_location TEXT DEFAULT NULL,
    p_metadata JSONB DEFAULT '{}'
)
RETURNS JSONB AS $$
DECLARE
    v_guest_credit_id UUID;
    v_current_balance DECIMAL;
    v_new_balance DECIMAL;
    v_transaction_id UUID;
    v_user_profile RECORD;
BEGIN
    -- Get current user profile
    SELECT id, full_name, role INTO v_user_profile
    FROM user_profiles
    WHERE user_id = auth.uid();

    -- Verify user is cashier or admin
    IF v_user_profile.role NOT IN ('admin', 'cashier') THEN
        RAISE EXCEPTION 'Unauthorized: Only cashiers and admins can process transactions';
    END IF;

    -- Get guest credit record
    SELECT id, credit_balance INTO v_guest_credit_id, v_current_balance
    FROM guest_credits
    WHERE qr_code = p_qr_code AND status = 'active'
    FOR UPDATE; -- Lock row for update

    IF v_guest_credit_id IS NULL THEN
        RAISE EXCEPTION 'QR code not found or inactive';
    END IF;

    -- Check sufficient balance
    IF v_current_balance < p_amount THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'insufficient_balance',
            'current_balance', v_current_balance,
            'requested_amount', p_amount,
            'shortfall', p_amount - v_current_balance
        );
    END IF;

    -- Calculate new balance
    v_new_balance := v_current_balance - p_amount;

    -- Update guest credit balance
    UPDATE guest_credits
    SET credit_balance = v_new_balance,
        updated_at = NOW()
    WHERE id = v_guest_credit_id;

    -- Insert transaction record
    INSERT INTO credit_transactions (
        guest_credit_id,
        transaction_type,
        amount,
        balance_before,
        balance_after,
        description,
        processed_by,
        processed_by_name,
        processed_by_role,
        location,
        metadata
    ) VALUES (
        v_guest_credit_id,
        'debit',
        p_amount,
        v_current_balance,
        v_new_balance,
        p_description,
        auth.uid(),
        v_user_profile.full_name,
        v_user_profile.role,
        p_location,
        p_metadata
    ) RETURNING id INTO v_transaction_id;

    -- Return success
    RETURN jsonb_build_object(
        'success', true,
        'transaction_id', v_transaction_id,
        'previous_balance', v_current_balance,
        'new_balance', v_new_balance,
        'amount_deducted', p_amount
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to add credit (for refunds or top-ups)
CREATE OR REPLACE FUNCTION add_credit(
    p_qr_code TEXT,
    p_amount DECIMAL,
    p_description TEXT,
    p_transaction_type TEXT DEFAULT 'credit'
)
RETURNS JSONB AS $$
DECLARE
    v_guest_credit_id UUID;
    v_current_balance DECIMAL;
    v_new_balance DECIMAL;
    v_transaction_id UUID;
    v_user_profile RECORD;
BEGIN
    -- Get current user profile
    SELECT id, full_name, role INTO v_user_profile
    FROM user_profiles
    WHERE user_id = auth.uid();

    -- Verify user is admin (only admins can add credit)
    IF v_user_profile.role != 'admin' THEN
        RAISE EXCEPTION 'Unauthorized: Only admins can add credits';
    END IF;

    -- Get guest credit record
    SELECT id, credit_balance INTO v_guest_credit_id, v_current_balance
    FROM guest_credits
    WHERE qr_code = p_qr_code AND status = 'active'
    FOR UPDATE;

    IF v_guest_credit_id IS NULL THEN
        RAISE EXCEPTION 'QR code not found or inactive';
    END IF;

    -- Calculate new balance
    v_new_balance := v_current_balance + p_amount;

    -- Update guest credit balance
    UPDATE guest_credits
    SET credit_balance = v_new_balance,
        updated_at = NOW()
    WHERE id = v_guest_credit_id;

    -- Insert transaction record
    INSERT INTO credit_transactions (
        guest_credit_id,
        transaction_type,
        amount,
        balance_before,
        balance_after,
        description,
        processed_by,
        processed_by_name,
        processed_by_role
    ) VALUES (
        v_guest_credit_id,
        p_transaction_type,
        p_amount,
        v_current_balance,
        v_new_balance,
        p_description,
        auth.uid(),
        v_user_profile.full_name,
        v_user_profile.role
    ) RETURNING id INTO v_transaction_id;

    RETURN jsonb_build_object(
        'success', true,
        'transaction_id', v_transaction_id,
        'previous_balance', v_current_balance,
        'new_balance', v_new_balance,
        'amount_added', p_amount
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 8. AUTO-UPDATE TRIGGERS
-- ============================================

CREATE TRIGGER update_guest_credits_updated_at
    BEFORE UPDATE ON guest_credits
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 9. GRANT PERMISSIONS
-- ============================================

GRANT SELECT, INSERT, UPDATE ON guest_credits TO authenticated;
GRANT SELECT, INSERT ON credit_transactions TO authenticated;
GRANT SELECT, INSERT, UPDATE ON payment_link_requests TO authenticated;

-- ============================================
-- 10. VIEWS FOR REPORTING
-- ============================================

-- View for cashiers to see guest credits
CREATE OR REPLACE VIEW cashier_guest_credits AS
SELECT
    gc.id,
    gc.qr_code,
    gc.guest_name,
    gc.guest_email,
    gc.credit_balance,
    gc.initial_credit,
    gc.status,
    gc.created_at,
    gc.expires_at,
    COUNT(ct.id) AS total_transactions,
    COALESCE(SUM(CASE WHEN ct.transaction_type = 'debit' THEN ct.amount ELSE 0 END), 0) AS total_spent
FROM guest_credits gc
LEFT JOIN credit_transactions ct ON ct.guest_credit_id = gc.id
GROUP BY gc.id, gc.qr_code, gc.guest_name, gc.guest_email, gc.credit_balance,
         gc.initial_credit, gc.status, gc.created_at, gc.expires_at
ORDER BY gc.created_at DESC;

GRANT SELECT ON cashier_guest_credits TO authenticated;

-- Verification query
SELECT
    'guest_credits' AS table_name,
    COUNT(*) AS row_count
FROM guest_credits
UNION ALL
SELECT
    'credit_transactions' AS table_name,
    COUNT(*) AS row_count
FROM credit_transactions;
