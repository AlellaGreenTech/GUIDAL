-- ============================================================================
-- PAYMENT NOTIFICATION FUNCTIONS
-- Functions to handle automated payment status updates from webhooks
-- ============================================================================

-- Function to mark order as paid
CREATE OR REPLACE FUNCTION mark_order_paid(
    p_order_number TEXT DEFAULT NULL,
    p_customer_email TEXT DEFAULT NULL,
    p_transaction_id TEXT DEFAULT NULL,
    p_payment_method TEXT DEFAULT NULL,
    p_amount NUMERIC DEFAULT NULL,
    p_metadata JSONB DEFAULT '{}'::JSONB
)
RETURNS JSONB AS $$
DECLARE
    v_order_id UUID;
    v_order_record RECORD;
    v_result JSONB;
BEGIN
    -- Try to find order by order number first
    IF p_order_number IS NOT NULL THEN
        SELECT id, payment_status, total_amount INTO v_order_record
        FROM public.pumpkin_patch_orders
        WHERE order_number = p_order_number
        LIMIT 1;

        IF FOUND THEN
            v_order_id := v_order_record.id;
            RAISE NOTICE 'Found order by order_number: %', p_order_number;
        END IF;
    END IF;

    -- If not found, try by customer email (most recent pending order)
    IF v_order_id IS NULL AND p_customer_email IS NOT NULL THEN
        SELECT id, payment_status, total_amount INTO v_order_record
        FROM public.pumpkin_patch_orders
        WHERE email = p_customer_email
        AND payment_status = 'pending'
        ORDER BY created_at DESC
        LIMIT 1;

        IF FOUND THEN
            v_order_id := v_order_record.id;
            RAISE NOTICE 'Found order by email: %', p_customer_email;
        END IF;
    END IF;

    -- If still not found, return error
    IF v_order_id IS NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Order not found',
            'searched_by', jsonb_build_object(
                'order_number', p_order_number,
                'customer_email', p_customer_email
            )
        );
    END IF;

    -- Check if already paid
    IF v_order_record.payment_status = 'paid' THEN
        RETURN jsonb_build_object(
            'success', true,
            'already_paid', true,
            'order_id', v_order_id,
            'message', 'Order was already marked as paid'
        );
    END IF;

    -- Validate amount if provided
    IF p_amount IS NOT NULL AND p_amount != v_order_record.total_amount THEN
        RAISE WARNING 'Payment amount mismatch. Expected: %, Received: %',
            v_order_record.total_amount, p_amount;
        -- Continue anyway, but log the discrepancy
    END IF;

    -- Update order status
    UPDATE public.pumpkin_patch_orders
    SET
        payment_status = 'paid',
        paid_at = NOW(),
        payment_method = COALESCE(p_payment_method, payment_method),
        admin_notes = COALESCE(admin_notes, '') ||
            E'\n\n[' || NOW()::TEXT || '] Payment confirmed automatically' ||
            E'\nTransaction ID: ' || COALESCE(p_transaction_id, 'N/A') ||
            E'\nPayment Method: ' || COALESCE(p_payment_method, 'N/A') ||
            E'\nAmount: ' || COALESCE(p_amount::TEXT, 'N/A') ||
            CASE
                WHEN p_metadata != '{}'::JSONB THEN E'\nMetadata: ' || p_metadata::TEXT
                ELSE ''
            END,
        updated_at = NOW()
    WHERE id = v_order_id;

    -- Return success
    v_result := jsonb_build_object(
        'success', true,
        'order_id', v_order_id,
        'order_number', (SELECT order_number FROM public.pumpkin_patch_orders WHERE id = v_order_id),
        'payment_status', 'paid',
        'paid_at', NOW(),
        'message', 'Payment status updated successfully'
    );

    RAISE NOTICE 'Order marked as paid: %', v_result;
    RETURN v_result;

EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', SQLERRM,
            'detail', SQLSTATE
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to service role
GRANT EXECUTE ON FUNCTION mark_order_paid TO service_role;

