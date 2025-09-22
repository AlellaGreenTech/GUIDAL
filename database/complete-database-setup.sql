-- GUIDAL Complete Database Setup
-- This script sets up the entire visits management system in one go
-- Run this in Supabase SQL Editor to create all tables and import historical data

-- ========================================
-- STEP 1: CREATE VISITS TABLE
-- ========================================

-- Drop existing table if it exists (be careful in production!)
DROP TABLE IF EXISTS visits CASCADE;

-- Create the properly named 'visits' table with all required fields
CREATE TABLE visits (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,

    -- Entity/School Information
    school_name TEXT NOT NULL,
    contact_name TEXT NOT NULL,
    contact_email TEXT NOT NULL,
    contact_phone TEXT,
    school_location TEXT,
    country_of_origin TEXT,

    -- Visit Classification
    visit_type TEXT DEFAULT 'school-visit' CHECK (visit_type IN (
        'school-visit',
        'corporate-visit',
        'family-visit',
        'individual-visit',
        'homeschool-visit',
        'university-visit',
        'workshop',
        'special-lunch',
        'event',
        'other'
    )),
    visit_format TEXT CHECK (visit_format IN (
        'full-day-with-lunch',
        'morning-with-lunch',
        'morning-no-lunch',
        'afternoon-session',
        'workshop-2hr',
        'workshop-4hr',
        'lunch-only',
        'evening-event',
        'custom'
    )),
    educational_focus TEXT CHECK (educational_focus IN (
        'hands-on-permaculture',
        'real-world-science',
        'balanced-mix',
        'iot-automation',
        'sustainability',
        'cooking-workshop',
        'gardening-workshop',
        'technology-workshop',
        'family-experience',
        'team-building',
        'other'
    )),

    -- Group Details
    student_count INTEGER NOT NULL CHECK (student_count > 0),
    teacher_count INTEGER DEFAULT 2,
    adult_count INTEGER DEFAULT 0,
    grade_level TEXT NOT NULL,
    age_range TEXT,
    special_needs TEXT,

    -- Visit Preferences
    preferred_date DATE NOT NULL,
    alternate_date DATE,
    visit_duration TEXT NOT NULL,
    arrival_time TIME,
    lunch_needs TEXT DEFAULT 'none' CHECK (lunch_needs IN ('none', 'pizza', 'bbq', 'own_lunch', 'required')),

    -- Learning Objectives
    primary_subjects TEXT[] DEFAULT '{}',
    learning_goals TEXT,
    topics_of_interest TEXT,
    educational_focus_details TEXT,

    -- Logistics
    transportation_method TEXT,
    special_dietary_requirements TEXT,
    accessibility_needs TEXT,
    emergency_contact TEXT,
    emergency_phone TEXT,

    -- Admin Fields
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'reviewing', 'approved', 'scheduled', 'completed', 'cancelled')),
    priority_level TEXT DEFAULT 'normal' CHECK (priority_level IN ('low', 'normal', 'high', 'urgent')),
    assigned_coordinator TEXT,
    internal_notes TEXT,
    public_notes TEXT,

    -- Requests and Communication
    additional_requests TEXT,
    follow_up_needed BOOLEAN DEFAULT false,
    marketing_consent BOOLEAN DEFAULT false,

    -- Pricing and Invoicing
    estimated_cost DECIMAL(10,2),
    final_cost DECIMAL(10,2),
    invoice_status TEXT DEFAULT 'not-invoiced' CHECK (invoice_status IN ('not-invoiced', 'invoiced', 'paid', 'overdue')),
    payment_method TEXT,
    payment_reference TEXT,

    -- Workshops/Activities
    selected_workshops TEXT[] DEFAULT '{}',
    workshop_preferences TEXT,
    custom_activities TEXT,

    -- Feedback and Follow-up
    feedback_rating INTEGER CHECK (feedback_rating >= 1 AND feedback_rating <= 5),
    feedback_comments TEXT,
    photos_consent BOOLEAN DEFAULT false,
    newsletter_signup BOOLEAN DEFAULT false,

    -- Timestamps
    submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    visit_completed_at TIMESTAMP WITH TIME ZONE,

    -- Pricing tier reference (will be added later)
    pricing_tier_id UUID
);

