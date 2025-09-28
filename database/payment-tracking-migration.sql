-- Payment Tracking Migration for Demand-Driven Booking System
-- Run these migrations in order to add payment tracking capabilities

-- STEP 1: Add payment fields to booking_participants
ALTER TABLE booking_participants
ADD COLUMN IF NOT EXISTS payment_status TEXT DEFAULT 'pending',
ADD COLUMN IF NOT EXISTS payment_deadline TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS payment_completed_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS payment_amount DECIMAL(10,2);

-- Add payment status constraint
ALTER TABLE booking_participants
ADD CONSTRAINT IF NOT EXISTS payment_status_check
CHECK (payment_status IN ('pending', 'completed', 'failed', 'refunded'));

-- STEP 2: Add payment tracking to booking_requests
ALTER TABLE booking_requests
ADD COLUMN IF NOT EXISTS payment_deadline TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS participants_paid INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS total_amount_paid DECIMAL(10,2) DEFAULT 0;

-- Update booking status constraint to include payment states
ALTER TABLE booking_requests DROP CONSTRAINT IF EXISTS booking_status_check;
ALTER TABLE booking_requests
ADD CONSTRAINT booking_status_check
CHECK (status IN ('pending', 'minimum_reached', 'payment_pending', 'confirmed', 'cancelled', 'expired'));

-- STEP 3: Create email tracking table
CREATE TABLE IF NOT EXISTS booking_email_log (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    booking_request_id UUID REFERENCES booking_requests(id) ON DELETE CASCADE,
    participant_id UUID REFERENCES booking_participants(id) ON DELETE CASCADE,
    email_type TEXT NOT NULL,
    recipient_email TEXT NOT NULL,
    sent_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    email_data JSONB DEFAULT '{}',
    delivery_status TEXT DEFAULT 'sent'
);

-- Add email type constraint
ALTER TABLE booking_email_log
ADD CONSTRAINT email_type_check
CHECK (email_type IN ('booking_confirmation', 'recruitment', 'minimum_reached', 'payment_reminder', 'payment_confirmation', 'session_confirmed', 'session_cancelled'));

-- Enable RLS on email log
ALTER TABLE booking_email_log ENABLE ROW LEVEL SECURITY;

-- STEP 4: Create payment tracking functions

