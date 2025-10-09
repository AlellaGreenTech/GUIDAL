# Cashier Payment System - Setup Guide

## Overview
Complete cashier system for managing guest credits via QR codes. Cashiers can scan QR codes, view balances, and process transactions on mobile devices.

## Features Implemented

### ✅ Database Schema
- **Cashier role** added to user_profiles
- **guest_credits** table - tracks QR codes and credit balances
- **credit_transactions** table - logs all credit usage
- **payment_link_requests** table - tracks top-up email requests
- **SQL functions** for credit deduction and addition
- **Row Level Security** - cashiers and admins only

### ✅ Admin Interface (`/admin/cashier-management.html`)
- **Cashier Management** - Assign/remove cashier role from users
- **Guest Credit Creation** - Create new guests with QR codes
- **QR Code Generation** - Auto-generate unique QR codes
- **Credit Overview** - View all guest credits and balances
- **Transaction Reporting** - See all transactions
- **Statistics Dashboard** - Total credits, active QR codes, transactions

### ✅ Mobile Cashier App (`/cashier/payments.html`)
- **QR Code Scanner** - Camera-based scanning
- **Manual QR Entry** - Type QR code if camera fails
- **Credit Display** - Large, clear balance display
- **Quick Amounts** - One-tap amounts (€1, €2, €5, €10, €15, €20)
- **Custom Amounts** - Enter any amount
- **Item Selection** - Dropdown for common items
- **Location Tracking** - Track where transaction occurred
- **Transaction History** - See guest's recent purchases
- **Insufficient Credit Alert** - Send top-up email button

## Setup Instructions

### 1. Run Database Migration

Run the SQL file in Supabase SQL Editor:

```bash
database/create-cashier-system.sql
```

This creates:
- All tables
- RLS policies
- Functions
- Indexes
- Views

### 2. Assign First Cashier

1. Go to `/admin/cashier-management.html`
2. Search for user by email
3. Click "Assign Cashier Role"

### 3. Create Guest Credits

1. In Cashier Management, go to "Guest Credits" tab
2. Fill in guest information:
   - Name
   - Email
   - Phone (optional)
   - Initial credit amount
3. Click "Create Guest Credit & Generate QR Code"
4. QR code will be displayed - print or show to guest

### 4. Test Cashier App

1. Open `/cashier/payments.html` on mobile device
2. Log in as cashier
3. Click "Start Scanner"
4. Scan guest QR code or enter manually
5. Select amount and description
6. Click "Process Payment"

## Database Tables

### guest_credits
```sql
- id (UUID)
- guest_name (TEXT)
- guest_email (TEXT)
- guest_phone (TEXT)
- qr_code (TEXT, UNIQUE) - Format: GUIDAL-XXXXXXXX
- credit_balance (DECIMAL)
- initial_credit (DECIMAL)
- status (active/inactive/expired)
- created_at, updated_at, expires_at
- order_id (optional link to pumpkin_patch_orders)
- notes (TEXT)
```

### credit_transactions
```sql
- id (UUID)
- guest_credit_id (FK to guest_credits)
- transaction_type (debit/credit/refund/adjustment)
- amount (DECIMAL)
- balance_before, balance_after (DECIMAL)
- description (TEXT) - What was purchased
- processed_by (FK to auth.users)
- processed_by_name, processed_by_role (TEXT)
- transaction_date (TIMESTAMP)
- location (TEXT) - e.g., "Food Stand"
- metadata (JSONB)
```

### payment_link_requests
```sql
- id (UUID)
- guest_credit_id (FK)
- guest_email (TEXT)
- amount_requested (DECIMAL)
- reason (TEXT)
- payment_link (TEXT)
- payment_status (pending/sent/paid/failed/cancelled)
- requested_by (FK to auth.users)
- requested_by_name (TEXT)
- created_at, email_sent_at, paid_at
```

## User Roles

### Admin
- Full access to everything
- Can assign cashier roles
- Can create guest credits
- Can add/refund credits
- Can view all transactions

### Cashier
- Access to cashier payment app
- Can scan QR codes
- Can process payments (deduct credits)
- Can view guest balances
- Can send top-up emails
- **Cannot** add credits (admins only)

## SQL Functions

### `deduct_credit(p_qr_code, p_amount, p_description, p_location, p_metadata)`
Deducts credit from guest account. Returns:
```json
{
  "success": true,
  "transaction_id": "uuid",
  "previous_balance": 50.00,
  "new_balance": 45.00,
  "amount_deducted": 5.00
}
```

Or if insufficient:
```json
{
  "success": false,
  "error": "insufficient_balance",
  "current_balance": 3.00,
  "requested_amount": 5.00,
  "shortfall": 2.00
}
```

### `add_credit(p_qr_code, p_amount, p_description, p_transaction_type)`
Adds credit (admins only). For refunds or top-ups.

