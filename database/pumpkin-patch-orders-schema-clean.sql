-- Pumpkin Patch Orders Schema - Clean Version
-- Run this entire file in Supabase SQL Editor

-- Main orders table
CREATE TABLE IF NOT EXISTS public.pumpkin_patch_orders (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  order_number TEXT UNIQUE NOT NULL,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  email TEXT NOT NULL,
  phone TEXT,
  total_amount NUMERIC(10,2) NOT NULL DEFAULT 0,
  currency TEXT DEFAULT 'EUR',
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'paid', 'cancelled', 'completed')),
  payment_status TEXT DEFAULT 'pending' CHECK (payment_status IN ('pending', 'paid', 'refunded', 'failed')),
  payment_method TEXT,
  user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  notes TEXT,
  admin_notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  paid_at TIMESTAMP WITH TIME ZONE,
  completed_at TIMESTAMP WITH TIME ZONE
);

-- Order line items table
CREATE TABLE IF NOT EXISTS public.pumpkin_patch_order_items (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  order_id UUID REFERENCES public.pumpkin_patch_orders(id) ON DELETE CASCADE NOT NULL,
  item_name TEXT NOT NULL,
  item_type TEXT NOT NULL,
  quantity INTEGER NOT NULL DEFAULT 1,
  unit_price NUMERIC(10,2) NOT NULL,
  total_price NUMERIC(10,2) NOT NULL,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_pumpkin_orders_email ON public.pumpkin_patch_orders(email);
CREATE INDEX IF NOT EXISTS idx_pumpkin_orders_order_number ON public.pumpkin_patch_orders(order_number);
CREATE INDEX IF NOT EXISTS idx_pumpkin_orders_created_at ON public.pumpkin_patch_orders(created_at);
CREATE INDEX IF NOT EXISTS idx_pumpkin_order_items_order_id ON public.pumpkin_patch_order_items(order_id);

-- Enable RLS
ALTER TABLE public.pumpkin_patch_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pumpkin_patch_order_items ENABLE ROW LEVEL SECURITY;

-- RLS: Allow anyone (including anonymous) to create orders
CREATE POLICY "Anyone can create pumpkin patch orders"
  ON public.pumpkin_patch_orders
  FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);

-- RLS: Allow anyone to create order items
CREATE POLICY "Anyone can create order items"
  ON public.pumpkin_patch_order_items
  FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);

-- RLS: Admins can view all orders
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

-- RLS: Admins can view all order items
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

-- RLS: Admins can update orders
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

-- Trigger for updated_at
CREATE TRIGGER handle_pumpkin_orders_updated_at
  BEFORE UPDATE ON public.pumpkin_patch_orders
  FOR EACH ROW
  EXECUTE PROCEDURE public.handle_updated_at();

-- Function to generate order numbers
CREATE OR REPLACE FUNCTION generate_pumpkin_order_number()
RETURNS TEXT AS $$
DECLARE
  order_date TEXT;
  order_count INTEGER;
  order_num TEXT;
BEGIN
  order_date := TO_CHAR(NOW(), 'YYYYMMDD');

  SELECT COUNT(*) INTO order_count
  FROM public.pumpkin_patch_orders
  WHERE order_number LIKE 'PP-' || order_date || '-%';

  order_num := 'PP-' || order_date || '-' || LPAD((order_count + 1)::TEXT, 3, '0');

  RETURN order_num;
END;
$$ LANGUAGE plpgsql;

-- View for reporting
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
  o.notes,
  COALESCE(
    JSON_AGG(
      JSON_BUILD_OBJECT(
        'item_name', oi.item_name,
        'item_type', oi.item_type,
        'quantity', oi.quantity,
        'unit_price', oi.unit_price,
        'total_price', oi.total_price
      ) ORDER BY oi.created_at
    ) FILTER (WHERE oi.id IS NOT NULL),
    '[]'::JSON
  ) AS items
FROM public.pumpkin_patch_orders o
LEFT JOIN public.pumpkin_patch_order_items oi ON oi.order_id = o.id
GROUP BY o.id
ORDER BY o.created_at DESC;

-- Grant access
GRANT SELECT ON pumpkin_patch_orders_report TO authenticated, anon;

-- Success message
DO $$
BEGIN
  RAISE NOTICE 'Pumpkin Patch Orders schema created successfully!';
END $$;
