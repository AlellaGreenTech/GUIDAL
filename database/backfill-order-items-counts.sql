-- Backfill adult_count and child_count for existing order items
-- This updates all existing orders to have the counts populated

-- Update Adult Entrance Party Tickets
UPDATE public.pumpkin_patch_order_items
SET adult_count = quantity,
    child_count = 0
WHERE item_name LIKE '%Adult Entrance%'
AND adult_count = 0;

-- Update Child Entrance Party Tickets
UPDATE public.pumpkin_patch_order_items
SET adult_count = 0,
    child_count = quantity
WHERE item_name LIKE '%Child Entrance%'
AND child_count = 0;

-- Update Visit Passes (count as adults)
UPDATE public.pumpkin_patch_order_items
SET adult_count = quantity,
    child_count = 0
WHERE item_name LIKE '%Pumpkin Patch Visit%'
AND adult_count = 0;

-- SCARES remain 0,0 (no change needed)

-- Verify the update
SELECT
    item_name,
    COUNT(*) as count,
    SUM(adult_count) as total_adults,
    SUM(child_count) as total_children
FROM public.pumpkin_patch_order_items
GROUP BY item_name;
