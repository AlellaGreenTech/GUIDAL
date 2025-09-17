-- Create station_votes table for collecting anonymous station preferences
-- Supports both regular and privacy mode voting

CREATE TABLE IF NOT EXISTS public.station_votes (
    id SERIAL PRIMARY KEY,
    visit_type VARCHAR(50) NOT NULL, -- 'prague', 'bfis', 'st-george', etc.
    station_id VARCHAR(100) NOT NULL, -- 'planting', 'composting', 'robotic-gardening', etc.
    privacy_mode BOOLEAN DEFAULT FALSE, -- TRUE for anonymous submissions
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL, -- NULL for privacy mode
    session_id VARCHAR(255), -- Browser session for privacy mode deduplication
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_station_votes_visit_type
ON public.station_votes(visit_type);

CREATE INDEX IF NOT EXISTS idx_station_votes_station_id
ON public.station_votes(station_id);

CREATE INDEX IF NOT EXISTS idx_station_votes_created_at
ON public.station_votes(created_at);

CREATE INDEX IF NOT EXISTS idx_station_votes_privacy_mode
ON public.station_votes(privacy_mode);

-- Enable Row Level Security (RLS)
ALTER TABLE public.station_votes ENABLE ROW LEVEL SECURITY;

-- Create policy to allow all operations for voting (public participation)
CREATE POLICY "Allow public voting operations"
ON public.station_votes
FOR ALL
USING (true)
WITH CHECK (true);

-- Grant permissions for anonymous and authenticated users
GRANT ALL ON public.station_votes TO anon;
GRANT ALL ON public.station_votes TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE station_votes_id_seq TO anon;
GRANT USAGE, SELECT ON SEQUENCE station_votes_id_seq TO authenticated;

-- Insert some sample data for testing
INSERT INTO public.station_votes (visit_type, station_id, privacy_mode) VALUES
('prague', 'planting', true),
('prague', 'composting', true),
('prague', 'robotic-gardening', true),
('prague', 'schoolair', true),
('prague', 'planting', true),
('prague', 'ram-pumps', true),
('prague', 'wattle-daub', true),
('prague', 'erosion-challenge', true)
ON CONFLICT DO NOTHING;

-- Verify the table was created correctly
SELECT
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'station_votes'
ORDER BY ordinal_position;