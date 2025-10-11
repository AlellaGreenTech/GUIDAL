-- ========================================================================
-- COMPREHENSIVE ANALYTICS SYSTEM FOR GUIDAL
-- ========================================================================
-- Tracks site usage, user behavior, bookings, and performance metrics
-- ========================================================================

-- ========================================================================
-- 1. ANALYTICS EVENTS TABLE
-- ========================================================================

CREATE TABLE IF NOT EXISTS analytics_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- Event identification
    event_type TEXT NOT NULL, -- 'page_view', 'button_click', 'form_submit', 'checkout_start', 'booking_complete', etc.
    event_category TEXT, -- 'navigation', 'engagement', 'conversion', 'error'
    event_name TEXT, -- Specific event name
    event_value NUMERIC, -- Numeric value (e.g., order amount, time spent)

    -- Page context
    page_url TEXT,
    page_title TEXT,
    referrer_url TEXT,

    -- User context
    session_id TEXT,
    user_id UUID, -- If authenticated
    visitor_id TEXT, -- Anonymous visitor tracking
    is_returning_visitor BOOLEAN DEFAULT false,

    -- Device & browser
    user_agent TEXT,
    device_type TEXT, -- 'mobile', 'tablet', 'desktop'
    browser TEXT,
    os TEXT,
    screen_resolution TEXT,

    -- Location
    ip_address INET,
    country TEXT,
    city TEXT,

    -- Related entities
    order_id UUID REFERENCES pumpkin_patch_orders(id),
    abandoned_booking_id UUID REFERENCES abandoned_bookings(id),

    -- Metadata
    metadata JSONB, -- Flexible storage for event-specific data

    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_analytics_events_type ON analytics_events(event_type);
CREATE INDEX IF NOT EXISTS idx_analytics_events_category ON analytics_events(event_category);
CREATE INDEX IF NOT EXISTS idx_analytics_events_created_at ON analytics_events(created_at);
CREATE INDEX IF NOT EXISTS idx_analytics_events_session ON analytics_events(session_id);
CREATE INDEX IF NOT EXISTS idx_analytics_events_visitor ON analytics_events(visitor_id);
CREATE INDEX IF NOT EXISTS idx_analytics_events_order ON analytics_events(order_id);

-- ========================================================================
-- 2. ANALYTICS SUMMARY VIEWS
-- ========================================================================

-- Daily summary statistics
CREATE OR REPLACE VIEW analytics_daily_summary AS
SELECT
    DATE(created_at) as date,
    COUNT(DISTINCT session_id) as unique_sessions,
    COUNT(DISTINCT visitor_id) as unique_visitors,
    COUNT(*) FILTER (WHERE event_type = 'page_view') as total_page_views,
    COUNT(*) FILTER (WHERE event_type = 'checkout_start') as checkout_starts,
    COUNT(*) FILTER (WHERE event_type = 'booking_complete') as bookings_completed,
    COUNT(*) FILTER (WHERE event_type = 'abandoned_cart') as carts_abandoned,
    ROUND(
        AVG(event_value) FILTER (WHERE event_type = 'time_on_page'),
        2
    ) as avg_time_on_page_seconds,
    device_type,
    browser
FROM analytics_events
GROUP BY DATE(created_at), device_type, browser
ORDER BY date DESC;

-- Conversion funnel view
CREATE OR REPLACE VIEW analytics_conversion_funnel AS
WITH funnel_stages AS (
    SELECT
        DATE(created_at) as date,
        COUNT(DISTINCT session_id) FILTER (WHERE event_type = 'page_view' AND page_url LIKE '%checkout%') as landed_on_checkout,
        COUNT(DISTINCT session_id) FILTER (WHERE event_type = 'email_entered') as entered_email,
        COUNT(DISTINCT session_id) FILTER (WHERE event_type = 'checkout_start') as proceeded_to_booking,
        COUNT(DISTINCT session_id) FILTER (WHERE event_type = 'booking_complete') as completed_booking,
        COUNT(DISTINCT order_id) FILTER (WHERE event_type = 'payment_completed') as paid_orders
    FROM analytics_events
    GROUP BY DATE(created_at)
)
SELECT
    date,
    landed_on_checkout,
    entered_email,
    proceeded_to_booking,
    completed_booking,
    paid_orders,
    ROUND(entered_email::NUMERIC / NULLIF(landed_on_checkout, 0) * 100, 2) as email_conversion_rate,
    ROUND(proceeded_to_booking::NUMERIC / NULLIF(entered_email, 0) * 100, 2) as proceed_conversion_rate,
    ROUND(completed_booking::NUMERIC / NULLIF(proceeded_to_booking, 0) * 100, 2) as completion_rate,
    ROUND(paid_orders::NUMERIC / NULLIF(completed_booking, 0) * 100, 2) as payment_rate
