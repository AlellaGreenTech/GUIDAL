-- Add party_date column to pumpkin_patch_orders table
-- This stores which Halloween party date the customer selected (Oct 25 or Nov 1)

ALTER TABLE public.pumpkin_patch_orders
ADD COLUMN IF NOT EXISTS party_date DATE;

-- Add comment for documentation
COMMENT ON COLUMN public.pumpkin_patch_orders.party_date IS 'Selected party date for entrance tickets: 2025-10-25 or 2025-11-01. NULL for visit passes.';

-- Verify the column was added
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_name = 'pumpkin_patch_orders'
  AND column_name = 'party_date';
