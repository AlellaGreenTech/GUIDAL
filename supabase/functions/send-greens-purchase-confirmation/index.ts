import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface PurchaseConfirmationRequest {
  transactionId: string
  guestEmail: string
  guestName: string
  amount: number
  description: string
  newBalance: number
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    console.log('📧 Processing GREENS purchase confirmation email...')

    const { transactionId, guestEmail, guestName, amount, description, newBalance }: PurchaseConfirmationRequest = await req.json()

    // Validate required data
    if (!transactionId || !guestEmail || !guestName) {
      throw new Error('Missing required fields')
    }

    console.log(`📨 Sending purchase confirmation to ${guestEmail}`)

    // Generate the email content
    const emailContent = generatePurchaseConfirmationEmail(guestName, amount, description, newBalance)

    // Send email using Resend
    const resendApiKey = Deno.env.get('RESEND_API_KEY')
    if (!resendApiKey) {
      throw new Error('RESEND_API_KEY environment variable not set')
    }

    const emailResponse = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${resendApiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        from: 'GUIDAL <noreply@guidal.org>',
        to: [guestEmail],
        subject: `Purchase Confirmation - ${description}`,
        html: emailContent,
        tags: [
          { name: 'category', value: 'greens_purchase' },
          { name: 'transaction_id', value: transactionId }
        ]
      }),
    })

    if (!emailResponse.ok) {
      const errorData = await emailResponse.text()
      console.error('❌ Resend API error:', errorData)
      throw new Error(`Email service error: ${emailResponse.status} ${emailResponse.statusText}`)
    }

    const emailResult = await emailResponse.json()
    console.log('✅ Email sent successfully:', emailResult.id)

    // Log the email send in the database
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    await supabase
      .from('email_logs')
      .insert({
        transaction_id: transactionId,
        recipient: guestEmail,
        email_type: 'greens_purchase_confirmation',
        email_id: emailResult.id,
        status: 'sent',
        sent_at: new Date().toISOString()
      })

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Purchase confirmation email sent successfully',
        email_id: emailResult.id
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    )

  } catch (error) {
    console.error('❌ Error sending purchase confirmation email:', error)

    return new Response(
      JSON.stringify({
        success: false,
        error: error.message || 'Failed to send purchase confirmation email'
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      }
    )
  }
})

function generatePurchaseConfirmationEmail(guestName: string, amount: number, description: string, newBalance: number): string {
  return `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>GUIDAL Purchase Confirmation</title>
</head>
<body style="margin: 0; padding: 0; font-family: Arial, sans-serif; line-height: 1.6; color: #333; background-color: #f4f4f4;">
  <div style="max-width: 600px; margin: 20px auto; background: #ffffff; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">

    <!-- Header -->
    <div style="background: linear-gradient(135deg, #28a745, #20c997); color: white; padding: 2rem; text-align: center;">
      <h1 style="margin: 0; font-size: 2rem;">🌱 GUIDAL</h1>
      <p style="margin: 0.5rem 0 0 0; opacity: 0.95; font-size: 1.1rem;">Purchase Confirmation</p>
    </div>

    <!-- Main Content -->
    <div style="padding: 2rem;">
      <h2 style="color: #28a745; margin-top: 0;">Thank you, ${guestName}!</h2>

      <p style="font-size: 1.1rem; margin-bottom: 1.5rem;">Your purchase has been confirmed.</p>

      <!-- Purchase Details -->
      <div style="background: #f8f9fa; border-left: 4px solid #28a745; padding: 1.5rem; border-radius: 4px; margin-bottom: 2rem;">
        <h3 style="margin: 0 0 1rem 0; color: #28a745;">📋 Purchase Details</h3>
        <table style="width: 100%; border-collapse: collapse;">
          <tr>
            <td style="padding: 0.5rem 0; color: #666;">Item:</td>
            <td style="padding: 0.5rem 0; font-weight: 600; text-align: right;">${description}</td>
          </tr>
          <tr>
            <td style="padding: 0.5rem 0; color: #666;">Amount:</td>
            <td style="padding: 0.5rem 0; font-weight: 600; text-align: right; color: #dc3545;">-${amount.toFixed(2)} GREENS</td>
          </tr>
          <tr style="border-top: 2px solid #dee2e6;">
            <td style="padding: 0.5rem 0; font-weight: 600;">Remaining Balance:</td>
            <td style="padding: 0.5rem 0; font-weight: 700; text-align: right; font-size: 1.2rem; color: #28a745;">${newBalance.toFixed(2)} GREENS</td>
          </tr>
        </table>
      </div>

      <!-- Top Up Button -->
      <div style="text-align: center; margin: 2rem 0;">
        <a href="https://guidal.org/greens/top-up" style="display: inline-block; background: #28a745; color: white; padding: 1rem 2.5rem; text-decoration: none; border-radius: 50px; font-weight: 600; font-size: 1.1rem; box-shadow: 0 4px 6px rgba(40, 167, 69, 0.3); transition: all 0.3s ease;">
          💰 Top up your GREENS credit
        </a>
      </div>

      <!-- Info Box -->
      <div style="background: #e7f3ff; border: 1px solid #b3d9ff; border-radius: 8px; padding: 1.5rem; margin-top: 2rem;">
        <h4 style="margin: 0 0 0.75rem 0; color: #004085;">ℹ️ About GREENS</h4>
        <p style="margin: 0; color: #004085; font-size: 0.95rem;">
          GREENS is our local currency at GUIDAL. Use your GREENS balance to purchase food, activities, and services at our farm.
          You can top up your balance anytime using the button above!
        </p>
      </div>

      <p style="margin-top: 2rem; color: #666; font-size: 0.95rem;">
        This is an automated confirmation of your purchase. No reply is needed.
      </p>
    </div>

    <!-- Footer -->
    <div style="background: #f8f9fa; padding: 1.5rem; text-align: center; border-top: 1px solid #dee2e6;">
      <p style="margin: 0 0 0.5rem 0; font-weight: 600; color: #28a745;">🌱 GUIDAL</p>
      <p style="margin: 0.25rem 0; color: #666; font-size: 0.9rem;">Growing Understanding In Diverse Agricultural Learning</p>
      <p style="margin: 0.5rem 0; color: #666; font-size: 0.9rem;">
        📧 <a href="mailto:info@guidal.org" style="color: #28a745; text-decoration: none;">info@guidal.org</a> |
        🌐 <a href="https://guidal.org" style="color: #28a745; text-decoration: none;">guidal.org</a>
      </p>

      <div style="margin-top: 1rem; padding-top: 1rem; border-top: 1px solid #dee2e6;">
        <p style="margin: 0; color: #999; font-size: 0.8rem;">
          Questions about your purchase? Contact us at
          <a href="mailto:info@guidal.org" style="color: #28a745;">info@guidal.org</a>
        </p>
      </div>
    </div>
  </div>
</body>
</html>
  `
}
