-- Check if deduct_credit function exists
SELECT
    proname as function_name,
    prosecdef as is_security_definer,
    provolatile as volatility,
    pg_get_functiondef(oid) as function_definition
FROM pg_proc
WHERE proname = 'deduct_credit';

-- Check permissions on the function
SELECT
    proname,
    proacl as permissions
FROM pg_proc
WHERE proname = 'deduct_credit';
