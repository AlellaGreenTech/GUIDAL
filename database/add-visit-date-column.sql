-- Add visit_date column to orders table for non-party visit passes

ALTER TABLE public.pumpkin_patch_orders
ADD COLUMN IF NOT EXISTS visit_date DATE;

COMMENT ON COLUMN public.pumpkin_patch_orders.visit_date IS 'Selected visit date for non-party visit passes. Should be any date Oct 10-31 except party dates (Oct 25, Nov 1)';

-- Verify the column was added
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_name = 'pumpkin_patch_orders'
AND column_name = 'visit_date';
