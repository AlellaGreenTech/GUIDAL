-- Backfill adult_count and child_count for existing orders
-- This script calculates counts from the order items

-- Update adult_count from order items
UPDATE pumpkin_patch_orders o
SET adult_count = (
    SELECT COALESCE(SUM(quantity), 0)
    FROM pumpkin_patch_order_items i
    WHERE i.order_id = o.id
      AND (
        i.item_name LIKE '%Adult%Ticket%'
        OR (i.metadata->>'participant_type' = 'adult')
      )
);

-- Update child_count from order items
UPDATE pumpkin_patch_orders o
SET child_count = (
    SELECT COALESCE(SUM(quantity), 0)
    FROM pumpkin_patch_order_items i
    WHERE i.order_id = o.id
      AND (
        i.item_name LIKE '%Child%Ticket%'
        OR (i.metadata->>'participant_type' = 'child')
      )
);

-- Verify the updates
SELECT
    order_number,
    first_name,
    last_name,
    adult_count,
    child_count,
    total_amount,
    created_at
FROM pumpkin_patch_orders
ORDER BY created_at DESC
LIMIT 20;
