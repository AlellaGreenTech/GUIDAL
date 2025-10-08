// Supabase Edge Function to send pumpkin patch emails via Resend
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const RESEND_API_KEY = 're_9dedNj8P_6CT6FGZ7wftUah1bw4uDNvqV'
const FROM_EMAIL = 'noreply@guidal.org' // Change this to your verified domain

serve(async (req) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST',
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
      }
    })
  }

  try {
    const { orderId, templateType } = await req.json()

    if (!orderId || !templateType) {
      throw new Error('Missing orderId or templateType')
    }

    // Initialize Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: req.headers.get('Authorization')! },
        },
      }
    )

    // Get order details
    const { data: order, error: orderError } = await supabaseClient
      .from('pumpkin_patch_orders')
      .select('*, items:pumpkin_patch_order_items(*)')
      .eq('id', orderId)
      .single()

    if (orderError) throw orderError

    // Get email template
    const { data: template, error: templateError } = await supabaseClient
      .from('pumpkin_patch_email_templates')
      .select('*')
      .eq('template_type', templateType)
      .eq('is_active', true)
      .single()

    if (templateError) throw templateError

    // Generate QR code
    const scares = order.items.find((item: any) => item.item_name.includes('SCARE'))?.quantity || 0
    const partyDateFormatted = order.party_date
      ? new Date(order.party_date).toLocaleDateString('en-US', { month: 'short', day: 'numeric' })
      : 'Visit Pass'

    const qrData = `ORDER:${order.order_number}|NAME:${order.first_name} ${order.last_name}|ADULTS:${order.adult_count || 0}|CHILDREN:${order.child_count || 0}|EVENT:${partyDateFormatted}|SCARES:${scares}|TOTAL:€${order.total_amount}`
    const qrCodeUrl = `https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=${encodeURIComponent(qrData)}`

    // Format party date for email
    let partyDateForEmail = 'Visit Pass (any non-party day)'
    if (order.party_date) {
      const date = new Date(order.party_date)
      partyDateForEmail = date.toLocaleDateString('en-US', {
        month: 'long',
        day: 'numeric',
        year: 'numeric'
      })
    }

    // Format items list
    const itemsList = order.items.map((item: any) =>
      `${item.quantity}x ${item.item_name}`
    ).join('<br>')

    // Replace template variables
    const emailData: Record<string, any> = {
      '{{order_number}}': order.order_number,
      '{{first_name}}': order.first_name,
      '{{last_name}}': order.last_name,
      '{{email}}': order.email,
      '{{phone}}': order.phone || 'Not provided',
      '{{party_date}}': partyDateForEmail,
      '{{adult_count}}': order.adult_count || 0,
      '{{child_count}}': order.child_count || 0,
      '{{items}}': itemsList,
      '{{total_amount}}': order.total_amount.toFixed(2),
      '{{qr_code}}': qrCodeUrl
    }

    let emailBody = template.html_body
    let emailSubject = template.subject

    Object.entries(emailData).forEach(([key, value]) => {
      emailBody = emailBody.replaceAll(key, String(value))
      emailSubject = emailSubject.replaceAll(key, String(value))
    })

    // Send email via Resend
    const resendResponse = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${RESEND_API_KEY}`
      },
      body: JSON.stringify({
        from: FROM_EMAIL,
        to: [order.email],
        subject: emailSubject,
        html: emailBody
      })
    })

    const resendData = await resendResponse.json()

    if (!resendResponse.ok) {
      throw new Error(`Resend API error: ${JSON.stringify(resendData)}`)
    }

    // Log email to database
    const { error: logError } = await supabaseClient
      .from('pumpkin_patch_email_log')
      .insert({
        order_id: orderId,
        template_type: templateType,
        recipient_email: order.email,
        subject: emailSubject,
        status: 'sent',
        sent_at: new Date().toISOString(),
        resend_id: resendData.id
      })

    if (logError) {
      console.error('Failed to log email:', logError)
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Email sent successfully',
        resendId: resendData.id
      }),
      {
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
      }
    )

  } catch (error) {
    console.error('Error sending email:', error)

    return new Response(
      JSON.stringify({
        success: false,
        error: error.message
      }),
      {
        status: 400,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
      }
    )
  }
})
