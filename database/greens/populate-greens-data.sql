-- Populate GREENs System with Sample Data
-- Run this after the main schema setup to add sample activities and users

-- Insert sample schools
INSERT INTO public.schools (name, country, contact_email) VALUES 
('Benjamin Franklin International School', 'Spain', 'info@bfischool.org'),
('International School of Prague', 'Czech Republic', 'admissions@isp.cz'),
('American School of Barcelona', 'Spain', 'info@asb.edu'),
('Independent Learners', 'Global', 'support@guidal.org')
ON CONFLICT (name) DO NOTHING;

-- Insert comprehensive sample activities with proper GREENs integration
INSERT INTO public.activities (
    title, slug, description, activity_type_id, activity_category, 
    greens_reward, greens_cost, date_time, duration_minutes, 
    max_participants, location, learning_objectives, materials_needed
) VALUES 
(
    'Station 1: Sustainable Planting Workshop', 
    'station-1-planting-workshop',
    'Hands-on workshop learning sustainable planting techniques, soil composition, and water management. Students will plant seeds and learn about permaculture principles.',
    (SELECT id FROM public.activity_types WHERE slug = 'station'),
    'educational',
    2, 0,
    '2025-09-16 10:00:00+02',
    45,
    15,
    'Greenhouse Station 1',
    ARRAY['Learn sustainable planting techniques', 'Understand soil composition', 'Practice water conservation'],
    ARRAY['Garden gloves', 'Seeds', 'Small pots', 'Soil samples']
),
(
    'Station 2: Composting and Waste Management', 
    'station-2-composting',
    'Interactive session on composting processes, waste reduction, and circular economy principles. Build your own mini compost system.',
    (SELECT id FROM public.activity_types WHERE slug = 'station'),
    'educational',
    2, 0,
    '2025-09-16 11:00:00+02',
    45,
    15,
    'Composting Station 2',
    ARRAY['Understand composting processes', 'Learn waste reduction techniques', 'Build compost system'],
    ARRAY['Organic waste samples', 'Compost containers', 'pH testing kits']
),
(
    'Full-Day Sustainability Workshop', 
    'full-day-sustainability',
    'Comprehensive 6-hour workshop covering renewable energy, sustainable agriculture, green building, and environmental monitoring with hands-on projects.',
    (SELECT id FROM public.activity_types WHERE slug = 'workshop'),
    'educational',
    3, 0,
    '2025-09-25 09:00:00+02',
    360,
    25,
    'Main Workshop Hall',
    ARRAY['Master renewable energy concepts', 'Build solar projects', 'Create environmental monitors'],
    ARRAY['Arduino kits', 'Solar panels', 'Building materials', 'Lunch included']
),
(
    'Football Break - Campus Recreation', 
    'football-break-recreation',
    'Recreational football session during breaks. Use your earned GREENs to enjoy some physical activity and socialize with other participants.',
    (SELECT id FROM public.activity_types WHERE slug = 'recreation'),
    'recreational',
    0, 1,
    '2025-09-16 13:00:00+02',
    30,
    20,
    'Campus Football Field',
    ARRAY[],
    ARRAY['Football', 'Goalposts', 'Water bottles']
),
(
    'Sustainability Presentation Series', 
    'sustainability-presentation',
    'Educational presentation on climate change, renewable energy, and sustainable living practices. Interactive Q&A session included.',
    (SELECT id FROM public.activity_types WHERE slug = 'workshop'),
    'educational',
    1, 0,
    '2025-09-20 14:00:00+02',
    60,
    50,
    'Main Auditorium',
    ARRAY['Understand climate science', 'Learn about renewable energy', 'Explore sustainable practices'],
    ARRAY['Presentation materials', 'Interactive displays']
),
(
    'Ram Pump Construction Workshop', 
    'ram-pump-construction',
    'Build your own hydraulic ram pump system. Learn water hammer physics and take home your working creation. Perfect blend of theory and hands-on engineering.',
    (SELECT id FROM public.activity_types WHERE slug = 'workshop'),
    'educational',
    3, 0,
    '2025-09-25 13:30:00+02',
    240,
    12,
    'Engineering Workshop',
    ARRAY['Master hydraulic principles', 'Build working ram pump', 'Understand water hammer physics'],
    ARRAY['PVC pipes', 'Valves', 'Tools', 'Water testing setup']
),
(
    'Community Sustainability Fair', 
    'community-sustainability-fair',
    'Large community event featuring local sustainable businesses, interactive demonstrations, food vendors, and educational exhibits about green technologies.',
    (SELECT id FROM public.activity_types WHERE slug = 'event'),
    'mixed',
    2, 0,
    '2025-10-15 10:00:00+02',
    480,
    200,
    'Campus Main Area',
    ARRAY['Explore sustainable businesses', 'Learn from demonstrations', 'Network with community'],
    ARRAY['Information booths', 'Food stalls', 'Interactive displays']
),
(
    'Table Tennis Tournament', 
    'table-tennis-tournament',
    'Competitive table tennis tournament for participants. Entry requires GREENs. Prizes awarded to winners!',
    (SELECT id FROM public.activity_types WHERE slug = 'recreation'),
    'recreational',
    0, 2,
    '2025-09-17 16:00:00+02',
    120,
    16,
    'Recreation Hall',
    ARRAY[],
    ARRAY['Table tennis equipment', 'Tournament brackets', 'Prizes']
)
ON CONFLICT (slug) DO UPDATE SET
    description = EXCLUDED.description,
    greens_reward = EXCLUDED.greens_reward,
    greens_cost = EXCLUDED.greens_cost,
    updated_at = NOW();

