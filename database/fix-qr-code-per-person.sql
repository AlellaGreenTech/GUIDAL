-- Fix QR codes to be person-based instead of order-based
-- Multiple orders from same person should share the same QR code and credit balance

-- Drop the old trigger first
DROP TRIGGER IF EXISTS create_guest_credits_on_order_paid ON pumpkin_patch_orders;

-- Update the function to use email as the primary identifier
-- This ensures the same person always gets the same QR code
CREATE OR REPLACE FUNCTION create_guest_credits_from_order()
RETURNS TRIGGER AS $$
DECLARE
    qr_data TEXT;
    adults_count INTEGER;
    children_count INTEGER;
    existing_credit_id UUID;
BEGIN
    -- Check if a credit record already exists for this email
    SELECT id INTO existing_credit_id
    FROM guest_credits
    WHERE guest_email = NEW.email
    LIMIT 1;

    IF existing_credit_id IS NOT NULL THEN
        -- Person already has credits - just add the new order amount to their balance
        UPDATE guest_credits
        SET
            credit_balance = credit_balance + NEW.total_amount,
            initial_credit = initial_credit + NEW.total_amount,
            updated_at = NOW()
        WHERE id = existing_credit_id;

        RETURN NEW;
    END IF;

    -- New person - create their credit record
    -- Calculate adults and children from items
    SELECT
        COALESCE(SUM(CASE WHEN item_name LIKE '%Adult%' THEN quantity ELSE 0 END), 0),
        COALESCE(SUM(CASE WHEN item_name LIKE '%Child%' THEN quantity ELSE 0 END), 0)
    INTO adults_count, children_count
    FROM pumpkin_patch_order_items
    WHERE order_id = NEW.id;

    -- Generate QR code data based on EMAIL (not order number)
    -- This ensures the same person always gets the same QR code
    qr_data := 'GUEST:' || NEW.email ||
               '|NAME:' || NEW.first_name || ' ' || NEW.last_name ||
               '|ADULTS:' || adults_count ||
               '|CHILDREN:' || children_count ||
               '|EVENT:' || COALESCE(TO_CHAR(NEW.party_date, 'Mon DD'), 'Visit Pass') ||
               '|SCARES:' || FLOOR(NEW.total_amount) ||
               '|TOTAL:€' || NEW.total_amount;

    -- Insert new guest credits record
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
    );

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

-- Consolidate existing records - merge duplicate emails into one credit balance
WITH consolidated AS (
    SELECT
        guest_email,
        (ARRAY_AGG(id ORDER BY created_at ASC))[1] as keep_id,
        MAX(guest_name) as guest_name,
        SUM(initial_credit) as total_initial,
        SUM(credit_balance) as total_balance,
        MAX(status) as status
    FROM guest_credits
    WHERE guest_email IS NOT NULL
    GROUP BY guest_email
)
UPDATE guest_credits gc
SET
    initial_credit = c.total_initial,
    credit_balance = c.total_balance,
    updated_at = NOW()
FROM consolidated c
WHERE gc.id = c.keep_id;

-- Delete duplicate records (keep only the first one per email)
DELETE FROM guest_credits
WHERE id NOT IN (
    SELECT (ARRAY_AGG(id ORDER BY created_at ASC))[1]
    FROM guest_credits
    WHERE guest_email IS NOT NULL
    GROUP BY guest_email
);

-- Update QR codes to use email-based format for existing records
UPDATE guest_credits gc
SET qr_code = 'GUEST:' || gc.guest_email ||
              '|NAME:' || gc.guest_name ||
              '|BALANCE:€' || gc.credit_balance
WHERE guest_email IS NOT NULL;

-- Verify consolidation
SELECT
    'Consolidated guest credits' as status,
    COUNT(*) as unique_guests,
    SUM(credit_balance) as total_balance
FROM guest_credits;
