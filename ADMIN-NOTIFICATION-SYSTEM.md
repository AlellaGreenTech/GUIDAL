# Admin Notification System - Documentation

## Overview

The GUIDAL Admin Notification System provides automated email notifications to administrators when important events occur on the website. This includes order notifications, abandoned cart tracking, and daily analytics summaries.

## Features

### 1. Order Notifications
- **Order Created**: Notifies admins when a customer creates a new order
- **Order Paid**: Notifies admins when an order is marked as paid
- **Abandoned Orders**: Alerts admins when customers create orders but don't complete payment

### 2. Daily Analytics Summary
- Automatic daily digest of website activity
- Includes order statistics (total, paid, pending, revenue)
- Button click tracking and analytics
- Page view statistics
- Unique session counts
- Customizable send time for each admin

### 3. Analytics Tracking
- Automatic tracking of all button clicks
- Page view tracking
- Form submission tracking
- Custom event tracking API for specific actions

## Setup Instructions

### Step 1: Run Database Schema

Execute the SQL script to create the necessary database tables:

```bash
# Run the SQL script in Supabase SQL Editor:
database/create-admin-notification-system.sql
```

This creates three tables:
- `admin_notification_settings` - Stores admin preferences
- `admin_notification_log` - Logs all sent notifications
- `analytics_events` - Tracks user interactions

### Step 2: Deploy Edge Functions

The Edge Functions are already deployed:
- ✅ `send-admin-notification` - Sends individual notifications
- ✅ `send-daily-summary` - Sends daily analytics summaries

To redeploy if needed:
```bash
./supabase-cli/supabase functions deploy send-admin-notification --project-ref lmsuyhzcmgdpjynosxvp
./supabase-cli/supabase functions deploy send-daily-summary --project-ref lmsuyhzcmgdpjynosxvp
```

### Step 3: Configure Admin Recipients

1. Navigate to the admin panel: `https://guidal.org/admin/pumpkin-orders.html`
2. Click **"📧 Notification Settings"** button in the header
3. Click **"➕ Add Admin"** to add a new notification recipient
4. Configure preferences:
   - Enable/disable specific notification types
   - Set daily summary time (default: 09:00)
   - Activate/deactivate admin notifications

### Step 4: Set Up Daily Summary Cron Job

To automatically send daily summaries, set up a cron job in Supabase:

1. Go to Supabase Dashboard → Database → Cron Jobs
2. Create a new cron job with this SQL:

```sql
SELECT cron.schedule(
  'send-daily-summary',
  '0 9 * * *', -- Run at 9:00 AM every day
  $$ SELECT net.http_post(
    url:='https://lmsuyhzcmgdpjynosxvp.supabase.co/functions/v1/send-daily-summary',
    headers:='{"Content-Type": "application/json", "Authorization": "Bearer YOUR_SERVICE_ROLE_KEY"}'::jsonb,
    body:='{}'::jsonb
  ) $$
);
```

**Note**: Replace `YOUR_SERVICE_ROLE_KEY` with your Supabase service role key (found in Project Settings → API)

Alternatively, use an external cron service like cron-job.org or GitHub Actions to trigger the function daily.

## Usage

### Automatic Notifications

Notifications are triggered automatically when:

1. **Order Created** - When a customer completes the checkout form and clicks "Continue to Payment"
   - Notification includes order details, items, and customer information
   - Sent to all admins with `notify_on_order_created` enabled

2. **Order Paid** - When an admin marks an order as paid in the dashboard
   - Notification confirms payment received
   - Sent to all admins with `notify_on_order_paid` enabled

3. **Abandoned Order** - When detecting orders that were created but not paid
   - Currently manual trigger (can be automated with scheduled check)
   - Sent to all admins with `notify_on_abandoned_order` enabled

### Manual Triggers

You can manually trigger notifications from the admin panel:
- Each order has action buttons to resend notifications if needed

### Analytics Tracking

The analytics tracker automatically records:

