-- Add cancelled_at column to pumpkin_patch_orders table

ALTER TABLE pumpkin_patch_orders
ADD COLUMN IF NOT EXISTS cancelled_at TIMESTAMP WITH TIME ZONE;

-- Create index for performance when filtering by cancellation status
CREATE INDEX IF NOT EXISTS idx_pumpkin_orders_cancelled_at
ON pumpkin_patch_orders(cancelled_at);

-- Add comment
COMMENT ON COLUMN pumpkin_patch_orders.cancelled_at IS 'Timestamp when the order was cancelled';
