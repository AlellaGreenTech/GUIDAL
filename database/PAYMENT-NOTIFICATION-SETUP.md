# Automated Payment Notification Setup

This guide explains how to set up automated payment notifications that automatically mark pumpkin patch orders as paid when you receive payment confirmation emails.

## Overview

When you receive a payment notification email, an automated system will:
1. Parse the email to extract payment details
2. Send a webhook to your Edge Function
3. Automatically update the order status to "paid"
4. Log the notification for audit purposes

## Components

1. **Edge Function**: `process-payment-notification` - Receives webhook and updates order
2. **Database Functions**:
   - `mark_order_paid()` - Updates order payment status
   - `log_payment_notification()` - Creates audit trail
3. **Email Parser Service**: Zapier, Make.com, or Mailparser (your choice)

---

## Step 1: Deploy Database Functions (5 minutes)

### Option A: Via Supabase SQL Editor (Recommended)

1. Go to Supabase Dashboard → SQL Editor
2. Open the file: `database/payment-notification-functions.sql`
3. Copy entire contents
4. Paste and click "Run"
5. Verify success messages appear

### Option B: Via psql

```bash
psql -h db.lmsuyhzcmgdpjynosxvp.supabase.co -U postgres -d postgres -f database/payment-notification-functions.sql
```

### What This Creates:

- ✅ `mark_order_paid()` function
- ✅ `log_payment_notification()` function
- ✅ `payment_notifications_log` table (audit trail)
- ✅ `payment_notifications_summary` view (for monitoring)

---

## Step 2: Deploy Edge Function (5 minutes)

```bash
./supabase-cli/supabase functions deploy process-payment-notification --project-ref lmsuyhzcmgdpjynosxvp
```

After deployment, note your webhook URL:
```
https://lmsuyhzcmgdpjynosxvp.supabase.co/functions/v1/process-payment-notification
```

---

## Step 3: Set Up Email-to-Webhook Service (15-30 minutes)

You need to choose ONE of these services to parse your payment emails and send webhooks.

### Option A: Zapier (Easiest, $20/month)

**Steps:**

1. **Create new Zap**
   - Trigger: "Email" → "New Inbound Email"
   - Get your Zapier email address (e.g., `john123@robot.zapier.com`)

2. **Forward payment emails**
   - In your email client, create a filter/rule
   - Forward emails matching payment criteria to Zapier email

3. **Add Filter Step** (Optional but recommended)
   - Only continue if subject contains specific text
   - Or from address matches payment provider

4. **Add Formatter Steps** to extract:
   - Order number (from subject or body)
   - Customer email
   - Payment amount
   - Transaction ID

5. **Add Webhooks Step**
   - Action: "Webhooks by Zapier" → "POST"
   - URL: `https://lmsuyhzcmgdpjynosxvp.supabase.co/functions/v1/process-payment-notification`
   - Payload Type: JSON
   - Data:
     ```json
     {
       "orderNumber": "{{extracted_order_number}}",
       "customerEmail": "{{extracted_email}}",
       "amount": "{{extracted_amount}}",
       "transactionId": "{{transaction_id}}",
       "paymentMethod": "paypal",
       "from": "{{trigger_from}}",
       "subject": "{{trigger_subject}}",
       "body": "{{trigger_body}}"
     }
     ```

6. **Test the Zap**
   - Send a test email or use Zapier's test feature
   - Check Supabase Edge Function logs

---

### Option B: Make.com (Free tier available)

**Steps:**

1. **Create new Scenario**
   - Module: "Email" → "Watch emails"
   - Filter by sender or subject

2. **Add Parser Module**
   - Use "Text parser" to extract:
     - Order number with regex: `PP-\d{8}-\d{3}` or your format
     - Email address with regex: `[\w\.-]+@[\w\.-]+\.\w+`
     - Amount with regex: `\$?[\d,]+\.?\d*`

3. **Add HTTP Module**
   - Method: POST
   - URL: Your Edge Function URL
   - Body: JSON with extracted fields

4. **Add Error Handler**
   - Send email notification if webhook fails

---

### Option C: Mailparser (Specialized for email parsing, $29/month)

**Steps:**

1. **Create new Inbox**
   - Get your Mailparser email (e.g., `abc123@inbound.mailparser.io`)

2. **Set up Parsing Rules**
   - Create rules to extract order number, email, amount
   - Test with sample email

3. **Create Webhook**
   - Webhook URL: Your Edge Function URL
   - Select parsed fields to send
   - Test delivery

