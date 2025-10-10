-- Check orders to see status vs payment_status mismatch
SELECT
    order_number,
    status,
    payment_status,
    paid_at,
    created_at
FROM pumpkin_patch_orders
WHERE payment_status = 'paid'
ORDER BY created_at DESC
LIMIT 20;

-- Count orders by status and payment_status
SELECT
    status,
    payment_status,
    COUNT(*) as count
FROM pumpkin_patch_orders
GROUP BY status, payment_status
ORDER BY status, payment_status;
