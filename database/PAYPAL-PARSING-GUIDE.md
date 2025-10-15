# PayPal Payment Notification Parsing Guide

This guide shows you exactly how to parse PayPal payment notifications from `servicio@paypal.es` with subject "Notification of payment received".

## Email Format

**From:** `PayPal <servicio@paypal.es>`
**Subject:** `Notification of payment received`

**Body contains:**
- Payment amount: `€86.00 EUR` (or other amounts)
- Customer email: `jamie@zigelbaum.com` (clickable link)
- Customer name: `Jamie Zigelbaum`
- Transaction ID: `3VN76117B87011620`

---

## Setup with Zapier (Recommended)

### Step 1: Create Email Parser Zap

1. **Go to Zapier** → Create New Zap

2. **Trigger: Email by Zapier**
   - Choose "New Inbound Email"
   - Zapier will give you an email like: `user@robot.zapier.com`
   - Copy this email address

3. **Set up Email Forwarding in Gmail:**
   - Gmail → Settings → Filters and Blocked Addresses
   - Create new filter:
     - **From:** `servicio@paypal.es`
     - **Subject:** `Notification of payment received`
   - Actions:
     - ✅ Forward to: `your-zapier-email@robot.zapier.com`
     - ✅ Mark as read (optional)
   - Create filter

4. **Test the Trigger**
   - Wait for next payment email OR
   - Forward an old payment email to test
   - Zapier should catch it

### Step 2: Add Formatter Steps

**Format Step 1: Extract Amount**
- Action: "Formatter by Zapier" → "Text" → "Extract Pattern"
- Input: `{{1. Body Plain}}` (the email body)
- Pattern: `€([\d,]+\.?\d*)\s*EUR`
- This extracts: `86.00` from `€86.00 EUR`

**Format Step 2: Extract Customer Email**
- Action: "Formatter by Zapier" → "Text" → "Extract Email"
- Input: `{{1. Body Plain}}`
- This extracts: `jamie@zigelbaum.com`

**Format Step 3: Extract Transaction ID**
- Action: "Formatter by Zapier" → "Text" → "Extract Pattern"
- Input: `{{1. Body Plain}}`
- Pattern: `Transaction ID[\s\S]*?([A-Z0-9]{17})`
- This extracts: `3VN76117B87011620`

### Step 3: Add Webhook POST

- Action: "Webhooks by Zapier" → "POST"
- URL: `https://lmsuyhzcmgdpjynosxvp.supabase.co/functions/v1/process-payment-notification`
- Payload Type: JSON
- Data:
  ```json
  {
    "customerEmail": "{{extracted_email}}",
    "amount": "{{extracted_amount}}",
    "transactionId": "{{extracted_transaction_id}}",
    "paymentMethod": "paypal",
    "from": "{{1. From}}",
    "subject": "{{1. Subject}}",
    "body": "{{1. Body Plain}}"
  }
  ```

### Step 4: Test End-to-End

1. Forward a test PayPal email to your Zapier email
2. Check Zapier dashboard - should show successful run
3. Check Supabase logs:
   ```bash
   ./supabase-cli/supabase functions logs process-payment-notification --project-ref lmsuyhzcmgdpjynosxvp --tail
   ```
4. Check your database:
   ```sql
   SELECT * FROM payment_notifications_log ORDER BY created_at DESC LIMIT 5;
   ```

---

## Setup with Make.com (Free Alternative)

### Step 1: Create Email Module

1. **Go to Make.com** → Create New Scenario

2. **Add Module: "Email" → "Watch emails"**
   - Connect your Gmail/email account
   - Folder: Inbox
   - Criteria:
     - From contains: `servicio@paypal.es`
     - Subject equals: `Notification of payment received`

### Step 2: Add Text Parser Modules

**Parser 1: Extract Amount**
- Module: "Text parser" → "Match pattern"
- Text: `{{1.text}}` (email body)
- Pattern: `€([\d,]+\.?\d*)\s*EUR`
- Global match: No
- Case sensitive: No
- Multiline: Yes
- Output: Save to variable `amount`

**Parser 2: Extract Email**
- Module: "Text parser" → "Match pattern"
- Text: `{{1.text}}`
- Pattern: `([a-zA-Z0-9._-]+@[a-zA-Z0-9._-]+\.[a-zA-Z0-9_-]+)`
- Output: Save to variable `customerEmail`

**Parser 3: Extract Transaction ID**
- Module: "Text parser" → "Match pattern"
- Text: `{{1.text}}`
- Pattern: `([A-Z0-9]{17})`
- Output: Save to variable `transactionId`

