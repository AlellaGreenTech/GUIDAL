-- =====================================================
-- GUIDAL Visit Planning Database Views
-- Efficient Data Retrieval for Admin Dashboard & Reports
-- =====================================================

-- Drop existing views if they exist
DROP VIEW IF EXISTS visits_complete_view CASCADE;
DROP VIEW IF EXISTS visits_dashboard_view CASCADE;
DROP VIEW IF EXISTS pending_visits_enhanced CASCADE;
DROP VIEW IF EXISTS visit_statistics_view CASCADE;
DROP VIEW IF EXISTS school_visit_history CASCADE;
DROP VIEW IF EXISTS contact_visit_summary CASCADE;

-- =====================================================
-- COMPLETE VISITS VIEW
-- All visit data with related contacts, school, and workshop details
-- =====================================================
CREATE OR REPLACE VIEW visits_complete_view AS
SELECT
    -- Visit core data
    v.id as visit_id,
    v.visit_type,
    v.status,
    v.priority_level,
    v.source,

    -- Dates and timing
    v.proposed_visit_date,
    v.potential_visit_dates,
    v.submitted_at,
    v.created_at,
    v.updated_at,

    -- School information (normalized)
    s.id as school_id,
    s.name as school_name,
    s.city as school_city,
    s.country as school_country,
    s.address as school_address,
    s.website as school_website,
    s.type as school_type,
    s.student_count_range,

    -- Organizer contact (if exists)
    oc.id as organizer_contact_id,
    oc.name as organizer_name,
    oc.email as organizer_email,
    oc.phone as organizer_phone,
    oc.position as organizer_position,

    -- Lead teacher contact
    tc.id as teacher_contact_id,
    tc.name as teacher_name,
    tc.email as teacher_email,
    tc.phone as teacher_phone,
    tc.position as teacher_position,

    -- Visit details
    v.preferred_language,
    v.number_of_students,
    v.number_of_adults,
    v.visit_format,
    v.visit_format_other,
    v.educational_focus,
    v.educational_focus_other,

    -- Overnight specific
    v.number_of_nights,
    v.arrival_date_time,
    v.departure_date_time,
    v.accommodation_selection,
    v.accommodation_needs,

    -- Additional information
    v.food_preferences,
    v.additional_comments,
    v.selected_workshops,

    -- Calculated fields
    CASE
        WHEN v.visit_type = 'school_overnight' THEN 'Overnight Visit'
        WHEN v.visit_type = 'school_day_trip' THEN 'Day Trip'
        ELSE INITCAP(REPLACE(v.visit_type, '_', ' '))
    END as visit_type_display,

    CASE
        WHEN v.proposed_visit_date IS NULL THEN 'No specific date'
        WHEN v.proposed_visit_date < CURRENT_DATE THEN 'Past date'
        WHEN v.proposed_visit_date = CURRENT_DATE THEN 'Today'
        WHEN v.proposed_visit_date <= CURRENT_DATE + INTERVAL '1 week' THEN 'This week'
        WHEN v.proposed_visit_date <= CURRENT_DATE + INTERVAL '1 month' THEN 'This month'
        ELSE 'Future'
    END as visit_urgency,

    -- Workshop details (aggregated)
    COALESCE(
        (SELECT json_agg(
            json_build_object(
                'id', a.id,
                'title', a.title,
                'description', a.description,
                'duration_minutes', a.duration_minutes,
                'max_participants', a.max_participants,
                'activity_type', at.name
            )
        )
        FROM unnest(v.selected_workshops) as workshop_id
        LEFT JOIN activities a ON a.id = workshop_id::uuid
        LEFT JOIN activity_types at ON at.id = a.activity_type_id
        WHERE a.id IS NOT NULL),
        '[]'::json
    ) as workshop_details,

    -- Contact summary
    CASE
        WHEN oc.name IS NOT NULL THEN oc.name || ' (Organizer), ' || tc.name || ' (Teacher)'
        ELSE tc.name || ' (Teacher)'
    END as contact_summary,

    -- Admin fields
    v.internal_notes,
    v.response_sent_at,
    v.confirmed_date,
    v.confirmed_format,
    v.estimated_cost

FROM visits v
LEFT JOIN schools s ON s.id = v.school_id
LEFT JOIN contacts oc ON oc.id = v.organizer_contact_id
LEFT JOIN contacts tc ON tc.id = v.lead_teacher_contact_id
ORDER BY v.submitted_at DESC;

