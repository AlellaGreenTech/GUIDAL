# Complete Account & GREENS System Documentation

## Overview

This is a production-ready account creation and GREENS (digital currency) management system for GUIDAL/Alella Green Tech. The system follows database best practices with proper constraints, transactions, RLS policies, and audit trails.

## System Architecture

### Flow Diagram

```
1. User checks out → checkbox "Create account" is checked by default
2. Order created → pending_account record created with:
   - Unique QR code (AGT-YYYYMMDD-XXXX)
   - Secure activation token
   - Initial GREENS balance from order
3. Welcome email scheduled (7 days later)
4. User receives email → clicks password setup link
5. User sets password → Auth account created
6. activate_pending_account() function:
   - Creates profile record
   - Links to Auth user
   - Creates initial GREENS transaction
   - Marks pending account as activated
7. User can now:
   - Log in with email/password
   - View GREENS balance
   - Use QR code at farm
```

## Database Schema

### 1. Profiles Table

Linked to Supabase Auth. Main user account table.

```sql
profiles (
    id UUID → auth.users(id)
    email TEXT UNIQUE
    first_name TEXT
    last_name TEXT
    phone TEXT
    qr_code TEXT UNIQUE (e.g., "AGT-20251014-1234")
    greens_balance DECIMAL(10,2) >= 0
    account_status TEXT ('pending'|'active'|'suspended'|'closed')
    created_at TIMESTAMP
    updated_at TIMESTAMP (auto-updated via trigger)
    activated_at TIMESTAMP
    last_login_at TIMESTAMP
)
```

**Indexes:**
- `idx_profiles_email` on `email`
- `idx_profiles_qr_code` on `qr_code`
- `idx_profiles_status` on `account_status`

### 2. Pending Accounts Table

Temporary storage before activation.

```sql
pending_accounts (
    id UUID PRIMARY KEY
    email TEXT UNIQUE
    first_name TEXT
    last_name TEXT
    phone TEXT
    qr_code TEXT UNIQUE
    initial_greens_balance DECIMAL(10,2)
    order_id UUID → pumpkin_patch_orders(id)
    activation_token TEXT UNIQUE (UUID)
    token_expires_at TIMESTAMP (30 days)
    created_at TIMESTAMP
    activated BOOLEAN DEFAULT FALSE
    activated_at TIMESTAMP
)
```

**Indexes:**
- `idx_pending_accounts_email`
- `idx_pending_accounts_token`
- `idx_pending_accounts_activated`

### 3. GREENS Transactions Table

Complete audit trail of all GREENS movements.

```sql
greens_transactions (
    id UUID PRIMARY KEY
    user_id UUID → profiles(id)
    amount DECIMAL(10,2) (+ for topup, - for debit)
    transaction_type TEXT ('purchase'|'topup'|'debit'|'refund'|'adjustment')
    balance_before DECIMAL(10,2)
    balance_after DECIMAL(10,2)
    description TEXT
    order_id UUID → pumpkin_patch_orders(id)
    metadata JSONB (additional data)
    created_at TIMESTAMP
    created_by UUID → profiles(id)
)
```

**Indexes:**
- `idx_greens_transactions_user_id`
- `idx_greens_transactions_created_at DESC`
- `idx_greens_transactions_type`
- `idx_greens_transactions_user_date` (composite for history queries)

## Key Functions

### 1. generate_unique_qr_code()

Generates unique QR codes in format: `AGT-YYYYMMDD-XXXX`

```sql
SELECT generate_unique_qr_code();
-- Returns: "AGT-20251014-3847"
```

### 2. create_greens_transaction()

**Atomic transaction creation with balance update. Prevents race conditions.**

```sql
SELECT create_greens_transaction(
    p_user_id := 'uuid-here',
    p_amount := 10.5,  -- positive for topup, negative for debit
    p_transaction_type := 'topup',
    p_description := 'Initial GREENS from order',
    p_order_id := 'order-uuid',
    p_metadata := '{"source": "account_activation"}'::jsonb,
    p_created_by := NULL
);
```

**Features:**
- Row-level locking (FOR UPDATE) prevents concurrent modifications
- Automatically calculates new balance
- Validates balance doesn't go negative
- Creates transaction record with before/after snapshots
- Updates profile balance atomically
- Returns transaction ID

### 3. activate_pending_account()

**Activates pending account and creates full profile.**

```sql
SELECT activate_pending_account(
    p_activation_token := 'token-from-email',
    p_auth_user_id := 'auth-user-id-from-signup'
);
```

