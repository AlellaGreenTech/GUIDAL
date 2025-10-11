-- ========================================================================
-- COMPREHENSIVE RLS SETUP FOR PUMPKIN PATCH BOOKING SYSTEM
-- ========================================================================
-- This script sets up all necessary RLS policies for the entire system
-- to allow anonymous users (customers) to complete bookings successfully
-- ========================================================================

-- ========================================================================
-- 1. PUMPKIN PATCH ORDER TABLES (Customer-facing checkout)
-- ========================================================================

-- pumpkin_patch_orders - Main order table
DROP POLICY IF EXISTS "Allow all users to insert orders" ON pumpkin_patch_orders;
DROP POLICY IF EXISTS "Allow all users to read orders" ON pumpkin_patch_orders;
DROP POLICY IF EXISTS "Allow all users to update orders" ON pumpkin_patch_orders;

CREATE POLICY "Allow all users to insert orders"
  ON pumpkin_patch_orders
  FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);

CREATE POLICY "Allow all users to read orders"
  ON pumpkin_patch_orders
  FOR SELECT
  TO anon, authenticated
  USING (true);

CREATE POLICY "Allow all users to update orders"
  ON pumpkin_patch_orders
  FOR UPDATE
  TO anon, authenticated
  USING (true)
  WITH CHECK (true);

-- pumpkin_patch_order_items - Order line items
DROP POLICY IF EXISTS "Allow all users to insert order items" ON pumpkin_patch_order_items;
DROP POLICY IF EXISTS "Allow all users to read order items" ON pumpkin_patch_order_items;

CREATE POLICY "Allow all users to insert order items"
  ON pumpkin_patch_order_items
  FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);

CREATE POLICY "Allow all users to read order items"
  ON pumpkin_patch_order_items
  FOR SELECT
  TO anon, authenticated
  USING (true);

-- ========================================================================
-- 2. ADMIN NOTIFICATION TABLES (Used by Edge Functions)
-- ========================================================================

-- admin_notification_settings - Email settings for admin notifications
DROP POLICY IF EXISTS "Allow all to read admin settings" ON admin_notification_settings;

CREATE POLICY "Allow all to read admin settings"
  ON admin_notification_settings
  FOR SELECT
  TO anon, authenticated
  USING (true);

-- admin_notification_log - Log of admin notification emails sent
DROP POLICY IF EXISTS "Allow all to insert admin notification log" ON admin_notification_log;
DROP POLICY IF EXISTS "Allow all to read admin notification log" ON admin_notification_log;

CREATE POLICY "Allow all to insert admin notification log"
  ON admin_notification_log
  FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);

CREATE POLICY "Allow all to read admin notification log"
  ON admin_notification_log
  FOR SELECT
  TO anon, authenticated
  USING (true);

-- ========================================================================
-- 3. EMAIL TABLES (Email templates and logs)
-- ========================================================================

-- pumpkin_patch_email_templates - Email template storage
DROP POLICY IF EXISTS "Allow all to read email templates" ON pumpkin_patch_email_templates;

CREATE POLICY "Allow all to read email templates"
  ON pumpkin_patch_email_templates
  FOR SELECT
  TO anon, authenticated
  USING (true);

-- pumpkin_patch_email_log - Email sending log
DROP POLICY IF EXISTS "Allow all to insert email logs" ON pumpkin_patch_email_log;
DROP POLICY IF EXISTS "Allow all to read email logs" ON pumpkin_patch_email_log;

CREATE POLICY "Allow all to insert email logs"
  ON pumpkin_patch_email_log
  FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);

CREATE POLICY "Allow all to read email logs"
  ON pumpkin_patch_email_log
  FOR SELECT
  TO anon, authenticated
  USING (true);

-- ========================================================================
-- 4. GUEST CREDITS TABLES (Cashier system)
-- ========================================================================

-- guest_credits - Guest credit balances
DROP POLICY IF EXISTS "Allow all to read guest credits" ON guest_credits;
DROP POLICY IF EXISTS "Allow all to insert guest credits" ON guest_credits;
DROP POLICY IF EXISTS "Allow all to update guest credits" ON guest_credits;

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

-- credit_transactions - Credit transaction history
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

-- ========================================================================
-- 5. ANALYTICS (Optional - if table exists)
-- ========================================================================

-- analytics_events - Analytics tracking
DROP POLICY IF EXISTS "Allow all to insert analytics" ON analytics_events;

CREATE POLICY "Allow all to insert analytics"
  ON analytics_events
  FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);

-- ========================================================================
-- 6. VERIFY ALL POLICIES
-- ========================================================================

SELECT
    tablename,
    policyname,
    cmd AS operation,
    roles,
    CASE
        WHEN cmd = 'SELECT' AND qual IS NULL THEN ' ALLOWS ALL'
        WHEN cmd IN ('INSERT', 'UPDATE', 'DELETE') AND with_check = 'true' THEN ' ALLOWS ALL'
        WHEN cmd IN ('INSERT', 'UPDATE', 'DELETE') AND with_check IS NOT NULL THEN '   RESTRICTED'
        ELSE ' OK'
    END as access_level
FROM pg_policies
WHERE tablename IN (
    'pumpkin_patch_orders',
    'pumpkin_patch_order_items',
    'admin_notification_settings',
    'admin_notification_log',
    'pumpkin_patch_email_templates',
    'pumpkin_patch_email_log',
    'guest_credits',
    'credit_transactions',
    'analytics_events'
)
ORDER BY tablename, cmd, policyname;

-- ========================================================================
-- 7. SUMMARY
-- ========================================================================

SELECT
    'Setup Complete!' as status,
    COUNT(DISTINCT tablename) as tables_configured,
    COUNT(*) as total_policies
FROM pg_policies
WHERE tablename IN (
    'pumpkin_patch_orders',
    'pumpkin_patch_order_items',
    'admin_notification_settings',
    'admin_notification_log',
    'pumpkin_patch_email_templates',
    'pumpkin_patch_email_log',
    'guest_credits',
    'credit_transactions',
    'analytics_events'
);
