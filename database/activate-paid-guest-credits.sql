-- Check current status of guest credits
SELECT
    gc.order_number,
    gc.guest_name,
    gc.status as credit_status,
    o.payment_status as order_payment_status,
    gc.credit_balance
FROM guest_credits gc
JOIN pumpkin_patch_orders o ON o.id = gc.order_id
ORDER BY gc.created_at DESC
LIMIT 10;

-- Update all guest credits to 'active' where the order is paid
UPDATE guest_credits gc
SET status = 'active'
FROM pumpkin_patch_orders o
WHERE gc.order_id = o.id
  AND o.payment_status = 'paid'
  AND gc.status != 'active';

-- Verify the update
SELECT
    COUNT(*) as active_credits,
    SUM(credit_balance) as total_active_balance
FROM guest_credits
WHERE status = 'active';