**What it does:**
1. Validates activation token (not expired, not already used)
2. Creates profile record linked to Auth user
3. Creates initial GREENS transaction if balance > 0
4. Marks pending account as activated
5. Returns profile ID

### 4. get_user_by_qr_code()

For cashier scanning at farm:

```sql
SELECT * FROM get_user_by_qr_code('AGT-20251014-1234');
```

Returns user info and current GREENS balance.

### 5. get_transaction_history()

Get user's transaction history:

```sql
SELECT * FROM get_transaction_history(
    p_user_id := 'uuid-here',
    p_limit := 50
);
```

## Row Level Security (RLS)

### Profiles

- ✅ Users can view/update own profile
- ✅ Service role has full access
- ❌ Users cannot view other profiles

### Pending Accounts

- ✅ Public can read by token (for activation)
- ✅ Service role has full access
- ❌ Users cannot directly access

### GREENS Transactions

- ✅ Users can view own transactions
- ✅ Service role has full access
- ❌ Users cannot view others' transactions
- ❌ Users cannot create transactions (only via function)

## Setup Instructions

### 1. Run Database Migrations

```bash
# Connect to your Supabase database
psql -h <your-host> -U postgres -d postgres -f database/create-accounts-and-greens-system.sql
```

Or run via Supabase SQL Editor:
- Copy contents of `database/create-accounts-and-greens-system.sql`
- Paste into SQL Editor
- Execute

### 2. Deploy Edge Functions

```bash
# 1. Deploy welcome account email scheduler
./supabase-cli/supabase functions deploy send-welcome-account-email --project-ref lmsuyhzcmgdpjynosxvp

# 2. Deploy scheduled email sender (cron job)
./supabase-cli/supabase functions deploy send-scheduled-welcome-emails --project-ref lmsuyhzcmgdpjynosxvp
```

### 3. Set Up Cron Job

In Supabase Dashboard, create a cron job that runs daily:

```sql
-- Schedule: 0 9 * * * (9 AM UTC daily)
SELECT
  net.http_post(
    url := 'https://lmsuyhzcmgdpjynosxvp.supabase.co/functions/v1/send-scheduled-welcome-emails',
    headers := '{"Content-Type": "application/json", "Authorization": "Bearer YOUR_SERVICE_ROLE_KEY"}'::jsonb,
    body := '{}'::jsonb
  );
```

### 4. Verify Setup

```sql
-- Check tables exist
\dt profiles pending_accounts greens_transactions

-- Check functions exist
\df generate_unique_qr_code
\df create_greens_transaction
\df activate_pending_account

-- Check indexes
SELECT tablename, indexname FROM pg_indexes
WHERE schemaname = 'public'
AND tablename IN ('profiles', 'pending_accounts', 'greens_transactions');

-- Check RLS policies
SELECT tablename, policyname FROM pg_policies
WHERE schemaname = 'public';
```

## User Journey

### Step 1: Checkout

1. User visits `/events/pumpkin-patch-checkout.html`
2. Fills in email, name, purchases GREENS
3. Checkbox "Make me an Alella Green Tech account" is checked by default
4. Clicks "Continue to Payment"
5. Order is saved to database
6. If checkbox checked:
   - `send-welcome-account-email` Edge Function is called
   - Pending account created with unique QR code
   - Activation token generated (expires in 30 days)
   - Welcome email scheduled for 7 days later

### Step 2: Welcome Email (7 days later)

User receives email with:
- Password setup link: `https://guidal.org/pages/auth/setup-password.html?token={activation_token}`
- QR code text (e.g., "AGT-20251014-1234")
- Initial GREENS balance
- Instructions

### Step 3: Password Setup

1. User clicks link from email
2. `/pages/auth/setup-password.html` loads
3. Page fetches pending account by token
4. Shows account info (name, email, balance, QR code)
5. User creates password (validated: 8+ chars, uppercase, lowercase, number)
6. On submit:
   - Supabase Auth account created via `signUp()`
   - `activate_pending_account()` RPC function called
   - Profile record created
   - Initial GREENS transaction logged
   - Pending account marked as activated
7. Success page shows
8. User can now log in

### Step 4: Using the Account

User can now:
- Log in at `/pages/auth/login.html`
- View GREENS balance
- Top up GREENS
- Show QR code at farm for purchases
- View transaction history

## API Reference

### Edge Function: send-welcome-account-email

**Endpoint:** `POST /functions/v1/send-welcome-account-email`

