-- Fix group_number constraints to allow multiple staff and other entries
-- while still preventing duplicate numbered groups (1-10)

-- Fix composting_recipes table
ALTER TABLE public.composting_recipes
DROP CONSTRAINT IF EXISTS composting_recipes_group_number_key;

-- Drop existing constraint
ALTER TABLE public.composting_recipes
DROP CONSTRAINT IF EXISTS check_group_number;

-- Add updated constraint that allows multiple staff (-1) and other (-2) entries
-- but still prevents duplicate numbered groups (1-10)
ALTER TABLE public.composting_recipes
ADD CONSTRAINT check_group_number
CHECK (group_number >= -2 AND group_number <= 10 AND group_number != 0);

-- Create a unique constraint only for numbered groups (1-10)
-- This allows multiple staff and other entries while preventing duplicate numbered groups
CREATE UNIQUE INDEX IF NOT EXISTS idx_unique_numbered_groups_recipes
ON public.composting_recipes (group_number)
WHERE group_number > 0;

-- Fix compost_monitoring_plans table
ALTER TABLE public.compost_monitoring_plans
DROP CONSTRAINT IF EXISTS compost_monitoring_plans_group_number_key;

-- Drop existing constraint (already handled by the existing script)
-- CREATE a unique constraint only for numbered groups (1-10)
CREATE UNIQUE INDEX IF NOT EXISTS idx_unique_numbered_groups_monitoring
ON public.compost_monitoring_plans (group_number)
WHERE group_number > 0;

-- Verify changes
SELECT
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename IN ('composting_recipes', 'compost_monitoring_plans')
    AND indexname LIKE '%group%'
ORDER BY tablename, indexname;