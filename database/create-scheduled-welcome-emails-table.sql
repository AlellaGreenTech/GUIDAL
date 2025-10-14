-- Create scheduled_welcome_emails table for account creation welcome emails
CREATE TABLE IF NOT EXISTS scheduled_welcome_emails (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT NOT NULL,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    qr_code_data TEXT NOT NULL,
    order_id UUID,
    scheduled_for TIMESTAMP WITH TIME ZONE NOT NULL,
    sent_at TIMESTAMP WITH TIME ZONE,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'failed')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for efficient querying of pending emails
CREATE INDEX IF NOT EXISTS idx_scheduled_welcome_emails_status_date
ON scheduled_welcome_emails(status, scheduled_for);

-- Enable RLS
ALTER TABLE scheduled_welcome_emails ENABLE ROW LEVEL SECURITY;

-- Policy: Service role can do everything
CREATE POLICY "Service role has full access to scheduled_welcome_emails"
ON scheduled_welcome_emails
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);
