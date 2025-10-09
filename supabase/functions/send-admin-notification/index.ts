import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const RESEND_API_KEY = 're_9dedNj8P_6CT6FGZ7wftUah1bw4uDNvqV'
const FROM_EMAIL = 'noreply@guidal.org'

serve(async (req) => {
  // Handle CORS preflight
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
    const { orderId, notificationType } = await req.json()

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
      .select(`
        *,
        items:pumpkin_patch_order_items(*)
      `)
      .eq('id', orderId)
      .single()

    if (orderError || !order) {
      throw new Error('Order not found: ' + orderError?.message)
    }

    // Get active admin notification settings based on notification type
    const settingColumn = getNotificationSettingColumn(notificationType)
    const { data: admins, error: adminsError } = await supabaseClient
      .from('admin_notification_settings')
      .select('*')
      .eq('is_active', true)
      .eq(settingColumn, true)

    if (adminsError) {
      throw new Error('Error fetching admins: ' + adminsError.message)
    }

    if (!admins || admins.length === 0) {
      return new Response(
        JSON.stringify({
          success: true,
          message: 'No active admins configured for this notification type'
        }),
        {
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
          }
        }
      )
    }

    // Generate email content based on notification type
    const { subject, htmlBody } = generateNotificationEmail(order, notificationType)

    // Send emails to all configured admins
    const emailPromises = admins.map(async (admin) => {
      try {
        // Send via Resend
        const resendResponse = await fetch('https://api.resend.com/emails', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${RESEND_API_KEY}`
          },
          body: JSON.stringify({
            from: FROM_EMAIL,
            to: [admin.admin_email],
            subject: subject,
            html: htmlBody
          })
        })

        const resendData = await resendResponse.json()

        if (!resendResponse.ok) {
          throw new Error(`Resend API error: ${resendData.message || 'Unknown error'}`)
        }

        // Log notification to database
        await supabaseClient
          .from('admin_notification_log')
          .insert({
            notification_type: notificationType,
            recipient_email: admin.admin_email,
            subject: subject,
            order_id: orderId,
            status: 'sent',
            resend_id: resendData.id,
            sent_at: new Date().toISOString()
          })

        return { success: true, admin: admin.admin_email, resendId: resendData.id }
      } catch (error) {
        // Log failed notification
        await supabaseClient
          .from('admin_notification_log')
          .insert({
            notification_type: notificationType,
            recipient_email: admin.admin_email,
            subject: subject,
            order_id: orderId,
            status: 'failed',
            error_message: error.message,
            sent_at: new Date().toISOString()
          })

        return { success: false, admin: admin.admin_email, error: error.message }
      }
    })

    const results = await Promise.all(emailPromises)
    const successCount = results.filter(r => r.success).length
    const failCount = results.filter(r => !r.success).length

    return new Response(
      JSON.stringify({
        success: true,
        message: `Notifications sent: ${successCount} successful, ${failCount} failed`,
        results: results
      }),
      {
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        }
      }
    )

  } catch (error) {
    console.error('Error in send-admin-notification:', error)
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message
      }),
      {
        status: 400,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        }
      }
    )
  }
})

function getNotificationSettingColumn(notificationType: string): string {
  const mapping: Record<string, string> = {
    'order_created': 'notify_on_order_created',
    'order_paid': 'notify_on_order_paid',
    'abandoned_order': 'notify_on_abandoned_order'
  }
  return mapping[notificationType] || 'notify_on_order_created'
}

function generateNotificationEmail(order: any, notificationType: string): { subject: string, htmlBody: string } {
  const orderUrl = `https://guidal.org/admin/pumpkin-orders.html`
  const orderTotal = order.total_amount?.toFixed(2) || '0.00'

  const itemsList = order.items.map((item: any) =>
    `<li>${item.quantity}x ${item.item_name} - €${item.price_per_item.toFixed(2)}</li>`
  ).join('')

  const baseStyles = `
    <style>
      body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
      .container { max-width: 600px; margin: 0 auto; padding: 20px; }
      .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
      .content { background: white; padding: 30px; border: 1px solid #ddd; }
      .order-info { background: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0; }
      .order-info h3 { margin-top: 0; color: #667eea; }
      .button { display: inline-block; background: #ff6b35; color: white; padding: 12px 30px; text-decoration: none; border-radius: 6px; margin: 20px 0; }
      .items-list { background: white; padding: 15px; border-left: 4px solid #667eea; }
      .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
      .alert { padding: 15px; border-radius: 6px; margin: 20px 0; }
      .alert-warning { background: #fff3cd; border-left: 4px solid #ffc107; }
      .alert-success { background: #d4edda; border-left: 4px solid #28a745; }
    </style>
  `

  let subject = ''
  let notificationContent = ''

  switch (notificationType) {
    case 'order_created':
      subject = `🎃 New Pumpkin Patch Order #${order.order_number}`
      notificationContent = `
        <div class="alert alert-success">
          <strong>✅ New order received!</strong><br>
          A customer has created a new order and is ${order.payment_status === 'pending' ? 'ready to proceed to payment' : 'completing their booking'}.
        </div>
      `
      break

    case 'order_paid':
      subject = `💰 Payment Confirmed - Order #${order.order_number}`
      notificationContent = `
        <div class="alert alert-success">
          <strong>✅ Payment confirmed!</strong><br>
          Order #${order.order_number} has been marked as PAID. The customer has received their confirmation email with entrance tickets.
        </div>
      `
      break

    case 'abandoned_order':
      subject = `⚠️ Abandoned Order Alert - #${order.order_number}`
      notificationContent = `
        <div class="alert alert-warning">
          <strong>⚠️ Order abandoned</strong><br>
          This order was created but the customer did not complete payment. Consider following up if appropriate.
        </div>
      `
      break

    default:
      subject = `🎃 Order Notification - #${order.order_number}`
      notificationContent = `<p>Order status update for #${order.order_number}</p>`
  }

  const htmlBody = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      ${baseStyles}
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>🎃 GUIDAL Admin Notification</h1>
          <p>${subject}</p>
        </div>
        <div class="content">
          ${notificationContent}

          <div class="order-info">
            <h3>📋 Order Details</h3>
            <p><strong>Order Number:</strong> ${order.order_number}</p>
            <p><strong>Customer:</strong> ${order.first_name} ${order.last_name}</p>
            <p><strong>Email:</strong> ${order.email}</p>
            <p><strong>Phone:</strong> ${order.phone || 'Not provided'}</p>
            <p><strong>Visit Date:</strong> ${order.visit_date || 'Not selected'}</p>
            <p><strong>Payment Status:</strong> <span style="color: ${order.payment_status === 'paid' ? '#28a745' : '#ffc107'}; font-weight: bold;">${order.payment_status.toUpperCase()}</span></p>
            <p><strong>Total:</strong> €${orderTotal}</p>
            <p><strong>Created:</strong> ${new Date(order.created_at).toLocaleString('en-GB', { timeZone: 'Europe/Madrid' })}</p>
          </div>

          <div class="items-list">
            <h3>🛒 Order Items:</h3>
            <ul>
              ${itemsList}
            </ul>
          </div>

          <div style="text-align: center;">
            <a href="${orderUrl}" class="button">View Order in Admin Panel</a>
          </div>

          <p style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #ddd; color: #666; font-size: 14px;">
            This is an automated notification from your GUIDAL Pumpkin Patch booking system.
            To manage notification preferences, visit the admin panel.
          </p>
        </div>
        <div class="footer">
          © ${new Date().getFullYear()} GUIDAL - Alella Green Tech<br>
          <a href="https://guidal.org" style="color: #667eea;">guidal.org</a>
        </div>
      </div>
    </body>
    </html>
  `

  return { subject, htmlBody }
}
