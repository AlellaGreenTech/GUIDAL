# Abandoned Booking Recovery System

## Overview

The abandoned booking recovery system tracks customers who start the checkout process but don't complete their booking. It automatically sends them a friendly recovery email with the message:

> **"The forces of evil must have interrupted you! If you'd like to finish your session on Alella Green Tech's GUIDAL app, click here"**

---

## How It Works

### 1. Tracking Abandonments

When a user enters their email and starts filling out the booking form:

1. **Automatic Tracking**: The system creates an `abandoned_booking` record in the database
2. **Updates on Activity**: As they fill in more fields or change quantities, the record is updated
3. **Debounced**: Updates happen 2 seconds after the last activity to avoid excessive database writes
4. **Session-Based**: Uses `sessionStorage` to track the same user across page refreshes

**What Gets Tracked:**
- Email address
- First name, last name, phone (if entered)
- Cart items (visits, tickets, pumpkins, SCARES)
- Cart total
- Timestamps (started, last activity)
- User agent and session ID

### 2. Completing a Booking

When the user successfully clicks "Proceed to Booking":

1. The `abandoned_booking` record is updated with `status: 'completed'`
2. The `completed_at` timestamp is set
3. The session storage is cleared
4. **No recovery email is sent** for completed bookings

### 3. Sending Recovery Emails

Recovery emails are sent via the Edge Function `send-abandoned-recovery`.

**Timing:**
- Only sent to bookings that are **24-72 hours old**
- Only sent if `recovery_email_sent_at` is `NULL` (one email per abandonment)
- Only sent if `status = 'abandoned'`

**Email Content:**
- Fun, themed message about "forces of evil" interrupting
- Shows what items they had in their cart
- Shows the total amount
- Big call-to-action button to return and complete booking
- Friendly tone - not pushy

---

## Database Schema

### Table: `abandoned_bookings`

```sql
CREATE TABLE abandoned_bookings (
    id UUID PRIMARY KEY,
    email TEXT NOT NULL,
    first_name TEXT,
    last_name TEXT,
    phone TEXT,
    cart_items JSONB,
    cart_total NUMERIC(10,2),
    page_url TEXT,

    -- Tracking
    started_at TIMESTAMP WITH TIME ZONE,
    last_activity_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    recovery_email_sent_at TIMESTAMP WITH TIME ZONE,
    recovery_email_opened_at TIMESTAMP WITH TIME ZONE,
    recovery_email_clicked_at TIMESTAMP WITH TIME ZONE,

    -- Status
    status TEXT CHECK (status IN ('abandoned', 'recovered', 'completed', 'ignored')),

    -- Metadata
    user_agent TEXT,
    session_id TEXT,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE
);
```

**Status Values:**
- `abandoned`: User left without completing (default)
- `completed`: User came back and completed their order
- `recovered`: User completed order after receiving recovery email
- `ignored`: User didn't respond to recovery email

---

## Setup Instructions

### 1. Create Database Table

Run the SQL script:

```bash
# In Supabase SQL Editor, run:
database/create-abandoned-bookings-table.sql
```

This will:
- Create the `abandoned_bookings` table
- Add indexes for performance
- Enable RLS with appropriate policies
- Grant permissions to `anon` and `authenticated` roles

### 2. Deploy Edge Function

```bash
./supabase-cli/supabase functions deploy send-abandoned-recovery --project-ref lmsuyhzcmgdpjynosxvp
```

### 3. Test the System

**Test abandoned tracking:**
1. Go to checkout page
2. Enter an email address
3. Fill in some fields
4. Close the browser tab
5. Check database:
   ```sql
   SELECT * FROM abandoned_bookings
   WHERE email = 'your-test@email.com'
   ORDER BY created_at DESC LIMIT 1;
   ```

**Test recovery email (manual trigger):**
```bash
curl -X POST \
  https://[your-project].supabase.co/functions/v1/send-abandoned-recovery \
  -H "Authorization: Bearer [your-anon-key]" \
  -H "Content-Type: application/json" \
  -d '{
    "abandonedBookingId": "uuid-from-database",
    "testMode": true
  }'
```