#### Automatic Tracking (no code changes needed):
- All button clicks across the site
- All link clicks
- All form submissions
- Page views on every page load

#### Custom Tracking (via JavaScript API):

```javascript
// Track a custom event
window.GuidalAnalytics.track('event_type', 'category', 'label', 'value');

// Track a button click
window.GuidalAnalytics.trackButtonClick('Button Text', 'category');

// Track a booking
window.GuidalAnalytics.trackBooking('Activity Name');

// Track checkout steps
window.GuidalAnalytics.trackCheckout('Payment Initiated');

// Track payment method
window.GuidalAnalytics.trackPayment('PayPal');
```

To add analytics to any page, include the script:
```html
<script src="/js/analytics-tracker.js"></script>
```

## Email Templates

### Order Created Notification
- Subject: `🎃 New Pumpkin Patch Order #ORDER_NUMBER`
- Includes: Customer info, order items, total, payment status
- Call-to-action: Link to admin panel

### Order Paid Notification
- Subject: `💰 Payment Confirmed - Order #ORDER_NUMBER`
- Includes: Full order details and confirmation
- Call-to-action: Link to admin panel

### Abandoned Order Notification
- Subject: `⚠️ Abandoned Order Alert - #ORDER_NUMBER`
- Includes: Order details and follow-up suggestions
- Call-to-action: Link to admin panel

### Daily Summary
- Subject: `📊 Daily Summary - DATE - GUIDAL Pumpkin Patch`
- Includes:
  - Order statistics (total, paid, pending, revenue)
  - Website analytics (sessions, page views, button clicks)
  - Top button clicks breakdown
  - Top pages viewed
- Call-to-action: Link to full dashboard

## Database Schema

### admin_notification_settings
```sql
- id (UUID, primary key)
- admin_email (TEXT, unique)
- admin_name (TEXT)
- notify_on_order_created (BOOLEAN)
- notify_on_order_paid (BOOLEAN)
- notify_on_abandoned_order (BOOLEAN)
- notify_daily_summary (BOOLEAN)
- daily_summary_time (TIME)
- is_active (BOOLEAN)
- created_at (TIMESTAMP)
- updated_at (TIMESTAMP)
```

### admin_notification_log
```sql
- id (UUID, primary key)
- notification_type (TEXT)
- recipient_email (TEXT)
- subject (TEXT)
- order_id (UUID, foreign key, nullable)
- status (TEXT: 'pending', 'sent', 'failed')
- resend_id (TEXT)
- error_message (TEXT, nullable)
- sent_at (TIMESTAMP)
- created_at (TIMESTAMP)
```

### analytics_events
```sql
- id (UUID, primary key)
- event_type (TEXT: 'button_click', 'link_click', 'page_view', 'form_submit')
- event_category (TEXT)
- event_label (TEXT)
- event_value (TEXT, nullable)
- page_url (TEXT)
- user_session_id (TEXT)
- user_ip (TEXT, nullable)
- user_agent (TEXT, nullable)
- created_at (TIMESTAMP)
```

## API Reference

### Edge Function: send-admin-notification

**Endpoint**: `POST /functions/v1/send-admin-notification`

**Request Body**:
```json
{
  "orderId": "uuid",
  "notificationType": "order_created" | "order_paid" | "abandoned_order"
}
```

**Response**:
```json
{
  "success": true,
  "message": "Notifications sent: 2 successful, 0 failed",
  "results": [
    {
      "success": true,
      "admin": "admin@example.com",
      "resendId": "abc123"
    }
  ]
}
```

### Edge Function: send-daily-summary

**Endpoint**: `POST /functions/v1/send-daily-summary`

**Request Body**: `{}` (empty)

**Response**:
```json
{
  "success": true,
  "message": "Daily summaries sent: 2 successful, 0 failed",
  "results": [...],
  "analytics": {
    "orders": {
      "total": 5,
      "paid": 3,
      "pending": 2,
      "revenue": 125.50
    },
    "analytics": {
      "totalEvents": 243,
      "buttonClicks": 45,
      "clicksByButton": {...},
      "pageViews": 198,
      "viewsByPage": {...},
      "uniqueSessions": 32
    }
  }
}
```

