-- Search for orders by customer email
-- Replace 'CUSTOMER_EMAIL_HERE' with the actual email address

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
WHERE email ILIKE '%CUSTOMER_EMAIL_HERE%'
ORDER BY created_at DESC;

-- Also check for partial email matches (in case of typos)
-- Example: if looking for john@example.com, this will find john%, %example%, etc.
