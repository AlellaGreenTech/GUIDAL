-- Check if guest_credits table has any data
SELECT COUNT(*) as total_guest_credits FROM guest_credits;

-- Check recent guest credits
SELECT
    id,
    order_number,
    guest_name,
    LEFT(qr_code, 50) as qr_code_preview,
    initial_credit,
    credit_balance,
    status,
    created_at
FROM guest_credits
ORDER BY created_at DESC
LIMIT 10;

-- Check paid orders without guest credits
SELECT
    o.id,
    o.order_number,
    o.first_name || ' ' || o.last_name as customer,
    o.payment_status,
    o.total_amount,
    o.created_at,
    CASE WHEN gc.id IS NULL THEN 'MISSING' ELSE 'EXISTS' END as has_guest_credit
FROM pumpkin_patch_orders o
LEFT JOIN guest_credits gc ON gc.order_id = o.id
WHERE o.payment_status = 'paid'
ORDER BY o.created_at DESC
LIMIT 10;

-- Check if the trigger function exists
SELECT
    proname as function_name,
    prosecdef as is_security_definer
FROM pg_proc
WHERE proname = 'create_guest_credits_from_order';

-- Check if the trigger exists
SELECT
    tgname as trigger_name,
    tgtype,
    tgenabled
FROM pg_trigger
WHERE tgname = 'create_guest_credits_on_order_paid';