## Troubleshooting

### Notifications Not Being Sent

1. **Check Admin Settings**:
   - Go to Notification Settings page
   - Verify admins are marked as "Active"
   - Verify the correct notification types are enabled

2. **Check Edge Function Logs**:
   - Go to Supabase Dashboard → Edge Functions
   - Click on the function (send-admin-notification or send-daily-summary)
   - View logs for errors

3. **Check Notification Log**:
   ```sql
   SELECT * FROM admin_notification_log
   ORDER BY created_at DESC
   LIMIT 20;
   ```

4. **Verify Resend API Key**:
   - Check that the Resend API key is correct in the Edge Functions
   - Current key: `re_9dedNj8P_6CT6FGZ7wftUah1bw4uDNvqV`
   - Verify domain verification in Resend dashboard

### Analytics Not Tracking

1. **Verify Script Loaded**:
   - Open browser console
   - Type `window.GuidalAnalytics` - should return an object
   - Check for JavaScript errors

2. **Check Database Permissions**:
   ```sql
   -- Verify RLS policies allow anonymous inserts
   SELECT * FROM analytics_events LIMIT 1;
   ```

3. **Check Network Requests**:
   - Open browser DevTools → Network tab
   - Look for POST requests to `/rest/v1/analytics_events`
   - Check for 401 or 403 errors

### Daily Summary Not Sending

1. **Verify Cron Job**:
   - Check if cron job is scheduled in Supabase
   - Verify it's enabled and running

2. **Test Manually**:
   ```bash
   curl -X POST \
     https://lmsuyhzcmgdpjynosxvp.supabase.co/functions/v1/send-daily-summary \
     -H "Authorization: Bearer YOUR_SERVICE_ROLE_KEY" \
     -H "Content-Type: application/json" \
     -d '{}'
   ```

3. **Check Admin Preferences**:
   - Verify at least one admin has `notify_daily_summary` enabled
   - Check `daily_summary_time` is set correctly

## File Structure

```
GUIDAL/
├── admin/
│   ├── pumpkin-orders.html (updated with notification link + triggers)
│   └── notification-settings.html (NEW - admin settings UI)
├── database/
│   └── create-admin-notification-system.sql (NEW - schema)
├── events/
│   └── pumpkin-patch-checkout.html (updated with notification triggers)
├── js/
│   └── analytics-tracker.js (NEW - analytics tracking)
├── supabase/
│   ├── config.toml (updated with new functions)
│   └── functions/
│       ├── send-admin-notification/
│       │   └── index.ts (NEW - order notifications)
│       └── send-daily-summary/
│           └── index.ts (NEW - daily summaries)
└── ADMIN-NOTIFICATION-SYSTEM.md (this file)
```

## Security & Privacy

- All notification settings require admin authentication
- Analytics events are anonymous (no PII stored)
- Session IDs are randomly generated and stored in sessionStorage
- IP addresses are NOT currently logged (can be enabled if needed)
- Email sending uses secure Resend API
- All database operations use Row Level Security (RLS)

## Future Enhancements

Potential features to add:
1. ✅ Real-time notification delivery tracking
2. ⏳ Slack/Discord webhook integration
3. ⏳ SMS notifications via Twilio
4. ⏳ Abandoned cart auto-recovery emails
5. ⏳ Weekly/monthly summary reports
6. ⏳ Custom notification templates per admin
7. ⏳ A/B testing for email subject lines
8. ⏳ Dashboard widget showing recent notifications

## Support

For questions or issues:
1. Check the troubleshooting section above
2. Review Edge Function logs in Supabase Dashboard
3. Check the `admin_notification_log` table for delivery status
4. Contact the development team

---

**Last Updated**: 2025-10-09
**Version**: 1.0.0
