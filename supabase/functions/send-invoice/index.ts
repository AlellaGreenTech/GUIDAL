import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface InvoiceEmailRequest {
  visitId: string
  recipient: string
  message: string
  invoiceData: {
    visit: any
    lineItems: any[]
    totals: {
      subtotal: number
      tax: number
      total: number
    }
  }
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    console.log('📧 Processing invoice email request...')

    const { visitId, recipient, message, invoiceData }: InvoiceEmailRequest = await req.json()

    // Validate required data
    if (!visitId || !recipient || !invoiceData) {
      throw new Error('Missing required fields: visitId, recipient, or invoiceData')
    }

    console.log(`📨 Sending invoice for visit ${visitId} to ${recipient}`)

    // Generate the email content
    const emailContent = generateInvoiceEmail(invoiceData, message)

    // Send email using Resend (recommended for Supabase Edge Functions)
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
        from: 'GUIDAL Invoices <onboarding@resend.dev>',
        to: [recipient],
        subject: `Invoice for Educational Visit - ${invoiceData.visit.school_name}`,
        html: emailContent,
        tags: [
          { name: 'category', value: 'invoice' },
          { name: 'visit_id', value: visitId }
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
        visit_id: visitId,
        recipient: recipient,
        email_type: 'invoice',
        email_id: emailResult.id,
        status: 'sent',
        sent_at: new Date().toISOString()
      })

    // Update visit status
    await supabase
      .from('visits')
      .update({
        invoice_status: 'sent',
        invoice_sent_at: new Date().toISOString(),
        invoice_sent_to: recipient
      })
      .eq('id', visitId)

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Invoice email sent successfully',
        email_id: emailResult.id
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    )

  } catch (error) {
    console.error('❌ Error sending invoice email:', error)

    return new Response(
      JSON.stringify({
        success: false,
        error: error.message || 'Failed to send invoice email'
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      }
    )
  }
})

