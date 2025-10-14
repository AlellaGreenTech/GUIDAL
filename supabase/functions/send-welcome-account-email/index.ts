import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface WelcomeEmailRequest {
  email: string
  firstName: string
  lastName: string
  phone?: string
  orderId?: string
  initialGreensBalance?: number
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    console.log('📧 Processing welcome account email...')

    const { email, firstName, lastName, phone, orderId, initialGreensBalance }: WelcomeEmailRequest = await req.json()

    // Validate required data
    if (!email || !firstName || !lastName) {
      throw new Error('Missing required fields')
    }

    console.log(`📨 Creating pending account for ${email}`)

    // Initialize Supabase client
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Generate unique QR code
    const { data: qrCodeData, error: qrCodeError } = await supabase
      .rpc('generate_unique_qr_code')

    if (qrCodeError) {
      console.error('❌ QR code generation error:', qrCodeError)
      throw new Error(`Failed to generate QR code: ${qrCodeError.message}`)
    }

    const qrCode = qrCodeData

    // Generate secure activation token
    const activationToken = crypto.randomUUID()

    // Token expires in 30 days
    const tokenExpiresAt = new Date()
    tokenExpiresAt.setDate(tokenExpiresAt.getDate() + 30)

    // Create pending account
    const { data: pendingAccount, error: pendingError } = await supabase
      .from('pending_accounts')
      .insert({
        email,
        first_name: firstName,
        last_name: lastName,
        phone: phone || null,
        qr_code: qrCode,
        initial_greens_balance: initialGreensBalance || 0,
        order_id: orderId,
        activation_token: activationToken,
        token_expires_at: tokenExpiresAt.toISOString()
      })
      .select()
      .single()

    if (pendingError) {
      console.error('❌ Pending account creation error:', pendingError)
      throw new Error(`Failed to create pending account: ${pendingError.message}`)
    }

    console.log('✅ Pending account created:', pendingAccount.id)

    // Schedule email for 1 week from now
    const scheduledDate = new Date()
    scheduledDate.setDate(scheduledDate.getDate() + 7)

    const { data: scheduledEmail, error: scheduleError } = await supabase
      .from('scheduled_welcome_emails')
      .insert({
        email,
        first_name: firstName,
        last_name: lastName,
        qr_code_data: qrCode,
        order_id: orderId,
        scheduled_for: scheduledDate.toISOString(),
        status: 'pending'
      })
      .select()
      .single()

    if (scheduleError) {
      console.error('❌ Email scheduling error:', scheduleError)
      throw new Error(`Failed to schedule email: ${scheduleError.message}`)
    }

    console.log('✅ Welcome email scheduled successfully:', scheduledEmail.id)

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Pending account created and welcome email scheduled',
        pending_account_id: pendingAccount.id,
        qr_code: qrCode,
        scheduled_for: scheduledDate.toISOString()
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    )

  } catch (error) {
    console.error('❌ Error scheduling welcome email:', error)

    return new Response(
      JSON.stringify({
        success: false,
        error: error.message || 'Failed to schedule welcome email'
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      }
    )
  }
})