-- Create sample demo users with different profiles
INSERT INTO public.users (
    email, full_name, username, age, city, region, country, 
    school_id, grade_level, languages, social_media, user_type,
    greens_balance, total_greens_earned
) VALUES 
(
    'alice@demo.com', 'Alice Green', 'alice_green', 16, 
    'Barcelona', 'Catalonia', 'Spain',
    (SELECT id FROM public.schools WHERE name = 'American School of Barcelona'),
    'High School', ARRAY['English', 'Spanish'], 
    '{"instagram": "@alice_green", "tiktok": "@alice_sustainability"}',
    'student', 8, 15
),
(
    'bob@demo.com', 'Bob Martinez', 'bob_eco', 17, 
    'Prague', 'Prague Region', 'Czech Republic',
    (SELECT id FROM public.schools WHERE name = 'International School of Prague'),
    'High School', ARRAY['English', 'Czech'], 
    '{"instagram": "@bob_eco_warrior"}',
    'student', 5, 12
),
(
    'carol@demo.com', 'Dr. Carol Johnson', 'dr_carol', 34, 
    'Barcelona', 'Catalonia', 'Spain',
    (SELECT id FROM public.schools WHERE name = 'Benjamin Franklin International School'),
    'Teacher', ARRAY['English', 'Spanish'], 
    '{"linkedin": "carol-johnson-sustainability"}',
    'teacher', 20, 25
),
(
    'david@demo.com', 'David Chen', 'david_builder', 15, 
    'Barcelona', 'Catalonia', 'Spain',
    (SELECT id FROM public.schools WHERE name = 'American School of Barcelona'),
    'High School', ARRAY['English', 'Catalan'], 
    '{"instagram": "@david_builds_green"}',
    'student', 12, 18
)
ON CONFLICT (email) DO UPDATE SET
    greens_balance = EXCLUDED.greens_balance,
    total_greens_earned = EXCLUDED.total_greens_earned;

-- Create sample activity registrations
INSERT INTO public.activity_registrations (user_id, activity_id, greens_used, status) 
SELECT 
    u.id,
    a.id,
    a.greens_cost,
    'registered'
