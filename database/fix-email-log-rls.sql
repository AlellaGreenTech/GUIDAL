-- Drop the table if it exists (to recreate it properly)
DROP TABLE IF EXISTS pumpkin_patch_email_log CASCADE;

-- Create pumpkin_patch_email_log table with correct structure
CREATE TABLE pumpkin_patch_email_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID REFERENCES pumpkin_patch_orders(id),
    template_type TEXT NOT NULL,
    recipient_email TEXT NOT NULL,
    subject TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending',
    sent_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    resend_id TEXT,
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Enable RLS
ALTER TABLE pumpkin_patch_email_log ENABLE ROW LEVEL SECURITY;

-- Create new permissive policies
CREATE POLICY "Allow all to insert email logs"
  ON pumpkin_patch_email_log
  FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);

CREATE POLICY "Allow all to read email logs"
  ON pumpkin_patch_email_log
  FOR SELECT
  TO anon, authenticated
  USING (true);

-- Grant permissions
GRANT SELECT, INSERT ON pumpkin_patch_email_log TO anon, authenticated;

-- Create indexes for performance
CREATE INDEX idx_email_log_order_id ON pumpkin_patch_email_log(order_id);
CREATE INDEX idx_email_log_created ON pumpkin_patch_email_log(created_at);

-- Verify the table was created
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_name = 'pumpkin_patch_email_log'
ORDER BY ordinal_position;
