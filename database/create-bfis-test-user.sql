-- Create test user for BFIS trip access
-- Username: bfis@example.com, Password: bfis
-- Already confirmed and ready to access the Benjamin Franklin visit

-- First, check if user already exists and delete if necessary
DELETE FROM auth.users WHERE email = 'bfis@example.com';

-- Create the test user in Supabase auth.users table
-- Note: In production, passwords should be properly hashed
-- This is a simplified version for testing purposes
INSERT INTO auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    confirmation_sent_at,
    confirmation_token,
    recovery_sent_at,
    recovery_token,
    email_change_sent_at,
    email_change,
    email_change_token_new,
    email_change_token_current,
    phone,
    phone_confirmed_at,
    phone_change,
    phone_change_token,
    phone_change_sent_at,
    confirmed_at,
    email_change_confirm_status,
    banned_until,
    reauthentication_token,
    reauthentication_sent_at,
    is_sso_user,
    deleted_at,
    created_at,
    updated_at,
    raw_app_meta_data,
    raw_user_meta_data,
    is_super_admin,
    last_sign_in_at
) VALUES (
    '00000000-0000-0000-0000-000000000000'::uuid,
    gen_random_uuid(),
    'authenticated',
    'authenticated',
    'bfis@example.com',
    crypt('bfis', gen_salt('bf')), -- Hash the password 'bfis'
    NOW(),
    NOW(),
    '',
    NULL,
    '',
    NULL,
    '',
    '',
    '',
    NULL,
    NULL,
    '',
    '',
    NULL,
    NOW(),
    0,
    NULL,
    '',
    NULL,
    false,
    NULL,
    NOW(),
    NOW(),
    '{"provider": "email", "providers": ["email"]}',
    '{"name": "BFIS Test User", "school": "Benjamin Franklin International School"}',
    false,
    NOW()
);

-- Create corresponding profile in public.users table if it exists
-- This assumes your app uses a public.users table for profile data
INSERT INTO public.users (
    id,
    email,
    name,
    user_type,
    school_id,
    created_at,
    updated_at
) VALUES (
    (SELECT id FROM auth.users WHERE email = 'bfis@example.com'),
    'bfis@example.com',
    'BFIS Test User',
    'student',
    (SELECT id FROM public.schools WHERE name = 'Benjamin Franklin International School' LIMIT 1),
    NOW(),
    NOW()
) ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    name = EXCLUDED.name,
    user_type = EXCLUDED.user_type,
    school_id = EXCLUDED.school_id,
    updated_at = NOW();

-- Verify the user was created
SELECT
    u.email,
    u.email_confirmed_at IS NOT NULL as email_confirmed,
    u.confirmed_at IS NOT NULL as account_confirmed,
    u.created_at
FROM auth.users u
WHERE u.email = 'bfis@example.com';

-- Also check public profile if it exists
SELECT
    pu.email,
    pu.name,
    pu.user_type,
    s.name as school_name
FROM public.users pu
LEFT JOIN public.schools s ON pu.school_id = s.id
WHERE pu.email = 'bfis@example.com';