**Request:**
```json
{
  "email": "user@example.com",
  "firstName": "John",
  "lastName": "Doe",
  "phone": "+34123456789",
  "orderId": "uuid",
  "initialGreensBalance": 10
}
```

**Response:**
```json
{
  "success": true,
  "message": "Pending account created and welcome email scheduled",
  "pending_account_id": "uuid",
  "qr_code": "AGT-20251014-1234",
  "scheduled_for": "2025-10-21T09:00:00Z"
}
```

### Edge Function: send-scheduled-welcome-emails

**Endpoint:** `POST /functions/v1/send-scheduled-welcome-emails`

Cron job function. Processes all pending welcome emails.

**Response:**
```json
{
  "success": true,
  "message": "Scheduled emails processed",
  "sent": 5,
  "failed": 0
}
```

## Database Queries

### Get all active users with GREENS balance

```sql
SELECT * FROM user_balance_summary
WHERE current_balance > 0
ORDER BY current_balance DESC;
```

### Get user transaction history

```sql
SELECT
    t.created_at,
    t.transaction_type,
    t.amount,
    t.balance_after,
    t.description
FROM greens_transactions t
JOIN profiles p ON p.id = t.user_id
WHERE p.email = 'user@example.com'
ORDER BY t.created_at DESC
LIMIT 20;
```

### Get pending account activations

```sql
SELECT
    email,
    first_name,
    last_name,
    qr_code,
    initial_greens_balance,
    token_expires_at,
    created_at
FROM pending_accounts
WHERE NOT activated
AND token_expires_at > NOW()
ORDER BY created_at DESC;
```

### Get users who haven't activated

```sql
SELECT
    pa.email,
    pa.first_name,
    pa.last_name,
    pa.created_at,
    pa.token_expires_at,
    EXTRACT(DAY FROM (pa.token_expires_at - NOW())) as days_until_expiry
FROM pending_accounts pa
WHERE NOT pa.activated
AND pa.token_expires_at > NOW()
ORDER BY pa.created_at DESC;
```

### Top up user GREENS (manual)

```sql
SELECT create_greens_transaction(
    p_user_id := (SELECT id FROM profiles WHERE email = 'user@example.com'),
    p_amount := 20.0,
    p_transaction_type := 'topup',
    p_description := 'Manual top-up by admin',
    p_order_id := NULL,
    p_metadata := '{"source": "manual_admin", "admin_note": "Customer request"}'::jsonb,
    p_created_by := (SELECT id FROM profiles WHERE email = 'admin@guidal.org')
);
```

### Debit GREENS (purchase at farm)

```sql
SELECT create_greens_transaction(
    p_user_id := (SELECT id FROM get_user_by_qr_code('AGT-20251014-1234')),
    p_amount := -5.5,
    p_transaction_type := 'debit',
    p_description := 'Purchase: Pizza slice + drink',
    p_order_id := NULL,
    p_metadata := '{"items": ["pizza_slice", "drink"], "cashier": "John"}'::jsonb,
    p_created_by := (SELECT id FROM profiles WHERE email = 'cashier@guidal.org')
);
```

## Testing

### Test 1: Create Pending Account

```bash
curl -X POST https://lmsuyhzcmgdpjynosxvp.supabase.co/functions/v1/send-welcome-account-email \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -d '{
    "email": "test@example.com",
    "firstName": "Test",
    "lastName": "User",
    "phone": "+34123456789",
    "orderId": null,
    "initialGreensBalance": 15
  }'
```

### Test 2: Check Pending Account

```sql
SELECT * FROM pending_accounts WHERE email = 'test@example.com';
```

### Test 3: Trigger Welcome Email (set scheduled_for to past)

```sql
UPDATE scheduled_welcome_emails
SET scheduled_for = NOW() - INTERVAL '1 hour'
WHERE email = 'test@example.com';
```

Then call the cron function:

```bash
curl -X POST https://lmsuyhzcmgdpjynosxvp.supabase.co/functions/v1/send-scheduled-welcome-emails \
  -H "Authorization: Bearer YOUR_SERVICE_ROLE_KEY"
```

### Test 4: Complete Activation Flow

1. Get activation token from pending_accounts
2. Visit: `https://guidal.org/pages/auth/setup-password.html?token={TOKEN}`
3. Set password
4. Verify profile and transaction created

```sql
-- Check profile created
SELECT * FROM profiles WHERE email = 'test@example.com';

-- Check transaction logged
SELECT * FROM greens_transactions
WHERE user_id = (SELECT id FROM profiles WHERE email = 'test@example.com');

-- Check pending account marked activated
SELECT activated, activated_at FROM pending_accounts WHERE email = 'test@example.com';
```