4. **Forward emails**
   - Create email forwarding rule to Mailparser inbox

---

### Option D: SendGrid Inbound Parse (Free with SendGrid account)

**Steps:**

1. **Set up Domain/Subdomain**
   - Use subdomain like `payments.guidal.org`
   - Add MX records as instructed

2. **Configure Inbound Parse**
   - URL: Your Edge Function URL
   - Check "POST raw email"

3. **Update Edge Function** to parse raw email format
   - SendGrid sends multipart form data
   - You'll need to parse email body differently

---

## Step 4: Configure Email Forwarding (5 minutes)

### Gmail Example:

1. Go to Settings → Filters and Blocked Addresses
2. Create new filter:
   - **From**: `service@paypal.com` (or your payment provider)
   - **Subject contains**: "Payment received" (or your keyword)
3. Check "Forward to"
4. Enter your parser service email (Zapier/Make/Mailparser)
5. Save filter

### Outlook Example:

1. Settings → Rules → Add new rule
2. Condition: From address matches payment provider
3. Action: Forward to parser email
4. Save

---

## Step 5: Test the System (10 minutes)

### Manual Test with curl:

```bash
curl -X POST https://lmsuyhzcmgdpjynosxvp.supabase.co/functions/v1/process-payment-notification \
  -H "Content-Type: application/json" \
  -d '{
    "orderNumber": "PP-20250101-001",
    "customerEmail": "test@example.com",
    "amount": 50.00,
    "transactionId": "TEST-12345",
    "paymentMethod": "paypal"
  }'
```

### Test with Real Email:

1. Create a test order in your system
2. Note the order number and customer email
3. Send yourself a test payment email with those details
4. Email should be forwarded → parsed → webhook sent
5. Check order status in admin dashboard

### Verify in Database:

```sql
-- Check if order was marked as paid
SELECT order_number, payment_status, paid_at, admin_notes
FROM pumpkin_patch_orders
WHERE order_number = 'PP-20250101-001';

-- View all payment notifications
SELECT * FROM payment_notifications_summary
ORDER BY created_at DESC
LIMIT 10;
```

---

## Webhook Payload Format

Your email parser should send a JSON payload with these fields:

```json
{
  "orderNumber": "PP-20250101-001",       // Required (or customerEmail)
  "customerEmail": "customer@example.com", // Required (or orderNumber)
  "amount": 50.00,                         // Optional but recommended
  "transactionId": "PAYPAL-ABC123",        // Optional
  "paymentMethod": "paypal",               // Optional (paypal, stripe, bank_transfer, etc.)
  "from": "service@paypal.com",            // Optional (for logging)
  "subject": "Payment received - Order PP-20250101-001", // Optional
  "body": "Full email body..."             // Optional (for debugging)
}
```

**Matching Logic:**
1. If `orderNumber` provided → finds order by order number
2. If not found, uses `customerEmail` → finds most recent pending order
3. If neither found → returns 404 error and logs attempt

---

## Monitoring & Troubleshooting

### View Payment Notification Logs:

```sql
-- All notifications (success and failures)
SELECT * FROM payment_notifications_summary
ORDER BY created_at DESC;

-- Failed notifications only
SELECT * FROM payment_notifications_log
WHERE status = 'failed'
ORDER BY created_at DESC;

-- Duplicate notifications (already paid)
SELECT * FROM payment_notifications_log
WHERE status = 'duplicate'
ORDER BY created_at DESC;
```

### Check Edge Function Logs:

```bash
./supabase-cli/supabase functions logs process-payment-notification --project-ref lmsuyhzcmgdpjynosxvp --tail
```

### Common Issues:

#### Issue: "Order not found"
**Causes:**
- Order number format doesn't match
- Customer email doesn't match
- Order already paid

**Solutions:**
- Check email parsing rules extract correct format
- Verify email addresses match exactly (case-insensitive)
- Check `payment_notifications_log` table for details

#### Issue: "Amount mismatch"
**Cause:** Parsed amount doesn't match order total

**Solution:**
- Check console warnings in Edge Function logs
- Order still gets marked as paid, but discrepancy is logged

#### Issue: Webhook not receiving data
**Causes:**
- Email forwarding not set up
- Parser service not sending webhook
- URL incorrect

**Solutions:**
- Test email forwarding manually
- Check parser service dashboard for errors
- Verify webhook URL is correct

---

## Email Parsing Examples

### PayPal Payment Notification:

