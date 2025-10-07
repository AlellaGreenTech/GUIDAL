# Email Integration Guide

## Overview

The pumpkin patch order system now includes:
- **Email template management** (CRUD interface at `/admin/email-templates.html`)
- **Automatic confirmation emails** when orders are marked as paid
- **Email logging** to track all sent emails

Currently, emails are **logged to the database** but not actually sent. To send real emails, you need to integrate with an email service.

## Database Setup

First, run the SQL script to create the necessary tables:

```bash
psql -h your-db-host -U your-user -d your-database -f database/create-email-templates.sql
```

This creates:
- `pumpkin_patch_email_templates` - Template storage
- `pumpkin_patch_email_log` - Email tracking
- Two default templates (Entrance Ticket & Visit Pass)

## Email Templates

### Template Types

1. **Entrance Ticket** (`entrance_ticket`)
   - For orders containing Adult/Child tickets
   - Used for October 25th & November 1st party days

2. **Visit Pass** (`visit_pass`)
   - For orders containing visit passes
   - Used for non-party-day visits

### Template Variables

Available variables in templates:
- `{{order_number}}` - Order number (e.g., PUMP-2025-001)
- `{{first_name}}` - Customer first name
- `{{last_name}}` - Customer last name
- `{{email}}` - Customer email
- `{{phone}}` - Customer phone number
- `{{adult_count}}` - Number of adult tickets
- `{{child_count}}` - Number of child tickets
- `{{total_amount}}` - Total order amount

### Managing Templates

1. Go to **Admin Dashboard** → **Email Templates**
2. Create, edit, or delete templates
3. Preview templates with sample data
4. Set templates as active/inactive
5. Only one active template per type is used

## Email Service Integration

### Option 1: Resend (Recommended)

Resend is a modern email API with excellent deliverability.

1. **Sign up at [resend.com](https://resend.com)**

2. **Get API key** from dashboard

3. **Add Resend to your project:**

```javascript
// In admin/pumpkin-orders.html, replace the TODO section:

async function sendActualEmail(to, subject, htmlBody) {
    const response = await fetch('https://api.resend.com/emails', {
        method: 'POST',
        headers: {
            'Authorization': `Bearer ${YOUR_RESEND_API_KEY}`,
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            from: 'GUIDAL <noreply@guidal.be>',
            to: [to],
            subject: subject,
            html: htmlBody
        })
    });

    if (!response.ok) {
        throw new Error('Failed to send email');
    }

    return await response.json();
}

// Then call it in sendConfirmationEmail():
await sendActualEmail(order.email, emailSubject, emailBody);
```

### Option 2: SendGrid

1. **Sign up at [sendgrid.com](https://sendgrid.com)**

2. **Get API key**

3. **Integration:**

```javascript
async function sendActualEmail(to, subject, htmlBody) {
    const response = await fetch('https://api.sendgrid.com/v3/mail/send', {
        method: 'POST',
        headers: {
            'Authorization': `Bearer ${YOUR_SENDGRID_API_KEY}`,
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            personalizations: [{
                to: [{ email: to }]
            }],
            from: { email: 'noreply@guidal.be', name: 'GUIDAL' },
            subject: subject,
            content: [{
                type: 'text/html',
                value: htmlBody
            }]
        })
    });

    if (!response.ok) {
        throw new Error('Failed to send email');
    }

    return await response.json();
}
```

### Option 3: Supabase Edge Function

For better security (API keys not exposed in frontend):

1. **Create Edge Function:**

```bash
supabase functions new send-confirmation-email
```

2. **Function code:**

```typescript
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

serve(async (req) => {
  const { to, subject, html } = await req.json()

  const res = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${Deno.env.get('RESEND_API_KEY')}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      from: 'GUIDAL <noreply@guidal.be>',
      to: [to],
      subject: subject,
      html: html,
    }),
  })

  const data = await res.json()
  return new Response(JSON.stringify(data), {
    headers: { 'Content-Type': 'application/json' },
  })
})
```

3. **Deploy:**

```bash
supabase functions deploy send-confirmation-email --no-verify-jwt
supabase secrets set RESEND_API_KEY=your_api_key_here
```

4. **Call from frontend:**

```javascript
async function sendActualEmail(to, subject, htmlBody) {
    const response = await fetch(
        'https://your-project.supabase.co/functions/v1/send-confirmation-email',
        {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ to, subject, html: htmlBody })
        }
    );

    if (!response.ok) {
        throw new Error('Failed to send email');
    }

    return await response.json();
}
```

## Current Workflow

1. Customer places order on `/events/pumpkin-patch-checkout.html`
2. Order is created with `payment_status: 'pending'`
3. Admin views order in `/admin/pumpkin-orders.html`
4. Admin marks order as "Paid"
5. System automatically:
   - Updates `payment_status` to 'paid'
   - Determines template type (entrance_ticket or visit_pass)
   - Fetches active template for that type
   - Replaces variables with order data
   - Logs email to `pumpkin_patch_email_log`
   - **(TODO)** Sends actual email via API

## Testing

1. **Create test templates** in Email Templates page
2. **Preview templates** with sample data
3. **Place test order** on checkout page
4. **Mark as paid** and check console logs
5. **Verify email log** in database:

```sql
SELECT * FROM pumpkin_patch_email_log ORDER BY sent_at DESC;
```

## Email Deliverability Tips

1. **Verify your domain** with your email provider
2. **Set up SPF, DKIM, and DMARC** records
3. **Use a dedicated sending domain** (e.g., mail.guidal.be)
4. **Monitor bounce rates** and unsubscribes
5. **Test emails** with Mail Tester or similar tools

## Troubleshooting

**No template found:**
- Ensure at least one template is marked as "Active"
- Check template type matches order items

**Email not sending:**
- Check browser console for errors
- Verify API key is correct
- Check email service dashboard for errors

**Variables not replaced:**
- Ensure variables use exact format: `{{variable_name}}`
- Check spelling matches available variables

## Future Enhancements

- [ ] Automatic email on order creation (pending payment reminder)
- [ ] Email when payment fails/is cancelled
- [ ] Bulk email resend functionality
- [ ] Email open tracking
- [ ] Click tracking for links in emails
- [ ] Attachment support (PDF tickets)
- [ ] Multi-language templates
