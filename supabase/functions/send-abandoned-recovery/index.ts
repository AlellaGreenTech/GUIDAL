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
    // This can be called manually or by a scheduled job
    const { abandonedBookingId, testMode } = await req.json()

    // Initialize Supabase client with service role for admin access
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    let abandonedBookings = []

    if (abandonedBookingId) {
      // Send recovery email for specific booking
      const { data, error } = await supabaseClient
        .from('abandoned_bookings')
        .select('*')
        .eq('id', abandonedBookingId)
        .single()

      if (error || !data) {
        throw new Error('Abandoned booking not found')
      }
      abandonedBookings = [data]
    } else {
      // Find all abandoned bookings from last 24-72 hours that haven't been contacted
      const oneDayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString()
      const threeDaysAgo = new Date(Date.now() - 3 * 24 * 60 * 60 * 1000).toISOString()

      const { data, error } = await supabaseClient
        .from('abandoned_bookings')
        .select('*')
        .eq('status', 'abandoned')
        .is('recovery_email_sent_at', null)
        .gte('started_at', threeDaysAgo)
        .lte('started_at', oneDayAgo)
        .order('started_at', { ascending: false })

      if (error) {
        throw new Error('Error fetching abandoned bookings: ' + error.message)
      }

      abandonedBookings = data || []
    }

    if (abandonedBookings.length === 0) {
      return new Response(
        JSON.stringify({
          success: true,
          message: 'No abandoned bookings to process',
          count: 0
        }),
        {
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
          }
        }
      )
    }

    // Send recovery emails
    const results = await Promise.all(abandonedBookings.map(async (booking) => {
      try {
        const emailHTML = generateRecoveryEmail(booking)

        // Send via Resend
        const resendResponse = await fetch('https://api.resend.com/emails', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${RESEND_API_KEY}`
          },
          body: JSON.stringify({
            from: FROM_EMAIL,
            to: [booking.email],
            subject: testMode ? '[TEST] The forces of evil interrupted you! 👻' : 'The forces of evil interrupted you! 👻',
            html: emailHTML
          })
        })

        const resendData = await resendResponse.json()

        if (!resendResponse.ok) {
          throw new Error(`Resend API error: ${resendData.message || 'Unknown error'}`)
        }

        // Update booking record
        await supabaseClient
          .from('abandoned_bookings')
          .update({
            recovery_email_sent_at: new Date().toISOString(),
            status: 'abandoned' // Keep as abandoned until they complete
          })
          .eq('id', booking.id)

        return {
          success: true,
          email: booking.email,
          bookingId: booking.id,
          resendId: resendData.id
        }
      } catch (error) {
        console.error('Error sending recovery email:', error)
        return {
          success: false,
          email: booking.email,
          bookingId: booking.id,
          error: error.message
        }
      }
    }))

    const successCount = results.filter(r => r.success).length
    const failCount = results.filter(r => !r.success).length

    return new Response(
      JSON.stringify({
        success: true,
        message: `Recovery emails sent: ${successCount} successful, ${failCount} failed`,
        totalProcessed: abandonedBookings.length,
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
    console.error('Error in send-abandoned-recovery:', error)
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

function generateRecoveryEmail(booking: any): string {
  const firstName = booking.first_name || 'there'
  const cartItems = booking.cart_items || {}
  const total = booking.cart_total ? Number(booking.cart_total).toFixed(2) : '0.00'

  // Generate cart summary
  const items = []
  if (cartItems.visit > 0) items.push(`${cartItems.visit}x Visit Pass (€5 each)`)
  if (cartItems.adults > 0) items.push(`${cartItems.adults}x Adult Party Ticket (€15 each)`)
  if (cartItems.children > 0) items.push(`${cartItems.children}x Child Party Ticket (€10 each)`)
  if (cartItems.smallPumpkin > 0) items.push(`${cartItems.smallPumpkin}x Small Pumpkin (€5)`)
  if (cartItems.mediumPumpkin > 0) items.push(`${cartItems.mediumPumpkin}x Medium Pumpkin (€10)`)
  if (cartItems.largePumpkin > 0) items.push(`${cartItems.largePumpkin}x Large Pumpkin (€15)`)
  if (cartItems.scares > 0) items.push(`${cartItems.scares}x SCARES top-up (€1 each)`)

  const itemsList = items.length > 0 ? items.map(item => `<li>${item}</li>`).join('') : '<li>No items selected</li>'

  return `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header {
          background: linear-gradient(135deg, #ff6b35, #764ba2);
          color: white;
          padding: 40px 30px;
          text-align: center;
          border-radius: 10px 10px 0 0;
        }
        .header h1 { margin: 0; font-size: 32px; text-shadow: 2px 2px 4px rgba(0,0,0,0.3); }
        .content { background: white; padding: 30px; border: 1px solid #ddd; border-top: none; }
        .evil-message {
          background: #fff3cd;
          border-left: 4px solid #ff6b35;
          padding: 20px;
          margin: 20px 0;
          border-radius: 4px;
        }
        .cart-summary {
          background: #f8f9fa;
          padding: 20px;
          border-radius: 8px;
          margin: 20px 0;
        }
        .cart-summary h3 { margin-top: 0; color: #667eea; }
        .cart-summary ul { padding-left: 20px; }
        .total { font-size: 1.3em; font-weight: bold; color: #ff6b35; margin-top: 15px; }
        .button {
          display: inline-block;
          background: linear-gradient(135deg, #ff6b35, #ff8c42);
          color: white;
          padding: 15px 40px;
          text-decoration: none;
          border-radius: 6px;
          font-weight: bold;
          font-size: 18px;
          margin: 20px 0;
          box-shadow: 0 4px 12px rgba(255, 107, 53, 0.3);
        }
        .button:hover { background: linear-gradient(135deg, #ff8c42, #ff6b35); }
        .footer {
          text-align: center;
          padding: 20px;
          color: #666;
          font-size: 12px;
          border-top: 1px solid #eee;
        }
        .ghost { font-size: 48px; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <div class="ghost">👻</div>
          <h1>The Forces of Evil Interrupted You!</h1>
          <p style="font-size: 18px; margin: 10px 0 0 0;">Your SCARY PUMPKIN PATCH booking is waiting...</p>
        </div>

        <div class="content">
          <p>Hi ${firstName},</p>

          <div class="evil-message">
            <p><strong>🎃 We noticed you started booking your visit to the SCARY PUMPKIN PATCH but didn't finish!</strong></p>
            <p>Did the forces of darkness interrupt your booking? Or perhaps a rogue ghost closed your browser? 👻</p>
          </div>

          <p>Don't let evil triumph! Your haunted adventure awaits at Alella Green Tech's GUIDAL pumpkin patch.</p>

          ${items.length > 0 ? `
          <div class="cart-summary">
            <h3>🛒 What You Were Booking:</h3>
            <ul>
              ${itemsList}
            </ul>
            <div class="total">Total: €${total}</div>
          </div>
          ` : '<p>You hadn\'t selected any items yet, but there\'s still time!</p>'}

          <div style="text-align: center; margin: 30px 0;">
            <a href="https://guidal.org/events/pumpkin-patch-checkout.html" class="button">
              ✨ Complete Your Booking Now ✨
            </a>
          </div>

          <p><strong>What awaits you:</strong></p>
          <ul>
            <li>🎃 <strong>Pumpkin picking</strong> from our haunted patch</li>
            <li>👻 <strong>Spooky decorations</strong> and Halloween atmosphere</li>
            <li>🌿 <strong>Nature walks</strong> through our green spaces</li>
            <li>💚 <strong>SCARES currency</strong> to use at our activities</li>
            <li>🎪 <strong>Special Halloween party</strong> on October 25th</li>
          </ul>

          <p style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #ddd; color: #666; font-size: 14px;">
            <em>This is a friendly reminder from your friends at GUIDAL. If you've changed your mind, no worries - just ignore this email. But if you're ready for a spooky good time, click the button above!</em>
          </p>
        </div>

        <div class="footer">
          © 2025 Alella Green Tech Foundation<br>
          <a href="https://guidal.org" style="color: #667eea;">guidal.org</a>
        </div>
      </div>
    </body>
    </html>
  `
}
