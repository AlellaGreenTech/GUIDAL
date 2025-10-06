-- Add email_logs table for tracking sent emails
-- This allows you to see what emails were sent and resend if needed

CREATE TABLE IF NOT EXISTS public.email_logs (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  order_id UUID REFERENCES public.pumpkin_patch_orders(id) ON DELETE SET NULL,
  recipient_email TEXT NOT NULL,
  email_type TEXT NOT NULL, -- e.g., 'order_confirmation', 'payment_reminder', 'payment_received'
  subject TEXT NOT NULL,
  html_content TEXT NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'failed')),
  sent_at TIMESTAMP WITH TIME ZONE,
  error_message TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index for quick lookups
CREATE INDEX IF NOT EXISTS idx_email_logs_order_id ON public.email_logs(order_id);
CREATE INDEX IF NOT EXISTS idx_email_logs_recipient ON public.email_logs(recipient_email);
CREATE INDEX IF NOT EXISTS idx_email_logs_status ON public.email_logs(status);

-- Enable RLS
ALTER TABLE public.email_logs ENABLE ROW LEVEL SECURITY;

-- Allow inserts from anyone (for logging)
CREATE POLICY "Allow insert email logs"
  ON public.email_logs
  FOR INSERT
  TO public
  WITH CHECK (true);

-- Only admins can view email logs
CREATE POLICY "Admins can view email logs"
  ON public.email_logs
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.user_type = 'admin'
    )
  );

-- Grant permissions
GRANT INSERT ON public.email_logs TO anon, authenticated, postgres;
GRANT SELECT ON public.email_logs TO authenticated, postgres;

-- Success message
DO $$
BEGIN
  RAISE NOTICE 'Email logs table created successfully!';
END $$;