**From:** `service@paypal.com`
**Subject:** `You've received a payment of $50.00 USD`

**Extraction Regex:**
- Amount: `\$(\d+\.?\d*)`
- Transaction ID: `Transaction ID: ([A-Z0-9]+)`

### Stripe Payment:

**From:** `no-reply@stripe.com`
**Subject:** `Payment received for $50.00`

**Extraction Regex:**
- Amount: `\$(\d+\.?\d*)`
- Customer email: Usually in email body

### Bank Transfer:

**From:** Your bank
**Subject:** `Wire transfer received - $50.00`

**Note:** You may need to manually include order reference in transfer notes

---

## Security Considerations

### Current Setup:
- ✅ Edge Function accepts POST requests
- ✅ Validates order exists before updating
- ✅ Logs all attempts for audit
- ✅ Prevents duplicate "paid" status updates

### Optional Enhancements:

#### 1. Add API Key Authentication:

Update Edge Function to check for secret key:

```typescript
const authHeader = req.headers.get('authorization')
const expectedKey = Deno.env.get('PAYMENT_WEBHOOK_SECRET')

if (!authHeader || authHeader !== `Bearer ${expectedKey}`) {
  return new Response('Unauthorized', { status: 401 })
}
```

Then set secret in Supabase:
```bash
./supabase-cli/supabase secrets set PAYMENT_WEBHOOK_SECRET=your-random-secret-here --project-ref lmsuyhzcmgdpjynosxvp
```

#### 2. IP Whitelist:

If using a service with static IPs, check request IP:

```typescript
const clientIp = req.headers.get('x-forwarded-for')
const allowedIps = ['1.2.3.4', '5.6.7.8'] // Parser service IPs

if (!allowedIps.includes(clientIp)) {
  return new Response('Forbidden', { status: 403 })
}
```

---

## Cost Analysis

### Service Costs:

| Service | Free Tier | Paid Plan | Notes |
|---------|-----------|-----------|-------|
| **Zapier** | 100 tasks/month | $20/month | Easiest to set up |
| **Make.com** | 1,000 operations/month | $9/month | Best value |
| **Mailparser** | N/A | $29/month | Most reliable parsing |
| **SendGrid Inbound** | Free | Free | Requires domain setup |

### Supabase Costs:
- Edge Function invocations: Free tier = 500K/month
- Database operations: Included in free tier
- No additional cost for this feature

---

## Maintenance

### Monthly Tasks:
- [ ] Review `payment_notifications_log` for errors
- [ ] Verify email forwarding rules still active
- [ ] Check parser service subscription status

### Quarterly Tasks:
- [ ] Audit payment matching accuracy
- [ ] Review and clean old logs (optional)
- [ ] Update extraction regex if email format changes

---

## Support

### Files:
- Edge Function: `supabase/functions/process-payment-notification/index.ts`
- Database Functions: `database/payment-notification-functions.sql`
- This Guide: `database/PAYMENT-NOTIFICATION-SETUP.md`

### Testing URL:
```
https://lmsuyhzcmgdpjynosxvp.supabase.co/functions/v1/process-payment-notification
```

### Logs:
```bash
# View live logs
./supabase-cli/supabase functions logs process-payment-notification --project-ref lmsuyhzcmgdpjynosxvp --tail

# View recent logs
./supabase-cli/supabase functions logs process-payment-notification --project-ref lmsuyhzcmgdpjynosxvp --limit 50
```

---

## Next Steps

1. ✅ Deploy database functions
2. ✅ Deploy Edge Function
3. ⏳ Choose email parser service (Zapier/Make/Mailparser/SendGrid)
4. ⏳ Set up email parsing rules
5. ⏳ Configure email forwarding
6. ⏳ Test with real payment email
7. ⏳ Monitor for 1 week to verify reliability

---

## Alternative: PayPal IPN / Stripe Webhooks

If you're using PayPal or Stripe directly, you can skip the email parsing and use their native webhooks:

### PayPal IPN:
1. Go to PayPal Dashboard → Account Settings → Notifications
2. Set IPN URL to your Edge Function
3. Update Edge Function to handle PayPal's IPN format

### Stripe Webhooks:
1. Go to Stripe Dashboard → Developers → Webhooks
2. Add endpoint: Your Edge Function URL
3. Select events: `payment_intent.succeeded`
4. Update Edge Function to handle Stripe webhook format

**Note:** These require modifications to the Edge Function to handle their specific payload formats.
