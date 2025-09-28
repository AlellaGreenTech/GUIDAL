-- Create booking configuration table for admin settings
CREATE TABLE IF NOT EXISTS booking_configuration (
    id TEXT PRIMARY KEY DEFAULT 'default',
    config JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE booking_configuration ENABLE ROW LEVEL SECURITY;

-- Only admins can read/write configuration
CREATE POLICY "Admin can manage booking configuration" ON booking_configuration
    FOR ALL USING (
        auth.jwt() ->> 'email' IN (
            SELECT email FROM user_roles
            WHERE role = 'admin'
        )
    );

-- Insert default configuration
INSERT INTO booking_configuration (id, config) VALUES ('default', '{
    "general": {
        "advanceBookingDays": 7,
        "maxBookingDays": 365,
        "defaultMinParticipants": 5,
        "bookingConfirmationHours": 48
    },
    "dateRestrictions": {
        "blockedDaysOfWeek": [],
        "blockedDateRanges": []
    },
    "timeSlots": {
        "morning": [
            {"time": "09:00", "label": "9:00 AM"},
            {"time": "10:00", "label": "10:00 AM"},
            {"time": "11:00", "label": "11:00 AM"}
        ],
        "afternoon": [
            {"time": "14:00", "label": "2:00 PM"},
            {"time": "15:00", "label": "3:00 PM"},
            {"time": "16:00", "label": "4:00 PM"}
        ]
    },
    "activitySpecific": {}
}'::JSONB) ON CONFLICT (id) DO NOTHING;

-- Add helpful comment
COMMENT ON TABLE booking_configuration IS 'Stores admin configuration for demand-driven booking system including date restrictions, time slots, and activity-specific settings';

-- Grant necessary permissions
GRANT SELECT ON booking_configuration TO authenticated;
GRANT ALL ON booking_configuration TO service_role;

-- Create function to update configuration timestamp
CREATE OR REPLACE FUNCTION update_booking_config_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to auto-update timestamp
CREATE TRIGGER update_booking_configuration_timestamp
    BEFORE UPDATE ON booking_configuration
    FOR EACH ROW
    EXECUTE FUNCTION update_booking_config_timestamp();