## Monitoring & Maintenance

### Daily Health Check

```sql
-- Pending accounts awaiting activation
SELECT COUNT(*) as pending_count FROM pending_accounts
WHERE NOT activated AND token_expires_at > NOW();

-- Expired tokens (need to be cleaned up or resent)
SELECT COUNT(*) as expired_count FROM pending_accounts
WHERE NOT activated AND token_expires_at <= NOW();

-- Failed welcome emails
SELECT COUNT(*) as failed_count FROM scheduled_welcome_emails
WHERE status = 'failed';

-- Total GREENS in circulation
SELECT SUM(greens_balance) as total_greens FROM profiles WHERE account_status = 'active';

-- Transactions today
SELECT
    transaction_type,
    COUNT(*) as count,
    SUM(amount) as total_amount
FROM greens_transactions
WHERE created_at >= CURRENT_DATE
GROUP BY transaction_type;
```

### Clean Up Expired Tokens

```sql
-- Archive or delete expired pending accounts (older than 60 days)
DELETE FROM pending_accounts
WHERE NOT activated
AND token_expires_at < NOW() - INTERVAL '30 days';
```

## Security Best Practices

✅ **Implemented:**
1. Row Level Security (RLS) on all tables
2. Secure token generation (UUID)
3. Token expiration (30 days)
4. Password strength validation (8+ chars, mixed case, number)
5. Atomic transactions (prevents race conditions)
6. Balance validation (cannot go negative)
7. Foreign key constraints
8. Email validation
9. Unique constraints on email, QR code, tokens

✅ **Additional Recommendations:**
1. Enable 2FA for admin accounts
2. Set up rate limiting on Auth endpoints
3. Monitor for suspicious activity
4. Regular database backups
5. Encrypt sensitive data at rest
6. Use HTTPS everywhere
7. Implement CAPTCHA on signup
8. Add email verification step

## Troubleshooting

### Issue: User didn't receive welcome email

**Check:**
```sql
SELECT * FROM scheduled_welcome_emails WHERE email = 'user@example.com';
SELECT * FROM email_logs WHERE recipient = 'user@example.com' AND email_type = 'welcome_account';
```

**Solutions:**
- Verify RESEND_API_KEY is set
- Check spam folder
- Manually trigger: Update `scheduled_for` to past, run cron function

### Issue: Activation link expired

**Solution:**
```sql
-- Extend token expiration
UPDATE pending_accounts
SET token_expires_at = NOW() + INTERVAL '7 days'
WHERE email = 'user@example.com' AND NOT activated;

-- Resend email
UPDATE scheduled_welcome_emails
SET status = 'pending', scheduled_for = NOW()
WHERE email = 'user@example.com';
```

### Issue: Balance discrepancy

**Audit:**
```sql
-- Check all transactions for user
SELECT * FROM greens_transactions
WHERE user_id = (SELECT id FROM profiles WHERE email = 'user@example.com')
ORDER BY created_at;

-- Recalculate balance
SELECT
    SUM(amount) as calculated_balance,
    (SELECT greens_balance FROM profiles WHERE email = 'user@example.com') as current_balance
FROM greens_transactions
WHERE user_id = (SELECT id FROM profiles WHERE email = 'user@example.com');
```

### Issue: Duplicate QR codes

**Check:**
```sql
SELECT qr_code, COUNT(*)
FROM (
    SELECT qr_code FROM profiles
    UNION ALL
    SELECT qr_code FROM pending_accounts
) combined
GROUP BY qr_code
HAVING COUNT(*) > 1;
```

Should return no rows (unique constraint prevents this).

## Future Enhancements

1. **QR Code Images**: Generate actual QR code images instead of text
2. **Mobile App**: Native app for scanning QR codes at farm
3. **GREENS Gifts**: Transfer GREENS between users
4. **Loyalty Program**: Bonus GREENS for frequent visitors
5. **Subscription Plans**: Monthly GREENS packages
6. **Admin Dashboard**: Web UI for managing accounts, transactions
7. **Analytics**: Usage reports, spending patterns
8. **Notifications**: Email/SMS for low balance, transactions
9. **Export**: Transaction history as CSV/PDF
10. **Referral System**: Earn GREENS by referring friends

## Support

For issues or questions:
- Email: info@guidal.org
- GitHub: https://github.com/AlellaGreenTech/GUIDAL/issues