**Test completion tracking:**
1. Start a booking (creates abandoned record)
2. Complete the booking (click "Proceed to Booking")
3. Check database - status should be `completed`

---

## Sending Recovery Emails

### Manual Sending (Single Email)

To send a recovery email for a specific abandoned booking:

```bash
curl -X POST \
  https://[your-project].supabase.co/functions/v1/send-abandoned-recovery \
  -H "Authorization: Bearer [your-anon-key]" \
  -H "Content-Type: application/json" \
  -d '{
    "abandonedBookingId": "uuid-of-abandoned-booking"
  }'
```

### Batch Sending (All Eligible)

To send recovery emails to all eligible abandoned bookings (24-72 hours old, not yet contacted):

```bash
curl -X POST \
  https://[your-project].supabase.co/functions/v1/send-abandoned-recovery \
  -H "Authorization: Bearer [your-anon-key]" \
  -H "Content-Type: application/json" \
  -d '{}'
```

### Automated Sending (Recommended)

Set up a scheduled job using Supabase Cron or an external scheduler:

**Option 1: Supabase Cron (pg_cron)**

```sql
-- Run daily at 10:00 AM
SELECT cron.schedule(
  'send-abandoned-recovery-emails',
  '0 10 * * *', -- Every day at 10:00 AM
  $$
  SELECT net.http_post(
    url := 'https://[your-project].supabase.co/functions/v1/send-abandoned-recovery',
    headers := '{"Content-Type": "application/json", "Authorization": "Bearer [your-service-role-key]"}'::jsonb,
    body := '{}'::jsonb
  ) as request_id;
  $$
);
```

**Option 2: External Cron (cron-job.org, etc.)**

Set up a daily HTTP POST request to:
- URL: `https://[your-project].supabase.co/functions/v1/send-abandoned-recovery`
- Method: `POST`
- Headers: `Authorization: Bearer [your-service-role-key]`
- Body: `{}`
- Schedule: Daily at 10:00 AM

---

## Monitoring & Analytics

### Check Abandoned Bookings

```sql
-- Count by status
SELECT
  status,
  COUNT(*) as count,
  SUM(cart_total) as potential_revenue
FROM abandoned_bookings
WHERE started_at > NOW() - INTERVAL '7 days'
GROUP BY status;

-- Recent abandonments (last 24 hours)
SELECT
  email,
  first_name,
  last_name,
  cart_total,
  started_at,
  last_activity_at,
  status
FROM abandoned_bookings
WHERE started_at > NOW() - INTERVAL '24 hours'
  AND status = 'abandoned'
ORDER BY started_at DESC;

-- Recovery email effectiveness
SELECT
  COUNT(*) as emails_sent,
  COUNT(CASE WHEN status = 'recovered' THEN 1 END) as conversions,
  ROUND(
    COUNT(CASE WHEN status = 'recovered' THEN 1 END)::NUMERIC /
    NULLIF(COUNT(*), 0) * 100,
    2
  ) as conversion_rate,
  SUM(CASE WHEN status = 'recovered' THEN cart_total ELSE 0 END) as recovered_revenue
FROM abandoned_bookings
WHERE recovery_email_sent_at IS NOT NULL;
```

### Dashboard Queries

**Daily Recovery Stats:**
```sql
SELECT
  DATE(recovery_email_sent_at) as date,
  COUNT(*) as emails_sent,
  COUNT(CASE WHEN status = 'recovered' THEN 1 END) as recovered,
  SUM(CASE WHEN status = 'recovered' THEN cart_total ELSE 0 END) as revenue
FROM abandoned_bookings
WHERE recovery_email_sent_at > NOW() - INTERVAL '30 days'
GROUP BY DATE(recovery_email_sent_at)
ORDER BY date DESC;
```

**Top Abandonment Times:**
```sql
SELECT
  EXTRACT(HOUR FROM started_at) as hour_of_day,
  COUNT(*) as abandonment_count
FROM abandoned_bookings
WHERE started_at > NOW() - INTERVAL '30 days'
  AND status = 'abandoned'
GROUP BY hour_of_day
ORDER BY abandonment_count DESC;
```

