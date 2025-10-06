-- Grant permissions on the view and underlying tables

-- Grant access to the view
GRANT SELECT ON pumpkin_patch_orders_report TO postgres, authenticated, anon;

-- Grant access to underlying tables for the view to work
GRANT SELECT ON public.pumpkin_patch_orders TO postgres, authenticated, anon;
GRANT SELECT ON public.pumpkin_patch_order_items TO postgres, authenticated, anon;

-- Now try to query the orders directly
SELECT
  order_number,
  first_name,
  last_name,
  email,
  phone,
  total_amount,
  status,
  payment_status,
  created_at
FROM public.pumpkin_patch_orders
ORDER BY created_at DESC;
