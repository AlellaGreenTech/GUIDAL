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
    // Initialize Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    // Calculate date range (last 24 hours)
    const now = new Date()
    const yesterday = new Date(now.getTime() - 24 * 60 * 60 * 1000)

    // Get active admins who want daily summaries
    const { data: admins, error: adminsError } = await supabaseClient
      .from('admin_notification_settings')
      .select('*')
      .eq('is_active', true)
      .eq('notify_daily_summary', true)

    if (adminsError) {
      throw new Error('Error fetching admins: ' + adminsError.message)
    }

    if (!admins || admins.length === 0) {
      return new Response(
        JSON.stringify({
          success: true,
          message: 'No active admins configured for daily summaries'
        }),
        {
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
          }
        }
      )
    }

    // Gather analytics data
    const analyticsData = await gatherAnalytics(supabaseClient, yesterday, now)

    // Generate email content
    const { subject, htmlBody } = generateDailySummaryEmail(analyticsData, yesterday, now)

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
            notification_type: 'daily_summary',
            recipient_email: admin.admin_email,
            subject: subject,
            order_id: null,
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
            notification_type: 'daily_summary',
            recipient_email: admin.admin_email,
            subject: subject,
            order_id: null,
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
        message: `Daily summaries sent: ${successCount} successful, ${failCount} failed`,
        results: results,
        analytics: analyticsData
      }),
      {
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        }
      }
    )

  } catch (error) {
    console.error('Error in send-daily-summary:', error)
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

async function gatherAnalytics(supabaseClient: any, startDate: Date, endDate: Date) {
  // Get orders created in the last 24 hours
  const { data: orders, error: ordersError } = await supabaseClient
    .from('pumpkin_patch_orders')
    .select('id, payment_status, total_amount, created_at')
    .gte('created_at', startDate.toISOString())
    .lte('created_at', endDate.toISOString())

  if (ordersError) {
    console.error('Error fetching orders:', ordersError)
  }

  const totalOrders = orders?.length || 0
  const paidOrders = orders?.filter((o: any) => o.payment_status === 'paid').length || 0
  const pendingOrders = orders?.filter((o: any) => o.payment_status === 'pending').length || 0
  const totalRevenue = orders?.reduce((sum: number, o: any) =>
    o.payment_status === 'paid' ? sum + (o.total_amount || 0) : sum, 0) || 0

  // Get analytics events (button clicks, etc.)
  const { data: events, error: eventsError } = await supabaseClient
    .from('analytics_events')
    .select('event_type, event_category, event_label, event_value')
    .gte('created_at', startDate.toISOString())
    .lte('created_at', endDate.toISOString())

  if (eventsError) {
    console.error('Error fetching analytics events:', eventsError)
  }

  // Count button clicks
  const buttonClicks = events?.filter((e: any) => e.event_type === 'button_click').length || 0

  // Group button clicks by label
  const clicksByButton: Record<string, number> = {}
  events?.filter((e: any) => e.event_type === 'button_click').forEach((e: any) => {
    const label = e.event_label || 'Unknown'
    clicksByButton[label] = (clicksByButton[label] || 0) + 1
  })

  // Count page views
  const pageViews = events?.filter((e: any) => e.event_type === 'page_view').length || 0

  // Group page views by URL
  const viewsByPage: Record<string, number> = {}
  events?.filter((e: any) => e.event_type === 'page_view').forEach((e: any) => {
    const url = e.page_url || 'Unknown'
    viewsByPage[url] = (viewsByPage[url] || 0) + 1
  })

  // Calculate unique sessions
  const uniqueSessions = new Set(events?.map((e: any) => e.user_session_id).filter(Boolean)).size

  return {
    orders: {
      total: totalOrders,
      paid: paidOrders,
      pending: pendingOrders,
      revenue: totalRevenue
    },
    analytics: {
      totalEvents: events?.length || 0,
      buttonClicks: buttonClicks,
      clicksByButton: clicksByButton,
      pageViews: pageViews,
      viewsByPage: viewsByPage,
      uniqueSessions: uniqueSessions
    }
  }
}

function generateDailySummaryEmail(data: any, startDate: Date, endDate: Date): { subject: string, htmlBody: string } {
  const dateStr = startDate.toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' })

  const subject = `📊 Daily Summary - ${dateStr} - GUIDAL Pumpkin Patch`

  const topButtons = Object.entries(data.analytics.clicksByButton)
    .sort(([, a]: any, [, b]: any) => b - a)
    .slice(0, 5)
    .map(([label, count]) => `<li><strong>${label}:</strong> ${count} clicks</li>`)
    .join('')

  const topPages = Object.entries(data.analytics.viewsByPage)
    .sort(([, a]: any, [, b]: any) => b - a)
    .slice(0, 5)
    .map(([url, count]) => `<li><strong>${url}:</strong> ${count} views</li>`)
    .join('')

  const htmlBody = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 700px; margin: 0 auto; padding: 20px; }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
        .content { background: white; padding: 30px; border: 1px solid #ddd; }
        .stats-grid { display: grid; grid-template-columns: repeat(2, 1fr); gap: 20px; margin: 30px 0; }
        .stat-card { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; border-radius: 10px; text-align: center; }
        .stat-card h2 { font-size: 2.5rem; margin: 10px 0; }
        .stat-card p { font-size: 0.9rem; opacity: 0.9; }
        .section { margin: 30px 0; padding: 20px; background: #f8f9fa; border-radius: 8px; }
        .section h3 { color: #667eea; margin-top: 0; }
        .list { list-style: none; padding: 0; }
        .list li { padding: 8px 0; border-bottom: 1px solid #ddd; }
        .list li:last-child { border-bottom: none; }
        .revenue { color: #28a745; font-size: 1.2rem; font-weight: bold; }
        .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
        .highlight { background: #fff3cd; padding: 15px; border-left: 4px solid #ffc107; border-radius: 4px; margin: 20px 0; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>📊 Daily Summary Report</h1>
          <p>${dateStr}</p>
          <p style="font-size: 0.9rem; opacity: 0.9;">GUIDAL Pumpkin Patch Activity</p>
        </div>
        <div class="content">
          <h2 style="color: #667eea;">🎃 Order Summary</h2>
          <div class="stats-grid">
            <div class="stat-card">
              <p>Total Orders</p>
              <h2>${data.orders.total}</h2>
            </div>
            <div class="stat-card">
              <p>Paid Orders</p>
              <h2>${data.orders.paid}</h2>
            </div>
            <div class="stat-card">
              <p>Pending Orders</p>
              <h2>${data.orders.pending}</h2>
            </div>
            <div class="stat-card">
              <p>Revenue (24h)</p>
              <h2>€${data.orders.revenue.toFixed(2)}</h2>
            </div>
          </div>

          ${data.orders.pending > 0 ? `
          <div class="highlight">
            <strong>⚠️ Note:</strong> You have ${data.orders.pending} pending order${data.orders.pending > 1 ? 's' : ''} awaiting payment.
            <a href="https://guidal.org/admin/pumpkin-orders.html" style="color: #667eea;">View in admin panel</a>
          </div>
          ` : ''}

          <h2 style="color: #667eea; margin-top: 40px;">📈 Website Analytics</h2>

          <div class="section">
            <h3>Overall Traffic</h3>
            <ul class="list">
              <li><strong>Total Events:</strong> ${data.analytics.totalEvents}</li>
              <li><strong>Unique Sessions:</strong> ${data.analytics.uniqueSessions}</li>
              <li><strong>Page Views:</strong> ${data.analytics.pageViews}</li>
              <li><strong>Button Clicks:</strong> ${data.analytics.buttonClicks}</li>
            </ul>
          </div>

          ${topButtons ? `
          <div class="section">
            <h3>🖱️ Top Button Clicks</h3>
            <ul class="list">
              ${topButtons || '<li>No button clicks recorded</li>'}
            </ul>
          </div>
          ` : ''}

          ${topPages ? `
          <div class="section">
            <h3>👁️ Top Pages Viewed</h3>
            <ul class="list">
              ${topPages || '<li>No page views recorded</li>'}
            </ul>
          </div>
          ` : ''}

          <div style="margin-top: 40px; padding-top: 20px; border-top: 2px solid #ddd; text-align: center;">
            <a href="https://guidal.org/admin/pumpkin-orders.html" style="display: inline-block; background: #ff6b35; color: white; padding: 12px 30px; text-decoration: none; border-radius: 6px; font-weight: bold;">
              View Full Dashboard
            </a>
          </div>

          <p style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #ddd; color: #666; font-size: 14px;">
            This is your automated daily summary from the GUIDAL Pumpkin Patch booking system.
            To manage notification preferences, visit the <a href="https://guidal.org/admin/notification-settings.html" style="color: #667eea;">notification settings</a> page.
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
