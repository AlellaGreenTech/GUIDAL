-- Complete Setup: Create tables and assign admin privileges
-- Run this entire script in Supabase SQL Editor

-- Step 1: Create the update_updated_at_column function if it doesn't exist
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Step 2: Create user_profiles table
CREATE TABLE IF NOT EXISTS user_profiles (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE NOT NULL,

    -- Profile Information
    full_name TEXT,
    avatar_url TEXT,
    phone TEXT,

    -- Role and Permissions
    role TEXT DEFAULT 'user' CHECK (role IN ('user', 'staff', 'admin')),
    permissions JSONB DEFAULT '[]',

    -- Organization Info (for staff/admin)
    organization TEXT,
    department TEXT,
    job_title TEXT,

    -- Account Status
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'suspended')),
    email_verified BOOLEAN DEFAULT FALSE,

    -- Preferences
    preferences JSONB DEFAULT '{}',
    notifications_enabled BOOLEAN DEFAULT TRUE,

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_login TIMESTAMP WITH TIME ZONE,

    -- Additional fields for school contacts
    school_name TEXT,
    school_location TEXT,
    subject_areas TEXT[] DEFAULT '{}'
);

-- Step 3: Add RLS (Row Level Security) policies
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (to avoid conflicts)
DROP POLICY IF EXISTS "Users can view own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON user_profiles;
DROP POLICY IF EXISTS "Admins can manage all profiles" ON user_profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON user_profiles;

-- Users can view and update their own profile
CREATE POLICY "Users can view own profile" ON user_profiles
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own profile" ON user_profiles
    FOR UPDATE USING (auth.uid() = user_id);

-- Admins can view and manage all profiles
CREATE POLICY "Admins can manage all profiles" ON user_profiles
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM user_profiles
            WHERE user_profiles.user_id = auth.uid()
            AND user_profiles.role IN ('admin', 'staff')
        )
    );

-- Allow authenticated users to insert their own profile
CREATE POLICY "Users can insert own profile" ON user_profiles
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Step 4: Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_user_profiles_user_id ON user_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_user_profiles_role ON user_profiles(role);
CREATE INDEX IF NOT EXISTS idx_user_profiles_status ON user_profiles(status);
CREATE INDEX IF NOT EXISTS idx_user_profiles_school_name ON user_profiles(school_name);

-- Step 5: Create trigger to update updated_at timestamp
DROP TRIGGER IF EXISTS update_user_profiles_updated_at ON user_profiles;
CREATE TRIGGER update_user_profiles_updated_at
    BEFORE UPDATE ON user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Step 6: Function to automatically create user profile on signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.user_profiles (user_id, full_name, email_verified)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email),
        NEW.email_confirmed_at IS NOT NULL
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 7: Trigger to create profile on user signup
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Step 8: View for admin user management
CREATE OR REPLACE VIEW admin_users AS
SELECT
    up.id,
    up.user_id,
    au.email,
    up.full_name,
    up.role,
    up.status,
    up.organization,
    up.school_name,
    up.created_at,
    up.last_login,
    au.email_confirmed_at IS NOT NULL AS email_verified,
    au.last_sign_in_at
FROM user_profiles up
JOIN auth.users au ON au.id = up.user_id
ORDER BY up.created_at DESC;

-- Step 9: Grant necessary permissions
GRANT SELECT, INSERT, UPDATE ON user_profiles TO authenticated;
GRANT SELECT ON admin_users TO authenticated;

-- Step 10: NOW ASSIGN ADMIN PRIVILEGES TO mpwicard@gmail.com

-- Check if user exists first
SELECT
    id,
    email,
    email_confirmed_at,
    created_at
FROM auth.users
WHERE email = 'mpwicard@gmail.com';

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

-- If no profile exists, create one
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

-- Final verification: Show the admin user
SELECT
    au.email,
    up.full_name,
    up.role,
    up.status,
    up.organization,
    up.job_title,
    up.email_verified,
    'SUCCESS: Admin privileges assigned' as result
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