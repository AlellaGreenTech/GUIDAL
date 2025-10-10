-- Migration script to update guest_credits table column names
-- This fixes the schema to match what the cashier app expects

-- First, drop the trigger and function
DROP TRIGGER IF EXISTS create_guest_credits_on_order_paid ON pumpkin_patch_orders;
DROP FUNCTION IF EXISTS create_guest_credits_from_order() CASCADE;

-- Rename columns in guest_credits table
ALTER TABLE guest_credits RENAME COLUMN qr_code_data TO qr_code;
ALTER TABLE guest_credits RENAME COLUMN initial_credits TO initial_credit;
ALTER TABLE guest_credits RENAME COLUMN remaining_credits TO credit_balance;

-- Change is_active from BOOLEAN to TEXT status
ALTER TABLE guest_credits ADD COLUMN status TEXT DEFAULT 'active';
UPDATE guest_credits SET status = CASE WHEN is_active THEN 'active' ELSE 'inactive' END;
ALTER TABLE guest_credits DROP COLUMN is_active;

-- Drop old unique constraint
ALTER TABLE guest_credits DROP CONSTRAINT IF EXISTS guest_credits_qr_code_data_key;

-- Drop old index and create new one with correct column name
DROP INDEX IF EXISTS idx_guest_credits_qr_code;
DROP INDEX IF EXISTS idx_guest_credits_qr_code_data;
CREATE UNIQUE INDEX idx_guest_credits_qr_code ON guest_credits(qr_code);
CREATE INDEX IF NOT EXISTS idx_guest_credits_status ON guest_credits(status);

-- Now recreate the trigger function with correct column names
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
               '|SCARES:' || FLOOR(NEW.total_amount) ||
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
        NEW.total_amount,
        NEW.total_amount,
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

-- Recreate trigger
CREATE TRIGGER create_guest_credits_on_order_paid
AFTER INSERT OR UPDATE OF payment_status
ON pumpkin_patch_orders
FOR EACH ROW
WHEN (NEW.payment_status = 'paid')
EXECUTE FUNCTION create_guest_credits_from_order();

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

-- Update existing QR codes to include SCARES count (only if they don't already have it)
UPDATE guest_credits gc
SET qr_code = (
    SELECT
        'ORDER:' || o.order_number ||
        '|NAME:' || o.first_name || ' ' || o.last_name ||
        '|ADULTS:' || COALESCE(SUM(CASE WHEN i.item_name LIKE '%Adult%' THEN i.quantity ELSE 0 END), 0) ||
        '|CHILDREN:' || COALESCE(SUM(CASE WHEN i.item_name LIKE '%Child%' THEN i.quantity ELSE 0 END), 0) ||
        '|EVENT:' || COALESCE(TO_CHAR(o.party_date, 'Mon DD'), 'Visit Pass') ||
        '|SCARES:' || FLOOR(o.total_amount) ||
        '|TOTAL:€' || o.total_amount
    FROM pumpkin_patch_orders o
    LEFT JOIN pumpkin_patch_order_items i ON i.order_id = o.id
    WHERE o.id = gc.order_id
    GROUP BY o.id, o.order_number, o.first_name, o.last_name, o.total_amount, o.party_date
)
WHERE order_id IS NOT NULL
AND qr_code NOT LIKE '%SCARES:%'; -- Only update if SCARES not already in QR code

-- Verify migration
SELECT
    'Migration complete' as status,
    COUNT(*) as total_credits,
    SUM(credit_balance) as total_balance
FROM guest_credits;
