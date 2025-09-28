-- Main Booking Schema for Demand-Driven Booking System
-- This creates the core booking tables needed for the demand-driven booking system

-- =====================================================
-- BOOKING REQUESTS TABLE
-- =====================================================
-- This table stores individual booking requests (when someone wants to book a date)
CREATE TABLE IF NOT EXISTS booking_requests (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,

    -- Activity being booked
    activity_id UUID NOT NULL REFERENCES activities(id) ON DELETE CASCADE,

    -- Requested date and time
    requested_date TIMESTAMP WITH TIME ZONE NOT NULL,

    -- Participant requirements
    participants_requested INTEGER NOT NULL DEFAULT 1,
    min_participants_needed INTEGER NOT NULL DEFAULT 5,
    current_participants INTEGER NOT NULL DEFAULT 0,

    -- Booking status
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN (
        'pending',           -- Waiting for more participants
        'minimum_reached',   -- Minimum reached, waiting for payments
        'payment_pending',   -- Some payments received, waiting for all
        'confirmed',         -- All payments received, session confirmed
        'cancelled',         -- Booking cancelled
        'expired'           -- Payment deadline passed
    )),

    -- Metadata
    created_by UUID REFERENCES profiles(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Share link identifier (for easy sharing)
    share_token TEXT UNIQUE DEFAULT substr(md5(random()::text), 1, 12)
);

-- =====================================================
-- BOOKING PARTICIPANTS TABLE
-- =====================================================
-- This table stores individual participants for each booking request
CREATE TABLE IF NOT EXISTS booking_participants (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,

    -- Which booking this participant joined
    booking_request_id UUID NOT NULL REFERENCES booking_requests(id) ON DELETE CASCADE,

    -- Who is participating
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

    -- How many people this user is bringing
    participants_count INTEGER NOT NULL DEFAULT 1,

    -- Timestamps
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Prevent duplicate participation
    UNIQUE(booking_request_id, user_id)
);

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_booking_requests_activity_id ON booking_requests(activity_id);
CREATE INDEX IF NOT EXISTS idx_booking_requests_requested_date ON booking_requests(requested_date);
CREATE INDEX IF NOT EXISTS idx_booking_requests_status ON booking_requests(status);
CREATE INDEX IF NOT EXISTS idx_booking_requests_share_token ON booking_requests(share_token);

CREATE INDEX IF NOT EXISTS idx_booking_participants_booking_id ON booking_participants(booking_request_id);
CREATE INDEX IF NOT EXISTS idx_booking_participants_user_id ON booking_participants(user_id);

-- =====================================================
-- ROW LEVEL SECURITY (RLS)
-- =====================================================
ALTER TABLE booking_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE booking_participants ENABLE ROW LEVEL SECURITY;

-- Users can view all pending/confirmed booking requests (for joining)
CREATE POLICY "Anyone can view open booking requests" ON booking_requests
    FOR SELECT USING (status IN ('pending', 'minimum_reached', 'confirmed'));

-- Users can create their own booking requests
CREATE POLICY "Users can create booking requests" ON booking_requests
    FOR INSERT WITH CHECK (auth.uid() = created_by);

-- Users can update their own booking requests
CREATE POLICY "Users can update own booking requests" ON booking_requests
    FOR UPDATE USING (auth.uid() = created_by);

-- Users can view participants for bookings they're involved with
CREATE POLICY "Users can view related participants" ON booking_participants
    FOR SELECT USING (
        user_id = auth.uid() OR
        booking_request_id IN (
            SELECT id FROM booking_requests WHERE created_by = auth.uid()
        )
    );

-- Users can join booking requests (create participant records)
CREATE POLICY "Users can join bookings" ON booking_participants
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own participation
CREATE POLICY "Users can update own participation" ON booking_participants
    FOR UPDATE USING (auth.uid() = user_id);

-- =====================================================
-- DATABASE FUNCTIONS
-- =====================================================

-- Function to update participant count when someone joins/leaves
CREATE OR REPLACE FUNCTION update_booking_participant_count()
RETURNS TRIGGER AS $$
BEGIN
    -- Update the current_participants count in booking_requests
    UPDATE booking_requests
    SET current_participants = (
        SELECT COALESCE(SUM(participants_count), 0)
        FROM booking_participants
        WHERE booking_request_id = COALESCE(NEW.booking_request_id, OLD.booking_request_id)
    ),
    updated_at = NOW()
    WHERE id = COALESCE(NEW.booking_request_id, OLD.booking_request_id);

    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Trigger to automatically update participant counts
CREATE TRIGGER update_booking_participants_count
    AFTER INSERT OR UPDATE OR DELETE ON booking_participants
    FOR EACH ROW
    EXECUTE FUNCTION update_booking_participant_count();

-- Function to increment participant count (used by JavaScript)
CREATE OR REPLACE FUNCTION increment_booking_participants(
    booking_id UUID,
    participant_count INTEGER
)
RETURNS BOOLEAN AS $$
BEGIN
    -- Update the current participants count
    UPDATE booking_requests
    SET
        current_participants = current_participants + participant_count,
        updated_at = NOW()
    WHERE id = booking_id;

    RETURN FOUND;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- GRANT PERMISSIONS
-- =====================================================
GRANT SELECT, INSERT, UPDATE ON booking_requests TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON booking_participants TO authenticated;
GRANT EXECUTE ON FUNCTION increment_booking_participants(UUID, INTEGER) TO authenticated;

-- =====================================================
-- HELPFUL VIEWS
-- =====================================================

-- View for easy booking overview with activity details
CREATE OR REPLACE VIEW booking_overview AS
SELECT
    br.id,
    br.requested_date,
    br.participants_requested,
    br.min_participants_needed,
    br.current_participants,
    br.status,
    br.created_at,
    br.share_token,
    a.title as activity_title,
    a.description as activity_description,
    a.price_euros,
    a.duration_minutes,
    at.name as activity_type_name,
    at.slug as activity_type_slug,
    p.name as created_by_name,
    p.email as created_by_email,
    -- Calculate if minimum is reached
    (br.current_participants >= br.min_participants_needed) as minimum_reached,
    -- Calculate spots remaining
    GREATEST(0, br.min_participants_needed - br.current_participants) as spots_needed
FROM booking_requests br
JOIN activities a ON br.activity_id = a.id
LEFT JOIN activity_types at ON a.activity_type_id = at.id
LEFT JOIN profiles p ON br.created_by = p.id;

-- Grant access to the view
GRANT SELECT ON booking_overview TO authenticated;

-- =====================================================
-- COMMENTS FOR DOCUMENTATION
-- =====================================================
COMMENT ON TABLE booking_requests IS 'Stores individual booking requests for activities - the core of the demand-driven booking system';
COMMENT ON TABLE booking_participants IS 'Tracks who has joined each booking request and how many participants they are bringing';
COMMENT ON FUNCTION update_booking_participant_count IS 'Automatically updates participant counts when people join or leave bookings';
COMMENT ON FUNCTION increment_booking_participants IS 'Helper function to safely increment participant counts from JavaScript';
COMMENT ON VIEW booking_overview IS 'Convenient view showing booking requests with activity details and calculated fields';

-- Success message
SELECT 'Main booking schema created successfully! Ready for payment tracking migration.' as message;