-- =====================================================
-- DASHBOARD VIEW
-- Optimized for admin dashboard with key metrics
-- =====================================================
CREATE OR REPLACE VIEW visits_dashboard_view AS
SELECT
    visit_id,
    visit_type,
    visit_type_display,
    status,
    priority_level,
    visit_urgency,

    -- Key contact info
    school_name,
    school_city,
    school_country,
    teacher_name,
    teacher_email,
    organizer_name,

    -- Key visit info
    proposed_visit_date,
    number_of_students,
    number_of_adults,
    (number_of_students + COALESCE(number_of_adults, 0)) as total_participants,

    -- Overnight info
    CASE WHEN number_of_nights > 0 THEN
        number_of_nights || ' night(s), ' || accommodation_selection
    ELSE 'Day visit'
    END as accommodation_summary,

    -- Timing
    submitted_at,
    EXTRACT(DAYS FROM (CURRENT_DATE - submitted_at::date)) as days_since_submission,

    -- Workshop count
    CASE
        WHEN selected_workshops IS NULL THEN 0
        ELSE array_length(selected_workshops, 1)
    END as workshop_count,

    -- Status indicators
    CASE
        WHEN status = 'pending' AND EXTRACT(DAYS FROM (CURRENT_DATE - submitted_at::date)) > 7 THEN 'overdue'
        WHEN status = 'pending' AND EXTRACT(DAYS FROM (CURRENT_DATE - submitted_at::date)) > 3 THEN 'due_soon'
        WHEN status = 'pending' THEN 'on_time'
        ELSE status
    END as status_indicator

FROM visits_complete_view
ORDER BY
    CASE status
        WHEN 'pending' THEN 1
        WHEN 'reviewing' THEN 2
        WHEN 'approved' THEN 3
        WHEN 'scheduled' THEN 4
        ELSE 5
    END,
    submitted_at DESC;

-- =====================================================
-- ENHANCED PENDING VISITS
-- For processing new requests
-- =====================================================
CREATE OR REPLACE VIEW pending_visits_enhanced AS
SELECT
    *,
    -- Priority scoring
    CASE
        WHEN priority_level = 'urgent' THEN 100
        WHEN priority_level = 'high' THEN 80
        WHEN visit_urgency = 'This week' THEN 70
        WHEN visit_urgency = 'This month' THEN 60
        WHEN number_of_students > 50 THEN 50
        WHEN status_indicator = 'overdue' THEN 90
        WHEN status_indicator = 'due_soon' THEN 75
        ELSE 40
    END as priority_score

FROM visits_dashboard_view
WHERE status = 'pending'
ORDER BY priority_score DESC, submitted_at ASC;

-- =====================================================
-- STATISTICS VIEW
-- For reporting and analytics
-- =====================================================
CREATE OR REPLACE VIEW visit_statistics_view AS
SELECT
    -- Time periods
    DATE_TRUNC('month', submitted_at) as month,
    DATE_TRUNC('week', submitted_at) as week,
    submitted_at::date as day,

    -- Counts
    COUNT(*) as total_visits,
    COUNT(*) FILTER (WHERE status = 'pending') as pending_count,
    COUNT(*) FILTER (WHERE status = 'completed') as completed_count,
    COUNT(*) FILTER (WHERE visit_type = 'school_overnight') as overnight_count,
    COUNT(*) FILTER (WHERE visit_type = 'school_day_trip') as day_trip_count,

    -- Participants
    SUM(number_of_students) as total_students,
    SUM(number_of_adults) as total_adults,
    AVG(number_of_students) as avg_students_per_visit,

    -- Geography
    COUNT(DISTINCT school_country) as countries_count,
    COUNT(DISTINCT school_city) as cities_count,
    COUNT(DISTINCT school_id) as unique_schools,

    -- Popular choices
    MODE() WITHIN GROUP (ORDER BY accommodation_selection) as popular_accommodation,
    MODE() WITHIN GROUP (ORDER BY educational_focus) as popular_focus

FROM visits_complete_view
GROUP BY DATE_TRUNC('month', submitted_at), DATE_TRUNC('week', submitted_at), submitted_at::date
ORDER BY month DESC, week DESC, day DESC;

