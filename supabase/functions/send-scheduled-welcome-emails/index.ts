import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    console.log('🔄 Processing scheduled welcome emails...')

    // Initialize Supabase client
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Get all pending emails that are due to be sent
    const now = new Date().toISOString()
    const { data: pendingEmails, error: fetchError } = await supabase
      .from('scheduled_welcome_emails')
      .select('*')
      .eq('status', 'pending')
      .lte('scheduled_for', now)
      .limit(50) // Process up to 50 emails at a time

    if (fetchError) {
      throw new Error(`Failed to fetch pending emails: ${fetchError.message}`)
    }

    if (!pendingEmails || pendingEmails.length === 0) {
      console.log('✓ No pending emails to send')
      return new Response(
        JSON.stringify({ success: true, message: 'No pending emails', count: 0 }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
      )
    }

    console.log(`📧 Found ${pendingEmails.length} emails to send`)

    const resendApiKey = Deno.env.get('RESEND_API_KEY')
    if (!resendApiKey) {
      throw new Error('RESEND_API_KEY environment variable not set')
    }

    let successCount = 0
    let failCount = 0

    // Process each email
    for (const emailRecord of pendingEmails) {
      try {
        console.log(`📨 Sending welcome email to ${emailRecord.email}`)

        // Generate password reset link (this would be your actual password setup URL)
        const passwordSetupLink = `https://guidal.org/pages/auth/setup-password.html?token=${emailRecord.id}`

        const emailContent = generateWelcomeEmail(
          emailRecord.first_name,
          emailRecord.last_name,
          passwordSetupLink,
          emailRecord.qr_code_data
        )

        // Send email using Resend
        const emailResponse = await fetch('https://api.resend.com/emails', {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${resendApiKey}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            from: 'GUIDAL <noreply@guidal.org>',
            to: [emailRecord.email],
            subject: 'Welcome to Alella Green Tech! 🌱 Setup Your Account',
            html: emailContent,
            tags: [
              { name: 'category', value: 'welcome_account' },
              { name: 'scheduled_id', value: emailRecord.id }
            ]
          }),
        })

        if (!emailResponse.ok) {
          const errorData = await emailResponse.text()
          console.error('❌ Resend API error:', errorData)
          throw new Error(`Email service error: ${emailResponse.status}`)
        }

        const emailResult = await emailResponse.json()
        console.log('✅ Email sent:', emailResult.id)

        // Update status to sent
        await supabase
          .from('scheduled_welcome_emails')
          .update({
            status: 'sent',
            sent_at: new Date().toISOString()
          })
          .eq('id', emailRecord.id)

        // Log to email_logs
        await supabase
          .from('email_logs')
          .insert({
            recipient: emailRecord.email,
            email_type: 'welcome_account',
            email_id: emailResult.id,
            status: 'sent',
            sent_at: new Date().toISOString()
          })

        successCount++

      } catch (emailError) {
        console.error(`❌ Failed to send email to ${emailRecord.email}:`, emailError)

        // Update status to failed
        await supabase
          .from('scheduled_welcome_emails')
          .update({ status: 'failed' })
          .eq('id', emailRecord.id)

        failCount++
      }
    }

    console.log(`✅ Completed: ${successCount} sent, ${failCount} failed`)

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Scheduled emails processed',
        sent: successCount,
        failed: failCount
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    )

  } catch (error) {
    console.error('❌ Error processing scheduled emails:', error)

    return new Response(
      JSON.stringify({
        success: false,
        error: error.message || 'Failed to process scheduled emails'
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      }
    )
  }
})