FROM public.users u
CROSS JOIN public.activities a
WHERE u.email IN ('alice@demo.com', 'bob@demo.com') 
AND a.slug IN ('station-1-planting-workshop', 'full-day-sustainability', 'sustainability-presentation')
ON CONFLICT (user_id, activity_id) DO NOTHING;

-- Create sample activity completions with GREENs rewards
INSERT INTO public.activity_completions (user_id, activity_id, greens_earned, completion_status, participation_score) 
SELECT 
    u.id,
    a.id,
    a.greens_reward,
    'completed',
    FLOOR(RANDOM() * 3 + 8)::INTEGER -- Random score between 8-10
FROM public.users u
CROSS JOIN public.activities a
WHERE u.email IN ('alice@demo.com', 'bob@demo.com', 'david@demo.com') 
AND a.activity_category = 'educational'
AND a.greens_reward > 0
ON CONFLICT (user_id, activity_id, completion_date::date) DO NOTHING;

-- Create corresponding GREENs transactions
INSERT INTO public.greens_transactions (
    user_id, transaction_type, greens_amount, balance_before, balance_after,
    activity_id, description, blockchain_hash, blockchain_verified
)
SELECT 
    ac.user_id,
    'earned',
    ac.greens_earned,
    0, -- Will be updated by trigger
    ac.greens_earned,
    ac.activity_id,
    'GREENs earned for completing ' || a.title,
    'GRN' || EXTRACT(EPOCH FROM NOW())::BIGINT || UPPER(SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 8)),
    TRUE
FROM public.activity_completions ac
JOIN public.activities a ON ac.activity_id = a.id
WHERE NOT EXISTS (
    SELECT 1 FROM public.greens_transactions gt 
    WHERE gt.user_id = ac.user_id AND gt.activity_id = ac.activity_id AND gt.transaction_type = 'earned'
);

-- Create some bonus transactions
INSERT INTO public.greens_transactions (
    user_id, transaction_type, greens_amount, balance_before, balance_after,
    description, blockchain_hash, blockchain_verified
)
SELECT 
    u.id,
    'bonus',
    3,
    0, -- Will be updated by trigger
    3,
    'Welcome bonus for joining GREENs community!',
    'GRN' || EXTRACT(EPOCH FROM NOW())::BIGINT || UPPER(SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 8)),
    TRUE
FROM public.users u
WHERE u.email LIKE '%@demo.com'
AND NOT EXISTS (
    SELECT 1 FROM public.greens_transactions gt 
    WHERE gt.user_id = u.id AND gt.transaction_type = 'bonus' AND gt.description LIKE '%Welcome bonus%'
);

-- Update user balances (the trigger should handle this, but let's ensure consistency)
UPDATE public.users 
SET greens_balance = (
    SELECT COALESCE(SUM(
        CASE 
            WHEN gt.transaction_type IN ('earned', 'bonus') THEN gt.greens_amount
            WHEN gt.transaction_type = 'spent' THEN -gt.greens_amount
            ELSE 0
        END
    ), 0)
    FROM public.greens_transactions gt 
    WHERE gt.user_id = users.id
),
total_greens_earned = (
    SELECT COALESCE(SUM(gt.greens_amount), 0)
    FROM public.greens_transactions gt 
    WHERE gt.user_id = users.id AND gt.transaction_type IN ('earned', 'bonus')
),
total_greens_spent = (
    SELECT COALESCE(SUM(gt.greens_amount), 0)
    FROM public.greens_transactions gt 
    WHERE gt.user_id = users.id AND gt.transaction_type = 'spent'
);

-- Show summary
SELECT 
    'Database populated with GREENs system data!' as status,
    COUNT(*) as activities_created
FROM public.activities;

SELECT 
    'Demo users created:' as info,
    email,
    full_name,
    greens_balance || ' GREENs' as balance
FROM public.users 
WHERE email LIKE '%@demo.com'
ORDER BY greens_balance DESC;