-- Create guest_credits table for tracking customer credit balances (money-based)
-- SCARES = money credits that can be spent at the event
CREATE TABLE IF NOT EXISTS guest_credits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID REFERENCES pumpkin_patch_orders(id) ON DELETE CASCADE,
    order_number TEXT NOT NULL,
    guest_name TEXT NOT NULL,
    guest_email TEXT,
    initial_credits DECIMAL(10,2) NOT NULL DEFAULT 0.00, -- Total money paid (€)
    remaining_credits DECIMAL(10,2) NOT NULL DEFAULT 0.00, -- Money remaining (€)
    qr_code_data TEXT NOT NULL UNIQUE,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create index for fast QR code lookups
CREATE INDEX IF NOT EXISTS idx_guest_credits_qr_code ON guest_credits(qr_code_data);
CREATE INDEX IF NOT EXISTS idx_guest_credits_order_id ON guest_credits(order_id);
CREATE INDEX IF NOT EXISTS idx_guest_credits_order_number ON guest_credits(order_number);

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
        initial_credits,
        remaining_credits,
        qr_code_data,
        is_active
    ) VALUES (
        NEW.id,
        NEW.order_number,
        NEW.first_name || ' ' || NEW.last_name,
        NEW.email,
        NEW.total_amount,  -- All money paid becomes credits
        NEW.total_amount,  -- Initially no money spent
        qr_data,
        NEW.payment_status = 'paid'
    )
    ON CONFLICT (qr_code_data) DO UPDATE
    SET
        initial_credits = EXCLUDED.initial_credits,
        remaining_credits = guest_credits.remaining_credits + (EXCLUDED.initial_credits - guest_credits.initial_credits),
        is_active = EXCLUDED.is_active,
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
    initial_credits,
    remaining_credits,
    qr_code_data,
    is_active
)
SELECT
    o.id,
    o.order_number,
    o.first_name || ' ' || o.last_name,
    o.email,
    o.total_amount as initial_credits,
    o.total_amount as remaining_credits,
    'ORDER:' || o.order_number ||
    '|NAME:' || o.first_name || ' ' || o.last_name ||
    '|ADULTS:' || COALESCE(SUM(CASE WHEN i.item_name LIKE '%Adult%' THEN i.quantity ELSE 0 END), 0) ||
    '|CHILDREN:' || COALESCE(SUM(CASE WHEN i.item_name LIKE '%Child%' THEN i.quantity ELSE 0 END), 0) ||
    '|EVENT:' || COALESCE(TO_CHAR(o.party_date, 'Mon DD'), 'Visit Pass') ||
    '|SCARES:0' ||
    '|TOTAL:€' || o.total_amount as qr_data,
    true
FROM pumpkin_patch_orders o
LEFT JOIN pumpkin_patch_order_items i ON i.order_id = o.id
WHERE o.payment_status = 'paid'
GROUP BY o.id, o.order_number, o.first_name, o.last_name, o.email, o.total_amount, o.party_date
ON CONFLICT (qr_code_data) DO NOTHING;

-- Verify tables
SELECT 'guest_credits' as table_name, COUNT(*) as record_count FROM guest_credits
UNION ALL
SELECT 'guest_credit_transactions', COUNT(*) FROM guest_credit_transactions;
