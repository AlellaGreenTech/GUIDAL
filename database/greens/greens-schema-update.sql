-- GREENs Blockchain System Database Enhancement
-- Run this in Supabase SQL Editor to upgrade existing schema

-- First, ensure we have the base tables (if not already created)
CREATE TABLE IF NOT EXISTS public.schools (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    country TEXT,
    contact_email TEXT,
    contact_person TEXT,
    website TEXT,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enhanced Users/Profiles table for comprehensive user management
CREATE TABLE IF NOT EXISTS public.users (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT, -- For simple auth (consider using Supabase Auth in production)
    full_name TEXT NOT NULL,
    username TEXT UNIQUE,
    avatar_url TEXT,
    
    -- Personal Information
    age INTEGER,
    birthday DATE,
    city TEXT,
    region TEXT,
    country TEXT,
    phone TEXT,
    emergency_contact TEXT,
    
    -- Educational Information
    school_id UUID REFERENCES public.schools(id),
    grade_level TEXT,
    user_type TEXT DEFAULT 'student' CHECK (user_type IN ('student', 'teacher', 'admin', 'staff', 'guest')),
    
    -- GREENs System
    greens_balance INTEGER DEFAULT 0,
    total_greens_earned INTEGER DEFAULT 0,
    total_greens_spent INTEGER DEFAULT 0,
    
    -- Additional Information
    languages TEXT[] DEFAULT ARRAY['English'],
    social_media JSONB DEFAULT '{}', -- Store Instagram, TikTok, etc. handles
    dietary_restrictions TEXT,
    last_campus_visit DATE,
    
    -- System
    email_verified BOOLEAN DEFAULT false,
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Activity Categories and Types
CREATE TABLE IF NOT EXISTS public.activity_types (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    slug TEXT NOT NULL UNIQUE,
    description TEXT,
    icon TEXT,
    color TEXT DEFAULT '#388e3c',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enhanced Activities table with GREENs integration
CREATE TABLE IF NOT EXISTS public.activities (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title TEXT NOT NULL,
    slug TEXT NOT NULL UNIQUE,
    description TEXT,
    activity_type_id UUID REFERENCES public.activity_types(id),
    
    -- Scheduling
    date_time TIMESTAMP WITH TIME ZONE,
    duration_minutes INTEGER,
    location TEXT,
    
    -- Participation
    max_participants INTEGER,
    min_participants INTEGER DEFAULT 1,
    current_participants INTEGER DEFAULT 0,
    age_min INTEGER,
    age_max INTEGER,
    
    -- GREENs System Integration
    activity_category TEXT NOT NULL DEFAULT 'educational' CHECK (activity_category IN ('educational', 'recreational', 'mixed')),
    greens_reward INTEGER DEFAULT 0, -- GREENs earned for completing
    greens_cost INTEGER DEFAULT 0,   -- GREENs required to participate
    difficulty_level TEXT CHECK (difficulty_level IN ('easy', 'moderate', 'challenging')),
    
    -- Activity Details
    learning_objectives TEXT[],
    materials_needed TEXT[],
    what_to_bring TEXT,
    special_requirements TEXT,
    instructor TEXT,
    
    -- Images and Media
    featured_image TEXT,
    gallery_images TEXT[] DEFAULT '{}',
    
    -- Logistics
    price DECIMAL(10,2) DEFAULT 0,
    requires_registration BOOLEAN DEFAULT true,
    contact_email TEXT,
    contact_phone TEXT,
    
    -- System
    status TEXT DEFAULT 'published' CHECK (status IN ('draft', 'published', 'cancelled', 'completed')),
    created_by UUID REFERENCES public.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User Activity Registrations
CREATE TABLE IF NOT EXISTS public.activity_registrations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    activity_id UUID REFERENCES public.activities(id) ON DELETE CASCADE NOT NULL,
    
    -- Registration Details
    registration_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    status TEXT DEFAULT 'registered' CHECK (status IN ('registered', 'confirmed', 'attended', 'completed', 'no_show', 'cancelled')),
    
    -- GREENs Transaction
    greens_used INTEGER DEFAULT 0,
    payment_status TEXT DEFAULT 'free' CHECK (payment_status IN ('free', 'paid', 'pending', 'refunded')),
    
    -- Additional Info
    notes TEXT,
    emergency_contact TEXT,
    dietary_requirements TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, activity_id)
);

-- Activity Completions (for GREENs rewards)
CREATE TABLE IF NOT EXISTS public.activity_completions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    activity_id UUID REFERENCES public.activities(id) ON DELETE CASCADE NOT NULL,
    registration_id UUID REFERENCES public.activity_registrations(id),
    
    -- Completion Details
    completion_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completion_status TEXT DEFAULT 'completed' CHECK (completion_status IN ('completed', 'partial', 'excellent')),
    
    -- GREENs Reward
    greens_earned INTEGER NOT NULL,
    bonus_greens INTEGER DEFAULT 0, -- For exceptional performance
    
    -- Verification (Blockchain ready)
    verified_by UUID REFERENCES public.users(id),
    verification_notes TEXT,
    blockchain_hash TEXT, -- Future: actual blockchain transaction hash
    verified_at TIMESTAMP WITH TIME ZONE,
    
    -- Performance tracking
    participation_score INTEGER CHECK (participation_score >= 1 AND participation_score <= 10),
    feedback TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, activity_id, completion_date::date)
);