### Step 3: Add HTTP Module

- Module: "HTTP" → "Make a request"
- URL: `https://lmsuyhzcmgdpjynosxvp.supabase.co/functions/v1/process-payment-notification`
- Method: POST
- Body type: Raw
- Content type: JSON
- Request content:
  ```json
  {
    "customerEmail": "{{customerEmail}}",
    "amount": "{{amount}}",
    "transactionId": "{{transactionId}}",
    "paymentMethod": "paypal",
    "from": "{{1.from}}",
    "subject": "{{1.subject}}"
  }
  ```

### Step 4: Add Error Handler

- Right-click HTTP module → Add error handler
- Add "Email" module → "Send an Email"
- To: Your admin email
- Subject: `Payment webhook failed`
- Body: `{{error.message}}`

---

## Manual Curl Test

To test the webhook manually with PayPal format:

```bash
curl -X POST https://lmsuyhzcmgdpjynosxvp.supabase.co/functions/v1/process-payment-notification \
  -H "Content-Type: application/json" \
  -d '{
    "customerEmail": "jamie@zigelbaum.com",
    "amount": 86.00,
    "transactionId": "3VN76117B87011620",
    "paymentMethod": "paypal",
    "from": "servicio@paypal.es",
    "subject": "Notification of payment received"
  }'
```

Expected response:
```json
{
  "success": true,
  "order_id": "...",
  "order_number": "PP-20250115-001",
  "payment_status": "paid",
  "paid_at": "2025-01-15T10:22:00Z",
  "message": "Payment status updated successfully"
}
```

---

## Important Notes

### ⚠️ Customer Email Must Match

The PayPal email shows the **payer's email** (`jamie@zigelbaum.com`). This must match the email used during checkout. If customers use different emails for PayPal vs checkout, the system won't find their order.

**Solution Options:**

1. **Ask customers to use same email** (preferred)
   - Add note at checkout: "Please use the same email for PayPal payment"

2. **Include order number in PayPal notes**
   - When sending PayPal invoice, include order number
   - Parse it from "Instructions to merchant" field
   - Update webhook to prioritize order number

3. **Manual fallback**
   - If webhook fails to find order (404 error)
   - You'll see it in `payment_notifications_log`
   - Manually mark as paid in admin dashboard

### 📊 Monitoring

Check for failed notifications weekly:

```sql
-- Failed payment webhooks
SELECT
    created_at,
    customer_email,
    transaction_id,
    amount,
    error_message
FROM payment_notifications_log
WHERE status = 'failed'
AND created_at > NOW() - INTERVAL '7 days'
ORDER BY created_at DESC;
```

### 🔄 Testing Checklist

- [ ] Email forwarding rule created in Gmail
- [ ] Zapier/Make.com parsing correctly extracts:
  - [ ] Amount (without € symbol)
  - [ ] Customer email
  - [ ] Transaction ID
- [ ] Webhook successfully calls Edge Function
- [ ] Order marked as paid in database
- [ ] Admin notes show payment details
- [ ] No errors in Supabase logs

---

## Regex Patterns Reference

| Field | Regex Pattern | Example Match |
|-------|---------------|---------------|
| **Amount** | `€([\d,]+\.?\d*)\s*EUR` | `€86.00 EUR` → `86.00` |
| **Email** | `([a-zA-Z0-9._-]+@[a-zA-Z0-9._-]+\.[a-zA-Z0-9_-]+)` | `jamie@zigelbaum.com` |
| **Transaction ID** | `([A-Z0-9]{17})` | `3VN76117B87011620` |
| **Customer Name** | `from ([A-Z][a-z]+ [A-Z][a-z]+)` | `Jamie Zigelbaum` |

---

## Next Steps

1. ✅ Choose Zapier or Make.com
2. ⏳ Set up email forwarding from Gmail
3. ⏳ Configure parsing rules
4. ⏳ Test with old PayPal email
5. ⏳ Monitor for 1 week
6. ⏳ Review failed notifications log

---

## Alternative: PayPal IPN (Advanced)

If you want real-time notifications directly from PayPal (no email parsing):

1. **PayPal Dashboard** → Account Settings → Notifications
2. **Instant Payment Notification (IPN)**
3. **Notification URL:** `https://lmsuyhzcmgdpjynosxvp.supabase.co/functions/v1/process-payment-notification`
4. **Update Edge Function** to handle IPN format (different from email)

**Pros:** More reliable, real-time, no email parsing
**Cons:** Requires updating Edge Function code, IPN format is complex

For now, email parsing is simpler and works perfectly for your use case.