function generateInvoiceEmail(invoiceData: any, customMessage: string): string {
  const { visit, lineItems, totals } = invoiceData

  const lineItemsHtml = lineItems.map(item => `
    <tr>
      <td style="padding: 8px; border-bottom: 1px solid #eee;">${item.description}</td>
      <td style="padding: 8px; border-bottom: 1px solid #eee; text-align: center;">${item.quantity}</td>
      <td style="padding: 8px; border-bottom: 1px solid #eee; text-align: right;">€${item.price.toFixed(2)}</td>
      <td style="padding: 8px; border-bottom: 1px solid #eee; text-align: right; font-weight: 600;">€${item.total.toFixed(2)}</td>
    </tr>
  `).join('')

  return `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>GUIDAL Invoice</title>
</head>
<body style="margin: 0; padding: 0; font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
  <div style="max-width: 600px; margin: 0 auto; background: #ffffff;">

    <!-- Header -->
    <div style="background: linear-gradient(135deg, #1565c0, #0d47a1); color: white; padding: 2rem; text-align: center;">
      <h1 style="margin: 0; font-size: 2.5rem;">🌱 GUIDAL</h1>
      <p style="margin: 0.5rem 0 0 0; opacity: 0.9;">Educational Visits & Sustainability Learning</p>
    </div>

    <!-- Invoice Details -->
    <div style="padding: 2rem;">
      <div style="background: #f8f9fa; padding: 1.5rem; border-radius: 8px; border-left: 4px solid #1565c0; margin-bottom: 2rem;">
        <h2 style="margin: 0 0 1rem 0; color: #1565c0;">📄 Invoice for Educational Visit</h2>
        <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 1rem;">
          <div>
            <p style="margin: 0.25rem 0;"><strong>🏫 School:</strong> ${visit.school_name}</p>
            <p style="margin: 0.25rem 0;"><strong>📧 Contact:</strong> ${visit.contact_email}</p>
            <p style="margin: 0.25rem 0;"><strong>📍 Location:</strong> ${visit.city || ''}, ${visit.country_of_origin || ''}</p>
          </div>
          <div>
            <p style="margin: 0.25rem 0;"><strong>📅 Visit Date:</strong> ${new Date(visit.preferred_date).toLocaleDateString()}</p>
            <p style="margin: 0.25rem 0;"><strong>👥 Students:</strong> ${visit.student_count}</p>
            <p style="margin: 0.25rem 0;"><strong>🎯 Visit Type:</strong> ${visit.visit_type?.replace('_', ' ') || 'Day Trip'}</p>
          </div>
        </div>
      </div>

      <!-- Custom Message -->
      ${customMessage ? `
      <div style="background: #e3f2fd; padding: 1.5rem; border-radius: 8px; margin-bottom: 2rem;">
        <h3 style="margin: 0 0 1rem 0; color: #1565c0;">💬 Message from GUIDAL</h3>
        <div style="white-space: pre-line;">${customMessage}</div>
      </div>
      ` : ''}

      <!-- Invoice Items -->
      <div style="margin-bottom: 2rem;">
        <h3 style="color: #1565c0; margin-bottom: 1rem;">📋 Invoice Details</h3>
        <table style="width: 100%; border-collapse: collapse; background: white; border: 1px solid #dee2e6; border-radius: 8px; overflow: hidden;">
          <thead>
            <tr style="background: #f8f9fa;">
              <th style="padding: 12px; text-align: left; font-weight: 600; color: #495057;">Description</th>
              <th style="padding: 12px; text-align: center; font-weight: 600; color: #495057;">Qty</th>
              <th style="padding: 12px; text-align: right; font-weight: 600; color: #495057;">Price</th>
              <th style="padding: 12px; text-align: right; font-weight: 600; color: #495057;">Total</th>
            </tr>
          </thead>
          <tbody>
            ${lineItemsHtml}
          </tbody>
        </table>
      </div>

      <!-- Totals -->
      <div style="background: #f8f9fa; padding: 1.5rem; border-radius: 8px; margin-bottom: 2rem;">
        <div style="display: flex; justify-content: space-between; margin-bottom: 0.5rem;">
          <span>Subtotal:</span>
          <span>€${totals.subtotal.toFixed(2)}</span>
        </div>
        <div style="display: flex; justify-content: space-between; margin-bottom: 0.5rem;">
          <span>Tax (21% VAT):</span>
          <span>€${totals.tax.toFixed(2)}</span>
        </div>
        <div style="display: flex; justify-content: space-between; font-size: 1.2rem; font-weight: 600; color: #1565c0; border-top: 2px solid #1565c0; padding-top: 0.5rem;">
          <span>Total:</span>
          <span>€${totals.total.toFixed(2)}</span>
        </div>
      </div>

      <!-- Call to Action -->
      <div style="text-align: center; margin: 2rem 0;">
        <div style="background: #28a745; color: white; padding: 1rem 2rem; border-radius: 8px; display: inline-block;">
          <h3 style="margin: 0 0 0.5rem 0;">🎉 We're Excited for Your Visit!</h3>
          <p style="margin: 0;">Please confirm your booking by replying to this email.</p>
        </div>
      </div>

      <!-- Payment Instructions -->
      <div style="background: #fff3cd; border: 1px solid #ffeaa7; border-radius: 8px; padding: 1.5rem; margin-bottom: 2rem;">
        <h4 style="margin: 0 0 1rem 0; color: #856404;">💳 Payment Information</h4>
        <p style="margin: 0.25rem 0;"><strong>Payment Method:</strong> Bank Transfer or Cash on Arrival</p>
        <p style="margin: 0.25rem 0;"><strong>Payment Due:</strong> Upon arrival or 7 days before visit</p>
        <p style="margin: 0.25rem 0;"><strong>Bank Details:</strong> Available upon request</p>
        <p style="margin: 1rem 0 0 0; font-style: italic;">Please reference your school name and visit date in payment details.</p>
      </div>
    </div>

    <!-- Footer -->
    <div style="background: #f8f9fa; padding: 1.5rem; text-align: center; border-top: 1px solid #dee2e6;">
      <p style="margin: 0 0 0.5rem 0; font-weight: 600; color: #1565c0;">🌱 GUIDAL - Growing Understanding In Diverse Agricultural Learning</p>
      <p style="margin: 0.25rem 0; color: #666; font-size: 0.9rem;">📧 info@guidal.com | 🌐 www.guidal.com</p>
      <p style="margin: 0.25rem 0; color: #666; font-size: 0.9rem;">📍 Sustainable Learning Center, Barcelona, Spain</p>

      <div style="margin-top: 1rem; padding-top: 1rem; border-top: 1px solid #dee2e6;">
        <p style="margin: 0; color: #999; font-size: 0.8rem;">
          This email was sent regarding your educational visit booking.
          If you have any questions, please reply to this email or contact us directly.
        </p>
      </div>
    </div>
  </div>
</body>
</html>
  `
}