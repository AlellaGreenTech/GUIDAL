-- Create guest_credits table for tracking customer credit balances (money-based)
-- SCARES/GREENS = money credits that can be spent at the event (1 credit = €1)
CREATE TABLE IF NOT EXISTS guest_credits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID REFERENCES pumpkin_patch_orders(id) ON DELETE CASCADE,
    order_number TEXT NOT NULL,
    guest_name TEXT NOT NULL,
    guest_email TEXT,
    initial_credit DECIMAL(10,2) NOT NULL DEFAULT 0.00, -- Total money paid (€)
    credit_balance DECIMAL(10,2) NOT NULL DEFAULT 0.00, -- Money remaining (€) - main balance field
    qr_code TEXT NOT NULL UNIQUE, -- QR code string for scanning
    status TEXT DEFAULT 'active', -- 'active' or 'inactive'
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create index for fast QR code lookups
CREATE INDEX IF NOT EXISTS idx_guest_credits_qr_code ON guest_credits(qr_code);
CREATE INDEX IF NOT EXISTS idx_guest_credits_order_id ON guest_credits(order_id);
CREATE INDEX IF NOT EXISTS idx_guest_credits_order_number ON guest_credits(order_number);
CREATE INDEX IF NOT EXISTS idx_guest_credits_status ON guest_credits(status);

-- Create transactions table for tracking all credit deductions (money spent)
CREATE TABLE IF NOT EXISTS guest_credit_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    guest_credit_id UUID REFERENCES guest_credits(id) ON DELETE CASCADE,
    cashier_id UUID REFERENCES profiles(id),
    amount DECIMAL(10,2) NOT NULL, -- Amount spent (€)
    description TEXT,
    balance_before DECIMAL(10,2) NOT NULL,
    balance_after DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create index for fast transaction lookups
CREATE INDEX IF NOT EXISTS idx_guest_credit_transactions_guest_credit_id ON guest_credit_transactions(guest_credit_id);
CREATE INDEX IF NOT EXISTS idx_guest_credit_transactions_cashier_id ON guest_credit_transactions(cashier_id);

-- Enable RLS
ALTER TABLE guest_credits ENABLE ROW LEVEL SECURITY;
ALTER TABLE guest_credit_transactions ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Allow authenticated users to read guest_credits" ON guest_credits;
DROP POLICY IF EXISTS "Allow service role full access to guest_credits" ON guest_credits;
DROP POLICY IF EXISTS "Allow cashiers to read and update guest_credits" ON guest_credits;
DROP POLICY IF EXISTS "Allow authenticated users to read transactions" ON guest_credit_transactions;
DROP POLICY IF EXISTS "Allow service role full access to transactions" ON guest_credit_transactions;
DROP POLICY IF EXISTS "Allow cashiers to create transactions" ON guest_credit_transactions;

-- RLS Policies for guest_credits
-- Allow service role (Edge Functions) full access
CREATE POLICY "Allow service role full access to guest_credits"
ON guest_credits
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- Allow authenticated users (admins and cashiers) to read
CREATE POLICY "Allow authenticated users to read guest_credits"
ON guest_credits
FOR SELECT
TO authenticated
USING (true);

-- Allow cashiers to update credits
CREATE POLICY "Allow cashiers to read and update guest_credits"
ON guest_credits
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- RLS Policies for guest_credit_transactions
-- Allow service role (Edge Functions) full access
CREATE POLICY "Allow service role full access to transactions"
ON guest_credit_transactions
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- Allow authenticated users to read transactions
CREATE POLICY "Allow authenticated users to read transactions"
ON guest_credit_transactions
FOR SELECT
TO authenticated
USING (true);

-- Allow cashiers to create transactions
CREATE POLICY "Allow cashiers to create transactions"
ON guest_credit_transactions
FOR INSERT
TO authenticated
WITH CHECK (true);

-- Create function to automatically create guest_credits from orders
-- All purchases create credits equal to the total amount paid
CREATE OR REPLACE FUNCTION create_guest_credits_from_order()
RETURNS TRIGGER AS $$
DECLARE
    qr_data TEXT;
    adults_count INTEGER;
    children_count INTEGER;
