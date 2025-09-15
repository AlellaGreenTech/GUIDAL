-- Update existing mpwicard@gmail.com user to have admin access everywhere
-- This script updates the existing user to have admin privileges

-- Update profiles table to set admin privileges
UPDATE public.profiles SET
    user_type = 'admin',
    updated_at = NOW()
WHERE email = 'mpwicard@gmail.com';

-- Update users table for GREENs system compatibility
UPDATE public.users SET
    user_type = 'admin',
    greens_balance = 1000,
    total_greens_earned = 1000
WHERE email = 'mpwicard@gmail.com';

-- If the user doesn't exist in users table, insert them
INSERT INTO public.users (
    email,
    full_name,
    username,
    age,
    city,
    region,
    country,
    user_type,
    greens_balance,
    total_greens_earned
)
SELECT
    'mpwicard@gmail.com',
    COALESCE(full_name, 'Martin Picard'),
    'martin_admin',
    35,
    'Barcelona',
    'Catalonia',
    'Spain',
    'admin',
    1000,
    1000
FROM public.profiles
WHERE email = 'mpwicard@gmail.com'
ON CONFLICT (email) DO NOTHING;

-- Verify the user was created
SELECT email, full_name, user_type FROM public.profiles WHERE email = 'mpwicard@gmail.com';
SELECT email, full_name, user_type, greens_balance FROM public.users WHERE email = 'mpwicard@gmail.com';