# Account Creation & Welcome Email Setup

## Overview
When users check the "Make me an Alella Green Tech account" checkbox during checkout, a welcome email is automatically scheduled to be sent 7 days later. This email includes:
- Password setup link
- Personal QR code (digital wallet)
- Information about using leftover GREENS
- Links to future activities

## Database Setup

Run the following SQL script in your Supabase SQL editor:

```bash
psql -h <your-supabase-host> -U postgres -d postgres -f database/create-scheduled-welcome-emails-table.sql
```

Or manually run the SQL from: `database/create-scheduled-welcome-emails-table.sql`

This creates:
- `scheduled_welcome_emails` table
- Indexes for efficient querying
- RLS policies for security

## Deploy Edge Functions

### 1. Deploy the Welcome Email Scheduler

```bash
./supabase-cli/supabase functions deploy send-welcome-account-email --project-ref lmsuyhzcmgdpjynosxvp
```

This function is called when a user checks the account creation checkbox. It schedules the welcome email for 7 days later.

### 2. Deploy the Scheduled Email Sender

```bash
./supabase-cli/supabase functions deploy send-scheduled-welcome-emails --project-ref lmsuyhzcmgdpjynosxvp
```

This function processes all pending scheduled emails that are due to be sent.

## Set Up Cron Job

To automatically send scheduled emails, set up a cron job in Supabase:

1. Go to Supabase Dashboard → Database → Cron Jobs (or use pg_cron extension)
2. Create a new cron job with this configuration:

**Schedule:** Every day at 9:00 AM UTC
```
0 9 * * *
```

**Command:**
```sql
SELECT
  net.http_post(
    url := 'https://lmsuyhzcmgdpjynosxvp.supabase.co/functions/v1/send-scheduled-welcome-emails',
    headers := '{"Content-Type": "application/json", "Authorization": "Bearer YOUR_SERVICE_ROLE_KEY"}'::jsonb,
    body := '{}'::jsonb
  );
```

Replace `YOUR_SERVICE_ROLE_KEY` with your actual service role key from Supabase settings.

## Environment Variables

Make sure these environment variables are set in your Supabase project:

- `RESEND_API_KEY` - For sending emails via Resend
- `SUPABASE_URL` - Your Supabase project URL
- `SUPABASE_SERVICE_ROLE_KEY` - Service role key for database access

## Testing

### Test Scheduling a Welcome Email

```bash
curl -X POST https://lmsuyhzcmgdpjynosxvp.supabase.co/functions/v1/send-welcome-account-email \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -d '{
    "email": "test@example.com",
    "firstName": "John",
    "lastName": "Doe",
    "qrCodeData": "AGT-test@example.com-12345",
    "orderId": "12345"
  }'
```

### Test Sending Scheduled Emails

```bash
curl -X POST https://lmsuyhzcmgdpjynosxvp.supabase.co/functions/v1/send-scheduled-welcome-emails \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_SERVICE_ROLE_KEY"
```

### Check Scheduled Emails in Database

```sql
SELECT * FROM scheduled_welcome_emails
ORDER BY created_at DESC
LIMIT 10;
```

### Manually Trigger a Test Email (Update scheduled_for to now)

```sql
UPDATE scheduled_welcome_emails
SET scheduled_for = NOW() - INTERVAL '1 minute'
WHERE id = 'YOUR_SCHEDULED_EMAIL_ID';
```

Then call the send-scheduled-welcome-emails function to process it immediately.

## Password Setup Page

You'll need to create a password setup page at:
`/pages/auth/setup-password.html`

This page should:
1. Accept a token parameter from the URL
2. Allow users to set their password
3. Create their account in Supabase Auth
4. Link their QR code to their account

## Monitoring

Check email logs:
```sql
SELECT * FROM email_logs
WHERE email_type = 'welcome_account'
ORDER BY sent_at DESC
LIMIT 20;
```

Check failed scheduled emails:
```sql
SELECT * FROM scheduled_welcome_emails
WHERE status = 'failed'
ORDER BY created_at DESC;
```

## Troubleshooting

**Emails not being sent:**
1. Check that the cron job is running: Look at Supabase logs
2. Verify RESEND_API_KEY is set correctly
3. Check `scheduled_welcome_emails` table for status='failed'
4. Review Edge Function logs in Supabase Dashboard

**QR Code not displaying:**
- The QR code data format is: `AGT-{email}-{order_id}`
- Consider using a QR code library to generate actual QR images
- Current implementation passes the data string, you may want to generate an image

## Future Enhancements

- Generate actual QR code images using a library like `qrcode-generator`
- Add ability to resend welcome emails
- Add ability to cancel scheduled emails if needed
- Track when users complete password setup
- Send reminder if password not set after 6 days
