-- User Profiles Table
-- Extends Supabase auth.users with additional profile information and roles

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

-- Add RLS (Row Level Security) policies
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

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

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_user_profiles_user_id ON user_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_user_profiles_role ON user_profiles(role);
CREATE INDEX IF NOT EXISTS idx_user_profiles_status ON user_profiles(status);
CREATE INDEX IF NOT EXISTS idx_user_profiles_school_name ON user_profiles(school_name);

-- Create trigger to update updated_at timestamp
CREATE TRIGGER update_user_profiles_updated_at
    BEFORE UPDATE ON user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Function to automatically create user profile on signup
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

-- Trigger to create profile on user signup
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- View for admin user management
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

-- Insert default admin user (you should update this with real credentials)
-- This is just an example - in production, create admin users through proper signup flow
INSERT INTO user_profiles (
    user_id,
    full_name,
    role,
    status,
    organization,
    email_verified
) VALUES (
    -- You'll need to replace this UUID with an actual user ID from auth.users
    -- after creating an admin account through the normal signup process
    '00000000-0000-0000-0000-000000000000'::uuid,
    'GUIDAL Administrator',
    'admin',
    'active',
    'Alella Green Tech',
    true
) ON CONFLICT (user_id) DO NOTHING;

-- Grant necessary permissions
GRANT SELECT, INSERT, UPDATE ON user_profiles TO authenticated;
GRANT SELECT ON admin_users TO authenticated;

-- Sample data for testing (optional)
-- Uncomment if you want some test data
/*
-- Create some sample staff/admin profiles
INSERT INTO user_profiles (
    user_id,
    full_name,
    role,
    status,
    organization,
    job_title,
    email_verified
) VALUES
(
    gen_random_uuid(),
    'Maria García',
    'staff',
    'active',
    'Alella Green Tech',
    'Education Coordinator',
    true
),
(
    gen_random_uuid(),
    'Hans Mueller',
    'staff',
    'active',
    'Alella Green Tech',
    'Workshop Facilitator',
    true
) ON CONFLICT (user_id) DO NOTHING;
*/