-- GREENs Transactions (Blockchain-ready)
CREATE TABLE IF NOT EXISTS public.greens_transactions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    
    -- Transaction Details
    transaction_type TEXT NOT NULL CHECK (transaction_type IN ('earned', 'spent', 'bonus', 'penalty', 'transfer')),
    greens_amount INTEGER NOT NULL,
    balance_before INTEGER NOT NULL,
    balance_after INTEGER NOT NULL,
    
    -- Reference
    activity_id UUID REFERENCES public.activities(id),
    completion_id UUID REFERENCES public.activity_completions(id),
    registration_id UUID REFERENCES public.activity_registrations(id),
    
    -- Blockchain Integration
    blockchain_hash TEXT,
    blockchain_verified BOOLEAN DEFAULT false,
    blockchain_network TEXT DEFAULT 'GUIDAL-Chain',
    
    -- Description and Notes
    description TEXT NOT NULL,
    notes TEXT,
    
    -- System
    processed_by UUID REFERENCES public.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User Sessions (for login tracking)
CREATE TABLE IF NOT EXISTS public.user_sessions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    session_token TEXT NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    ip_address TEXT,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- School Visits (enhanced)
CREATE TABLE IF NOT EXISTS public.school_visits (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    school_id UUID REFERENCES public.schools(id) NOT NULL,
    visit_date DATE NOT NULL,
    access_code TEXT UNIQUE NOT NULL,
    
    -- Visit Details
    student_count INTEGER DEFAULT 0,
    teacher_count INTEGER DEFAULT 0,
    grade_levels TEXT[],
    duration_hours DECIMAL(3,1),
    
    -- Program Details
    focus_areas TEXT[],
    stations_included TEXT[],
    lunch_included BOOLEAN DEFAULT false,
    
    -- Contact Information
    lead_teacher_name TEXT,
    lead_teacher_email TEXT,
    lead_teacher_phone TEXT,
    emergency_contact TEXT,
    
    -- Logistics
    arrival_time TIME,
    departure_time TIME,
    transport_details TEXT,
    special_requirements TEXT,
    
    -- Status
    status TEXT DEFAULT 'planned' CHECK (status IN ('planned', 'confirmed', 'active', 'completed', 'cancelled')),
    
    -- System
    created_by UUID REFERENCES public.users(id),
    visit_coordinator UUID REFERENCES public.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert default activity types
INSERT INTO public.activity_types (name, slug, description, icon) VALUES 
('Educational Workshop', 'workshop', 'Hands-on learning experiences', '🔬'),
('Recreational Activity', 'recreation', 'Fun activities that cost GREENs', '⚽'),
('Station Visit', 'station', 'Learning stations during school visits', '🌱'),
('Community Event', 'event', 'Special events and gatherings', '🎉'),
('Skill Building', 'skill', 'Practical skill development sessions', '🛠️')
ON CONFLICT (slug) DO NOTHING;

-- Insert sample activities with GREENs rewards
INSERT INTO public.activities (title, slug, description, activity_type_id, activity_category, greens_reward, greens_cost, duration_minutes, max_participants) VALUES 
('Station 1: Planting', 'station-1-planting', 'Learn sustainable planting techniques and soil composition', (SELECT id FROM public.activity_types WHERE slug = 'station'), 'educational', 2, 0, 40, 12),
('Station 2: Composting', 'station-2-composting', 'Understand composting processes and waste management', (SELECT id FROM public.activity_types WHERE slug = 'station'), 'educational', 2, 0, 40, 12),
('Football Break', 'football-break', 'Recreational football during breaks', (SELECT id FROM public.activity_types WHERE slug = 'recreation'), 'recreational', 0, 1, 30, 20),
('Full Day Workshop', 'full-day-workshop', 'Complete sustainability workshop with manual work', (SELECT id FROM public.activity_types WHERE slug = 'workshop'), 'educational', 3, 0, 360, 25),
('Presentation Attendance', 'presentation', 'Attend educational presentations', (SELECT id FROM public.activity_types WHERE slug = 'workshop'), 'educational', 1, 0, 60, 50)
ON CONFLICT (slug) DO NOTHING;

-- Enable Row Level Security
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity_registrations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity_completions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.greens_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity_types ENABLE ROW LEVEL SECURITY;

-- RLS Policies for public access (adjust as needed)
CREATE POLICY "Public read access for activities" ON public.activities FOR SELECT USING (true);
CREATE POLICY "Public read access for activity_types" ON public.activity_types FOR SELECT USING (true);
CREATE POLICY "Users can view own data" ON public.users FOR SELECT USING (auth.uid()::text = id::text OR true); -- Simplified for demo
CREATE POLICY "Users can register for activities" ON public.activity_registrations FOR ALL USING (true); -- Simplified for demo
CREATE POLICY "Public read access for registrations" ON public.activity_registrations FOR SELECT USING (true);
CREATE POLICY "Public insert access for completions" ON public.activity_completions FOR INSERT WITH CHECK (true);
CREATE POLICY "Public read access for completions" ON public.activity_completions FOR SELECT USING (true);
CREATE POLICY "Public read access for transactions" ON public.greens_transactions FOR SELECT USING (true);
CREATE POLICY "Public insert access for transactions" ON public.greens_transactions FOR INSERT WITH CHECK (true);

-- Functions for GREENs management
CREATE OR REPLACE FUNCTION update_user_greens_balance()
RETURNS TRIGGER AS $$
BEGIN
    -- Update user's GREENs balance when a transaction is created
    UPDATE public.users 
    SET 
        greens_balance = NEW.balance_after,
        total_greens_earned = CASE 
            WHEN NEW.transaction_type IN ('earned', 'bonus') 
            THEN total_greens_earned + NEW.greens_amount 
            ELSE total_greens_earned 
        END,
        total_greens_spent = CASE 
            WHEN NEW.transaction_type = 'spent' 
            THEN total_greens_spent + NEW.greens_amount 
            ELSE total_greens_spent 
        END,
        updated_at = NOW()
    WHERE id = NEW.user_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to automatically update user balance
DROP TRIGGER IF EXISTS trigger_update_greens_balance ON public.greens_transactions;
CREATE TRIGGER trigger_update_greens_balance
    AFTER INSERT ON public.greens_transactions
    FOR EACH ROW
    EXECUTE FUNCTION update_user_greens_balance();

-- Function to award GREENs for activity completion
CREATE OR REPLACE FUNCTION award_greens_for_completion(
    p_user_id UUID,
    p_activity_id UUID,
    p_greens_amount INTEGER,
    p_completion_notes TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_user_balance INTEGER;
    v_completion_id UUID;
    v_transaction_id UUID;
BEGIN
    -- Get current user balance
    SELECT greens_balance INTO v_user_balance 
    FROM public.users 
    WHERE id = p_user_id;
    
    -- Create completion record
    INSERT INTO public.activity_completions (user_id, activity_id, greens_earned, verification_notes)
    VALUES (p_user_id, p_activity_id, p_greens_amount, p_completion_notes)
    RETURNING id INTO v_completion_id;
    
    -- Create GREENs transaction
    INSERT INTO public.greens_transactions (
        user_id, 
        transaction_type, 
        greens_amount, 
        balance_before, 
        balance_after, 
        activity_id, 
        completion_id, 
        description
    )
    VALUES (
        p_user_id,
        'earned',
        p_greens_amount,
        v_user_balance,
        v_user_balance + p_greens_amount,
        p_activity_id,
        v_completion_id,
        'GREENs earned for completing activity'
    )
    RETURNING id INTO v_transaction_id;
    
    RETURN v_completion_id;
END;
$$ LANGUAGE plpgsql;