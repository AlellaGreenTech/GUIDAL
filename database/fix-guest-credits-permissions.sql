-- Fix guest_credits table permissions for admin operations
-- This allows authenticated users (admins) to insert/update when marking orders as paid

-- Check if the table exists first
SELECT tablename FROM pg_tables WHERE tablename = 'guest_credits';

-- Enable RLS if not already enabled
ALTER TABLE guest_credits ENABLE ROW LEVEL SECURITY;

-- Drop old restrictive policies
DROP POLICY IF EXISTS "Authenticated users can read guest credits" ON guest_credits;
DROP POLICY IF EXISTS "Service role can manage guest credits" ON guest_credits;
DROP POLICY IF EXISTS "Allow cashiers to view credits" ON guest_credits;
DROP POLICY IF EXISTS "Allow cashiers to update credits" ON guest_credits;

-- Create new permissive policies
CREATE POLICY "Allow authenticated to read guest credits"
  ON guest_credits
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Allow authenticated to insert guest credits"
  ON guest_credits
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Allow authenticated to update guest credits"
  ON guest_credits
  FOR UPDATE
  TO authenticated
  USING (true);

-- Grant necessary permissions
GRANT SELECT, INSERT, UPDATE ON guest_credits TO authenticated;

-- Verify the policies
SELECT policyname, cmd, roles FROM pg_policies WHERE tablename = 'guest_credits';