FROM funnel_stages
ORDER BY date DESC;

-- Top pages view
CREATE OR REPLACE VIEW analytics_top_pages AS
SELECT
    page_url,
    page_title,
    COUNT(*) as page_views,
    COUNT(DISTINCT session_id) as unique_sessions,
    COUNT(DISTINCT visitor_id) as unique_visitors,
    ROUND(AVG(event_value) FILTER (WHERE event_type = 'time_on_page'), 2) as avg_time_seconds,
    ROUND(
        COUNT(*) FILTER (WHERE event_type = 'bounce')::NUMERIC /
        NULLIF(COUNT(DISTINCT session_id), 0) * 100,
        2
    ) as bounce_rate
FROM analytics_events
WHERE event_type = 'page_view'
  AND created_at > NOW() - INTERVAL '30 days'
GROUP BY page_url, page_title
ORDER BY page_views DESC
LIMIT 50;

-- ========================================================================
-- 3. BOOKING STATISTICS VIEW
-- ========================================================================

CREATE OR REPLACE VIEW analytics_booking_stats AS
SELECT
    DATE(created_at) as date,

    -- Booking counts
    COUNT(*) as total_bookings,
    COUNT(*) FILTER (WHERE payment_status = 'paid') as paid_bookings,
    COUNT(*) FILTER (WHERE payment_status = 'pending') as pending_bookings,

    -- Revenue
    SUM(total_amount) as total_revenue,
    SUM(total_amount) FILTER (WHERE payment_status = 'paid') as paid_revenue,
    SUM(total_amount) FILTER (WHERE payment_status = 'pending') as pending_revenue,

    -- Averages
    ROUND(AVG(total_amount), 2) as avg_order_value,
    ROUND(AVG(adult_count + child_count), 2) as avg_party_size,

    -- Popular items
    SUM(adult_count) as total_adults,
    SUM(child_count) as total_children

FROM pumpkin_patch_orders
GROUP BY DATE(created_at)
ORDER BY date DESC;

-- ========================================================================
-- 4. ABANDONED BOOKING ANALYTICS VIEW
-- ========================================================================

CREATE OR REPLACE VIEW analytics_abandoned_bookings AS
SELECT
    DATE(started_at) as date,

    -- Counts
    COUNT(*) as total_abandoned,
    COUNT(*) FILTER (WHERE status = 'completed') as recovered_naturally,
    COUNT(*) FILTER (WHERE status = 'recovered') as recovered_via_email,
    COUNT(*) FILTER (WHERE recovery_email_sent_at IS NOT NULL) as recovery_emails_sent,

    -- Revenue
    SUM(cart_total) as potential_revenue_lost,
    SUM(cart_total) FILTER (WHERE status IN ('completed', 'recovered')) as revenue_recovered,

    -- Rates
    ROUND(
        COUNT(*) FILTER (WHERE status IN ('completed', 'recovered'))::NUMERIC /
        NULLIF(COUNT(*), 0) * 100,
        2
    ) as recovery_rate,

    ROUND(
        COUNT(*) FILTER (WHERE status = 'recovered')::NUMERIC /
        NULLIF(COUNT(*) FILTER (WHERE recovery_email_sent_at IS NOT NULL), 0) * 100,
        2
    ) as email_recovery_rate

FROM abandoned_bookings
GROUP BY DATE(started_at)
ORDER BY date DESC;

-- ========================================================================
-- 5. REAL-TIME DASHBOARD VIEW
-- ========================================================================

