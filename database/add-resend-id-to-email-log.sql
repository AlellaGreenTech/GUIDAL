-- Add resend_id column to pumpkin_patch_email_log table
ALTER TABLE pumpkin_patch_email_log
ADD COLUMN IF NOT EXISTS resend_id TEXT;

-- Add index for faster lookups
CREATE INDEX IF NOT EXISTS idx_email_log_resend_id ON pumpkin_patch_email_log(resend_id);

-- Verify the column was added
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'pumpkin_patch_email_log'
ORDER BY ordinal_position;
