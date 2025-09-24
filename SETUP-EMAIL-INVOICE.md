# 📧 Email Invoice Setup Guide

This guide walks you through setting up the email functionality for invoice sending using Supabase Edge Functions and Resend.

## 🚀 Quick Start

### Step 1: Set up Resend Account (Email Service)

1. **Sign up at [resend.com](https://resend.com)**
   - Free tier: 3,000 emails/month
   - Professional email delivery
   - Great for Supabase Edge Functions

2. **Get your API key**
   - Go to API Keys section
   - Create a new API key
   - Copy the key (starts with `re_`)

3. **Add your domain (optional but recommended)**
   - Go to Domains section
   - Add `guidal.com` or your domain
   - Verify with DNS records

### Step 2: Deploy Supabase Edge Function

1. **Install Supabase CLI** (if not already installed):
```bash
npm install -g supabase
```

2. **Login to Supabase**:
```bash
supabase login
```

3. **Deploy the email function**:
```bash
cd /Users/martinpicard/Websites/GUIDAL
supabase functions deploy send-invoice
```

4. **Set environment variables in Supabase**:
```bash
# Set the Resend API key
supabase secrets set RESEND_API_KEY=re_your_api_key_here
```

### Step 3: Set up Database

Run this SQL in your Supabase SQL Editor:

```sql
-- Create email logs table
CREATE TABLE IF NOT EXISTS email_logs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    visit_id UUID REFERENCES visits(id) ON DELETE CASCADE,
    recipient TEXT NOT NULL,
    email_type TEXT NOT NULL DEFAULT 'invoice',
    email_id TEXT,
    subject TEXT,
    status TEXT NOT NULL DEFAULT 'sent',
    sent_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    delivered_at TIMESTAMP WITH TIME ZONE,
    opened_at TIMESTAMP WITH TIME ZONE,
    clicked_at TIMESTAMP WITH TIME ZONE,
    user_agent TEXT,
    ip_address INET,
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_email_logs_visit_id ON email_logs(visit_id);
CREATE INDEX IF NOT EXISTS idx_email_logs_recipient ON email_logs(recipient);
CREATE INDEX IF NOT EXISTS idx_email_logs_email_type ON email_logs(email_type);

-- Enable RLS
ALTER TABLE email_logs ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Authenticated users can view email logs" ON email_logs
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Service role can manage email logs" ON email_logs
    FOR ALL USING (auth.role() = 'service_role');

-- Grant permissions
GRANT SELECT ON email_logs TO authenticated;
GRANT ALL ON email_logs TO service_role;
```

### Step 4: Update visits table (if needed)

Add email tracking fields to your visits table:

```sql
ALTER TABLE visits ADD COLUMN IF NOT EXISTS invoice_sent_to TEXT;
ALTER TABLE visits ADD COLUMN IF NOT EXISTS invoice_sent_at TIMESTAMP WITH TIME ZONE;
```

## 🎯 How It Works

### 1. **User clicks "📤 Send Invoice"**
   - Enhanced invoice page opens in new tab
   - Form pre-populated with visit data
   - User can edit line items and add custom message

### 2. **Email is sent via Supabase Edge Function**
   - Function calls Resend API
   - Professional HTML email with invoice details
   - Logs email in database

### 3. **Visit status is updated**
   - `invoice_status` → 'sent'
   - `invoice_sent_at` → current timestamp
   - `invoice_sent_to` → recipient email

## 📧 Email Features

### ✅ Professional Email Template
- **GUIDAL branding** with colors and logo
- **Invoice details table** with line items
- **Custom message** from user
- **Payment instructions**
- **Mobile-responsive** design

### ✅ Tracking & Analytics
- **Email delivery status** (sent, delivered, bounced)
- **Open and click tracking** (via Resend)
- **Email logs** stored in database
- **Analytics view** for reporting

### ✅ Error Handling
- **Validation** for email addresses
- **Retry functionality** if sending fails
- **Detailed error messages**
- **Fallback options**

## 🔧 Configuration Options

### Customize Email Template

Edit the `generateInvoiceEmail()` function in `/supabase/functions/send-invoice/index.ts`:

```typescript
// Add your custom branding
const headerColor = '#1565c0'  // Your brand color
const logoUrl = 'https://your-domain.com/logo.png'  // Your logo

// Customize email content
const footerText = 'Your custom footer text'
const contactInfo = 'your-email@guidal.com'
```

### Email Service Alternatives

Instead of Resend, you can use:

- **SendGrid**: More features, higher cost
- **Mailgun**: Good for high volume
- **Amazon SES**: Cheapest for high volume
- **SMTP**: Use your own email server

Just update the API call in the Edge Function.

## 🧪 Testing

### Test Email Sending

1. **Open enhanced invoice**: Click "💰 Invoice" on any visit
2. **Add test recipient**: Use your email address
3. **Send test invoice**: Click "📤 Send Invoice"
4. **Check email logs**: Query `email_logs` table

### Debug Issues

Check Supabase Edge Function logs:
```bash
supabase functions logs send-invoice
```

Common issues:
- ❌ **Invalid API key**: Check `RESEND_API_KEY` secret
- ❌ **Domain not verified**: Add DNS records for your domain
- ❌ **RLS policies**: Ensure proper database permissions

## 📊 Analytics & Monitoring

### Email Performance Dashboard

Create a simple analytics view:

```sql
-- Email stats by day
SELECT
    DATE(sent_at) as date,
    COUNT(*) as total_sent,
    COUNT(CASE WHEN status = 'delivered' THEN 1 END) as delivered,
    COUNT(CASE WHEN opened_at IS NOT NULL THEN 1 END) as opened
FROM email_logs
WHERE email_type = 'invoice'
GROUP BY DATE(sent_at)
ORDER BY date DESC;
```

### Monitor Bounce Rates

```sql
-- Check for bounced emails
SELECT recipient, error_message, sent_at
FROM email_logs
WHERE status = 'bounced'
ORDER BY sent_at DESC;
```

## 🎉 Next Steps

1. **Test the system** with a few real invoices
2. **Monitor email delivery** rates and opens
3. **Customize email template** with your branding
4. **Add more email types** (confirmations, reminders)
5. **Set up webhooks** from Resend for delivery tracking

## 💡 Pro Tips

- **Use your own domain** for better deliverability
- **Keep subject lines short** and descriptive
- **Test emails** across different clients (Gmail, Outlook)
- **Monitor bounce rates** and clean invalid emails
- **A/B test** different email templates

## 🆘 Support

If you need help:

1. **Check Supabase logs**: `supabase functions logs send-invoice`
2. **Verify database**: Check `email_logs` table for errors
3. **Test Resend API**: Use their dashboard to send test emails
4. **Contact support**: Both Supabase and Resend have great support

---

**🌱 GUIDAL Email System - Professional, Reliable, Scalable!**