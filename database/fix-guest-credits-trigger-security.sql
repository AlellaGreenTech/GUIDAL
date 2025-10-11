-- Alternative fix: Make the trigger function run with SECURITY DEFINER
-- This allows the function to bypass RLS when creating guest credits

-- Recreate the function with SECURITY DEFINER
CREATE OR REPLACE FUNCTION create_guest_credits_from_order()
RETURNS TRIGGER
SECURITY DEFINER  -- This makes the function run with the owner's privileges
SET search_path = public
AS $$
DECLARE
    adult_count INT;
    child_count INT;
    qr_data TEXT;
BEGIN
    -- Only proceed if payment_status is 'paid'
    IF NEW.payment_status != 'paid' THEN
        RETURN NEW;
    END IF;

    -- Calculate adults and children from order items
    SELECT
        COALESCE(SUM(CASE WHEN item_name LIKE '%Adult%' THEN quantity ELSE 0 END), 0),
        COALESCE(SUM(CASE WHEN item_name LIKE '%Child%' THEN quantity ELSE 0 END), 0)
    INTO adult_count, child_count
    FROM pumpkin_patch_order_items
    WHERE order_id = NEW.id;

    -- Generate QR code data
    qr_data := 'ORDER:' || NEW.order_number ||
               '|NAME:' || NEW.first_name || ' ' || NEW.last_name ||
               '|ADULTS:' || adult_count ||
               '|CHILDREN:' || child_count ||
               '|EVENT:' || COALESCE(TO_CHAR(NEW.party_date, 'Mon DD'), 'Visit Pass') ||
               '|SCARES:' || FLOOR(NEW.total_amount) ||
               '|TOTAL:€' || NEW.total_amount;

    -- Create or update guest credits
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
    VALUES (
        NEW.id,
        NEW.order_number,
        NEW.first_name || ' ' || NEW.last_name,
        NEW.email,
        NEW.total_amount,
        NEW.total_amount,
        qr_data,
        'active'
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

-- Verify the function was created with SECURITY DEFINER
SELECT proname, prosecdef
FROM pg_proc
WHERE proname = 'create_guest_credits_from_order';
