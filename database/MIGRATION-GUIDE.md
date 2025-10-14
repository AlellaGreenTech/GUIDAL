# Database Migration Guide: Account & GREENS System

## Quick Start

Your database already has a `profiles` table, so we need to migrate it rather than create from scratch.

### Step 1: Check Current Schema (5 minutes)

**Option A: Via Supabase SQL Editor (Easiest)**

1. Go to Supabase Dashboard → SQL Editor
2. Copy contents of `database/check-current-schema.sql`
3. Paste and click "Run"
4. Review the output to see what exists

**Option B: Via psql command line**

```bash
psql -h db.lmsuyhzcmgdpjynosxvp.supabase.co -U postgres -d postgres -f database/check-current-schema.sql
```

**What to look for:**
- Which tables exist (profiles, pending_accounts, greens_transactions)
- Which columns are missing from profiles (qr_code, greens_balance, etc.)
- Which functions need to be created

### Step 2: Run Migration (5 minutes)

**Option A: Via Supabase SQL Editor (Recommended)**

1. Go to Supabase Dashboard → SQL Editor
2. Copy entire contents of `database/migrate-to-accounts-system.sql`
3. Paste and click "Run"
4. Review success messages

**Option B: Via psql command line**

```bash
psql -h db.lmsuyhzcmgdpjynosxvp.supabase.co -U postgres -d postgres -f database/migrate-to-accounts-system.sql
```

**What it does:**
- ✅ Adds missing columns to existing `profiles` table
- ✅ Creates `pending_accounts` table
- ✅ Creates `greens_transactions` table
- ✅ Creates all functions (generate_unique_qr_code, create_greens_transaction, etc.)
- ✅ Sets up indexes for performance
- ✅ Enables Row Level Security
- ✅ Preserves all existing data

### Step 3: Deploy Edge Functions (10 minutes)

```bash
# 1. Deploy welcome email scheduler
./supabase-cli/supabase functions deploy send-welcome-account-email --project-ref lmsuyhzcmgdpjynosxvp

# 2. Deploy scheduled email sender (cron)
./supabase-cli/supabase functions deploy send-scheduled-welcome-emails --project-ref lmsuyhzcmgdpjynosxvp
```

### Step 4: Set Up Cron Job (5 minutes)

1. Go to Supabase Dashboard → Database → Cron Jobs
2. Create new cron job:
   - **Schedule**: `0 9 * * *` (daily at 9 AM UTC)
   - **Command**:
   ```sql
   SELECT
     net.http_post(
       url := 'https://lmsuyhzcmgdpjynosxvp.supabase.co/functions/v1/send-scheduled-welcome-emails',
       headers := '{"Content-Type": "application/json", "Authorization": "Bearer YOUR_SERVICE_ROLE_KEY"}'::jsonb,
       body := '{}'::jsonb
     );
   ```

Replace `YOUR_SERVICE_ROLE_KEY` with your actual service role key from Settings → API.

### Step 5: Test (5 minutes)

1. Make a test order at checkout with "Create account" checked
2. Check `pending_accounts` table:
   ```sql
   SELECT * FROM pending_accounts ORDER BY created_at DESC LIMIT 5;
   ```
3. Check that QR code was generated
4. Verify welcome email was scheduled for 7 days later

## What Got Migrated

### Profiles Table - New Columns Added:
- `qr_code` - Unique identifier (AGT-YYYYMMDD-XXXX)
- `greens_balance` - Current GREENS balance (with CHECK >= 0)
- `account_status` - 'pending', 'active', 'suspended', 'closed'
- `activated_at` - When account was activated
- `last_login_at` - Last login timestamp
- `first_name`, `last_name`, `phone` - If they didn't exist

### New Tables Created:
- `pending_accounts` - Pre-activation storage
- `greens_transactions` - Complete audit trail
- `scheduled_welcome_emails` - (Already existed from previous work)

### New Functions:
- `generate_unique_qr_code()` - Creates unique QR codes
- `create_greens_transaction()` - Atomic balance updates
- `activate_pending_account()` - Converts pending → active
- `get_user_by_qr_code()` - For cashier scanning
- `get_transaction_history()` - User's transactions

