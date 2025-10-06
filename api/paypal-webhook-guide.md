# PayPal Webhook Integration Guide

This guide explains how to set up PayPal webhooks to automatically mark orders as paid.

## Overview

When a customer pays via PayPal, PayPal can send a webhook notification to your server to update the order status automatically.

## Setup Steps

### 1. Create a Supabase Edge Function

Supabase Edge Functions can receive webhook notifications from PayPal.

```bash
# In your Supabase project directory
supabase functions new paypal-webhook
```

### 2. Edge Function Code

Create `/supabase/functions/paypal-webhook/index.ts`:

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  try {
    // Get PayPal webhook event
    const paypalEvent = await req.json()

    console.log('PayPal webhook received:', paypalEvent.event_type)

    // Verify this is a payment completion
    if (paypalEvent.event_type === 'PAYMENT.CAPTURE.COMPLETED') {
      // Extract order details from custom_id or other fields
      const orderNumber = paypalEvent.resource.custom_id

      if (!orderNumber) {
        return new Response(JSON.stringify({ error: 'No order number found' }), {
          status: 400,
          headers: { 'Content-Type': 'application/json' }
        })
      }

      // Initialize Supabase client
      const supabaseClient = createClient(
        Deno.env.get('SUPABASE_URL') ?? '',
        Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
      )

      // Update order status
      const { error } = await supabaseClient
        .from('pumpkin_patch_orders')
        .update({
          payment_status: 'paid',
          payment_method: 'paypal',
          paid_at: new Date().toISOString()
        })
        .eq('order_number', orderNumber)

      if (error) {
        console.error('Error updating order:', error)
        return new Response(JSON.stringify({ error: error.message }), {
          status: 500,
          headers: { 'Content-Type': 'application/json' }
        })
      }

      // TODO: Send payment confirmation email

      return new Response(JSON.stringify({ success: true }), {
        headers: { 'Content-Type': 'application/json' }
      })
    }

    // Acknowledge other events
    return new Response(JSON.stringify({ received: true }), {
      headers: { 'Content-Type': 'application/json' }
    })

  } catch (error) {
    console.error('Webhook error:', error)
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    })
  }
})
```

### 3. Deploy the Edge Function

```bash
supabase functions deploy paypal-webhook
```

### 4. Get the Webhook URL

Your webhook URL will be:
```
https://[YOUR-PROJECT-ID].supabase.co/functions/v1/paypal-webhook
```

### 5. Configure PayPal Webhook

1. Go to [PayPal Developer Dashboard](https://developer.paypal.com/dashboard/)
2. Go to **Apps & Credentials**
3. Select your app
4. Click **Add Webhook**
5. Enter your webhook URL
6. Select these events:
   - `PAYMENT.CAPTURE.COMPLETED`
   - `PAYMENT.CAPTURE.DENIED`
   - `PAYMENT.CAPTURE.REFUNDED`
7. Save

### 6. Update PayPal Payment Link

Update the PayPal button to include the order number:

```javascript
// In the checkout page, update the PayPal link
const paypalLink = `https://www.paypal.com/ncp/payment/YOUR_PAYMENT_ID?custom_id=${orderNumber}`;
```

## Alternative: Manual Payment Tracking

If you don't want to set up webhooks immediately, you can:

1. **Use the Admin Dashboard** - Manually mark orders as paid
2. **Customer Notification** - Ask customers to send payment confirmation
3. **Regular Checks** - Check PayPal transactions daily and update orders

## Testing

### Test Mode
1. Use PayPal Sandbox for testing
2. Create test buyer and seller accounts
3. Test the full payment flow

### Verify Webhook
```bash
# Check if webhook is receiving events
supabase functions logs paypal-webhook
```

## Security Considerations

1. **Verify Webhook Signature** - Validate that webhooks are actually from PayPal
2. **Use HTTPS** - Always use secure connections
3. **Rate Limiting** - Implement rate limiting on the webhook endpoint
4. **Idempotency** - Handle duplicate webhook notifications

## Example: Adding Order Number to PayPal

In `/events/pumpkin-patch-checkout.html`, update the PayPal button:

```javascript
// After order is created
const orderNumber = order.order_number;
const paypalUrl = `https://www.paypal.com/ncp/payment/4T2B69VFPFHH8?custom_id=${orderNumber}&amount=${total}`;

document.getElementById('payButton').href = paypalUrl;
```

## Troubleshooting

### Webhook not receiving events
- Check the webhook URL is correct
- Verify Edge Function is deployed
- Check Supabase function logs

### Orders not updating
- Check database permissions
- Verify order_number matches
- Check Edge Function logs for errors

### PayPal not sending webhooks
- Verify webhook is active in PayPal dashboard
- Check webhook event types are selected
- Test with PayPal webhook simulator
