-- Check if orders exist for mwpicard@gmail.com
SELECT
    id,
    order_number,
    email,
    first_name,
    last_name,
    payment_status,
    created_at
FROM pumpkin_patch_orders
WHERE email = 'mwpicard@gmail.com'
ORDER BY created_at DESC;

-- Also check for any variations
SELECT
    email,
    COUNT(*) as order_count
FROM pumpkin_patch_orders
WHERE email ILIKE '%picard%' OR email ILIKE '%mwpicard%'
GROUP BY email;

-- Check total orders in database
SELECT COUNT(*) as total_orders FROM pumpkin_patch_orders;
