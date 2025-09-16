-- Create test user for BFIS trip access
-- Username: bfis@example.com, Password: bfis
-- Instructions for manual setup since Supabase auth requires special handling

-- STEP 1: Create the user through normal signup process
-- Go to: http://localhost:8080/pages/auth/register.html
-- Use these credentials:
--   Email: bfis@example.com
--   Password: bfis
--   Name: BFIS Test User
--   User Type: Student
--   School: Benjamin Franklin International School

-- STEP 2: Run this script to confirm the user and make them ready for login
UPDATE auth.users
SET
    email_confirmed_at = NOW(),
    phone_confirmed_at = NOW()
WHERE email = 'bfis@example.com';

-- STEP 3: Verify the user is ready
SELECT
    email,
    email_confirmed_at IS NOT NULL as email_confirmed,
    created_at,
    raw_user_meta_data
FROM auth.users
WHERE email = 'bfis@example.com';

-- Check if public.users table exists and show profile if available
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'users') THEN
        RAISE NOTICE 'Public users table exists - checking profile...';
        PERFORM u.email, u.full_name, u.user_type, s.name as school_name, u.created_at
        FROM public.users u
        LEFT JOIN public.schools s ON u.school_id = s.id
        WHERE u.email = 'bfis@example.com';
    ELSE
        RAISE NOTICE 'Public users table does not exist - user will only exist in auth.users';
    END IF;
END $$;

-- Alternative: If you need to create user programmatically (advanced)
-- You can use Supabase's admin API or create through the dashboard:
-- 1. Go to Supabase Dashboard → Authentication → Users
-- 2. Click "Add user"
-- 3. Email: bfis@example.com
-- 4. Password: bfis
-- 5. Email confirmed: Yes
-- 6. Then run the public.users insert below if needed

-- Create public profile if user exists in auth but not in public.users
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'users') THEN
        INSERT INTO public.users (
            id,
            email,
            full_name,
            user_type,
            school_id,
            created_at
        )
        SELECT
            au.id,
            'bfis@example.com',
            'BFIS Test User',
            'student',
            s.id,
            NOW()
        FROM auth.users au
        CROSS JOIN public.schools s
        WHERE au.email = 'bfis@example.com'
          AND s.name = 'Benjamin Franklin International School'
          AND NOT EXISTS (
              SELECT 1 FROM public.users pu WHERE pu.id = au.id
          )
        ON CONFLICT (id) DO NOTHING;

        RAISE NOTICE 'Public profile created/updated for bfis@example.com';
    ELSE
        RAISE NOTICE 'Public users table does not exist - skipping profile creation';
    END IF;
END $$;

-- Final verification
SELECT 'Setup complete! Test user ready for login.' as status;