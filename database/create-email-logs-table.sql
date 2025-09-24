-- =====================================================
-- Email Logs Table for Tracking Invoice Emails
-- Run this in your Supabase SQL Editor
-- =====================================================

CREATE TABLE IF NOT EXISTS email_logs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,

    -- Reference to the visit
    visit_id UUID REFERENCES visits(id) ON DELETE CASCADE,

    -- Email details
    recipient TEXT NOT NULL,
    email_type TEXT NOT NULL DEFAULT 'invoice', -- 'invoice', 'confirmation', 'reminder', etc.
    email_id TEXT, -- External email service ID (e.g., Resend email ID)

    -- Email content tracking
    subject TEXT,
    status TEXT NOT NULL DEFAULT 'sent', -- 'sent', 'delivered', 'bounced', 'failed'

    -- Timestamps
    sent_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    delivered_at TIMESTAMP WITH TIME ZONE,
    opened_at TIMESTAMP WITH TIME ZONE,
    clicked_at TIMESTAMP WITH TIME ZONE,

    -- Additional metadata
    user_agent TEXT,
    ip_address INET,
    error_message TEXT,

    -- Tracking
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_email_logs_visit_id ON email_logs(visit_id);
CREATE INDEX IF NOT EXISTS idx_email_logs_recipient ON email_logs(recipient);
CREATE INDEX IF NOT EXISTS idx_email_logs_email_type ON email_logs(email_type);
CREATE INDEX IF NOT EXISTS idx_email_logs_status ON email_logs(status);
CREATE INDEX IF NOT EXISTS idx_email_logs_sent_at ON email_logs(sent_at);

-- Add RLS (Row Level Security)
ALTER TABLE email_logs ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to read email logs
CREATE POLICY "Authenticated users can view email logs" ON email_logs
    FOR SELECT USING (auth.role() = 'authenticated');

-- Allow service role to manage email logs
CREATE POLICY "Service role can manage email logs" ON email_logs
    FOR ALL USING (auth.role() = 'service_role');

-- Grant permissions
GRANT SELECT ON email_logs TO authenticated;
GRANT ALL ON email_logs TO service_role;

-- Add some constraints
ALTER TABLE email_logs ADD CONSTRAINT email_logs_email_type_check
    CHECK (email_type IN ('invoice', 'confirmation', 'reminder', 'update', 'cancellation'));

ALTER TABLE email_logs ADD CONSTRAINT email_logs_status_check
    CHECK (status IN ('sent', 'delivered', 'opened', 'clicked', 'bounced', 'failed', 'complained'));

-- Create a function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_email_logs_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger for updated_at
CREATE TRIGGER update_email_logs_updated_at
    BEFORE UPDATE ON email_logs
    FOR EACH ROW
    EXECUTE FUNCTION update_email_logs_updated_at();

-- Create a view for email analytics
CREATE OR REPLACE VIEW email_analytics AS
SELECT
    email_type,
    status,
    COUNT(*) as count,
    DATE_TRUNC('day', sent_at) as date
FROM email_logs
GROUP BY email_type, status, DATE_TRUNC('day', sent_at)
ORDER BY date DESC, email_type, status;

-- Grant access to the view
GRANT SELECT ON email_analytics TO authenticated, service_role;