-- Function to update participant payment status
CREATE OR REPLACE FUNCTION update_participant_payment(
    p_participant_id UUID,
    p_payment_status TEXT,
    p_payment_amount DECIMAL DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    v_booking_id UUID;
    v_total_participants INTEGER;
    v_paid_participants INTEGER;
BEGIN
    -- Update the participant payment
    UPDATE booking_participants
    SET
        payment_status = p_payment_status,
        payment_completed_at = CASE
            WHEN p_payment_status = 'completed' THEN NOW()
            ELSE payment_completed_at
        END,
        payment_amount = COALESCE(p_payment_amount, payment_amount)
    WHERE id = p_participant_id
    RETURNING booking_request_id INTO v_booking_id;

    -- Get participant counts
    SELECT
        COUNT(*) as total,
        COUNT(*) FILTER (WHERE payment_status = 'completed') as paid
    FROM booking_participants
    WHERE booking_request_id = v_booking_id
    INTO v_total_participants, v_paid_participants;

    -- Update booking request
    UPDATE booking_requests
    SET
        participants_paid = v_paid_participants,
        total_amount_paid = (
            SELECT COALESCE(SUM(payment_amount), 0)
            FROM booking_participants
            WHERE booking_request_id = v_booking_id
            AND payment_status = 'completed'
        ),
        status = CASE
            WHEN v_paid_participants = v_total_participants THEN 'confirmed'
            WHEN v_paid_participants > 0 THEN 'payment_pending'
            ELSE status
        END
    WHERE id = v_booking_id;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Function to check and update booking status based on participant count
CREATE OR REPLACE FUNCTION check_minimum_participants(p_booking_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    v_current_participants INTEGER;
    v_min_participants INTEGER;
    v_current_status TEXT;
BEGIN
    -- Get current participant count and minimum required
    SELECT
        current_participants,
        min_participants_needed,
        status
    FROM booking_requests
    WHERE id = p_booking_id
    INTO v_current_participants, v_min_participants, v_current_status;

    -- If minimum reached and status is still pending, update to minimum_reached
    IF v_current_participants >= v_min_participants AND v_current_status = 'pending' THEN
        UPDATE booking_requests
        SET
            status = 'minimum_reached',
            payment_deadline = NOW() + INTERVAL '48 hours'
        WHERE id = p_booking_id;

        -- Set payment deadline for all participants
        UPDATE booking_participants
        SET payment_deadline = NOW() + INTERVAL '48 hours'
        WHERE booking_request_id = p_booking_id;

        RETURN TRUE; -- Indicates minimum was just reached
    END IF;

    RETURN FALSE; -- Minimum was already reached or not yet reached
END;
$$ LANGUAGE plpgsql;

-- Function to log emails
CREATE OR REPLACE FUNCTION log_booking_email(
    p_booking_id UUID,
    p_participant_id UUID DEFAULT NULL,
    p_email_type TEXT,
    p_recipient_email TEXT,
    p_email_data JSONB DEFAULT '{}'
)
RETURNS UUID AS $$
DECLARE
    v_log_id UUID;
BEGIN
    INSERT INTO booking_email_log (
        booking_request_id,
        participant_id,
        email_type,
        recipient_email,
        email_data
    ) VALUES (
        p_booking_id,
        p_participant_id,
        p_email_type,
        p_recipient_email,
        p_email_data
    ) RETURNING id INTO v_log_id;

    RETURN v_log_id;
END;
$$ LANGUAGE plpgsql;

-- STEP 5: Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_booking_participants_payment_status ON booking_participants(payment_status);
CREATE INDEX IF NOT EXISTS idx_booking_participants_payment_deadline ON booking_participants(payment_deadline);
CREATE INDEX IF NOT EXISTS idx_booking_requests_payment_deadline ON booking_requests(payment_deadline);
CREATE INDEX IF NOT EXISTS idx_booking_email_log_booking_id ON booking_email_log(booking_request_id);
CREATE INDEX IF NOT EXISTS idx_booking_email_log_email_type ON booking_email_log(email_type);
CREATE INDEX IF NOT EXISTS idx_booking_email_log_sent_at ON booking_email_log(sent_at);

-- STEP 6: Create RLS policies for email log

-- Users can view email logs for their own bookings
CREATE POLICY "Users can view own booking emails" ON booking_email_log
    FOR SELECT USING (
        booking_request_id IN (
            SELECT DISTINCT bp.booking_request_id
            FROM booking_participants bp
            WHERE bp.user_id = auth.uid()
        )
    );

-- Admins can view all email logs
CREATE POLICY "Admins can view all booking emails" ON booking_email_log
    FOR ALL USING (
        auth.jwt() ->> 'email' IN (
            SELECT email FROM user_roles WHERE role = 'admin'
        )
    );

-- STEP 7: Grant permissions
GRANT SELECT, INSERT, UPDATE ON booking_email_log TO authenticated;
GRANT SELECT, INSERT, UPDATE ON booking_participants TO authenticated;
GRANT SELECT, UPDATE ON booking_requests TO authenticated;

-- Grant execute permissions on functions
GRANT EXECUTE ON FUNCTION update_participant_payment(UUID, TEXT, DECIMAL) TO authenticated;
GRANT EXECUTE ON FUNCTION check_minimum_participants(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION log_booking_email(UUID, UUID, TEXT, TEXT, JSONB) TO authenticated;

-- STEP 8: Create a view for booking summary with payment info
CREATE OR REPLACE VIEW booking_summary AS
SELECT
    br.id,
    br.activity_id,
    br.requested_date,
    br.status,
    br.current_participants,
    br.min_participants_needed,
    br.participants_paid,
    br.total_amount_paid,
    br.payment_deadline,
    br.created_at,
    a.title as activity_title,
    a.price_euros as activity_price,
    -- Calculate expected total payment
    (br.current_participants * COALESCE(a.price_euros, 25)) as expected_total_payment,
    -- Payment completion percentage
    CASE
        WHEN br.current_participants > 0
        THEN ROUND((br.participants_paid::DECIMAL / br.current_participants) * 100, 1)
        ELSE 0
    END as payment_completion_percentage,
    -- Status summary
    CASE
        WHEN br.status = 'pending' AND br.current_participants < br.min_participants_needed
        THEN 'Waiting for participants'
        WHEN br.status = 'minimum_reached' OR br.status = 'payment_pending'
        THEN 'Payment required'
        WHEN br.status = 'confirmed'
        THEN 'Confirmed'
        WHEN br.status = 'cancelled'
        THEN 'Cancelled'
        WHEN br.status = 'expired'
        THEN 'Expired'
        ELSE br.status
    END as status_display
FROM booking_requests br
JOIN activities a ON br.activity_id = a.id;

-- Grant access to the view
GRANT SELECT ON booking_summary TO authenticated;

-- Add helpful comments
COMMENT ON TABLE booking_email_log IS 'Tracks all emails sent for booking system to prevent duplicates and provide audit trail';
COMMENT ON FUNCTION update_participant_payment IS 'Updates participant payment status and recalculates booking totals';
COMMENT ON FUNCTION check_minimum_participants IS 'Checks if minimum participants reached and updates booking status accordingly';
COMMENT ON FUNCTION log_booking_email IS 'Logs outgoing emails for audit trail and duplicate prevention';
COMMENT ON VIEW booking_summary IS 'Convenient view showing booking status with payment information';

-- Migration complete message
SELECT 'Payment tracking migration completed successfully!' as message;