function generateWelcomeEmail(firstName: string, lastName: string, passwordSetupLink: string, qrCodeData: string): string {
  return `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Welcome to Alella Green Tech</title>
</head>
<body style="margin: 0; padding: 0; font-family: Arial, sans-serif; line-height: 1.6; color: #333; background-color: #f4f4f4;">
  <div style="max-width: 600px; margin: 20px auto; background: #ffffff; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">

    <!-- Header -->
    <div style="background: linear-gradient(135deg, #28a745, #20c997); color: white; padding: 2rem; text-align: center;">
      <h1 style="margin: 0; font-size: 2rem;">🌱 Welcome to Alella Green Tech!</h1>
      <p style="margin: 0.5rem 0 0 0; opacity: 0.95; font-size: 1.1rem;">Your account is ready</p>
    </div>

    <!-- Main Content -->
    <div style="padding: 2rem;">
      <h2 style="color: #28a745; margin-top: 0;">Congratulations, ${firstName}!</h2>

      <p style="font-size: 1.1rem; margin-bottom: 1.5rem;">
        You've made an Alella Green Tech account for quick access to future farm and educational science-in-action activities.
      </p>

      <!-- Password Setup -->
      <div style="background: #fff3cd; border-left: 4px solid #ffc107; padding: 1.5rem; border-radius: 4px; margin-bottom: 2rem;">
        <h3 style="margin: 0 0 1rem 0; color: #856404;">🔐 Please Choose Your Password</h3>
        <p style="margin: 0 0 1rem 0; color: #856404;">
          To secure your account, please set up your password by clicking the button below:
        </p>
        <div style="text-align: center;">
          <a href="${passwordSetupLink}" style="display: inline-block; background: #ffc107; color: #000; padding: 1rem 2rem; text-decoration: none; border-radius: 6px; font-weight: 600; font-size: 1.1rem;">
            🔑 Set Up Password
          </a>
        </div>
        <p style="margin: 1rem 0 0 0; color: #856404; font-size: 0.9rem;">
          This link will expire in 7 days.
        </p>
      </div>

      <!-- QR Code -->
      <div style="background: #e7f3ff; border: 1px solid #b3d9ff; border-radius: 8px; padding: 1.5rem; margin-bottom: 2rem; text-align: center;">
        <h3 style="margin: 0 0 1rem 0; color: #004085;">📱 Your Personal QR Code</h3>
        <p style="margin: 0 0 1rem 0; color: #004085;">
          This is your digital wallet for AGT. Save this email or take a screenshot!
        </p>
        <div style="background: white; padding: 1rem; border-radius: 8px; display: inline-block;">
          <img src="${qrCodeData}" alt="Your QR Code" style="width: 200px; height: 200px; display: block;">
        </div>
        <p style="margin: 1rem 0 0 0; color: #004085; font-size: 0.9rem;">
          Show this QR code at the farm to access your GREENS balance and make purchases.
        </p>
      </div>

      <!-- GREENS Info -->
      <div style="background: #d4edda; border: 1px solid #c3e6cb; border-radius: 8px; padding: 1.5rem; margin-bottom: 2rem;">
        <h3 style="margin: 0 0 1rem 0; color: #155724;">💰 About Your GREENS</h3>
        <p style="margin: 0; color: #155724;">
          Any leftover GREENS from your recent order will remain in your account and can be used for:
        </p>
        <ul style="margin: 0.5rem 0; padding-left: 1.5rem; color: #155724;">
          <li>Food and drinks at the farm</li>
          <li>Future activities and events</li>
          <li>Educational workshops</li>
          <li>Science-in-action programs</li>
        </ul>
      </div>

      <p style="margin-top: 2rem; color: #666; font-size: 0.95rem;">
        We're excited to have you as part of the Alella Green Tech community!
      </p>
    </div>

    <!-- Footer -->
    <div style="background: #f8f9fa; padding: 1.5rem; text-align: center; border-top: 1px solid #dee2e6;">
      <p style="margin: 0 0 0.5rem 0; font-weight: 600; color: #28a745;">🌱 GUIDAL at Alella Green Tech</p>
      <p style="margin: 0.25rem 0; color: #666; font-size: 0.9rem;">Growing Understanding In Diverse Agricultural Learning</p>
      <p style="margin: 0.5rem 0; color: #666; font-size: 0.9rem;">
        📧 <a href="mailto:info@guidal.org" style="color: #28a745; text-decoration: none;">info@guidal.org</a> |
        🌐 <a href="https://guidal.org" style="color: #28a745; text-decoration: none;">guidal.org</a>
      </p>

      <div style="margin-top: 1rem; padding-top: 1rem; border-top: 1px solid #dee2e6;">
        <p style="margin: 0; color: #999; font-size: 0.8rem;">
          Questions? Contact us at <a href="mailto:info@guidal.org" style="color: #28a745;">info@guidal.org</a>
        </p>
      </div>
    </div>
  </div>
</body>
</html>
  `
}
