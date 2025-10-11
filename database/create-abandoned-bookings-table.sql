-- Create table to track abandoned bookings
-- Captures emails of users who started but didn't complete booking

CREATE TABLE IF NOT EXISTS abandoned_bookings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT NOT NULL,
    first_name TEXT,
    last_name TEXT,
    phone TEXT,
    cart_items JSONB, -- Store what they were trying to book
    cart_total NUMERIC(10,2),
    page_url TEXT DEFAULT 'https://guidal.org/events/pumpkin-patch-checkout.html',

    -- Tracking fields
    started_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_activity_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP WITH TIME ZONE, -- Set when they complete booking
    recovery_email_sent_at TIMESTAMP WITH TIME ZONE,
    recovery_email_opened_at TIMESTAMP WITH TIME ZONE,
    recovery_email_clicked_at TIMESTAMP WITH TIME ZONE,

    -- Status
    status TEXT DEFAULT 'abandoned' CHECK (status IN ('abandoned', 'recovered', 'completed', 'ignored')),

    -- Metadata
    user_agent TEXT,
    session_id TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create index for fast lookups
CREATE INDEX IF NOT EXISTS idx_abandoned_bookings_email ON abandoned_bookings(email);
CREATE INDEX IF NOT EXISTS idx_abandoned_bookings_status ON abandoned_bookings(status);
CREATE INDEX IF NOT EXISTS idx_abandoned_bookings_started_at ON abandoned_bookings(started_at);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_abandoned_bookings_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update updated_at
DROP TRIGGER IF EXISTS update_abandoned_bookings_timestamp ON abandoned_bookings;
CREATE TRIGGER update_abandoned_bookings_timestamp
    BEFORE UPDATE ON abandoned_bookings
    FOR EACH ROW
    EXECUTE FUNCTION update_abandoned_bookings_updated_at();

-- Enable RLS
ALTER TABLE abandoned_bookings ENABLE ROW LEVEL SECURITY;

-- Allow anonymous users to insert and update their own records
DROP POLICY IF EXISTS "Allow anon to track abandonments" ON abandoned_bookings;
CREATE POLICY "Allow anon to track abandonments"
  ON abandoned_bookings
  FOR ALL
  TO anon, authenticated
  USING (true)
  WITH CHECK (true);

-- Grant permissions
GRANT SELECT, INSERT, UPDATE ON abandoned_bookings TO anon, authenticated;

-- Verify setup
SELECT
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables
WHERE tablename = 'abandoned_bookings';

SELECT
    policyname,
    cmd,
    roles
FROM pg_policies
WHERE tablename = 'abandoned_bookings';
