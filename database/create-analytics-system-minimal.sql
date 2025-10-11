-- ========================================================================
-- COMPREHENSIVE ANALYTICS SYSTEM FOR GUIDAL (MINIMAL VERSION)
-- ========================================================================
-- This version works without abandoned_bookings table
-- ========================================================================

-- Drop existing table if it exists (careful - this deletes data!)
DROP TABLE IF EXISTS analytics_events CASCADE;

-- ========================================================================
-- 1. ANALYTICS EVENTS TABLE
-- ========================================================================

CREATE TABLE analytics_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- Event identification
    event_type TEXT NOT NULL,
    event_category TEXT,
    event_name TEXT,
    event_value NUMERIC,

    -- Page context
    page_url TEXT,
    page_title TEXT,
    referrer_url TEXT,

    -- User context
    session_id TEXT,
    user_id UUID,
    visitor_id TEXT,
    is_returning_visitor BOOLEAN DEFAULT false,

    -- Device & browser
    user_agent TEXT,
    device_type TEXT,
    browser TEXT,
    os TEXT,
    screen_resolution TEXT,

    -- Location
    ip_address INET,
    country TEXT,
    city TEXT,

    -- Related entities
    order_id UUID,
    abandoned_booking_id UUID,

    -- Metadata
    metadata JSONB,

    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Add foreign key constraint to orders (only if exists)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'pumpkin_patch_orders') THEN
        ALTER TABLE analytics_events
          ADD CONSTRAINT fk_analytics_order
          FOREIGN KEY (order_id) REFERENCES pumpkin_patch_orders(id) ON DELETE SET NULL;
    END IF;
END $$;

-- Indexes for performance
CREATE INDEX idx_analytics_events_type ON analytics_events(event_type);
CREATE INDEX idx_analytics_events_category ON analytics_events(event_category);
CREATE INDEX idx_analytics_events_created_at ON analytics_events(created_at);
CREATE INDEX idx_analytics_events_session ON analytics_events(session_id);
CREATE INDEX idx_analytics_events_visitor ON analytics_events(visitor_id);
CREATE INDEX idx_analytics_events_order ON analytics_events(order_id);

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
-- 3. BOOKING STATISTICS VIEW (only if table exists)
-- ========================================================================

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'pumpkin_patch_orders') THEN
        EXECUTE '
        CREATE OR REPLACE VIEW analytics_booking_stats AS
        SELECT
            DATE(created_at) as date,
            COUNT(*) as total_bookings,
            COUNT(*) FILTER (WHERE payment_status = ''paid'') as paid_bookings,
            COUNT(*) FILTER (WHERE payment_status = ''pending'') as pending_bookings,
            SUM(total_amount) as total_revenue,
            SUM(total_amount) FILTER (WHERE payment_status = ''paid'') as paid_revenue,
            SUM(total_amount) FILTER (WHERE payment_status = ''pending'') as pending_revenue,
            ROUND(AVG(total_amount), 2) as avg_order_value,
            ROUND(AVG(adult_count + child_count), 2) as avg_party_size,
            SUM(adult_count) as total_adults,
            SUM(child_count) as total_children
        FROM pumpkin_patch_orders
        GROUP BY DATE(created_at)
        ORDER BY date DESC';
    END IF;
END $$;

-- ========================================================================
-- 4. ABANDONED BOOKING ANALYTICS VIEW (only if table exists)
-- ========================================================================

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'abandoned_bookings') THEN
        EXECUTE '
        CREATE OR REPLACE VIEW analytics_abandoned_bookings AS
        SELECT
            DATE(started_at) as date,
            COUNT(*) as total_abandoned,
            COUNT(*) FILTER (WHERE status = ''completed'') as recovered_naturally,
            COUNT(*) FILTER (WHERE status = ''recovered'') as recovered_via_email,
            COUNT(*) FILTER (WHERE recovery_email_sent_at IS NOT NULL) as recovery_emails_sent,
            SUM(cart_total) as potential_revenue_lost,
            SUM(cart_total) FILTER (WHERE status IN (''completed'', ''recovered'')) as revenue_recovered,
            ROUND(
                COUNT(*) FILTER (WHERE status IN (''completed'', ''recovered''))::NUMERIC /
                NULLIF(COUNT(*), 0) * 100,
                2
            ) as recovery_rate,
            ROUND(
                COUNT(*) FILTER (WHERE status = ''recovered'')::NUMERIC /
                NULLIF(COUNT(*) FILTER (WHERE recovery_email_sent_at IS NOT NULL), 0) * 100,
                2
            ) as email_recovery_rate
        FROM abandoned_bookings
        GROUP BY DATE(started_at)
        ORDER BY date DESC';
    END IF;
END $$;

-- ========================================================================
-- 5. REAL-TIME DASHBOARD VIEW
-- ========================================================================

CREATE OR REPLACE VIEW analytics_realtime_dashboard AS
SELECT
    (SELECT COUNT(DISTINCT session_id) FROM analytics_events WHERE created_at > CURRENT_DATE) as sessions_today,
    (SELECT COUNT(*) FROM analytics_events WHERE event_type = 'page_view' AND created_at > CURRENT_DATE) as pageviews_today,
    (SELECT COALESCE(COUNT(*), 0) FROM pumpkin_patch_orders WHERE created_at > CURRENT_DATE) as bookings_today,
    (SELECT COALESCE(COUNT(*), 0) FROM pumpkin_patch_orders WHERE payment_status = 'paid' AND created_at > CURRENT_DATE) as paid_bookings_today,
    (SELECT COALESCE(SUM(total_amount), 0) FROM pumpkin_patch_orders WHERE payment_status = 'paid' AND created_at > CURRENT_DATE) as revenue_today,
    (SELECT COUNT(DISTINCT session_id) FROM analytics_events WHERE created_at > NOW() - INTERVAL '24 hours') as sessions_24h,
    (SELECT COALESCE(COUNT(*), 0) FROM pumpkin_patch_orders WHERE created_at > NOW() - INTERVAL '24 hours') as bookings_24h,
    (SELECT COUNT(DISTINCT session_id) FROM analytics_events WHERE created_at > NOW() - INTERVAL '1 hour') as sessions_last_hour,
    (SELECT COUNT(*) FROM analytics_events WHERE event_type = 'page_view' AND created_at > NOW() - INTERVAL '1 hour') as pageviews_last_hour,
    (SELECT COUNT(DISTINCT session_id) FROM analytics_events WHERE created_at > NOW() - INTERVAL '5 minutes') as active_sessions_now;

-- ========================================================================
-- 6. RLS POLICIES
-- ========================================================================

ALTER TABLE analytics_events ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow anon to insert analytics" ON analytics_events;
CREATE POLICY "Allow anon to insert analytics"
  ON analytics_events
  FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);

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
GRANT SELECT ON analytics_realtime_dashboard TO authenticated;

-- Grant on optional views if they exist
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.views WHERE table_name = 'analytics_booking_stats') THEN
        GRANT SELECT ON analytics_booking_stats TO authenticated;
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.views WHERE table_name = 'analytics_abandoned_bookings') THEN
        GRANT SELECT ON analytics_abandoned_bookings TO authenticated;
    END IF;
END $$;

-- ========================================================================
-- 7. VERIFICATION
-- ========================================================================

SELECT '✅ Analytics system created successfully!' as status;

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
