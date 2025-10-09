-- Admin Notification System Database Schema

-- Table to store admin notification settings
CREATE TABLE IF NOT EXISTS admin_notification_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    admin_email TEXT NOT NULL,
    admin_name TEXT NOT NULL,
    notify_on_order_created BOOLEAN DEFAULT true,
    notify_on_order_paid BOOLEAN DEFAULT true,
    notify_on_abandoned_order BOOLEAN DEFAULT true,
    notify_daily_summary BOOLEAN DEFAULT true,
    daily_summary_time TIME DEFAULT '09:00:00', -- Time to send daily summary
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(admin_email)
);

-- Table to log notification events
CREATE TABLE IF NOT EXISTS admin_notification_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    notification_type TEXT NOT NULL, -- 'order_created', 'order_paid', 'abandoned_order', 'daily_summary'
    recipient_email TEXT NOT NULL,
    subject TEXT NOT NULL,
    order_id UUID REFERENCES pumpkin_patch_orders(id), -- NULL for daily summaries
    status TEXT NOT NULL DEFAULT 'pending', -- 'pending', 'sent', 'failed'
    resend_id TEXT,
    error_message TEXT,
    sent_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table to track analytics events (button clicks, page views, etc.)
CREATE TABLE IF NOT EXISTS analytics_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_type TEXT NOT NULL, -- 'button_click', 'page_view', 'form_submit', etc.
    event_category TEXT, -- 'booking', 'navigation', 'checkout', etc.
    event_label TEXT, -- Specific button/link text or identifier
    event_value TEXT, -- Additional data (e.g., which activity was booked)
    page_url TEXT,
    user_session_id TEXT, -- Client-generated session ID for tracking unique users
    user_ip TEXT,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_notification_log_type ON admin_notification_log(notification_type);
CREATE INDEX IF NOT EXISTS idx_notification_log_created ON admin_notification_log(created_at);
CREATE INDEX IF NOT EXISTS idx_notification_log_order ON admin_notification_log(order_id);
CREATE INDEX IF NOT EXISTS idx_analytics_events_type ON analytics_events(event_type);
CREATE INDEX IF NOT EXISTS idx_analytics_events_created ON analytics_events(created_at);
CREATE INDEX IF NOT EXISTS idx_analytics_events_category ON analytics_events(event_category);

-- RLS Policies for admin_notification_settings
ALTER TABLE admin_notification_settings ENABLE ROW LEVEL SECURITY;

-- Authenticated users can read settings (admins only in practice)
CREATE POLICY "Authenticated users can read notification settings" ON admin_notification_settings
    FOR SELECT TO authenticated USING (true);

-- Authenticated users can update settings (admins only in practice)
CREATE POLICY "Authenticated users can update notification settings" ON admin_notification_settings
    FOR UPDATE TO authenticated USING (true);

-- Authenticated users can insert settings
CREATE POLICY "Authenticated users can insert notification settings" ON admin_notification_settings
    FOR INSERT TO authenticated WITH CHECK (true);

-- RLS Policies for admin_notification_log
ALTER TABLE admin_notification_log ENABLE ROW LEVEL SECURITY;

-- Allow service role to insert notification logs
CREATE POLICY "Service role can insert notification logs" ON admin_notification_log
    FOR INSERT TO authenticated WITH CHECK (true);

-- Authenticated users can read notification logs
CREATE POLICY "Authenticated users can read notification logs" ON admin_notification_log
    FOR SELECT TO authenticated USING (true);

-- RLS Policies for analytics_events
ALTER TABLE analytics_events ENABLE ROW LEVEL SECURITY;

-- Allow anonymous users to insert analytics events
CREATE POLICY "Anyone can insert analytics events" ON analytics_events
    FOR INSERT TO anon, authenticated WITH CHECK (true);

-- Authenticated users can read analytics events
CREATE POLICY "Authenticated users can read analytics events" ON analytics_events
    FOR SELECT TO authenticated USING (true);

-- Grant necessary permissions
GRANT SELECT, INSERT, UPDATE ON admin_notification_settings TO authenticated;
GRANT SELECT, INSERT ON admin_notification_log TO authenticated, anon;
GRANT SELECT, INSERT ON analytics_events TO authenticated, anon;

-- Insert default admin notification settings (update email as needed)
INSERT INTO admin_notification_settings (admin_email, admin_name)
VALUES ('martin@guidal.org', 'Martin Picard')
ON CONFLICT (admin_email) DO NOTHING;

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger to update updated_at on admin_notification_settings
DROP TRIGGER IF EXISTS update_admin_notification_settings_updated_at ON admin_notification_settings;
CREATE TRIGGER update_admin_notification_settings_updated_at
    BEFORE UPDATE ON admin_notification_settings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

COMMENT ON TABLE admin_notification_settings IS 'Stores admin email notification preferences';
COMMENT ON TABLE admin_notification_log IS 'Logs all admin notifications sent';
COMMENT ON TABLE analytics_events IS 'Tracks user interactions and button clicks for analytics';
