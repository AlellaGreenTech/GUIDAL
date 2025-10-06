-- Pumpkin Patch Orders Schema
-- This schema allows guest checkout without authentication
-- Stores complete order information for easy retrieval and reporting

-- Main orders table
CREATE TABLE IF NOT EXISTS public.pumpkin_patch_orders (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  order_number TEXT UNIQUE NOT NULL, -- e.g., "PP-20251006-001"

  -- Customer information (no auth required)
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  email TEXT NOT NULL,
  phone TEXT,

  -- Order details
  total_amount NUMERIC(10,2) NOT NULL DEFAULT 0,
  currency TEXT DEFAULT 'EUR',

  -- Order status
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'paid', 'cancelled', 'completed')),
  payment_status TEXT DEFAULT 'pending' CHECK (payment_status IN ('pending', 'paid', 'refunded', 'failed')),
  payment_method TEXT, -- e.g., 'card', 'cash', 'transfer'

  -- Optional link to registered user (if they're logged in)
  user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,

  -- Notes and metadata
  notes TEXT,
  admin_notes TEXT,

  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  paid_at TIMESTAMP WITH TIME ZONE,
  completed_at TIMESTAMP WITH TIME ZONE
);

-- Order line items table (what they purchased)
CREATE TABLE IF NOT EXISTS public.pumpkin_patch_order_items (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  order_id UUID REFERENCES public.pumpkin_patch_orders(id) ON DELETE CASCADE NOT NULL,

  -- Item details
  item_name TEXT NOT NULL, -- e.g., "Pumpkin Patch Visit (adult or child)"
  item_type TEXT NOT NULL, -- e.g., 'visit_pass', 'party_ticket', 'pumpkin_scare', 'food_scare'
  quantity INTEGER NOT NULL DEFAULT 1,
  unit_price NUMERIC(10,2) NOT NULL,
  total_price NUMERIC(10,2) NOT NULL, -- quantity * unit_price

  -- Additional item metadata (flexible for future use)
  metadata JSONB DEFAULT '{}', -- e.g., {"date": "2025-10-31", "time": "10:00"}

  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_pumpkin_orders_email ON public.pumpkin_patch_orders(email);
CREATE INDEX IF NOT EXISTS idx_pumpkin_orders_order_number ON public.pumpkin_patch_orders(order_number);
CREATE INDEX IF NOT EXISTS idx_pumpkin_orders_status ON public.pumpkin_patch_orders(status);
CREATE INDEX IF NOT EXISTS idx_pumpkin_orders_created_at ON public.pumpkin_patch_orders(created_at);
CREATE INDEX IF NOT EXISTS idx_pumpkin_order_items_order_id ON public.pumpkin_patch_order_items(order_id);

-- Enable RLS
ALTER TABLE public.pumpkin_patch_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pumpkin_patch_order_items ENABLE ROW LEVEL SECURITY;

-- RLS Policies

-- Allow anonymous users to create orders (guest checkout)
DROP POLICY IF EXISTS "Anyone can create pumpkin patch orders" ON public.pumpkin_patch_orders;
CREATE POLICY "Anyone can create pumpkin patch orders"
  ON public.pumpkin_patch_orders
  FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);

-- Users can view their own orders by email or user_id
DROP POLICY IF EXISTS "Users can view their own pumpkin patch orders" ON public.pumpkin_patch_orders;
CREATE POLICY "Users can view their own pumpkin patch orders"
  ON public.pumpkin_patch_orders
  FOR SELECT
  USING (
    email = current_setting('request.jwt.claims', true)::json->>'email'
    OR user_id = auth.uid()
  );

-- Admins can view all orders
DROP POLICY IF EXISTS "Admins can view all pumpkin patch orders" ON public.pumpkin_patch_orders;
CREATE POLICY "Admins can view all pumpkin patch orders"
  ON public.pumpkin_patch_orders
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.user_type = 'admin'
    )
  );

-- Admins can update orders
DROP POLICY IF EXISTS "Admins can update pumpkin patch orders" ON public.pumpkin_patch_orders;
CREATE POLICY "Admins can update pumpkin patch orders"
  ON public.pumpkin_patch_orders
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.user_type = 'admin'
    )
  );

