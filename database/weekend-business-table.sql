-- Create weekend_business_interest table for storing business opportunity leads

CREATE TABLE IF NOT EXISTS public.weekend_business_interest (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    interest_description TEXT NOT NULL,
    workshop_type VARCHAR(50) NOT NULL DEFAULT 'robotic_gardening',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Add constraint to ensure valid workshop types
ALTER TABLE public.weekend_business_interest
ADD CONSTRAINT check_workshop_type
CHECK (workshop_type IN ('robotic_gardening', 'composting', 'permaculture', 'renewable_energy', 'other'));

-- Create an index on email for faster lookups
CREATE INDEX IF NOT EXISTS idx_weekend_business_interest_email
ON public.weekend_business_interest(email);

-- Create an index on workshop_type for filtering
CREATE INDEX IF NOT EXISTS idx_weekend_business_interest_workshop_type
ON public.weekend_business_interest(workshop_type);

-- Enable Row Level Security (RLS)
ALTER TABLE public.weekend_business_interest ENABLE ROW LEVEL SECURITY;

-- Create policy to allow everyone to read and insert (for educational purposes)
CREATE POLICY "Allow all operations for weekend business interest"
ON public.weekend_business_interest
FOR ALL
USING (true)
WITH CHECK (true);

-- Grant permissions
GRANT ALL ON public.weekend_business_interest TO anon;
GRANT ALL ON public.weekend_business_interest TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE weekend_business_interest_id_seq TO anon;
GRANT USAGE, SELECT ON SEQUENCE weekend_business_interest_id_seq TO authenticated;

-- Sample data for testing (optional)
INSERT INTO public.weekend_business_interest (
    name, email, interest_description, workshop_type
) VALUES (
    'Jane Entrepreneur', 'jane@example.com', 'I love teaching kids about technology and see a great opportunity to combine robotics with sustainable gardening. I have experience with Arduino and would love to create hands-on workshops for local schools.', 'robotic_gardening'
) ON CONFLICT (email) DO NOTHING;

-- Verify the table was created correctly
SELECT
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'weekend_business_interest'
ORDER BY ordinal_position;