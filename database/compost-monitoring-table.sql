-- Create compost_monitoring_plans table for storing student monitoring system proposals

CREATE TABLE IF NOT EXISTS public.compost_monitoring_plans (
    id SERIAL PRIMARY KEY,
    group_number INTEGER NOT NULL UNIQUE,
    monitoring_system TEXT NOT NULL,
    weekend_build VARCHAR(10) NOT NULL CHECK (weekend_build IN ('yes', 'no', 'maybe')),
    student_name VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Add constraint to ensure group_number is between 1 and 10
ALTER TABLE public.compost_monitoring_plans
ADD CONSTRAINT check_group_number_monitoring
CHECK (group_number >= 1 AND group_number <= 10);

-- Create an index on group_number for faster lookups
CREATE INDEX IF NOT EXISTS idx_compost_monitoring_plans_group_number
ON public.compost_monitoring_plans(group_number);

-- Enable Row Level Security (RLS)
ALTER TABLE public.compost_monitoring_plans ENABLE ROW LEVEL SECURITY;

-- Create policy to allow everyone to read and insert (for educational purposes)
CREATE POLICY "Allow all operations for monitoring plans"
ON public.compost_monitoring_plans
FOR ALL
USING (true)
WITH CHECK (true);

-- Grant permissions
GRANT ALL ON public.compost_monitoring_plans TO anon;
GRANT ALL ON public.compost_monitoring_plans TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE compost_monitoring_plans_id_seq TO anon;
GRANT USAGE, SELECT ON SEQUENCE compost_monitoring_plans_id_seq TO authenticated;

-- Verify the table was created correctly
SELECT
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'compost_monitoring_plans'
ORDER BY ordinal_position;