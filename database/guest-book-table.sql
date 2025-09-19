-- Create or update guest_book_entries table for visit guest book functionality

-- Create the table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.guest_book_entries (
    id SERIAL PRIMARY KEY,
    visit_id UUID REFERENCES public.activities(id),
    student_name VARCHAR(255) NOT NULL,
    group_name VARCHAR(50),
    favorite_station VARCHAR(100),
    interests VARCHAR(255),
    message TEXT NOT NULL,
    photo_url VARCHAR(500),
    instagram_handle VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Add new columns if they don't exist (for existing installations)
DO $$
BEGIN
    -- Add group_name column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'guest_book_entries' AND column_name = 'group_name') THEN
        ALTER TABLE public.guest_book_entries ADD COLUMN group_name VARCHAR(50);
    END IF;

    -- Add favorite_station column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'guest_book_entries' AND column_name = 'favorite_station') THEN
        ALTER TABLE public.guest_book_entries ADD COLUMN favorite_station VARCHAR(100);
    END IF;

    -- Add interests column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'guest_book_entries' AND column_name = 'interests') THEN
        ALTER TABLE public.guest_book_entries ADD COLUMN interests VARCHAR(255);
    END IF;
END $$;

-- Add constraint to ensure valid interest selections
ALTER TABLE public.guest_book_entries
DROP CONSTRAINT IF EXISTS check_valid_interests;

ALTER TABLE public.guest_book_entries
ADD CONSTRAINT check_valid_interests
CHECK (interests IN (
    'Volunteering',
    'Building cool stuff',
    'The gardening robot',
    'Doing R&D with microcontrollers',
    'The SchoolAIR project',
    'Tending animals',
    'Gardening at AGT',
    'Starting a weekend workshop or similar business at AGT',
    'Receiving cool stuff to read'
));

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_guest_book_entries_visit_id
ON public.guest_book_entries(visit_id);

CREATE INDEX IF NOT EXISTS idx_guest_book_entries_interests
ON public.guest_book_entries(interests);

CREATE INDEX IF NOT EXISTS idx_guest_book_entries_favorite_station
ON public.guest_book_entries(favorite_station);

CREATE INDEX IF NOT EXISTS idx_guest_book_entries_created_at
ON public.guest_book_entries(created_at DESC);

-- Enable Row Level Security (RLS)
ALTER TABLE public.guest_book_entries ENABLE ROW LEVEL SECURITY;

-- Drop existing policy if it exists and recreate
DROP POLICY IF EXISTS "Allow all operations for guest book entries" ON public.guest_book_entries;

CREATE POLICY "Allow all operations for guest book entries"
ON public.guest_book_entries
FOR ALL
USING (true)
WITH CHECK (true);

-- Grant permissions
GRANT ALL ON public.guest_book_entries TO anon;
GRANT ALL ON public.guest_book_entries TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE guest_book_entries_id_seq TO anon;
GRANT USAGE, SELECT ON SEQUENCE guest_book_entries_id_seq TO authenticated;

-- Sample data for testing (optional - commented out to avoid issues)
-- Uncomment and modify if you want to add test data:
-- INSERT INTO public.guest_book_entries (
--     student_name, group_name, favorite_station, interests, message
-- ) VALUES (
--     'Test Student', 'Group 1', 'Robotic Gardening', 'Building cool stuff', 'Amazing experience learning about sustainable technology!'
-- );

-- Verify the table structure
SELECT
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'guest_book_entries'
ORDER BY ordinal_position;