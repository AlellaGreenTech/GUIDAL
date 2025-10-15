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
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const payload = await req.json()

    console.log('Received payment notification:', JSON.stringify(payload, null, 2))

    // Extract payment information from the parsed email
    // The structure will depend on your email parser service
    // Common fields we might receive:
    const {
      orderNumber,      // Order number from email
      customerEmail,    // Customer email
      amount,           // Payment amount
      transactionId,    // Payment transaction ID
      paymentMethod,    // e.g., 'paypal', 'stripe', 'bank_transfer'
      rawEmail,         // Original email content (if provided)
      from,             // Email from address
      subject,          // Email subject
      body              // Email body
    } = payload

    console.log('Extracted data:', {
      orderNumber,
      customerEmail,
      amount,
      transactionId,
      paymentMethod
    })

    // Try to find the order by order number first
    let order = null
    let orderId = null

    if (orderNumber) {
      const { data: orderData, error: orderError } = await supabase
        .from('pumpkin_patch_orders')
        .select('*')
        .eq('order_number', orderNumber)
        .single()

      if (orderError) {
        console.error('Error finding order by order number:', orderError)
      } else {
        order = orderData
        orderId = orderData.id
        console.log('Found order by order number:', orderId)
      }
    }

    // If not found by order number, try by email
    if (!order && customerEmail) {
      const { data: orderData, error: orderError } = await supabase
        .from('pumpkin_patch_orders')
        .select('*')
        .eq('email', customerEmail)
        .eq('payment_status', 'pending')
        .order('created_at', { ascending: false })
        .limit(1)
        .single()

      if (orderError) {
        console.error('Error finding order by email:', orderError)
      } else {
        order = orderData
        orderId = orderData.id
        console.log('Found order by customer email:', orderId)
      }
    }

    // Use database function to mark order as paid
    const { data: result, error: rpcError } = await supabase
      .rpc('mark_order_paid', {
        p_order_number: orderNumber || null,
        p_customer_email: customerEmail || null,
        p_transaction_id: transactionId || null,
        p_payment_method: paymentMethod || null,
        p_amount: amount || null,
        p_metadata: {
          from_email: from,
          subject: subject,
          automated: true,
          raw_payload: payload
        }
      })

    if (rpcError) {
      console.error('Error calling mark_order_paid:', rpcError)

      // Log failed attempt
      await supabase.rpc('log_payment_notification', {
        p_order_number: orderNumber || null,
        p_customer_email: customerEmail || null,
        p_transaction_id: transactionId || null,
        p_payment_method: paymentMethod || null,
        p_amount: amount || null,
        p_status: 'failed',
        p_raw_payload: payload,
        p_error_message: rpcError.message
      })

      return new Response(
        JSON.stringify({
          success: false,
          error: 'Failed to update order',
          details: rpcError
        }),
        {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    console.log('mark_order_paid result:', result)

    // Check if the function call was successful
    if (!result.success) {
      // Log failed attempt
      await supabase.rpc('log_payment_notification', {
        p_order_number: orderNumber || null,
        p_customer_email: customerEmail || null,
        p_transaction_id: transactionId || null,
        p_payment_method: paymentMethod || null,
        p_amount: amount || null,
        p_status: 'failed',
        p_raw_payload: payload,
        p_error_message: result.error || 'Unknown error'
      })

      return new Response(
        JSON.stringify(result),
        {
          status: result.error === 'Order not found' ? 404 : 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    // Log successful payment notification
    await supabase.rpc('log_payment_notification', {
      p_order_id: result.order_id,
      p_order_number: result.order_number,
      p_customer_email: customerEmail || null,
      p_transaction_id: transactionId || null,
      p_payment_method: paymentMethod || null,
      p_amount: amount || null,
      p_status: result.already_paid ? 'duplicate' : 'success',
      p_raw_payload: payload,
      p_error_message: null
    })

    console.log('Successfully processed payment notification:', result)

    // Optionally: Send confirmation email to customer
    // You could call another Edge Function here

    return new Response(
      JSON.stringify(result),
      {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )

  } catch (error) {
    console.error('Error processing payment notification:', error)
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message
      }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }
})
