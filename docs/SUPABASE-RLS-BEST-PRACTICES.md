# Best Practices for Row Level Security Setup for Supabase Applications

## Table of Contents
1. [Overview](#overview)
2. [Core Principles](#core-principles)
3. [Development Workflow](#development-workflow)
4. [RLS Policy Patterns](#rls-policy-patterns)
5. [Testing Procedures](#testing-procedures)
6. [Error Handling](#error-handling)
7. [Troubleshooting Guide](#troubleshooting-guide)
8. [Checklist for New Applications](#checklist-for-new-applications)

---

## Overview

Row Level Security (RLS) is a PostgreSQL security feature that controls which rows a user can access in database tables. In Supabase applications, RLS policies must be explicitly configured for **both anonymous (`anon`) and authenticated users** to access data.

**Critical Understanding:**
- When RLS is enabled on a table, **ALL access is denied by default**
- You must create explicit policies to grant access
- Anonymous users (`anon` role) need separate policies from authenticated users
- Missing policies cause silent failures or "new row violates row-level security policy" errors

---

## Core Principles

### Principle 1: Map All Database Access Points FIRST

**Before writing any RLS policies**, create a comprehensive map of:

1. **All tables** used by the application
2. **Which user roles** need access (anon, authenticated, service_role)
3. **What operations** each role needs (SELECT, INSERT, UPDATE, DELETE)
4. **Which components** access each table (frontend pages, Edge Functions, triggers)

**How to Map:**

```bash
# Search for all database table references in your codebase
grep -r "\.from('" --include="*.html" --include="*.js" --include="*.ts" | \
  grep -o "\.from('[^']*')" | sort | uniq

# Search for RPC function calls
grep -r "\.rpc('" --include="*.html" --include="*.js" --include="*.ts" | \
  grep -o "\.rpc('[^']*')" | sort | uniq
```

### Principle 2: Design Policies from User Journey Perspective

**Think through each user flow:**

1. **Anonymous user checkout flow:**
   - Needs: INSERT orders, INSERT order items, SELECT order confirmation
   - Tables: orders, order_items, maybe pricing_config (read-only)

2. **Admin management flow:**
   - Needs: Full CRUD on all tables
   - Should use authenticated role with additional checks

3. **Edge Function flows:**
   - Needs: SELECT orders, INSERT email_logs, SELECT email_templates
   - Uses service_role or authenticated context

### Principle 3: Default to Permissive, Secure Progressively

**Development Strategy:**
1. Start with permissive policies (allow all) to ensure functionality works
2. Test thoroughly with anonymous users
3. Progressively tighten policies based on actual security requirements
4. Document any restrictions with clear comments

**Example Progression:**
```sql
-- Stage 1: Development - Permissive
CREATE POLICY "dev_allow_all" ON orders
  TO anon, authenticated
  USING (true)
  WITH CHECK (true);

-- Stage 2: Production - Restricted
CREATE POLICY "users_own_orders" ON orders
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
```

---

## Development Workflow

### Step 1: Database Schema Design

When creating tables, **immediately** create RLS policies:

```sql
-- ❌ WRONG: Create table without RLS consideration
CREATE TABLE orders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  customer_email TEXT NOT NULL,
  total_amount NUMERIC NOT NULL
);

-- ✅ CORRECT: Create table WITH RLS setup
CREATE TABLE orders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  customer_email TEXT NOT NULL,
  total_amount NUMERIC NOT NULL
);

-- Enable RLS immediately
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

-- Create policies based on user roles
CREATE POLICY "anon_can_insert_orders"
  ON orders
  FOR INSERT
  TO anon
  WITH CHECK (true);

CREATE POLICY "anon_can_read_own_orders"
  ON orders
  FOR SELECT
  TO anon
  USING (true); -- Tighten later with session checks

-- Document what each policy does
COMMENT ON POLICY "anon_can_insert_orders" ON orders IS
  'Allows anonymous customers to create orders during checkout';
```

### Step 2: Create Comprehensive RLS Setup Script

**Always maintain a single source of truth SQL file:**

```sql
-- database/rls-policies-complete.sql
-- ========================================================================
-- COMPREHENSIVE RLS SETUP FOR [PROJECT NAME]
-- Last Updated: [DATE]
-- ========================================================================

-- TABLE 1: orders
-- Purpose: Store customer orders
-- Access: anon (INSERT, SELECT), authenticated (all), admin (all)
-- ========================================================================

ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "anon_can_insert_orders" ON orders;
DROP POLICY IF EXISTS "anon_can_read_orders" ON orders;
DROP POLICY IF EXISTS "authenticated_full_access" ON orders;

CREATE POLICY "anon_can_insert_orders"
  ON orders FOR INSERT TO anon
  WITH CHECK (true);

CREATE POLICY "anon_can_read_orders"
  ON orders FOR SELECT TO anon
  USING (true);

CREATE POLICY "authenticated_full_access"
  ON orders FOR ALL TO authenticated
  USING (true) WITH CHECK (true);

-- TABLE 2: order_items
-- [Repeat for every table...]
```

### Step 3: Test with Both Roles

**Create test scripts for each user role:**

```javascript
// test/test-anon-checkout.html
// Tests anonymous user can complete full checkout flow

async function testAnonCheckout() {
  // Sign out to ensure anonymous
  await supabase.auth.signOut();

  console.log('Testing anonymous checkout...');

  // Test 1: Can insert order
  const { data: order, error: orderError } = await supabase
    .from('orders')
    .insert({ customer_email: 'test@example.com', total_amount: 100 })
    .select()
    .single();

  if (orderError) {
    console.error('❌ FAILED: Cannot insert order', orderError);
    return false;
  }
  console.log('✅ PASS: Can insert order');

  // Test 2: Can insert order items
  const { error: itemError } = await supabase
    .from('order_items')
    .insert({ order_id: order.id, item_name: 'Test', quantity: 1 });

  if (itemError) {
    console.error('❌ FAILED: Cannot insert order item', itemError);
    return false;
  }
  console.log('✅ PASS: Can insert order items');

  // Test 3: Can read confirmation
  const { data: confirmation, error: readError } = await supabase
    .from('orders')
    .select('*, order_items(*)')
    .eq('id', order.id)
    .single();

  if (readError) {
    console.error('❌ FAILED: Cannot read order', readError);
    return false;
  }
  console.log('✅ PASS: Can read order confirmation');

  console.log('✅ ALL TESTS PASSED');
  return true;
}
```

### Step 4: Document Edge Cases

**Create a reference document:**

```markdown
# RLS Edge Cases - [Project Name]

## Email Sending Edge Functions
- **Issue**: Edge Functions run with `service_role` by default, bypassing RLS
- **Solution**: When calling from frontend, pass `anon` or `authenticated` token
- **Tables affected**: email_logs, email_templates

## Triggers and Functions
- **Issue**: Database triggers run with `security definer` which may bypass RLS
- **Solution**: Ensure trigger functions are created with `SECURITY INVOKER`
- **Tables affected**: guest_credits (created by trigger)

## Admin Pages
- **Issue**: Admin needs to see all data, not just own data
- **Solution**: Use authenticated role with permissive policies for admin pages
- **Tables affected**: All admin_* tables
```

---

## RLS Policy Patterns

### Pattern 1: Public Read, Authenticated Write

**Use case:** Public data like blog posts, products, pricing

```sql
CREATE POLICY "public_read"
  ON products
  FOR SELECT
  TO anon, authenticated
  USING (true);

CREATE POLICY "authenticated_write"
  ON products
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.role() = 'authenticated');
```

### Pattern 2: Anonymous User Transactions

**Use case:** Guest checkout, anonymous feedback

```sql
-- Allow anonymous to create but not modify
CREATE POLICY "anon_can_create_orders"
  ON orders
  FOR INSERT
  TO anon
  WITH CHECK (true);

-- Anonymous can only read their own (using session or email)
CREATE POLICY "anon_can_read_own"
  ON orders
  FOR SELECT
  TO anon
  USING (
    customer_email = current_setting('request.jwt.claims', true)::json->>'email'
    OR created_at > NOW() - INTERVAL '1 hour' -- Recent orders visible
  );
```

### Pattern 3: Owner-Only Access

**Use case:** User profiles, personal data

```sql
CREATE POLICY "users_own_data"
  ON user_profiles
  FOR ALL
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
```

### Pattern 4: Role-Based Access

**Use case:** Admin-only tables

```sql
-- Create custom claim check function
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN (
    SELECT COALESCE(
      current_setting('request.jwt.claims', true)::json->>'role' = 'admin',
      false
    )
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Use in policy
CREATE POLICY "admin_only"
  ON admin_settings
  FOR ALL
  TO authenticated
  USING (is_admin())
  WITH CHECK (is_admin());
```

### Pattern 5: Service Role Bypass

**Use case:** Edge Functions that need full access

```sql
-- Edge Functions use service_role which bypasses RLS
-- No policy needed, but document this clearly

COMMENT ON TABLE internal_logs IS
  'No RLS policies - only accessible via service_role (Edge Functions)';
```

---

## Testing Procedures

### Automated RLS Test Suite

Create a test suite that runs against your staging database:

```sql
-- database/test-rls-policies.sql
-- ========================================================================
-- RLS POLICY TEST SUITE
-- Run this after any schema changes
-- ========================================================================

-- Setup test environment
SET ROLE anon;

-- Test 1: Anonymous can insert orders
DO $$
DECLARE
  test_order_id UUID;
BEGIN
  INSERT INTO orders (customer_email, total_amount)
  VALUES ('test@example.com', 100)
  RETURNING id INTO test_order_id;

  RAISE NOTICE '✅ Test 1 PASSED: anon can insert orders';
EXCEPTION
  WHEN insufficient_privilege THEN
    RAISE EXCEPTION '❌ Test 1 FAILED: anon cannot insert orders';
END $$;

-- Test 2: Anonymous can read orders
DO $$
DECLARE
  order_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO order_count FROM orders WHERE created_at > NOW() - INTERVAL '1 minute';

  IF order_count > 0 THEN
    RAISE NOTICE '✅ Test 2 PASSED: anon can read orders';
  ELSE
    RAISE EXCEPTION '❌ Test 2 FAILED: anon cannot read orders';
  END IF;
EXCEPTION
  WHEN insufficient_privilege THEN
    RAISE EXCEPTION '❌ Test 2 FAILED: anon lacks SELECT privilege';
END $$;

-- Test 3: Anonymous cannot delete orders
DO $$
BEGIN
  DELETE FROM orders WHERE customer_email = 'test@example.com';
  RAISE EXCEPTION '❌ Test 3 FAILED: anon can delete orders (should not be allowed)';
EXCEPTION
  WHEN insufficient_privilege THEN
    RAISE NOTICE '✅ Test 3 PASSED: anon cannot delete orders';
END $$;

-- Reset role
RESET ROLE;
```

### Frontend Testing Checklist

**For every major user flow:**

- [ ] Test as anonymous user (sign out first)
- [ ] Test as authenticated user
- [ ] Test with network throttling (slow connections)
- [ ] Test error scenarios (database down, RLS denied)
- [ ] Verify error messages are user-friendly
- [ ] Check console for RLS policy errors

### Edge Function Testing

```typescript
// Test Edge Function with different auth contexts

// Test 1: With anon key
const response1 = await fetch(`${SUPABASE_URL}/functions/v1/my-function`, {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({ test: true })
});

// Test 2: With authenticated user token
const { data: { session } } = await supabase.auth.getSession();
const response2 = await fetch(`${SUPABASE_URL}/functions/v1/my-function`, {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${session.access_token}`,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({ test: true })
});
```

---

## Error Handling

### Pattern 1: Graceful Degradation

**Always handle RLS errors at the application level:**

```javascript
async function createOrder(orderData) {
  try {
    const { data, error } = await supabase
      .from('orders')
      .insert(orderData)
      .select()
      .single();

    if (error) {
      // Check if it's an RLS error
      if (error.message.includes('row-level security') ||
          error.message.includes('policy')) {

        // Show user-friendly error
        showError(
          'Unable to complete order',
          'There was a permission error. Please contact support.',
          { technicalDetails: error.message, contactEmail: 'support@example.com' }
        );

        // Log for debugging
        console.error('RLS Policy Error:', {
          table: 'orders',
          operation: 'INSERT',
          error: error.message,
          userRole: await getUserRole(),
          timestamp: new Date().toISOString()
        });

        // Optionally send to error tracking service
        logToErrorService('RLS_POLICY_ERROR', {
          table: 'orders',
          error: error.message
        });

        return { success: false, error: 'PERMISSION_DENIED' };
      }

      // Handle other errors
      return { success: false, error: error.message };
    }

    return { success: true, data };

  } catch (err) {
    console.error('Unexpected error:', err);
    return { success: false, error: 'UNEXPECTED_ERROR' };
  }
}
```

### Pattern 2: Prominent User Feedback

```javascript
function showError(title, message, details) {
  // Create prominent error banner
  const banner = document.createElement('div');
  banner.style.cssText = `
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    background: #dc3545;
    color: white;
    padding: 20px;
    text-align: center;
    font-size: 18px;
    font-weight: bold;
    z-index: 999999;
    box-shadow: 0 4px 12px rgba(0,0,0,0.3);
  `;

  banner.innerHTML = `
    <div style="max-width: 800px; margin: 0 auto;">
      ⚠️ ${title}<br>
      <span style="font-size: 14px; font-weight: normal; margin-top: 10px; display: block;">
        ${message}<br>
        ${details.contactEmail ? `Contact: ${details.contactEmail}` : ''}
        ${details.technicalDetails ? `<br><small>Error: ${details.technicalDetails}</small>` : ''}
      </span>
    </div>
  `;

  document.body.insertBefore(banner, document.body.firstChild);
  window.scrollTo(0, 0);

  // Also show alert for emphasis
  alert(`⚠️ ${title}\n\n${message}`);
}
```

### Pattern 3: Fallback Mechanisms

```javascript
async function getEmailSettings() {
  try {
    // Try to get from database
    const { data, error } = await supabase
      .from('admin_notification_settings')
      .select('admin_email')
      .single();

    if (error) {
      console.warn('Could not fetch email settings, using fallback');

      // Fallback to environment variable or hardcoded value
      return {
        admin_email: import.meta.env.VITE_ADMIN_EMAIL || 'admin@example.com'
      };
    }

    return data;

  } catch (err) {
    console.error('Email settings fetch failed:', err);
    return {
      admin_email: 'admin@example.com' // Ultimate fallback
    };
  }
}
```

---

## Troubleshooting Guide

### Issue 1: "new row violates row-level security policy"

**Symptoms:**
- Error message contains "row-level security policy"
- INSERT or UPDATE operations fail
- Works in Supabase dashboard but not in app

**Diagnosis:**
```sql
-- Check if RLS is enabled
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename = 'your_table';

-- Check existing policies
SELECT * FROM pg_policies
WHERE tablename = 'your_table';

-- Check if policy exists for current role
SELECT policyname, cmd, roles
FROM pg_policies
WHERE tablename = 'your_table'
  AND 'anon' = ANY(roles);
```

**Solution:**
```sql
-- Create INSERT policy for anonymous users
CREATE POLICY "anon_can_insert"
  ON your_table
  FOR INSERT
  TO anon
  WITH CHECK (true);
```

### Issue 2: "permission denied for table"

**Symptoms:**
- Error message: "permission denied for table X"
- Different from RLS error
- No policies exist at all

**Diagnosis:**
```sql
-- Check if table has RLS enabled
SELECT tablename, rowsecurity
FROM pg_tables
WHERE tablename = 'your_table';

-- Check table grants
SELECT grantee, privilege_type
FROM information_schema.role_table_grants
WHERE table_name = 'your_table';
```

**Solution:**
```sql
-- Grant table-level permissions
GRANT SELECT, INSERT, UPDATE ON your_table TO anon, authenticated;

-- Then add RLS policies
ALTER TABLE your_table ENABLE ROW LEVEL SECURITY;

CREATE POLICY "appropriate_policy"
  ON your_table
  FOR ALL
  TO anon, authenticated
  USING (true)
  WITH CHECK (true);
```

### Issue 3: Policies exist but still getting errors

**Symptoms:**
- Policies show up in pg_policies
- Still getting RLS violations
- Works for authenticated, fails for anon

**Diagnosis:**
```sql
-- Check policy details including USING and WITH CHECK clauses
SELECT
  policyname,
  cmd,
  roles,
  qual AS using_clause,
  with_check AS with_check_clause
FROM pg_policies
WHERE tablename = 'your_table';

-- Test with explicit role
SET ROLE anon;
SELECT * FROM your_table LIMIT 1;
RESET ROLE;
```

**Common causes:**
- Policy has restrictive USING/WITH CHECK clauses
- Policy only covers SELECT, not INSERT
- Role is not included in policy (missing 'anon')

**Solution:**
```sql
-- Drop and recreate with correct clauses
DROP POLICY "old_policy" ON your_table;

CREATE POLICY "new_policy"
  ON your_table
  FOR INSERT  -- Specify exact operation
  TO anon, authenticated  -- Include both roles
  WITH CHECK (true);  -- Permissive check
```

### Issue 4: Edge Functions can't access tables

**Symptoms:**
- Edge Function fails with RLS error
- Works when called from authenticated admin
- Fails when called from frontend with anon key

**Diagnosis:**
```typescript
// Check what token is being passed
console.log('Token:', request.headers.get('authorization'));

// Check Supabase client creation
const supabase = createClient(
  Deno.env.get('SUPABASE_URL'),
  Deno.env.get('SUPABASE_ANON_KEY'),  // or SERVICE_ROLE_KEY?
  { ... }
);
```

**Solution:**
```typescript
// Option 1: Use service_role key (bypasses RLS)
const supabaseAdmin = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  {
    auth: {
      autoRefreshToken: false,
      persistSession: false
    }
  }
);

// Option 2: Respect RLS by using passed token
const authHeader = request.headers.get('authorization');
const token = authHeader?.replace('Bearer ', '');

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_ANON_KEY')!,
  {
    global: {
      headers: { authorization: `Bearer ${token}` }
    }
  }
);
```

### Issue 5: Triggers creating records that fail RLS

**Symptoms:**
- Trigger executes but created rows violate RLS
- Works in Supabase dashboard, fails in app
- Error: "new row violates row-level security policy"

**Diagnosis:**
```sql
-- Check trigger function security
SELECT
  routine_name,
  security_type
FROM information_schema.routines
WHERE routine_name = 'your_trigger_function';

-- Check if triggered table has RLS
SELECT tablename, rowsecurity
FROM pg_tables
WHERE tablename = 'triggered_table';
```

**Solution:**
```sql
-- Option 1: Make trigger function SECURITY DEFINER
CREATE OR REPLACE FUNCTION your_trigger_function()
RETURNS TRIGGER
SECURITY DEFINER  -- Run with function owner privileges
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  -- Function body
  RETURN NEW;
END;
$$;

-- Option 2: Add RLS policy for trigger-created rows
CREATE POLICY "allow_trigger_inserts"
  ON triggered_table
  FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);
```

---

## Checklist for New Applications

### Phase 1: Planning (Before Writing Code)

- [ ] **List all tables** needed for the application
- [ ] **Identify user roles**: Anonymous, Authenticated, Admin, Service
- [ ] **Map operations** per role per table (CRUD matrix)
- [ ] **Document user flows** that involve database access
- [ ] **Identify Edge Functions** and what they need to access
- [ ] **Plan RLS strategy**: Permissive vs restrictive

**Example CRUD Matrix:**

| Table | anon | authenticated | admin | service_role |
|-------|------|---------------|-------|--------------|
| orders | INSERT, SELECT own | INSERT, SELECT own, UPDATE own | ALL | ALL |
| products | SELECT | SELECT | ALL | ALL |
| admin_settings | - | - | ALL | ALL |
| email_logs | INSERT | INSERT | SELECT | ALL |

### Phase 2: Initial Development

- [ ] **Create RLS setup script** (`database/rls-setup.sql`)
- [ ] **Enable RLS** on all tables immediately after creation
- [ ] **Create permissive policies** for development (WITH CHECK true)
- [ ] **Grant table permissions**: `GRANT SELECT, INSERT... TO anon, authenticated`
- [ ] **Document each policy** with comments explaining purpose
- [ ] **Run setup script** on development database

### Phase 3: Testing

- [ ] **Create test script** for anonymous user flows
- [ ] **Create test script** for authenticated user flows
- [ ] **Test each major feature** as anonymous user (sign out first)
- [ ] **Test Edge Functions** with both anon and authenticated tokens
- [ ] **Test error scenarios**: RLS denied, network failure, database down
- [ ] **Verify error messages** are user-friendly (no technical jargon)
- [ ] **Check browser console** for RLS errors during all tests

### Phase 4: Error Handling

- [ ] **Add try-catch** around all database operations
- [ ] **Detect RLS errors** specifically (check error message content)
- [ ] **Show prominent user feedback** (red banners, alerts)
- [ ] **Include contact information** in error messages
- [ ] **Log errors** to console with context (table, operation, role)
- [ ] **Implement fallbacks** where possible (cached data, defaults)
- [ ] **Prevent data loss**: Don't let users continue after RLS errors

### Phase 5: Production Preparation

- [ ] **Review all policies** for security implications
- [ ] **Tighten policies** where appropriate (from permissive to restrictive)
- [ ] **Add audit logging** for sensitive operations
- [ ] **Document all policies** in project README
- [ ] **Create rollback script** to restore policies if needed
- [ ] **Run full test suite** on staging database
- [ ] **Load test** with realistic concurrent user scenarios

### Phase 6: Deployment

- [ ] **Run RLS setup script** on production database
- [ ] **Verify policies** were created (run verification query)
- [ ] **Test production** with anonymous checkout immediately
- [ ] **Monitor error logs** closely for first 24 hours
- [ ] **Have rollback plan** ready (previous working SQL script)

### Phase 7: Maintenance

- [ ] **Document RLS setup** in project wiki/README
- [ ] **Create runbook** for common RLS issues
- [ ] **Set up alerts** for RLS policy errors in production
- [ ] **Review policies** quarterly for security improvements
- [ ] **Update RLS docs** whenever tables are added/modified
- [ ] **Train team members** on RLS concepts and troubleshooting

---

## Quick Reference: Common Commands

### Check RLS Status
```sql
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public';
```

### List All Policies
```sql
SELECT tablename, policyname, cmd, roles
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, cmd;
```

### Enable RLS
```sql
ALTER TABLE table_name ENABLE ROW LEVEL SECURITY;
```

### Create Permissive Policy
```sql
CREATE POLICY "allow_all"
  ON table_name
  FOR ALL
  TO anon, authenticated
  USING (true)
  WITH CHECK (true);
```

### Drop Policy
```sql
DROP POLICY IF EXISTS "policy_name" ON table_name;
```

### Test as Anonymous User
```sql
SET ROLE anon;
SELECT * FROM table_name LIMIT 1;
RESET ROLE;
```

### Grant Table Permissions
```sql
GRANT SELECT, INSERT, UPDATE, DELETE
ON table_name
TO anon, authenticated;
```

---

## Template: RLS Setup Script

```sql
-- ========================================================================
-- RLS SETUP FOR [PROJECT NAME]
-- Created: [DATE]
-- Description: [Brief description of what this application does]
-- ========================================================================

-- ========================================================================
-- TABLE: table_name
-- Purpose: [What this table stores]
-- Access Patterns:
--   - anon: [What anonymous users need to do]
--   - authenticated: [What authenticated users need to do]
-- ========================================================================

-- Enable RLS
ALTER TABLE table_name ENABLE ROW LEVEL SECURITY;

-- Clean up existing policies
DROP POLICY IF EXISTS "policy_1" ON table_name;
DROP POLICY IF EXISTS "policy_2" ON table_name;

-- Grant table-level permissions
GRANT SELECT, INSERT ON table_name TO anon, authenticated;
GRANT UPDATE, DELETE ON table_name TO authenticated;

-- Create policies
CREATE POLICY "anon_can_read"
  ON table_name
  FOR SELECT
  TO anon
  USING (true);

COMMENT ON POLICY "anon_can_read" ON table_name IS
  'Allows anonymous users to read public data';

CREATE POLICY "anon_can_insert"
  ON table_name
  FOR INSERT
  TO anon
  WITH CHECK (true);

COMMENT ON POLICY "anon_can_insert" ON table_name IS
  'Allows anonymous users to create records during checkout';

-- Repeat for all tables...

-- ========================================================================
-- VERIFICATION
-- ========================================================================

SELECT
  tablename,
  policyname,
  cmd,
  roles,
  CASE
    WHEN cmd = 'SELECT' AND qual IS NULL THEN '✅ ALLOWS ALL'
    WHEN cmd IN ('INSERT', 'UPDATE') AND with_check = 'true' THEN '✅ ALLOWS ALL'
    ELSE '⚠️ RESTRICTED'
  END as status
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, cmd;
```

---

## GitHub README Template

Include this section in your project's README.md:

````markdown
## Database Setup & Row Level Security

This application uses Supabase with Row Level Security (RLS) enabled on all tables.

### Initial Setup

1. Run the RLS setup script to configure all policies:
   ```bash
   psql $DATABASE_URL -f database/rls-setup.sql
   ```

2. Verify policies were created:
   ```sql
   SELECT tablename, COUNT(*) as policy_count
   FROM pg_policies
   WHERE schemaname = 'public'
   GROUP BY tablename;
   ```

### User Roles & Permissions

- **Anonymous (`anon`)**: Can create orders, read public data
- **Authenticated**: Full access to own data, read public data
- **Service Role**: Full access (Edge Functions only)

### Testing RLS

Before deploying, always test with anonymous user:

```javascript
// Sign out to test as anonymous
await supabase.auth.signOut();

// Test critical flow (e.g., checkout)
const { data, error } = await supabase
  .from('orders')
  .insert({ /* ... */ });

if (error) {
  console.error('RLS Error:', error);
}
```

### Troubleshooting

If you see "row-level security policy" errors:

1. Check if policy exists: `SELECT * FROM pg_policies WHERE tablename = 'your_table';`
2. Verify role is included: Check `roles` column includes `{anon}` or `{authenticated}`
3. Run setup script again: `psql $DATABASE_URL -f database/rls-setup.sql`

See [docs/SUPABASE-RLS-BEST-PRACTICES.md](docs/SUPABASE-RLS-BEST-PRACTICES.md) for complete guide.
````

---

## Appendix: Real-World Example

**Pumpkin Patch Booking System (Case Study)**

### Problem
Anonymous users couldn't complete bookings - RLS policies were missing, causing silent failures.

### Discovery Process
1. User reported: "No bookings coming through"
2. Tested as anonymous user → RLS policy violation
3. Checked database: `SELECT * FROM pg_policies WHERE tablename = 'pumpkin_patch_orders'`
4. Result: No INSERT policy for `anon` role

### Solution
```sql
-- Added missing policies
CREATE POLICY "Allow all users to insert orders"
  ON pumpkin_patch_orders
  FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);

CREATE POLICY "Allow all users to insert order items"
  ON pumpkin_patch_order_items
  FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);

-- Also needed for email system
CREATE POLICY "Allow all to read admin settings"
  ON admin_notification_settings
  FOR SELECT
  TO anon, authenticated
  USING (true);
```

### Lessons Learned
1. **Map ALL tables upfront** - Multiple tables involved in single user flow
2. **Test as anonymous immediately** - Don't assume it works
3. **Add prominent error messages** - Silent failures cause user confusion
4. **Create comprehensive setup script** - One script to rule them all

### Prevention
Created `database/comprehensive-rls-setup.sql` covering:
- Order tables (orders, order_items)
- Email tables (email_log, email_templates, notification_settings)
- Credit tables (guest_credits, credit_transactions)
- Analytics tables (analytics_events)

**Result:** No more RLS surprises. One script ensures everything works.

---

## Conclusion

**Key Takeaways:**

1. **RLS denies everything by default** - You must explicitly grant access
2. **Map first, code later** - Know all tables and access patterns upfront
3. **Test as anonymous always** - Your admin login bypasses RLS issues
4. **One source of truth** - Maintain comprehensive RLS setup script
5. **Handle errors prominently** - Prevent silent failures that damage reputation
6. **Document everything** - Future you will thank present you

**Golden Rule:**
> If an anonymous user needs to do it in production, test it as an anonymous user in development.

**Final Checklist:**
- [ ] I have a comprehensive RLS setup script
- [ ] I have tested every user flow as anonymous
- [ ] I have prominent error handling for RLS failures
- [ ] I have documented all policies with comments
- [ ] I have a rollback plan if something breaks
- [ ] I have verified policies on production database
- [ ] I have monitoring/alerts for RLS errors

---

*Document Version: 1.0*
*Last Updated: 2025-10-11*
*Maintainer: [Your Name]*
