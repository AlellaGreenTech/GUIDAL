-- Add adult_count and child_count to order items

ALTER TABLE public.pumpkin_patch_order_items
ADD COLUMN IF NOT EXISTS adult_count INTEGER DEFAULT 0;

ALTER TABLE public.pumpkin_patch_order_items
ADD COLUMN IF NOT EXISTS child_count INTEGER DEFAULT 0;

-- Verify the columns were added
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_name = 'pumpkin_patch_order_items'
AND column_name IN ('adult_count', 'child_count');
