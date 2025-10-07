-- Add adult_count and child_count to order items for clarity
-- This makes it clear how many adults/children each line item represents

ALTER TABLE public.pumpkin_patch_order_items
ADD COLUMN IF NOT EXISTS adult_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS child_count INTEGER DEFAULT 0;

-- Add comment explaining the columns
COMMENT ON COLUMN public.pumpkin_patch_order_items.adult_count IS 'Number of adults this item represents (for visit passes, party tickets, etc.)';
COMMENT ON COLUMN public.pumpkin_patch_order_items.child_count IS 'Number of children this item represents (for party tickets, etc.)';

-- Verify the columns were added
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_name = 'pumpkin_patch_order_items'
AND column_name IN ('adult_count', 'child_count');