-- Function to log payment notifications (for debugging/audit trail)
CREATE TABLE IF NOT EXISTS public.payment_notifications_log (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    order_id UUID REFERENCES public.pumpkin_patch_orders(id) ON DELETE SET NULL,
    order_number TEXT,
    customer_email TEXT,
    transaction_id TEXT,
    payment_method TEXT,
    amount NUMERIC(10,2),
    status TEXT, -- 'success', 'failed', 'duplicate'
    raw_payload JSONB,
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index for faster lookups
CREATE INDEX IF NOT EXISTS idx_payment_notifications_order_id
    ON public.payment_notifications_log(order_id);
CREATE INDEX IF NOT EXISTS idx_payment_notifications_created_at
    ON public.payment_notifications_log(created_at);
CREATE INDEX IF NOT EXISTS idx_payment_notifications_status
    ON public.payment_notifications_log(status);

-- Enable RLS
ALTER TABLE public.payment_notifications_log ENABLE ROW LEVEL SECURITY;

-- Only admins can view payment notification logs
DROP POLICY IF EXISTS "Admins can view payment notifications log" ON public.payment_notifications_log;
CREATE POLICY "Admins can view payment notifications log"
    ON public.payment_notifications_log
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = auth.uid()
            AND profiles.user_type = 'admin'
        )
    );

-- Service role can insert logs
DROP POLICY IF EXISTS "Service role can insert payment logs" ON public.payment_notifications_log;
CREATE POLICY "Service role can insert payment logs"
    ON public.payment_notifications_log
    FOR INSERT
    TO service_role
    WITH CHECK (true);

-- Function to log payment notification
CREATE OR REPLACE FUNCTION log_payment_notification(
    p_order_id UUID DEFAULT NULL,
    p_order_number TEXT DEFAULT NULL,
    p_customer_email TEXT DEFAULT NULL,
    p_transaction_id TEXT DEFAULT NULL,
    p_payment_method TEXT DEFAULT NULL,
    p_amount NUMERIC DEFAULT NULL,
    p_status TEXT DEFAULT 'success',
    p_raw_payload JSONB DEFAULT '{}'::JSONB,
    p_error_message TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_log_id UUID;
BEGIN
    INSERT INTO public.payment_notifications_log (
        order_id,
        order_number,
        customer_email,
        transaction_id,
        payment_method,
        amount,
        status,
        raw_payload,
        error_message
    ) VALUES (
        p_order_id,
        p_order_number,
        p_customer_email,
        p_transaction_id,
        p_payment_method,
        p_amount,
        p_status,
        p_raw_payload,
        p_error_message
    )
    RETURNING id INTO v_log_id;

    RETURN v_log_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION log_payment_notification TO service_role;

-- View for easy monitoring
CREATE OR REPLACE VIEW payment_notifications_summary AS
SELECT
    pnl.id,
    pnl.created_at,
    pnl.order_number,
    pnl.customer_email,
    pnl.transaction_id,
    pnl.payment_method,
    pnl.amount,
    pnl.status,
    pnl.error_message,
    ppo.payment_status AS current_order_status,
    ppo.paid_at AS order_paid_at
FROM public.payment_notifications_log pnl
LEFT JOIN public.pumpkin_patch_orders ppo ON ppo.id = pnl.order_id
ORDER BY pnl.created_at DESC;

GRANT SELECT ON payment_notifications_summary TO authenticated;

-- Comments
COMMENT ON FUNCTION mark_order_paid IS 'Marks a pumpkin patch order as paid. Searches by order_number or customer_email.';
COMMENT ON FUNCTION log_payment_notification IS 'Logs payment notification attempts for audit trail';
COMMENT ON TABLE public.payment_notifications_log IS 'Audit log of all payment notification webhook calls';
COMMENT ON VIEW payment_notifications_summary IS 'Summary view of payment notifications with current order status';
