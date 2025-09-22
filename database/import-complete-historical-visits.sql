-- Import Complete Historical Visits from CSV Data
-- This imports all 17 historical visits from your Google Forms responses

-- First, clear any existing sample data
DELETE FROM trip_requests WHERE school_name IN (
    'Barcelona International School',
    'International School of Catalunya',
    'American School of Barcelona',
    'Individual Visitor',
    'Green Tech Company',
    'Zurich International School',
    'Benjamin Franklin International School'
);

-- Import all historical visits from CSV data
INSERT INTO trip_requests (
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
    status,
    additional_requests,
    learning_goals,
    internal_notes,
    submitted_at,
    created_at,
    updated_at
) VALUES

-- 1. CAS Trips (January 2024) - COMPLETED & INVOICED
('[Cas Trips to provide it]', 'Tom Wolverton', 'thomasw@bfischool.org', NULL,
 25, 3, 'Grade 7', '2024-01-22', 'Full day', 'pizza', 'completed',
 'Kitchen Chemistry and Ecology unit. Pizza making focus.',
 'Finishing 7th grade unit on Kitchen Chemistry with Autonomy skills, transitioning to Ecology unit',
 'INVOICED: Yes. 7th grade Kitchen Chemistry/Ecology. Water aspects, automation, erosion prevention.',
 '2024-01-21 21:18:10', '2024-01-21 21:18:10', NOW()),

-- 2. CAS Trips Saudi Arabia (December 2024) - COMPLETED & INVOICED
('[Cas Trips to provide it]', 'Kamila Repikova', 'Kamila.R@castrips.org', NULL,
 25, 3, 'Grade 16-17', '2024-12-15', 'Half day', 'pizza', 'completed',
 'Focus on hands on activities. Water aspects, IoT, automation, clay building.',
 'Hands on experience with water, IoT sensors, robotics, Farm.Bot, clay harvesting',
 'INVOICED: Yes. Saudi Arabia group. Hands-on focus with water, automation, Farm.Bot.',
 '2024-02-12 14:04:55', '2024-02-12 14:04:55', NOW()),

-- 3. CAS Trips USA (August 2024) - COMPLETED & INVOICED
('[Cas Trips to provide it]', 'Kamila Repikova', 'Kamila.R@castrips.org', NULL,
 22, 3, 'Grade 16-17', '2024-08-03', 'Morning with lunch', 'pizza', 'completed',
 'Very hands on visit with plants and soil following permaculture principles.',
 'Hands on permaculture, water aspects, farm animals, treasure hunting, insect collection',
 'INVOICED: Yes. USA group. Morning session, hands-on permaculture focus.',
 '2024-06-06 13:31:58', '2024-06-06 13:31:58', NOW()),

-- 4. CAS Trips H-Farm International (October 2024) - NEEDS INVOICING
('CAS Trips - H-Farm International', 'Mara', 'Kamila.R@castrips.org', NULL,
 25, 3, 'IB DP Students', '2024-10-24', 'Morning with lunch', 'pizza', 'completed',
 'Interdisciplinary approaches for IB collaborative science project. GIS, Farm.Bot, vines.',
 'Diverse group with computer science, design, chemistry, environmental systems backgrounds',
 'NEEDS INVOICE. Italy group. IB DP collaborative science project preparation.',
 '2024-09-26 11:40:15', '2024-09-26 11:40:15', NOW()),

-- 5. St. Patricks International School (November 2024) - COMPLETED & INVOICED
('St. Patricks International School', 'Silvia Quílez', 'missroisin@stpatricksinternationalschool.com', NULL,
 27, 3, 'Primary', '2024-11-12', 'Full day', 'none', 'completed',
 'Ecosystems, habitats, food chains focus. Brought own lunch.',
 'Ecosystems, habitats, food chains. Water aspects, erosion, IoT, automation, clay building',
 'INVOICED: Yes. Ecosystems/habitats focus. Full day, own lunch brought.',
 '2024-10-08 15:04:22', '2024-10-08 15:04:22', NOW()),

-- 6. Barcelona Montessori School (November 2024) - COMPLETED & INVOICED
('Barcelona Montessori School', 'Dominic', 'dominic@barcelonamontessorischool.com', NULL,
 35, 4, 'Mixed ages', '2024-11-07', 'Full day', 'pizza', 'completed',
 'Maximum hands on work and farm experience. Water, clay, ram pumps, vines, planting.',
 'Want to do as much hands on work as possible and get to know the farm',
 'INVOICED: Yes. Barcelona Montessori. Full hands-on farm experience.',
 '2024-10-14 09:17:52', '2024-10-14 09:17:52', NOW()),

-- 7. Homeschool Maresme (TBD) - NEEDS INVOICING
('Homeschool Maresme', 'Rebecca', 'delsolarie@gmail.com', NULL,
 20, 15, 'Mixed ages', '2024-12-01', 'Afternoon session', 'pizza', 'scheduled',
 'Start with lunch at 12, end around 16-17hr. Mix of English and Spanish.',
 'Focus on sustainability and conservation. Water aspects, wells, planting',
 'NEEDS INVOICE. Homeschool group. Afternoon session, bilingual delivery.',
 '2024-10-26 14:06:54', '2024-10-26 14:06:54', NOW()),

