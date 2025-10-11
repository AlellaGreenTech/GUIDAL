-- Check actual QR codes in the database
SELECT
    id,
    order_number,
    guest_name,
    qr_code,
    LENGTH(qr_code) as qr_length,
    status,
    credit_balance
FROM guest_credits
ORDER BY created_at DESC
LIMIT 5;

-- Check if QR codes are stored in uppercase or mixed case
SELECT
    qr_code as original,
    UPPER(qr_code) as uppercased,
    CASE WHEN qr_code = UPPER(qr_code) THEN 'ALREADY UPPERCASE' ELSE 'MIXED CASE' END as case_status
FROM guest_credits
LIMIT 3;
