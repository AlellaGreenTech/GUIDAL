-- Assign Admin Privileges to mpwicard@gmail.com
-- This script grants admin access to the specified email address

-- Step 1: Check if user exists in auth.users table
SELECT
    id,
    email,
    email_confirmed_at,
    created_at
FROM auth.users
WHERE email = 'mpwicard@gmail.com';

-- Step 2: If user exists, update their profile to admin role
-- If user doesn't exist, they need to sign up first through the normal process

-- Update existing user profile to admin role
UPDATE user_profiles
SET
    role = 'admin',
    status = 'active',
    organization = 'Alella Green Tech',
    job_title = 'Administrator',
    email_verified = true,
    updated_at = NOW()
WHERE user_id IN (
    SELECT id FROM auth.users WHERE email = 'mpwicard@gmail.com'
);

-- If no profile exists, create one (this handles the case where user exists in auth but no profile)
INSERT INTO user_profiles (
    user_id,
    full_name,
    role,
    status,
    organization,
    job_title,
    email_verified,
    created_at,
    updated_at
)
SELECT
    au.id,
    COALESCE(au.raw_user_meta_data->>'full_name', 'Martin Picard'),
    'admin',
    'active',
    'Alella Green Tech',
    'Administrator',
    true,
    NOW(),
    NOW()
FROM auth.users au
WHERE au.email = 'mpwicard@gmail.com'
AND NOT EXISTS (
    SELECT 1 FROM user_profiles up WHERE up.user_id = au.id
);

-- Verify the admin assignment
SELECT
    au.email,
    up.full_name,
    up.role,
    up.status,
    up.organization,
    up.job_title,
    up.email_verified
FROM auth.users au
JOIN user_profiles up ON up.user_id = au.id
WHERE au.email = 'mpwicard@gmail.com';

-- Show all admin users for verification
SELECT
    email,
    full_name,
    role,
    status,
    organization,
    created_at
FROM admin_users
WHERE role IN ('admin', 'staff')
ORDER BY role DESC, created_at DESC;