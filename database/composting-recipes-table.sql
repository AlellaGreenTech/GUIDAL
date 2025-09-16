-- Create composting_recipes table for storing student group composting recipes

CREATE TABLE IF NOT EXISTS public.composting_recipes (
    id SERIAL PRIMARY KEY,
    group_number INTEGER NOT NULL UNIQUE,
    biomass DECIMAL(5,2) NOT NULL DEFAULT 0,
    horse_manure DECIMAL(5,2) NOT NULL DEFAULT 0,
    cow_manure DECIMAL(5,2) NOT NULL DEFAULT 0,
    recebo_soil DECIMAL(5,2) NOT NULL DEFAULT 0,
    sand DECIMAL(5,2) NOT NULL DEFAULT 0,
    water DECIMAL(5,2) NOT NULL DEFAULT 0,
    other_material VARCHAR(255),
    other_percentage DECIMAL(5,2) NOT NULL DEFAULT 0,
    total_percentage DECIMAL(5,2) NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Add constraint to ensure total_percentage is 100
ALTER TABLE public.composting_recipes
ADD CONSTRAINT check_total_percentage
CHECK (total_percentage = 100);

-- Add constraint to ensure group_number is valid (1-10, or special values for staff/other)
-- We'll store staff as -1 and other as -2 to maintain integer type
ALTER TABLE public.composting_recipes
ADD CONSTRAINT check_group_number
CHECK (group_number >= -2 AND group_number <= 10 AND group_number != 0);

-- Add constraint to ensure all percentages are non-negative and <= 100
ALTER TABLE public.composting_recipes
ADD CONSTRAINT check_positive_percentages
CHECK (
    biomass >= 0 AND biomass <= 100 AND
    horse_manure >= 0 AND horse_manure <= 100 AND
    cow_manure >= 0 AND cow_manure <= 100 AND
    recebo_soil >= 0 AND recebo_soil <= 100 AND
    sand >= 0 AND sand <= 100 AND
    water >= 0 AND water <= 100 AND
    other_percentage >= 0 AND other_percentage <= 100
);

-- Create an index on group_number for faster lookups
CREATE INDEX IF NOT EXISTS idx_composting_recipes_group_number
ON public.composting_recipes(group_number);

-- Enable Row Level Security (RLS)
ALTER TABLE public.composting_recipes ENABLE ROW LEVEL SECURITY;

-- Create policy to allow everyone to read and insert (for educational purposes)
CREATE POLICY "Allow all operations for composting recipes"
ON public.composting_recipes
FOR ALL
USING (true)
WITH CHECK (true);

-- Grant permissions
GRANT ALL ON public.composting_recipes TO anon;
GRANT ALL ON public.composting_recipes TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE composting_recipes_id_seq TO anon;
GRANT USAGE, SELECT ON SEQUENCE composting_recipes_id_seq TO authenticated;

-- Sample data for testing (optional) - using valid group number
INSERT INTO public.composting_recipes (
    group_number, biomass, horse_manure, cow_manure, recebo_soil, sand, water, total_percentage
) VALUES (
    1, 40.0, 20.0, 15.0, 10.0, 5.0, 10.0, 100.0
) ON CONFLICT (group_number) DO NOTHING;

-- Verify the table was created correctly
SELECT
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'composting_recipes'
ORDER BY ordinal_position;