-- Order items policies

-- Allow anonymous users to insert order items (during checkout)
DROP POLICY IF EXISTS "Anyone can create order items" ON public.pumpkin_patch_order_items;
CREATE POLICY "Anyone can create order items"
  ON public.pumpkin_patch_order_items
  FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);

-- Users can view items for their orders
DROP POLICY IF EXISTS "Users can view their order items" ON public.pumpkin_patch_order_items;
CREATE POLICY "Users can view their order items"
  ON public.pumpkin_patch_order_items
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.pumpkin_patch_orders
      WHERE pumpkin_patch_orders.id = order_id
      AND (
        pumpkin_patch_orders.email = current_setting('request.jwt.claims', true)::json->>'email'
        OR pumpkin_patch_orders.user_id = auth.uid()
      )
    )
  );

-- Admins can view all order items
DROP POLICY IF EXISTS "Admins can view all order items" ON public.pumpkin_patch_order_items;
CREATE POLICY "Admins can view all order items"
  ON public.pumpkin_patch_order_items
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.user_type = 'admin'
    )
  );

-- Trigger for updated_at
DROP TRIGGER IF EXISTS handle_pumpkin_orders_updated_at ON public.pumpkin_patch_orders;
CREATE TRIGGER handle_pumpkin_orders_updated_at
  BEFORE UPDATE ON public.pumpkin_patch_orders
  FOR EACH ROW
  EXECUTE PROCEDURE public.handle_updated_at();

-- Function to generate order number
CREATE OR REPLACE FUNCTION generate_pumpkin_order_number()
RETURNS TEXT AS $$
DECLARE
  order_date TEXT;
  order_count INTEGER;
  order_num TEXT;
BEGIN
  -- Format: PP-YYYYMMDD-XXX
  order_date := TO_CHAR(NOW(), 'YYYYMMDD');

  -- Count orders for today
  SELECT COUNT(*) INTO order_count
  FROM public.pumpkin_patch_orders
  WHERE order_number LIKE 'PP-' || order_date || '-%';

  -- Generate order number
  order_num := 'PP-' || order_date || '-' || LPAD((order_count + 1)::TEXT, 3, '0');

  RETURN order_num;
END;
$$ LANGUAGE plpgsql;

-- View for easy reporting (joins orders with items)
CREATE OR REPLACE VIEW pumpkin_patch_orders_report AS
SELECT
  o.id,
  o.order_number,
  o.first_name,
  o.last_name,
  o.email,
  o.phone,
  o.total_amount,
  o.status,
  o.payment_status,
  o.payment_method,
  o.created_at,
  o.paid_at,
  o.completed_at,
  o.notes,
  o.admin_notes,
  -- Aggregate order items into JSON array
  COALESCE(
    JSON_AGG(
      JSON_BUILD_OBJECT(
        'item_name', oi.item_name,
        'item_type', oi.item_type,
        'quantity', oi.quantity,
        'unit_price', oi.unit_price,
        'total_price', oi.total_price,
        'metadata', oi.metadata
      ) ORDER BY oi.created_at
    ) FILTER (WHERE oi.id IS NOT NULL),
    '[]'::JSON
  ) AS items
FROM public.pumpkin_patch_orders o
LEFT JOIN public.pumpkin_patch_order_items oi ON oi.order_id = o.id
GROUP BY o.id, o.order_number, o.first_name, o.last_name, o.email, o.phone,
         o.total_amount, o.status, o.payment_status, o.payment_method,
         o.created_at, o.paid_at, o.completed_at, o.notes, o.admin_notes
ORDER BY o.created_at DESC;

-- Grant access to the view
GRANT SELECT ON pumpkin_patch_orders_report TO authenticated, anon;

-- Comments for documentation
COMMENT ON TABLE public.pumpkin_patch_orders IS 'Guest checkout orders for pumpkin patch event';
COMMENT ON TABLE public.pumpkin_patch_order_items IS 'Line items for pumpkin patch orders';
COMMENT ON VIEW pumpkin_patch_orders_report IS 'Easy reporting view with orders and all their items';
COMMENT ON FUNCTION generate_pumpkin_order_number() IS 'Generates unique order numbers in format PP-YYYYMMDD-XXX';
