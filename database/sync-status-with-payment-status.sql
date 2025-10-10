-- Fix existing orders where payment_status is 'paid' but status is still 'pending'
-- This updates the status field to match the payment_status

UPDATE pumpkin_patch_orders
SET status = 'paid'
WHERE payment_status = 'paid'
  AND status = 'pending';

-- Verify the fix
SELECT
    order_number,
    status,
    payment_status,
    paid_at,
    created_at
FROM pumpkin_patch_orders
WHERE payment_status = 'paid'
ORDER BY created_at DESC;

-- Show count after fix
SELECT
    status,
    payment_status,
    COUNT(*) as count
FROM pumpkin_patch_orders
GROUP BY status, payment_status
ORDER BY status, payment_status;
