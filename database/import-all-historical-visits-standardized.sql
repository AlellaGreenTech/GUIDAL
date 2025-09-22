-- Import Complete Historical Visits into Standardized 'visits' Table
-- This imports all 17 historical visits with proper visit types and formats

-- Clear any existing data first
DELETE FROM visits;

-- Import all historical visits with proper categorization
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

-- Show summary of imported standardized data
SELECT 'Standardized visits import completed!' as info;

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

SELECT 'Total visits:' as info;
SELECT COUNT(*) as total FROM visits;