## QR Code Format

QR codes use this format:
```
GUIDAL-XXXXXXXX
```

Example: `GUIDAL-A7B3F9D2`

The code is:
- Automatically generated
- Unique (enforced by database)
- Case-insensitive for scanning
- Links to exactly one guest_credit record

## Mobile App Features

### Scanner Mode
- Uses device camera
- Auto-detects QR codes
- Vibrates on successful scan (if supported)
- Falls back to manual entry if camera fails

### Payment Flow
1. Scan QR code
2. See guest name and balance
3. Select item or enter custom amount
4. Optionally select location
5. Click "Process Payment"
6. See confirmation and new balance
7. View transaction in history

### Insufficient Credit Flow
1. Scan QR code
2. See low/zero balance
3. Click "Send Top-Up Email"
4. Confirm email address
5. Email sent with PayPal payment link
6. Guest receives email
7. Guest pays via PayPal
8. Balance auto-updates (via webhook - to be implemented)

## Integration with Pumpkin Patch Orders

Guest credits can be linked to pumpkin patch orders:

```sql
UPDATE guest_credits
SET order_id = '<pumpkin_order_id>'
WHERE id = '<guest_credit_id>';
```

This allows tracking which order generated the credit.

## Security

### Row Level Security (RLS)
- ✅ Only cashiers and admins can view/update guest_credits
- ✅ Only cashiers and admins can insert transactions
- ✅ Only admins can create guest credits
- ✅ Only admins can add credits (refunds/top-ups)

### SQL Injection Protection
- ✅ All queries use parameterized functions
- ✅ RPC functions validate user roles
- ✅ Input validation on client side

### Authentication
- ✅ Supabase Auth required
- ✅ Role checked on every page load
- ✅ Unauthorized users redirected

## TODO / Future Enhancements

### ✅ Completed
- Database schema
- Admin interface
- Cashier mobile app
- QR code generation
- Credit deduction
- Transaction logging

### 🔨 In Progress
- Top-up email functionality
- PayPal integration for top-ups

### 📋 Planned
- SMS notifications for low balance
- Bulk QR code generation
- Print QR codes as PDF
- Transaction analytics dashboard
- Export transactions to CSV
- Cashier performance reports
- Guest credit expiration automation
- WhatsApp top-up notifications

## Testing Checklist

### Admin Interface
- [ ] Can assign cashier role to user
- [ ] Can create guest credit
- [ ] QR code is generated and displayed
- [ ] Can view all guest credits
- [ ] Can view all transactions
- [ ] Statistics update correctly

### Cashier App
- [ ] Only cashiers/admins can access
- [ ] QR scanner starts correctly
- [ ] Manual QR entry works
- [ ] Credit balance displays correctly
- [ ] Can process payment
- [ ] Balance updates after payment
- [ ] Transaction appears in history
- [ ] Insufficient credit shows error
- [ ] Quick amount buttons work
- [ ] Custom amount input works

### Database
- [ ] RLS policies work (try as non-cashier)
- [ ] Transactions are logged
- [ ] Balances are accurate
- [ ] No negative balances allowed

## Troubleshooting

### Scanner won't start
- Check browser permissions (Camera access)
- Use HTTPS (required for camera API)
- Try manual QR entry instead

### QR code not found
- Check QR code is uppercase
- Verify guest_credit status is 'active'
- Check for typos in manual entry

### Insufficient permissions
- Verify user has cashier or admin role
- Check RLS policies are enabled
- Verify Supabase client is authenticated

### Balance not updating
- Check transaction was successful
- Verify deduct_credit function executed
- Look for errors in browser console
- Check transaction history

## Support

For issues or questions:
1. Check browser console for errors
2. Verify database migration ran successfully
3. Check user role in user_profiles table
4. Review transaction logs in credit_transactions table

## Files Created

```
database/create-cashier-system.sql          - Database schema and functions
admin/cashier-management.html               - Admin interface
cashier/payments.html                       - Mobile cashier app
CASHIER-SYSTEM-SETUP.md                     - This file
```

## Quick Start Commands

```sql
-- Check if tables exist
SELECT table_name FROM information_schema.tables
WHERE table_name IN ('guest_credits', 'credit_transactions', 'payment_link_requests');

-- Create a test guest credit
INSERT INTO guest_credits (guest_name, guest_email, qr_code, credit_balance, initial_credit)
VALUES ('Test Guest', 'test@example.com', 'GUIDAL-TEST01', 50.00, 50.00);

-- Assign cashier role
UPDATE user_profiles
SET role = 'cashier'
WHERE user_id = '<user_id>';

-- View all transactions
SELECT * FROM credit_transactions
ORDER BY transaction_date DESC
LIMIT 10;
```

---

**System Status:** ✅ Ready for Testing
**Next Step:** Run database migration and assign first cashier
