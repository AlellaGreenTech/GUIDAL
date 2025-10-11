-- Check the exact QR code for order PP-20251010-007
SELECT
    order_number,
    guest_name,
    qr_code,
    LENGTH(qr_code) as qr_length,
    status,
    credit_balance
FROM guest_credits
WHERE order_number = 'PP-20251010-007';

-- Also check what QR codes start with 'ORDER:PP-20251010-007'
SELECT
    order_number,
    LEFT(qr_code, 80) as qr_preview,
    status,
    credit_balance
FROM guest_credits
WHERE qr_code LIKE 'ORDER:PP-20251010-007%';

-- Check if the issue is case sensitivity
SELECT
    order_number,
    qr_code,
    status
FROM guest_credits
WHERE UPPER(qr_code) LIKE '%PP-20251010-007%';