-- =====================================================
-- SCHOOL VISIT HISTORY
-- For managing school relationships
-- =====================================================
CREATE OR REPLACE VIEW school_visit_history AS
SELECT
    s.id as school_id,
    s.name as school_name,
    s.city,
    s.country,
    s.type as school_type,

    -- Visit statistics
    COUNT(v.id) as total_visits,
    COUNT(v.id) FILTER (WHERE v.status = 'completed') as completed_visits,
    COUNT(v.id) FILTER (WHERE v.status = 'pending') as pending_visits,
    MIN(v.submitted_at) as first_visit_request,
    MAX(v.submitted_at) as latest_visit_request,
    SUM(v.number_of_students) as total_students_brought,

    -- Visit types
    COUNT(v.id) FILTER (WHERE v.visit_type = 'school_overnight') as overnight_visits,
    COUNT(v.id) FILTER (WHERE v.visit_type = 'school_day_trip') as day_visits,

    -- Contact information
    string_agg(DISTINCT c.name, ', ') as contact_names,
    string_agg(DISTINCT c.email, ', ') as contact_emails,

    -- Relationship strength
    CASE
        WHEN COUNT(v.id) >= 5 THEN 'Strong'
        WHEN COUNT(v.id) >= 2 THEN 'Regular'
        WHEN COUNT(v.id) = 1 THEN 'New'
        ELSE 'Prospect'
    END as relationship_level

FROM schools s
LEFT JOIN visits v ON v.school_id = s.id
LEFT JOIN contacts c ON c.school_id = s.id AND c.active = true
WHERE s.active = true
GROUP BY s.id, s.name, s.city, s.country, s.type
ORDER BY total_visits DESC, latest_visit_request DESC;

-- =====================================================
-- CONTACT VISIT SUMMARY
-- For managing contact relationships
-- =====================================================
CREATE OR REPLACE VIEW contact_visit_summary AS
SELECT
    c.id as contact_id,
    c.name,
    c.email,
    c.phone,
    c.type as contact_type,
    c.position,

    -- School info
    s.name as school_name,
    s.city as school_city,
    s.country as school_country,

    -- Visit counts as organizer
    COUNT(v1.id) as visits_as_organizer,
    -- Visit counts as lead teacher
    COUNT(v2.id) as visits_as_teacher,
    -- Total visits
    (COUNT(v1.id) + COUNT(v2.id)) as total_visits,

    -- Latest activity
    GREATEST(
        COALESCE(MAX(v1.submitted_at), '1900-01-01'::timestamp),
        COALESCE(MAX(v2.submitted_at), '1900-01-01'::timestamp)
    ) as latest_visit_request,

    -- Contact engagement level
    CASE
        WHEN (COUNT(v1.id) + COUNT(v2.id)) >= 3 THEN 'Very Active'
        WHEN (COUNT(v1.id) + COUNT(v2.id)) >= 2 THEN 'Active'
        WHEN (COUNT(v1.id) + COUNT(v2.id)) = 1 THEN 'New'
        ELSE 'Inactive'
    END as engagement_level

FROM contacts c
LEFT JOIN schools s ON s.id = c.school_id
LEFT JOIN visits v1 ON v1.organizer_contact_id = c.id
LEFT JOIN visits v2 ON v2.lead_teacher_contact_id = c.id
WHERE c.active = true
GROUP BY c.id, c.name, c.email, c.phone, c.type, c.position, s.name, s.city, s.country
ORDER BY total_visits DESC, latest_visit_request DESC;

-- =====================================================
-- GRANT PERMISSIONS
-- =====================================================

GRANT SELECT ON visits_complete_view TO anon, authenticated;
GRANT SELECT ON visits_dashboard_view TO anon, authenticated;
GRANT SELECT ON pending_visits_enhanced TO anon, authenticated;
GRANT SELECT ON visit_statistics_view TO anon, authenticated;
GRANT SELECT ON school_visit_history TO anon, authenticated;
GRANT SELECT ON contact_visit_summary TO anon, authenticated;

-- =====================================================
-- VIEWS CREATION COMPLETE
-- =====================================================

-- Summary of views created:
-- ✅ visits_complete_view - Full visit data with all relationships
-- ✅ visits_dashboard_view - Optimized for admin dashboard
-- ✅ pending_visits_enhanced - Prioritized pending visits
-- ✅ visit_statistics_view - Analytics and reporting
-- ✅ school_visit_history - School relationship management
-- ✅ contact_visit_summary - Contact relationship management