### New View:
- `user_balance_summary` - Reporting view

## Rollback (If Needed)

If something goes wrong, you can rollback:

**Via Supabase SQL Editor:**
1. Copy contents of `database/rollback-accounts-migration.sql`
2. Paste and run
3. Type "YES" when prompted

**Via psql:**
```bash
psql -h db.lmsuyhzcmgdpjynosxvp.supabase.co -U postgres -d postgres -f database/rollback-accounts-migration.sql
```

**WARNING:** Rollback will delete:
- All GREENS transactions
- All pending accounts
- New columns from profiles table

## Verification Queries

After migration, run these to verify:

```sql
-- Check profiles table has new columns
\d profiles

-- Check new tables exist
\dt pending_accounts greens_transactions

-- Check functions exist
\df generate_unique_qr_code
\df create_greens_transaction
\df activate_pending_account

-- Test QR code generation
SELECT generate_unique_qr_code();

-- Check view works
SELECT * FROM user_balance_summary LIMIT 5;
```

## Common Issues

### Issue: "column qr_code does not exist"
**Cause:** Tried to run `create-accounts-and-greens-system.sql` instead of `migrate-to-accounts-system.sql`
**Solution:** Run `migrate-to-accounts-system.sql` which safely adds columns

### Issue: "relation profiles already exists"
**Cause:** Normal - migration script uses `IF NOT EXISTS`
**Solution:** This is expected, migration adds columns to existing table

### Issue: "duplicate key value violates unique constraint"
**Cause:** Trying to add duplicate data
**Solution:** Check existing data in pending_accounts table

### Issue: Functions not found after migration
**Cause:** Schema permissions or wrong database
**Solution:**
```sql
-- Check functions exist
SELECT routine_name FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_name LIKE '%greens%' OR routine_name LIKE '%qr%';
```

## Migration Timeline

Total time: ~30 minutes

1. ✅ Check current schema (5 min)
2. ✅ Run migration SQL (5 min)
3. ✅ Deploy Edge Functions (10 min)
4. ✅ Set up cron job (5 min)
5. ✅ Test system (5 min)

## Post-Migration Checklist

- [ ] Run `check-current-schema.sql` to verify
- [ ] Profiles table has qr_code column
- [ ] pending_accounts table exists
- [ ] greens_transactions table exists
- [ ] All functions created successfully
- [ ] Indexes created
- [ ] RLS policies enabled
- [ ] Edge Functions deployed
- [ ] Cron job configured
- [ ] Test account creation works
- [ ] Welcome email sent successfully

## Support

For issues:
- Check `COMPLETE-ACCOUNT-SYSTEM.md` for full documentation
- Review Supabase logs for errors
- Test functions manually with SQL queries
- Contact: info@guidal.org

## Next Steps After Migration

1. **Test the flow:**
   - Make test order with account creation
   - Check pending_accounts table
   - Wait for welcome email (or manually trigger)
   - Complete password setup
   - Verify profile created

2. **Monitor:**
   ```sql
   -- Check pending accounts
   SELECT COUNT(*) FROM pending_accounts WHERE NOT activated;

   -- Check transactions
   SELECT COUNT(*) FROM greens_transactions;

   -- Check active users
   SELECT COUNT(*) FROM profiles WHERE account_status = 'active';
   ```

3. **Backup:**
   - Regular backups of pending_accounts
   - Regular backups of greens_transactions
   - Supabase has automatic backups, but good to verify

## Files Reference

- `check-current-schema.sql` - Diagnostic script (run first)
- `migrate-to-accounts-system.sql` - Safe migration (run second)
- `rollback-accounts-migration.sql` - Undo migration (emergency)
- `create-accounts-and-greens-system.sql` - Clean install (don't use if profiles exists)
- `COMPLETE-ACCOUNT-SYSTEM.md` - Full system documentation
- `ACCOUNT-CREATION-SETUP.md` - Original setup guide
