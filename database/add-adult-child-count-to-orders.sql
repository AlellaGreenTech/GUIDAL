-- Add adult_count and child_count columns to pumpkin_patch_orders table
-- These fields will track the number of adults and children from ticket orders

ALTER TABLE public.pumpkin_patch_orders
ADD COLUMN IF NOT EXISTS adult_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS child_count INTEGER DEFAULT 0;

-- Add comment for documentation
COMMENT ON COLUMN public.pumpkin_patch_orders.adult_count IS 'Number of adult tickets ordered (from Oct 25th Adult or Nov 1st Adult)';
COMMENT ON COLUMN public.pumpkin_patch_orders.child_count IS 'Number of child tickets ordered (from Oct 25th Child or Nov 1st Child)';

-- Verify the columns were added
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_name = 'pumpkin_patch_orders'
  AND column_name IN ('adult_count', 'child_count');