BEGIN
    -- Calculate adults and children from items
    SELECT
        COALESCE(SUM(CASE WHEN item_name LIKE '%Adult%' THEN quantity ELSE 0 END), 0),
        COALESCE(SUM(CASE WHEN item_name LIKE '%Child%' THEN quantity ELSE 0 END), 0)
    INTO adults_count, children_count
    FROM pumpkin_patch_order_items
    WHERE order_id = NEW.id;

    -- Generate QR code data (same format as email QR codes)
    qr_data := 'ORDER:' || NEW.order_number ||
               '|NAME:' || NEW.first_name || ' ' || NEW.last_name ||
               '|ADULTS:' || adults_count ||
               '|CHILDREN:' || children_count ||
               '|EVENT:' || COALESCE(TO_CHAR(NEW.party_date, 'Mon DD'), 'Visit Pass') ||
               '|SCARES:0' ||
               '|TOTAL:€' || NEW.total_amount;

    -- Insert guest credits record with total amount as credits
    INSERT INTO guest_credits (
        order_id,
        order_number,
        guest_name,
        guest_email,
        initial_credit,
        credit_balance,
        qr_code,
        status
    ) VALUES (
        NEW.id,
        NEW.order_number,
        NEW.first_name || ' ' || NEW.last_name,
        NEW.email,
        NEW.total_amount,  -- All money paid becomes credits
        NEW.total_amount,  -- Initially no money spent
        qr_data,
        CASE WHEN NEW.payment_status = 'paid' THEN 'active' ELSE 'inactive' END
    )
    ON CONFLICT (qr_code) DO UPDATE
    SET
        initial_credit = EXCLUDED.initial_credit,
        credit_balance = guest_credits.credit_balance + (EXCLUDED.initial_credit - guest_credits.initial_credit),
        status = EXCLUDED.status,
        updated_at = NOW();

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to auto-create guest credits when order is paid
DROP TRIGGER IF EXISTS create_guest_credits_on_order_paid ON pumpkin_patch_orders;
CREATE TRIGGER create_guest_credits_on_order_paid
AFTER INSERT OR UPDATE OF payment_status
ON pumpkin_patch_orders
FOR EACH ROW
WHEN (NEW.payment_status = 'paid')
EXECUTE FUNCTION create_guest_credits_from_order();

-- Backfill existing paid orders - all paid orders get credits equal to total amount
INSERT INTO guest_credits (
    order_id,
    order_number,
    guest_name,
    guest_email,
    initial_credit,
    credit_balance,
    qr_code,
    status
)
SELECT
    o.id,
    o.order_number,
    o.first_name || ' ' || o.last_name,
    o.email,
    o.total_amount as initial_credit,
    o.total_amount as credit_balance,
    'ORDER:' || o.order_number ||
    '|NAME:' || o.first_name || ' ' || o.last_name ||
    '|ADULTS:' || COALESCE(SUM(CASE WHEN i.item_name LIKE '%Adult%' THEN i.quantity ELSE 0 END), 0) ||
    '|CHILDREN:' || COALESCE(SUM(CASE WHEN i.item_name LIKE '%Child%' THEN i.quantity ELSE 0 END), 0) ||
    '|EVENT:' || COALESCE(TO_CHAR(o.party_date, 'Mon DD'), 'Visit Pass') ||
    '|SCARES:' || FLOOR(o.total_amount) ||
    '|TOTAL:€' || o.total_amount as qr_code,
    'active'
FROM pumpkin_patch_orders o
LEFT JOIN pumpkin_patch_order_items i ON i.order_id = o.id
WHERE o.payment_status = 'paid'
GROUP BY o.id, o.order_number, o.first_name, o.last_name, o.email, o.total_amount, o.party_date
ON CONFLICT (qr_code) DO NOTHING;

-- Create RPC function to deduct credits (used by cashier app)
CREATE OR REPLACE FUNCTION deduct_credit(
    p_qr_code TEXT,
    p_amount DECIMAL(10,2),
    p_description TEXT,
    p_cashier_id UUID,
    p_location TEXT DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
    v_guest_credit guest_credits%ROWTYPE;
    v_balance_before DECIMAL(10,2);
    v_balance_after DECIMAL(10,2);
    v_transaction_id UUID;
BEGIN
    -- Get and lock the guest credit record
    SELECT * INTO v_guest_credit
    FROM guest_credits
    WHERE qr_code = p_qr_code AND status = 'active'
    FOR UPDATE;

    IF NOT FOUND THEN
        RETURN json_build_object('success', false, 'error', 'Guest credit not found or inactive');
    END IF;

    -- Check sufficient balance
    IF v_guest_credit.credit_balance < p_amount THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Insufficient credit',
            'available', v_guest_credit.credit_balance,
            'requested', p_amount
        );
    END IF;

    -- Store balances
    v_balance_before := v_guest_credit.credit_balance;
    v_balance_after := v_balance_before - p_amount;

    -- Update credit balance
    UPDATE guest_credits
    SET credit_balance = v_balance_after,
        updated_at = NOW()
    WHERE id = v_guest_credit.id;

    -- Create transaction record
    INSERT INTO guest_credit_transactions (
        guest_credit_id,
        cashier_id,
        amount,
        description,
        balance_before,
        balance_after
    ) VALUES (
        v_guest_credit.id,
        p_cashier_id,
        p_amount,
        p_description || COALESCE(' at ' || p_location, ''),
        v_balance_before,
        v_balance_after
    ) RETURNING id INTO v_transaction_id;

    -- Return success with updated balance
    RETURN json_build_object(
        'success', true,
        'transaction_id', v_transaction_id,
        'balance_before', v_balance_before,
        'balance_after', v_balance_after,
        'guest_name', v_guest_credit.guest_name
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Verify tables
SELECT 'guest_credits' as table_name, COUNT(*) as record_count FROM guest_credits
UNION ALL
SELECT 'guest_credit_transactions', COUNT(*) FROM guest_credit_transactions;