CREATE OR REPLACE VIEW analytics_realtime_dashboard AS
SELECT
    -- Today's stats
    (SELECT COUNT(DISTINCT session_id) FROM analytics_events WHERE created_at > CURRENT_DATE) as sessions_today,
    (SELECT COUNT(*) FROM analytics_events WHERE event_type = 'page_view' AND created_at > CURRENT_DATE) as pageviews_today,
    (SELECT COUNT(*) FROM pumpkin_patch_orders WHERE created_at > CURRENT_DATE) as bookings_today,
    (SELECT COUNT(*) FROM pumpkin_patch_orders WHERE payment_status = 'paid' AND created_at > CURRENT_DATE) as paid_bookings_today,
    (SELECT SUM(total_amount) FROM pumpkin_patch_orders WHERE payment_status = 'paid' AND created_at > CURRENT_DATE) as revenue_today,

    -- Last 24 hours
    (SELECT COUNT(DISTINCT session_id) FROM analytics_events WHERE created_at > NOW() - INTERVAL '24 hours') as sessions_24h,
    (SELECT COUNT(*) FROM pumpkin_patch_orders WHERE created_at > NOW() - INTERVAL '24 hours') as bookings_24h,

    -- Last hour
    (SELECT COUNT(DISTINCT session_id) FROM analytics_events WHERE created_at > NOW() - INTERVAL '1 hour') as sessions_last_hour,
    (SELECT COUNT(*) FROM analytics_events WHERE event_type = 'page_view' AND created_at > NOW() - INTERVAL '1 hour') as pageviews_last_hour,

    -- Active now (last 5 minutes)
    (SELECT COUNT(DISTINCT session_id) FROM analytics_events WHERE created_at > NOW() - INTERVAL '5 minutes') as active_sessions_now;

-- ========================================================================
-- 6. RLS POLICIES
-- ========================================================================

ALTER TABLE analytics_events ENABLE ROW LEVEL SECURITY;

-- Allow anonymous users to insert analytics events
DROP POLICY IF EXISTS "Allow anon to insert analytics" ON analytics_events;
CREATE POLICY "Allow anon to insert analytics"
  ON analytics_events
  FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);

-- Allow authenticated users to read analytics (admin only)
DROP POLICY IF EXISTS "Allow authenticated to read analytics" ON analytics_events;
CREATE POLICY "Allow authenticated to read analytics"
  ON analytics_events
  FOR SELECT
  TO authenticated
  USING (true);

-- Grant permissions
GRANT SELECT, INSERT ON analytics_events TO anon, authenticated;
GRANT SELECT ON analytics_daily_summary TO authenticated;
GRANT SELECT ON analytics_conversion_funnel TO authenticated;
GRANT SELECT ON analytics_top_pages TO authenticated;
GRANT SELECT ON analytics_booking_stats TO authenticated;
GRANT SELECT ON analytics_abandoned_bookings TO authenticated;
GRANT SELECT ON analytics_realtime_dashboard TO authenticated;

-- ========================================================================
-- 7. HELPER FUNCTIONS
-- ========================================================================

-- Function to get conversion rate between two event types
CREATE OR REPLACE FUNCTION get_conversion_rate(
    start_event TEXT,
    end_event TEXT,
    days_ago INTEGER DEFAULT 7
)
RETURNS NUMERIC AS $$
DECLARE
    start_count INTEGER;
    end_count INTEGER;
BEGIN
    SELECT COUNT(DISTINCT session_id) INTO start_count
    FROM analytics_events
    WHERE event_type = start_event
      AND created_at > NOW() - (days_ago || ' days')::INTERVAL;

    SELECT COUNT(DISTINCT session_id) INTO end_count
    FROM analytics_events
    WHERE event_type = end_event
      AND created_at > NOW() - (days_ago || ' days')::INTERVAL;

    IF start_count = 0 THEN
        RETURN 0;
    END IF;

    RETURN ROUND((end_count::NUMERIC / start_count * 100), 2);
END;
$$ LANGUAGE plpgsql;

-- ========================================================================
-- 8. VERIFICATION
-- ========================================================================

SELECT 'Analytics system created successfully!' as status;

SELECT
    'Table: analytics_events' as component,
    COUNT(*) as row_count
FROM analytics_events
UNION ALL
SELECT
    'RLS Enabled',
    CASE WHEN rowsecurity THEN 1 ELSE 0 END
FROM pg_tables
WHERE tablename = 'analytics_events'
UNION ALL
SELECT
    'Policies Created',
    COUNT(*)::INTEGER
FROM pg_policies
WHERE tablename = 'analytics_events';
