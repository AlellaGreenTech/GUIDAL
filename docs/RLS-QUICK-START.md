# RLS Quick Start Guide for Claude

> **USE THIS**: When starting any new Supabase application, provide this document to Claude to ensure proper RLS setup from the start.

---

## Core Rule

**When RLS is enabled, ALL access is denied by default.** You must create explicit policies for:
- `anon` (anonymous users)
- `authenticated` (logged-in users)

---

## Workflow

### 1. Map All Tables First

Before writing ANY policies, identify:
```bash
# Find all table references
grep -r "\.from('" --include="*.html" --include="*.js" --include="*.ts" |
  grep -o "\.from('[^']*')" | sort | uniq
```

**Create a CRUD matrix:**
| Table | anon | authenticated | Operations |
|-------|------|---------------|------------|
| orders | ✅ | ✅ | INSERT, SELECT |
| order_items | ✅ | ✅ | INSERT, SELECT |
| admin_settings | ❌ | ✅ | SELECT only |

### 2. Create Comprehensive RLS Script

**Always maintain ONE master script:**

```sql
-- database/rls-setup.sql
-- ========================================================================
-- RLS SETUP FOR [PROJECT]
-- ========================================================================

-- For EVERY table used:

ALTER TABLE table_name ENABLE ROW LEVEL SECURITY;

-- Grant table-level permissions first
GRANT SELECT, INSERT ON table_name TO anon, authenticated;

-- Then create policies
DROP POLICY IF EXISTS "anon_can_insert" ON table_name;
CREATE POLICY "anon_can_insert"
  ON table_name
  FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);

DROP POLICY IF EXISTS "anon_can_read" ON table_name;
CREATE POLICY "anon_can_read"
  ON table_name
  FOR SELECT
  TO anon, authenticated
  USING (true);

-- Verify
SELECT tablename, policyname, cmd, roles
FROM pg_policies
WHERE tablename = 'table_name';
```

### 3. Test as Anonymous ALWAYS

```javascript
// CRITICAL: Test every flow as anonymous
await supabase.auth.signOut();

// Test the flow
const { data, error } = await supabase
  .from('orders')
  .insert({ /* ... */ });

if (error && error.message.includes('row-level security')) {
  console.error('❌ RLS POLICY MISSING');
}
```

### 4. Handle RLS Errors Prominently

```javascript
if (error && error.message.includes('row-level security')) {
  // Show RED banner at top
  const banner = document.createElement('div');
  banner.style.cssText = 'position:fixed; top:0; left:0; right:0; background:#dc3545; color:white; padding:20px; text-align:center; font-size:18px; z-index:999999;';
  banner.innerHTML = '⚠️ SYSTEM ERROR - ORDER NOT SAVED<br><small>Contact support@example.com</small>';
  document.body.insertBefore(banner, document.body.firstChild);

  alert('ERROR: Order not saved. DO NOT proceed with payment.');
  return false;
}
```

---

## Common Tables to Check

For ANY application involving:

**Customer Checkout:**
- [ ] orders table
- [ ] order_items table
- [ ] pricing_config (SELECT only)

**Email System:**
- [ ] email_log table
- [ ] email_templates table (SELECT only)
- [ ] admin_notification_settings (SELECT only)

**Credits/Payments:**
- [ ] guest_credits table
- [ ] credit_transactions table

**Analytics:**
- [ ] analytics_events table

---

## Standard Policies

### Pattern 1: Anonymous Transactions
```sql
-- Allow anon to create orders
CREATE POLICY "anon_insert"
  ON orders FOR INSERT TO anon
  WITH CHECK (true);

-- Allow anon to read recent orders
CREATE POLICY "anon_read"
  ON orders FOR SELECT TO anon
  USING (true);
```

### Pattern 2: Read-Only Config
```sql
-- Anyone can read, only admin can write
CREATE POLICY "public_read"
  ON pricing_config FOR SELECT
  TO anon, authenticated
  USING (true);
```

### Pattern 3: Full Access for Auth
```sql
CREATE POLICY "auth_full"
  ON admin_settings FOR ALL
  TO authenticated
  USING (true) WITH CHECK (true);
```

---

## Troubleshooting

### Error: "new row violates row-level security policy"

```sql
-- Check if policy exists
SELECT * FROM pg_policies WHERE tablename = 'your_table';

-- If missing, add it
CREATE POLICY "anon_can_insert"
  ON your_table FOR INSERT TO anon
  WITH CHECK (true);
```

### Error: "permission denied for table"

```sql
-- Grant table permissions first
GRANT SELECT, INSERT, UPDATE ON your_table TO anon, authenticated;

-- Then enable RLS and add policies
ALTER TABLE your_table ENABLE ROW LEVEL SECURITY;
```

---

## Checklist for New Projects

**Phase 1: Before Coding**
- [ ] List ALL tables the app will use
- [ ] Create CRUD matrix (which roles need what)
- [ ] Identify Edge Functions and their table access

**Phase 2: Development**
- [ ] Create `database/rls-setup.sql` with ALL tables
- [ ] Enable RLS on all tables immediately
- [ ] Create permissive policies (WITH CHECK true)
- [ ] Run script on dev database

**Phase 3: Testing**
- [ ] Test EVERY user flow as anonymous (sign out first)
- [ ] Test Edge Functions with anon token
- [ ] Verify error messages are user-friendly

**Phase 4: Production**
- [ ] Run RLS setup script on production
- [ ] Test anonymous checkout immediately
- [ ] Monitor errors for first 24 hours

---

## Template for Claude

When asking Claude to build a Supabase app:

```
I'm building a [description] using Supabase.

IMPORTANT: Follow the RLS best practices in docs/RLS-QUICK-START.md

Specifically:
1. Map all database tables and operations needed
2. Create comprehensive RLS setup script (database/rls-setup.sql)
3. Include policies for anon AND authenticated users
4. Add prominent error handling for RLS failures
5. Test all flows as anonymous user

Tables needed: [list them]
Anonymous users need to: [list operations]
```

---

## Quick Reference Commands

```sql
-- Check RLS status
SELECT tablename, rowsecurity FROM pg_tables WHERE schemaname = 'public';

-- List all policies
SELECT tablename, policyname, cmd, roles FROM pg_policies;

-- Test as anon
SET ROLE anon;
SELECT * FROM your_table LIMIT 1;
RESET ROLE;

-- Create standard policy
CREATE POLICY "allow_anon_insert"
  ON your_table FOR INSERT TO anon
  WITH CHECK (true);
```

---

## Remember

1. **RLS denies by default** - Must explicitly allow
2. **Test as anonymous** - Your admin login bypasses issues
3. **One master script** - Single source of truth
4. **Handle errors prominently** - No silent failures
5. **Map first, code later** - Know all tables upfront

**Golden Rule:**
> If anonymous users do it in production, test it as anonymous in development.

---

*Quick Start Version 1.0*
*See docs/SUPABASE-RLS-BEST-PRACTICES.md for full documentation*
