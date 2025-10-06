-- Query Pumpkin Patch Orders
-- Use these queries to retrieve and analyze orders

-- 1. Get all orders with their items (using the report view)
SELECT * FROM pumpkin_patch_orders_report
ORDER BY created_at DESC;

-- 2. Get the most recent order
SELECT * FROM pumpkin_patch_orders_report
ORDER BY created_at DESC
LIMIT 1;

-- 3. Get all orders (basic info only)
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

-- 4. Get order details for a specific email
SELECT * FROM pumpkin_patch_orders_report
WHERE email = 'customer@example.com';  -- Replace with actual email

-- 5. Get order items breakdown for all orders
SELECT
  o.order_number,
  o.first_name || ' ' || o.last_name AS customer_name,
  o.email,
  o.total_amount,
  oi.item_name,
  oi.quantity,
  oi.unit_price,
  oi.total_price,
  o.created_at
FROM public.pumpkin_patch_orders o
LEFT JOIN public.pumpkin_patch_order_items oi ON oi.order_id = o.id
ORDER BY o.created_at DESC, oi.item_name;

-- 6. Get summary statistics
SELECT
  COUNT(*) as total_orders,
  COUNT(DISTINCT email) as unique_customers,
  SUM(total_amount) as total_revenue,
  AVG(total_amount) as average_order_value,
  COUNT(CASE WHEN payment_status = 'paid' THEN 1 END) as paid_orders,
  COUNT(CASE WHEN payment_status = 'pending' THEN 1 END) as pending_orders
FROM public.pumpkin_patch_orders;

-- 7. Get item sales summary
SELECT
  oi.item_name,
  oi.item_type,
  COUNT(*) as times_ordered,
  SUM(oi.quantity) as total_quantity_sold,
  SUM(oi.total_price) as total_revenue
FROM public.pumpkin_patch_order_items oi
GROUP BY oi.item_name, oi.item_type
ORDER BY total_revenue DESC;

-- 8. Get orders from today
SELECT * FROM pumpkin_patch_orders_report
WHERE DATE(created_at) = CURRENT_DATE
ORDER BY created_at DESC;

-- 9. Get pending payment orders
SELECT
  order_number,
  first_name,
  last_name,
  email,
  total_amount,
  created_at
FROM public.pumpkin_patch_orders
WHERE payment_status = 'pending'
ORDER BY created_at DESC;

-- 10. Export-ready format for Excel/CSV
SELECT
  o.order_number AS "Order Number",
  o.created_at AS "Order Date",
  o.first_name AS "First Name",
  o.last_name AS "Last Name",
  o.email AS "Email",
  o.phone AS "Phone",
  o.total_amount AS "Total Amount (EUR)",
  o.status AS "Order Status",
  o.payment_status AS "Payment Status",
  STRING_AGG(
    oi.item_name || ' (x' || oi.quantity || ')',
    ', '
  ) AS "Items Ordered"
FROM public.pumpkin_patch_orders o
LEFT JOIN public.pumpkin_patch_order_items oi ON oi.order_id = o.id
GROUP BY o.id, o.order_number, o.created_at, o.first_name, o.last_name,
         o.email, o.phone, o.total_amount, o.status, o.payment_status
ORDER BY o.created_at DESC;
