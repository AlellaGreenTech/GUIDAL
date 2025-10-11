-- Search for orders from sergiomruiz@gmail.com

SELECT
    id,
    order_number,
    first_name,
    last_name,
    email,
    phone,
    total_amount,
    payment_status,
    status,
    created_at,
    party_date
FROM pumpkin_patch_orders
WHERE email ILIKE '%sergiomruiz@gmail.com%'
ORDER BY created_at DESC;

-- Also check order items if order exists
SELECT
    o.order_number,
    o.email,
    o.created_at,
    i.item_name,
    i.quantity,
    i.total_price
FROM pumpkin_patch_orders o
LEFT JOIN pumpkin_patch_order_items i ON i.order_id = o.id
WHERE o.email ILIKE '%sergiomruiz@gmail.com%'
ORDER BY o.created_at DESC;

-- Check if guest credits were created for this customer
SELECT
    gc.order_number,
    gc.guest_name,
    gc.guest_email,
    gc.credit_balance,
    gc.status,
    gc.created_at
FROM guest_credits gc
WHERE gc.guest_email ILIKE '%sergiomruiz@gmail.com%';