-- ========================================
-- STEP 2: CREATE PRICING TABLES
-- ========================================

-- Standard pricing table
CREATE TABLE IF NOT EXISTS pricing (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    price_per_child DECIMAL(10,2) NOT NULL DEFAULT 15.00,
    price_per_adult DECIMAL(10,2) NOT NULL DEFAULT 25.00,
    meal_price_child DECIMAL(10,2) NOT NULL DEFAULT 8.00,
    meal_price_adult DECIMAL(10,2) NOT NULL DEFAULT 12.00,
    vat_rate DECIMAL(5,2) NOT NULL DEFAULT 21.00,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- School-specific pricing overrides
CREATE TABLE IF NOT EXISTS school_pricing (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    school_name TEXT NOT NULL,
    price_per_child DECIMAL(10,2),
    price_per_adult DECIMAL(10,2),
    meal_price_child DECIMAL(10,2),
    meal_price_adult DECIMAL(10,2),
    vat_rate DECIMAL(5,2),
    notes TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Pricing tiers for different event types
CREATE TABLE IF NOT EXISTS pricing_tiers (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    tier_name TEXT NOT NULL UNIQUE,
    visit_type TEXT NOT NULL,
    visit_format TEXT,
    child_visit_price DECIMAL(10,2) NOT NULL DEFAULT 0,
    adult_visit_price DECIMAL(10,2) NOT NULL DEFAULT 0,
    child_meal_price DECIMAL(10,2) NOT NULL DEFAULT 0,
    adult_meal_price DECIMAL(10,2) NOT NULL DEFAULT 0,
    minimum_group_size INTEGER DEFAULT 1,
    maximum_group_size INTEGER DEFAULT 100,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ========================================
-- STEP 3: CREATE TRIGGERS
-- ========================================

-- Update timestamp trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply triggers to all tables
CREATE TRIGGER update_visits_updated_at
    BEFORE UPDATE ON visits
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_pricing_updated_at
    BEFORE UPDATE ON pricing
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_school_pricing_updated_at
    BEFORE UPDATE ON school_pricing
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_pricing_tiers_updated_at
    BEFORE UPDATE ON pricing_tiers
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ========================================
-- STEP 4: INSERT DEFAULT PRICING DATA
-- ========================================

-- Insert standard pricing
INSERT INTO pricing (price_per_child, price_per_adult, meal_price_child, meal_price_adult, vat_rate)
VALUES (15.00, 25.00, 8.00, 12.00, 21.00);

-- Insert pricing tiers for different event types
INSERT INTO pricing_tiers (tier_name, visit_type, visit_format, child_visit_price, adult_visit_price, child_meal_price, adult_meal_price, minimum_group_size, maximum_group_size, description) VALUES

-- School visit pricing (existing)
('School Visits', 'school-visit', NULL, 15.00, 25.00, 8.00, 12.00, 10, 70, 'Standard school group visits'),

-- Workshop pricing
('Technology Workshop', 'workshop', 'workshop-2hr', 20.00, 30.00, 0.00, 0.00, 5, 20, '2-hour hands-on technology workshops'),
('Permaculture Workshop', 'workshop', 'workshop-4hr', 35.00, 45.00, 8.00, 12.00, 5, 25, '4-hour permaculture workshops with lunch'),
('Cooking Workshop', 'workshop', 'workshop-2hr', 25.00, 35.00, 0.00, 0.00, 6, 15, 'Farm-to-table cooking workshops'),

-- Special lunch pricing
('Special Lunch', 'special-lunch', 'lunch-only', 0.00, 0.00, 15.00, 20.00, 4, 50, 'Special lunch experiences only'),
('Lunch & Tour', 'special-lunch', 'morning-with-lunch', 10.00, 15.00, 15.00, 20.00, 4, 30, 'Tour with special lunch'),

-- Family visit pricing
('Family Experience', 'family-visit', 'afternoon-session', 12.00, 18.00, 8.00, 12.00, 2, 8, 'Family-friendly afternoon experiences'),

-- Corporate/team building
('Corporate Team Building', 'corporate-visit', 'custom', 40.00, 40.00, 15.00, 20.00, 8, 40, 'Corporate team building experiences'),

-- Individual visits
('Individual Visit', 'individual-visit', 'custom', 25.00, 25.00, 12.00, 15.00, 1, 4, 'Individual or small group visits');

-- ========================================
-- STEP 5: IMPORT HISTORICAL VISITS DATA
-- ========================================

-- Import all 17 historical visits with proper categorization
INSERT INTO visits (
    school_name,
    contact_name,
    contact_email,
    contact_phone,
    student_count,
    teacher_count,
    grade_level,
    preferred_date,
    visit_duration,
    lunch_needs,
    visit_type,
    visit_format,
    educational_focus,
    status,
    additional_requests,
    learning_goals,
    topics_of_interest,
    special_dietary_requirements,
    internal_notes,
    submitted_at,
    created_at,
    updated_at,
    invoice_status
) VALUES

-- 1. CAS Trips (January 2024) - COMPLETED & INVOICED
('[Cas Trips to provide it]', 'Tom Wolverton', 'thomasw@bfischool.org', NULL,
 25, 3, 'Grade 7', '2024-01-22', '6 hours', 'pizza',
 'school-visit', 'full-day-with-lunch', 'real-world-science', 'completed',
 'Kitchen Chemistry and Ecology unit. Pizza making focus.',
 'Finishing 7th grade unit on Kitchen Chemistry with Autonomy skills, transitioning to Ecology unit',
 'Water aspects, automation, erosion prevention, robotic gardening, clay building',
 NULL,
 'INVOICED. 7th grade Kitchen Chemistry/Ecology focus.',
 '2024-01-21 21:18:10', '2024-01-21 21:18:10', NOW(), 'invoiced'),

-- 2. CAS Trips Saudi Arabia (December 2024) - COMPLETED & INVOICED
('[Cas Trips to provide it]', 'Kamila Repikova', 'Kamila.R@castrips.org', NULL,
 25, 3, 'Grade 16-17', '2024-12-15', '4 hours', 'pizza',
 'school-visit', 'morning-with-lunch', 'hands-on-permaculture', 'completed',
 'Focus on hands on activities. Water aspects, IoT, automation, clay building.',
 'Hands on experience with water, IoT sensors, robotics, Farm.Bot, clay harvesting',
 'Water, IoT, automation, Farm.Bot, clay harvesting, ram pumps, farm animals, treasure hunting',
 NULL,
 'INVOICED. Saudi Arabia group. Hands-on focus.',
 '2024-02-12 14:04:55', '2024-02-12 14:04:55', NOW(), 'invoiced'),

-- 3. CAS Trips USA (August 2024) - COMPLETED & INVOICED
('[Cas Trips to provide it]', 'Kamila Repikova', 'Kamila.R@castrips.org', NULL,
 22, 3, 'Grade 16-17', '2024-08-03', '4 hours', 'pizza',
 'school-visit', 'morning-with-lunch', 'hands-on-permaculture', 'completed',
 'Very hands on visit with plants and soil following permaculture principles.',
 'Hands on permaculture, water aspects, farm animals, treasure hunting, insect collection',
 'Water ponds, farm animals, treasure hunting, insect specimens, hiking',
 NULL,
 'INVOICED. USA group. Morning session, hands-on permaculture.',
 '2024-06-06 13:31:58', '2024-06-06 13:31:58', NOW(), 'invoiced'),

-- 4. CAS Trips H-Farm International (October 2024) - NEEDS INVOICING
('CAS Trips - H-Farm International', 'Mara', 'Kamila.R@castrips.org', NULL,
 25, 3, 'IB DP Students', '2024-10-24', '4 hours', 'pizza',
 'school-visit', 'morning-with-lunch', 'iot-automation', 'completed',
 'Interdisciplinary approaches for IB collaborative science project. GIS, Farm.Bot, vines.',
 'Diverse group with computer science, design, chemistry, environmental systems backgrounds',
 'GIS, Farm.Bot automation, vine management, interdisciplinary science',
 'Nut allergy',
 'NEEDS INVOICE. Italy group. IB DP collaborative science project.',
 '2024-09-26 11:40:15', '2024-09-26 11:40:15', NOW(), 'not-invoiced'),

-- 5. St. Patricks International School (November 2024) - COMPLETED & INVOICED
('St. Patricks International School', 'Silvia Quílez', 'missroisin@stpatricksinternationalschool.com', NULL,
 27, 3, 'Primary', '2024-11-12', '6 hours', 'none',
 'school-visit', 'full-day-with-lunch', 'sustainability', 'completed',
 'Ecosystems, habitats, food chains focus. Brought own lunch.',
 'Ecosystems, habitats, food chains. Water aspects, erosion, IoT, automation, clay building',
 'Water aspects, erosion prevention, IoT sensors, automation, clay building, ram pumps, drones',
 NULL,
 'INVOICED. Ecosystems/habitats focus. Full day, own lunch.',
 '2024-10-08 15:04:22', '2024-10-08 15:04:22', NOW(), 'invoiced'),

-- 6. Barcelona Montessori School (November 2024) - COMPLETED & INVOICED
('Barcelona Montessori School', 'Dominic', 'dominic@barcelonamontessorischool.com', NULL,
 35, 4, 'Mixed ages', '2024-11-07', '6 hours', 'pizza',
 'school-visit', 'full-day-with-lunch', 'hands-on-permaculture', 'completed',
 'Maximum hands on work and farm experience. Water, clay, ram pumps, vines, planting.',
 'Want to do as much hands on work as possible and get to know the farm',
 'Water aspects, clay building, ram pumps, vine management, hiking, vegetable planting',
 NULL,
 'INVOICED. Barcelona Montessori. Full hands-on farm experience.',
 '2024-10-14 09:17:52', '2024-10-14 09:17:52', NOW(), 'invoiced'),

-- 7. Homeschool Maresme (TBD) - NEEDS INVOICING
('Homeschool Maresme', 'Rebecca', 'delsolarie@gmail.com', NULL,
 20, 15, 'Mixed ages', '2024-12-01', '4 hours', 'pizza',
 'homeschool-visit', 'afternoon-session', 'sustainability', 'scheduled',
 'Start with lunch at 12, end around 16-17hr. Mix of English and Spanish.',
 'Focus on sustainability and conservation. Water aspects, wells, planting',
 'Water aspects, ancient wells, vegetable planting, sustainability focus',
 NULL,
 'NEEDS INVOICE. Homeschool group. Afternoon session, bilingual.',
 '2024-10-26 14:06:54', '2024-10-26 14:06:54', NOW(), 'not-invoiced'),

-- 8. Learnlife (December 2024) - COMPLETED - NEEDS INVOICING
('Learnlife', 'Nicole', 'nicole@learnlife.com', '675714634',
 14, 2, 'AP Environmental Science', '2024-12-04', '3 hours', 'none',
 'school-visit', 'morning-no-lunch', 'real-world-science', 'completed',
 'AP Environmental Science. Focus on land and water use, irrigation methods.',
 'AP Environmental Science focus on land and water use, seeing real world examples',
 'Water aspects, erosion prevention, ancient wells, ram pumps, irrigation methods',
 NULL,
 'NEEDS INVOICE. AP Environmental Science. Morning only.',
 '2024-11-19 19:28:30', '2024-11-19 19:28:30', NOW(), 'not-invoiced'),

-- 9. St George (April 2025) - SCHEDULED
('St George', 'Gemma Garmeson', 'gemsicle@gmail.com', '671749745',
 17, 2, 'Year 10 GCSE Computer Science', '2025-04-29', '6 hours', 'pizza',
 'school-visit', 'full-day-with-lunch', 'iot-automation', 'scheduled',
 'Computer Science GCSE - automated systems, robotics, AI, Python programming.',
 'Year 10 computer science GCSE class focusing on automated systems, robotics and AI',
 'IoT sensors, automation, smart farming, agricultural drones',
 NULL,
 'Year 10 Computer Science. Automated systems, IoT, robotics focus.',
 '2025-03-25 13:47:00', '2025-03-25 13:47:00', NOW(), 'not-invoiced'),

-- 10. CAS Trips - Zurich International School Day 1 (August 2025) - SCHEDULED
('CAS Trips - Zurich International School', 'Kamila Repikova', 'kamila.r@castrips.org', NULL,
 49, 8, 'High School', '2025-08-26', '4 hours', 'pizza',
 'school-visit', 'morning-with-lunch', 'sustainability', 'scheduled',
 'Two groups (26+23 students). Sustainability focus - solar power, recycling, clothing swaps.',
 'ZIS values sustainability - solar power, recycling, no PET sales, clothing swaps',
 'Vegetable planting, agricultural drones, sustainability practices',
 NULL,
 'ZIS Day 1. 26+23 students, 4+4 teachers. Sustainability focus.',
 '2025-06-03 15:49:11', '2025-06-03 15:49:11', NOW(), 'not-invoiced'),

-- 11. Zurich International School Day 2 (August 2025) - SCHEDULED
('Zurich International School', 'Kamila', 'kamila.r@castrips.org', NULL,
 51, 8, 'High School', '2025-08-27', '4 hours', 'pizza',
 'school-visit', 'morning-with-lunch', 'hands-on-permaculture', 'scheduled',
 'Second day of ZIS visit. Hands on permaculture work, drones and agriculture.',
 'Hands on visit with land, water, plants, soil following permaculture principles',
 'Agricultural drones, hands-on permaculture, land and water work',
 NULL,
 'ZIS Day 2. 27+24 students. Permaculture and drones focus.',
 '2025-08-14 16:08:34', '2025-08-14 16:08:34', NOW(), 'not-invoiced'),

-- 12. International School of Prague (September 2025) - SCHEDULED
('International School of Prague', 'Kamila Repikova', 'Kamila.R@castrips.org', NULL,
 38, 7, 'Grades 9-12', '2025-09-17', '4 hours', 'pizza',
 'school-visit', 'morning-with-lunch', 'balanced-mix', 'scheduled',
 'Grades 9-12 mixed group. Sustainability, IoT, automation, clay building, vines, drones.',
 'Students discuss sustainability in various classes, robotics program, water quality focus',
 'IoT, automation, smart farming, clay building, vine management, agricultural drones',
 NULL,
 'Prague visit. Grades 9-12. Sustainability curriculum alignment.',
 '2025-09-01 10:53:19', '2025-09-01 10:53:19', NOW(), 'not-invoiced'),

-- 13. Benjamin Franklin International School (September 2025) - SCHEDULED
('Benjamin Franklin International School', 'Teacher', 'roses@bfischool.org', '661418131',
 70, 7, 'IB Diploma Programme', '2025-09-16', '6 hours', 'own_lunch',
 'school-visit', 'full-day-with-lunch', 'balanced-mix', 'scheduled',
 'IBDP Collaborative Sciences Project. 6 different activities for 6 courses. Own packed lunches.',
 'IBDP Collaborative Sciences Project aligned with biology, chemistry, ESS, physics, computer science, design technology',
 'Water aspects, IoT, automation, smart farming, clay building, ram pumps, erosion challenge, planting',
 NULL,
 'IBDP Collaborative Sciences. 6 activities for 6 courses. Largest group.',
 '2025-09-02 09:38:28', '2025-09-02 09:38:28', NOW(), 'not-invoiced'),

-- 14. CAS Trips May 2025 (Additional entry) - SCHEDULED - NEEDS INVOICING
('[Cas Trips to provide it]', 'Mara', 'Kamila.R@castrips.org', '693057741',
 34, 4, 'Mixed', '2025-05-14', '6 hours', 'pizza',
 'school-visit', 'full-day-with-lunch', 'iot-automation', 'scheduled',
 'Smart farming focus, IoT, treasure hunting, hiking. Nut allergy noted.',
 'Smart Farming: Sensors, Micro Controllers, IoT and big data. Metal detector treasure hunt',
 'Smart farming, IoT sensors, treasure hunting, hiking',
 'Nut allergy',
 'NEEDS INVOICE. May 2025 group. Smart farming and IoT focus.',
 '2025-05-01 12:00:00', '2025-05-01 12:00:00', NOW(), 'not-invoiced');

-- ========================================
-- STEP 6: CREATE RLS POLICIES
-- ========================================

-- Enable Row Level Security
ALTER TABLE visits ENABLE ROW LEVEL SECURITY;
ALTER TABLE pricing ENABLE ROW LEVEL SECURITY;
ALTER TABLE school_pricing ENABLE ROW LEVEL SECURITY;
ALTER TABLE pricing_tiers ENABLE ROW LEVEL SECURITY;

-- Allow public read access to visits (for public forms)
CREATE POLICY "Public can view visits" ON visits FOR SELECT USING (true);

-- Allow public insert for new visit requests
CREATE POLICY "Public can insert visits" ON visits FOR INSERT WITH CHECK (true);

-- Allow authenticated users full access (for admin)
CREATE POLICY "Authenticated users full access visits" ON visits FOR ALL USING (auth.role() = 'authenticated');

-- Pricing table policies (admin only for modifications)
CREATE POLICY "Public can view pricing" ON pricing FOR SELECT USING (true);
CREATE POLICY "Authenticated users full access pricing" ON pricing FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "Public can view school_pricing" ON school_pricing FOR SELECT USING (true);
CREATE POLICY "Authenticated users full access school_pricing" ON school_pricing FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "Public can view pricing_tiers" ON pricing_tiers FOR SELECT USING (true);
CREATE POLICY "Authenticated users full access pricing_tiers" ON pricing_tiers FOR ALL USING (auth.role() = 'authenticated');

-- ========================================
-- COMPLETION SUMMARY
-- ========================================

-- Show summary of setup
SELECT 'Database setup completed successfully!' as status;

SELECT 'Summary by Visit Type:' as category, visit_type, COUNT(*) as count
FROM visits GROUP BY visit_type
UNION ALL
SELECT 'Summary by Visit Format:' as category, visit_format, COUNT(*) as count
FROM visits GROUP BY visit_format
UNION ALL
SELECT 'Summary by Educational Focus:' as category, educational_focus, COUNT(*) as count
FROM visits GROUP BY educational_focus
UNION ALL
SELECT 'Summary by Status:' as category, status, COUNT(*) as count
FROM visits GROUP BY status
UNION ALL
SELECT 'Summary by Invoice Status:' as category, invoice_status, COUNT(*) as count
FROM visits GROUP BY invoice_status;

-- Show visits that need invoicing
SELECT 'Visits that need invoicing:' as info;
SELECT school_name, preferred_date, student_count, status, invoice_status
FROM visits
WHERE invoice_status = 'not-invoiced' AND status = 'completed'
ORDER BY preferred_date;

SELECT 'Total visits imported:' as info;
SELECT COUNT(*) as total FROM visits;