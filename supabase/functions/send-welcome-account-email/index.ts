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
  qrCodeData: string
  orderId?: string
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    console.log('📧 Processing welcome account email...')

    const { email, firstName, lastName, qrCodeData, orderId }: WelcomeEmailRequest = await req.json()

    // Validate required data
    if (!email || !firstName || !lastName || !qrCodeData) {
      throw new Error('Missing required fields')
    }

    console.log(`📨 Scheduling welcome email for ${email}`)

    // Initialize Supabase client
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Schedule email for 1 week from now
    const scheduledDate = new Date()
    scheduledDate.setDate(scheduledDate.getDate() + 7)

    const { data, error } = await supabase
      .from('scheduled_welcome_emails')
      .insert({
        email,
        first_name: firstName,
        last_name: lastName,
        qr_code_data: qrCodeData,
        order_id: orderId,
        scheduled_for: scheduledDate.toISOString(),
        status: 'pending'
      })
      .select()
      .single()

    if (error) {
      console.error('❌ Database error:', error)
      throw new Error(`Database error: ${error.message}`)
    }

    console.log('✅ Welcome email scheduled successfully:', data.id)

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Welcome email scheduled successfully',
        scheduled_id: data.id,
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