---

## Privacy & GDPR Compliance

**Data Retention:**
- Abandoned booking records should be automatically deleted after 90 days
- Completed bookings can be linked to the main order record

**User Rights:**
- Users can request deletion of their abandoned booking data
- Recovery emails include an unsubscribe mechanism (future enhancement)

**Suggested Cleanup Job:**

```sql
-- Delete old abandoned bookings (90 days)
DELETE FROM abandoned_bookings
WHERE started_at < NOW() - INTERVAL '90 days'
  AND status IN ('abandoned', 'ignored');
```

---

## Troubleshooting

### Abandoned bookings not being created

**Check:**
1. RLS policies exist: `SELECT * FROM pg_policies WHERE tablename = 'abandoned_bookings';`
2. Permissions granted: `SELECT grantee, privilege_type FROM information_schema.role_table_grants WHERE table_name = 'abandoned_bookings';`
3. Browser console for errors (set `DEBUG_MODE = true`)

**Fix:**
```bash
# Re-run the setup script
psql $DATABASE_URL -f database/create-abandoned-bookings-table.sql
```

### Recovery emails not sending

**Check:**
1. Edge Function deployed: `./supabase-cli/supabase functions list`
2. Resend API key is correct in Edge Function
3. Check Edge Function logs for errors

**Test manually:**
```bash
# Test with a specific booking ID
curl -X POST \
  https://[your-project].supabase.co/functions/v1/send-abandoned-recovery \
  -H "Authorization: Bearer [your-anon-key]" \
  -H "Content-Type: application/json" \
  -d '{"abandonedBookingId": "your-uuid-here", "testMode": true}'
```

### Bookings not marked as completed

**Check:**
1. `markBookingCompleted()` is called after successful order creation
2. `abandonedBookingId` is stored in sessionStorage
3. No errors in browser console during checkout

**Manual fix:**
```sql
UPDATE abandoned_bookings
SET status = 'completed', completed_at = NOW()
WHERE email = 'customer@example.com'
  AND started_at > NOW() - INTERVAL '24 hours';
```

---

## Future Enhancements

### Phase 2 Features:

1. **Email Click Tracking**
   - Add tracking pixel to recovery emails
   - Update `recovery_email_opened_at` when opened
   - Use UTM parameters to track `recovery_email_clicked_at`

2. **A/B Testing**
   - Test different email subject lines
   - Test different timing (24h vs 48h vs 72h)
   - Test different messaging (funny vs serious)

3. **Multi-Touch Recovery**
   - Send second recovery email after 5 days if no response
   - Send SMS recovery message (if phone provided)
   - Show recovery banner on return visit

4. **Personalization**
   - Include customer's name in subject line
   - Show personalized product recommendations
   - Use customer's language preference

5. **Analytics Dashboard**
   - Create admin page to view abandonment stats
   - Show recovery email performance
   - Track ROI of recovery campaigns

---

## Email Template Customization

To customize the recovery email, edit:
`supabase/functions/send-abandoned-recovery/index.ts`

**Current message theme:** "Forces of evil interrupted you" with ghost emoji 👻

**To change:**
1. Edit `generateRecoveryEmail()` function
2. Modify HTML template and subject line
3. Redeploy Edge Function

**Best practices:**
- Keep tone friendly, not pushy
- Include visual cart summary
- Make CTA button prominent
- Provide easy way to continue
- Don't send more than 2 recovery emails per customer

---

## Summary

**Setup checklist:**
- [x] Create `abandoned_bookings` table
- [x] Enable RLS policies
- [x] Deploy `send-abandoned-recovery` Edge Function
- [x] Add tracking JavaScript to checkout page
- [ ] Set up automated daily sending (cron job)
- [ ] Test with real email
- [ ] Monitor recovery conversion rates

**Key metrics to track:**
- Abandonment rate
- Recovery email open rate
- Recovery conversion rate
- Revenue recovered

---

*Last Updated: 2025-10-11*
*Maintainer: GUIDAL Team*
