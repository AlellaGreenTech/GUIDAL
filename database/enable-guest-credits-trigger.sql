-- Enable the guest credits trigger
ALTER TABLE pumpkin_patch_orders
  ENABLE TRIGGER create_guest_credits_on_order_paid;

-- Verify it's enabled (should show tgenabled = 'O' for enabled)
SELECT
    tgname as trigger_name,
    tgenabled,
    CASE tgenabled
        WHEN 'O' THEN 'ENABLED'
        WHEN 'D' THEN 'DISABLED'
        WHEN 'A' THEN 'ALWAYS'
        ELSE 'UNKNOWN'
    END as status
FROM pg_trigger
WHERE tgname = 'create_guest_credits_on_order_paid';

-- Now backfill guest credits for existing paid orders that don't have them
-- This will create credits for all paid orders
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
LEFT JOIN guest_credits gc ON gc.order_id = o.id
WHERE o.payment_status = 'paid'
  AND gc.id IS NULL  -- Only insert if doesn't already exist
GROUP BY o.id, o.order_number, o.first_name, o.last_name, o.email, o.total_amount, o.party_date
ON CONFLICT (qr_code) DO NOTHING;

-- Show results
SELECT
    COUNT(*) as total_guest_credits,
    SUM(credit_balance) as total_credits_value
FROM guest_credits;
