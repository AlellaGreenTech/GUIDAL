# GUIDAL - Pumpkin Patch Booking System

Event booking and management system for pumpkin patch visits and Halloween parties.

---

## 📋 Documentation

### Row Level Security (RLS) Setup

**IMPORTANT:** This project uses Supabase with Row Level Security enabled on all tables.

- **Full Guide:** [docs/SUPABASE-RLS-BEST-PRACTICES.md](docs/SUPABASE-RLS-BEST-PRACTICES.md)
- **Quick Reference:** [docs/RLS-QUICK-START.md](docs/RLS-QUICK-START.md)

**When working with Claude on new features:**
> Provide the RLS-QUICK-START.md document to ensure proper RLS setup from the beginning.

---

## 🚀 Getting Started

### Database Setup

Run the comprehensive RLS setup script:

```bash
# Via Supabase Dashboard SQL Editor
# Copy contents of: database/comprehensive-rls-setup.sql
# Paste and run in SQL Editor
```

Or if you have direct database access:

```bash
psql $DATABASE_URL -f database/comprehensive-rls-setup.sql
```

### Verify RLS Policies

```sql
SELECT tablename, COUNT(*) as policy_count
FROM pg_policies
WHERE schemaname = 'public'
GROUP BY tablename
ORDER BY tablename;
```

---

## 🛠 Development

### Testing Anonymous User Flows

**Critical:** Always test checkout flows as anonymous user:

```javascript
// Sign out first
await supabase.auth.signOut();

// Test the checkout flow
const { data, error } = await supabase
  .from('pumpkin_patch_orders')
  .insert({
    order_number: 'TEST-001',
    first_name: 'Test',
    last_name: 'User',
    email: 'test@example.com',
    total_amount: 50
  });

if (error && error.message.includes('row-level security')) {
  console.error('❌ RLS POLICY MISSING - See docs/RLS-QUICK-START.md');
}
```

### Deploying Edge Functions

```bash
# Deploy email function
./supabase-cli/supabase functions deploy send-pumpkin-email --project-ref lmsuyhzcmgdpjynosxvp

# Deploy admin notification
./supabase-cli/supabase functions deploy send-admin-notification --project-ref lmsuyhzcmgdpjynosxvp

# Deploy daily summary
./supabase-cli/supabase functions deploy send-daily-summary --project-ref lmsuyhzcmgdpjynosxvp
```

---

## 📁 Project Structure

```
GUIDAL/
├── docs/
│   ├── SUPABASE-RLS-BEST-PRACTICES.md  # Complete RLS guide
│   └── RLS-QUICK-START.md              # Quick reference for Claude
├── database/
│   ├── comprehensive-rls-setup.sql     # Master RLS script
│   ├── fix-insert-rls-simple.sql       # Legacy fix scripts
│   └── *.sql                           # Other database scripts
├── events/
│   └── pumpkin-patch-checkout.html     # Customer checkout page
├── admin/
│   ├── pumpkin-orders.html             # Order management
│   └── *.html                          # Other admin pages
├── cashier/
│   └── payments.html                   # QR code scanning & credits
└── supabase/
    └── functions/                      # Edge Functions
        ├── send-pumpkin-email/
        ├── send-admin-notification/
        └── send-daily-summary/
```

---

## 🔐 Security & Permissions

### User Roles

| Role | Description | Access Level |
|------|-------------|--------------|
| `anon` | Anonymous users (customers) | INSERT/SELECT on orders, order_items |
| `authenticated` | Logged-in users (admin) | Full access to management features |
| `service_role` | Edge Functions | Full access, bypasses RLS |

### Key Tables & Policies

| Table | anon | authenticated | Purpose |
|-------|------|---------------|---------|
| `pumpkin_patch_orders` | INSERT, SELECT | ALL | Customer orders |
| `pumpkin_patch_order_items` | INSERT, SELECT | ALL | Order line items |
| `admin_notification_settings` | SELECT | ALL | Email settings |
| `pumpkin_patch_email_log` | INSERT, SELECT | ALL | Email tracking |
| `guest_credits` | ALL | ALL | Credit balances |
| `credit_transactions` | INSERT, SELECT | ALL | Credit history |

---

## 🐛 Troubleshooting

### "new row violates row-level security policy"

**Cause:** Missing RLS policy for the table/operation.

**Solution:**
1. Check if policy exists:
   ```sql
   SELECT * FROM pg_policies WHERE tablename = 'your_table';
   ```

2. If missing, run comprehensive setup:
   ```bash
   # Run database/comprehensive-rls-setup.sql
   ```

3. Test as anonymous user again

### "permission denied for table"

**Cause:** Table-level permissions not granted.

**Solution:**
```sql
GRANT SELECT, INSERT, UPDATE ON your_table TO anon, authenticated;
```

### Email not sending

**Check:**
1. Resend API key configured in Edge Function
2. Email log table has INSERT policy
3. Admin notification settings has SELECT policy

### QR code not found in cashier app

**Check:**
1. Guest credits created when order marked as paid
2. QR code format matches: `ORDER:PP-YYYYMMDD-NNN|NAME:...|...`
3. Case-insensitive search enabled

---

## 📊 Database Maintenance

### Check Order Status

```sql
SELECT
  COUNT(*) as total_orders,
  SUM(CASE WHEN payment_status = 'paid' THEN 1 ELSE 0 END) as paid,
  SUM(CASE WHEN payment_status = 'pending' THEN 1 ELSE 0 END) as pending,
  SUM(total_amount) FILTER (WHERE payment_status = 'paid') as revenue
FROM pumpkin_patch_orders
WHERE created_at > NOW() - INTERVAL '7 days';
```

### Find Order by Email

```bash
# Use prepared script
# database/search-order-by-email.sql
```

### Verify RLS Policies

```sql
-- Check all tables have policies
SELECT
  t.tablename,
  t.rowsecurity as rls_enabled,
  COUNT(p.policyname) as policy_count
FROM pg_tables t
LEFT JOIN pg_policies p ON p.tablename = t.tablename
WHERE t.schemaname = 'public'
  AND t.tablename LIKE '%pumpkin%'
GROUP BY t.tablename, t.rowsecurity
ORDER BY t.tablename;
```

---

## 🎯 Best Practices Checklist

When adding new features:

- [ ] **Map all tables** that will be accessed
- [ ] **Add RLS policies** to comprehensive-rls-setup.sql
- [ ] **Test as anonymous** if customers will use it
- [ ] **Add error handling** with prominent user feedback
- [ ] **Document in this README** if it's a major feature
- [ ] **Update RLS docs** if new patterns are needed

---

## 📞 Support

For issues or questions:
- **Email:** mwpicard@gmail.com
- **Database Issues:** See [docs/RLS-QUICK-START.md](docs/RLS-QUICK-START.md)
- **RLS Policy Errors:** Run `database/comprehensive-rls-setup.sql`

---

## 🔄 Recent Changes

### 2025-10-11: Comprehensive RLS Setup
- Created master RLS setup script covering all tables
- Fixed anonymous user checkout blocking issue
- Added prominent error messages for RLS failures
- Created RLS best practices documentation

### 2025-10-10: Pumpkin Patch Booking System
- Added customer checkout page
- Implemented PayPal integration
- Created admin order management
- Added email confirmation system
- Implemented QR code-based credit system

---

## 📝 License

Proprietary - GUIDAL

---

*Last Updated: 2025-10-11*