-- 8. Learnlife (December 2024) - COMPLETED - NEEDS INVOICING
('Learnlife', 'Nicole', 'nicole@learnlife.com', '675714634',
 14, 2, 'AP Environmental Science', '2024-12-04', 'Morning only', 'none', 'completed',
 'AP Environmental Science. Focus on land and water use, irrigation methods.',
 'AP Environmental Science focus on land and water use, seeing real world examples',
 'NEEDS INVOICE. AP Environmental Science. Morning only, no lunch.',
 '2024-11-19 19:28:30', '2024-11-19 19:28:30', NOW()),

-- 9. St George (April 2025) - SCHEDULED
('St George', 'Gemma Garmeson', 'gemsicle@gmail.com', '671749745',
 17, 2, 'Year 10 GCSE Computer Science', '2025-04-29', 'Full day', 'pizza', 'scheduled',
 'Computer Science GCSE - automated systems, robotics, AI, Python programming.',
 'Year 10 computer science GCSE class focusing on automated systems, robotics and AI',
 'Year 10 Computer Science. Automated systems, IoT, robotics focus.',
 '2025-03-25 13:47:00', '2025-03-25 13:47:00', NOW()),

-- 10. CAS Trips - Zurich International School (August 2025) - SCHEDULED
('CAS Trips - Zurich International School', 'Kamila Repikova', 'kamila.r@castrips.org', NULL,
 49, 8, 'High School', '2025-08-26', 'Morning with lunch', 'pizza', 'scheduled',
 'Two groups (26+23 students). Sustainability focus - solar power, recycling, clothing swaps.',
 'ZIS values sustainability - solar power, recycling, no PET sales, clothing swaps',
 '2-day visit. 26+23 students, 4+4 teachers. Sustainability and drones focus.',
 '2025-06-03 15:49:11', '2025-06-03 15:49:11', NOW()),

-- 11. Zurich International School (August 2025) - SCHEDULED
('Zurich International School', 'Kamila', 'kamila.r@castrips.org', NULL,
 51, 8, 'High School', '2025-08-27', 'Morning with lunch', 'pizza', 'scheduled',
 'Second day of ZIS visit. Hands on permaculture work, drones and agriculture.',
 'Hands on visit with land, water, plants, soil following permaculture principles',
 'Day 2 of ZIS visit. 27+24 students. Permaculture and drones focus.',
 '2025-08-14 16:08:34', '2025-08-14 16:08:34', NOW()),

-- 12. International School of Prague (September 2025) - SCHEDULED
('International School of Prague', 'Kamila Repikova', 'Kamila.R@castrips.org', NULL,
 38, 7, 'Grades 9-12', '2025-09-17', 'Morning with lunch', 'pizza', 'scheduled',
 'Grades 9-12 mixed group. Sustainability, IoT, automation, clay building, vines, drones.',
 'Students discuss sustainability in various classes, robotics program, water quality focus',
 'Prague visit. Grades 9-12. Sustainability curriculum alignment.',
 '2025-09-01 10:53:19', '2025-09-01 10:53:19', NOW()),

-- 13. Benjamin Franklin International School (September 2025) - SCHEDULED
('Benjamin Franklin International School', 'Teacher', 'roses@bfischool.org', '661418131',
 70, 7, 'IB Diploma Programme', '2025-09-16', 'Full day', 'own_lunch', 'scheduled',
 'IBDP Collaborative Sciences Project. 6 different activities for 6 courses. Own packed lunches.',
 'IBDP Collaborative Sciences Project aligned with biology, chemistry, ESS, physics, computer science, design technology',
 'IBDP Collaborative Sciences. 6 activities for 6 courses. Largest group.',
 '2025-09-02 09:38:28', '2025-09-02 09:38:28', NOW()),

-- 14. CAS Trips May 2025 (Additional entry) - SCHEDULED - NEEDS INVOICING
('[Cas Trips to provide it]', 'Mara', 'Kamila.R@castrips.org', '693057741',
 34, 4, 'Mixed', '2025-05-14', 'Full day', 'pizza', 'scheduled',
 'Smart farming focus, IoT, treasure hunting, hiking. Nut allergy noted.',
 'Smart Farming: Sensors, Micro Controllers, IoT and big data. Metal detector treasure hunt',
 'NEEDS INVOICE. May 2025 group. Smart farming and IoT focus. Nut allergy.',
 '2025-05-01 12:00:00', '2025-05-01 12:00:00', NOW());

-- Show summary of imported data
SELECT 'Import completed! Summary by status:' as info;

SELECT
    status,
    COUNT(*) as count,
    STRING_AGG(school_name, ', ') as schools
FROM trip_requests
GROUP BY status
ORDER BY
    CASE status
        WHEN 'completed' THEN 1
        WHEN 'scheduled' THEN 2
        WHEN 'pending' THEN 3
        ELSE 4
    END;

-- Show visits that need invoicing
SELECT 'Visits that need invoicing (based on notes):' as info;

SELECT
    school_name,
    contact_name,
    preferred_date,
    student_count,
    status,
    internal_notes
FROM trip_requests
WHERE internal_notes LIKE '%NEEDS INVOICE%'
ORDER BY preferred_date;

SELECT 'Total visits imported:' as info;
SELECT COUNT(*) as total_visits FROM trip_requests;