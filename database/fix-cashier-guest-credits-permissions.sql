-- Fix guest_credits permissions for cashier app
-- Cashier app needs to read and update credits

-- Enable RLS if not already enabled
ALTER TABLE guest_credits ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "Allow authenticated to read guest credits" ON guest_credits;
DROP POLICY IF EXISTS "Allow authenticated to insert guest credits" ON guest_credits;
DROP POLICY IF EXISTS "Allow authenticated to update guest credits" ON guest_credits;
DROP POLICY IF EXISTS "Allow cashiers to view credits" ON guest_credits;
DROP POLICY IF EXISTS "Allow cashiers to update credits" ON guest_credits;

-- Create permissive policies for both anonymous and authenticated users
-- This allows the cashier app to work

CREATE POLICY "Allow all to read guest credits"
  ON guest_credits
  FOR SELECT
  TO anon, authenticated
  USING (true);

CREATE POLICY "Allow all to insert guest credits"
  ON guest_credits
  FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);

CREATE POLICY "Allow all to update guest credits"
  ON guest_credits
  FOR UPDATE
  TO anon, authenticated
  USING (true)
  WITH CHECK (true);

-- Grant necessary permissions
GRANT SELECT, INSERT, UPDATE ON guest_credits TO anon, authenticated;

-- Also fix credit_transactions table permissions (used by cashier app)
ALTER TABLE credit_transactions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow all to read transactions" ON credit_transactions;
DROP POLICY IF EXISTS "Allow all to insert transactions" ON credit_transactions;

CREATE POLICY "Allow all to read transactions"
  ON credit_transactions
  FOR SELECT
  TO anon, authenticated
  USING (true);

CREATE POLICY "Allow all to insert transactions"
  ON credit_transactions
  FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);

GRANT SELECT, INSERT ON credit_transactions TO anon, authenticated;

-- Verify the policies
SELECT
    tablename,
    policyname,
    cmd as operation,
    roles
FROM pg_policies
WHERE tablename IN ('guest_credits', 'credit_transactions')
ORDER BY tablename, policyname;
