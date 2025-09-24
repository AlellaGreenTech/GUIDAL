-- Add Overnight Visit Support to Visits Table
-- Run this in Supabase SQL Editor with admin permissions

-- Add new columns to support different visit types and overnight stays
ALTER TABLE visits ADD COLUMN IF NOT EXISTS visit_type TEXT DEFAULT 'school_day_trip' CHECK (visit_type IN (
    'school_day_trip',      -- Traditional day field trip
    'school_overnight',     -- Overnight school field trip
    'individual_workshops', -- Individual workshop bookings
    'event',               -- Special events
    'special_lunch'        -- Special lunch experiences
));

-- Add overnight-specific fields
ALTER TABLE visits ADD COLUMN IF NOT EXISTS number_of_nights INTEGER DEFAULT 0;
ALTER TABLE visits ADD COLUMN IF NOT EXISTS arrival_date_time TIMESTAMP WITH TIME ZONE;
ALTER TABLE visits ADD COLUMN IF NOT EXISTS departure_date_time TIMESTAMP WITH TIME ZONE;

-- Add contacts table for better contact management
CREATE TABLE IF NOT EXISTS contacts (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    visit_id UUID REFERENCES visits(id) ON DELETE CASCADE,
    contact_type TEXT NOT NULL CHECK (contact_type IN ('organizer', 'lead_teacher', 'emergency')),
    full_name TEXT NOT NULL,
    email TEXT,
    phone TEXT,
    position TEXT,
    is_primary BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add RLS for contacts table
ALTER TABLE contacts ENABLE ROW LEVEL SECURITY;

-- Contacts policies
CREATE POLICY "Anyone can insert contacts" ON contacts
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can view contacts for their visits" ON contacts
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM visits
            WHERE visits.id = contacts.visit_id
            AND visits.contact_email = auth.jwt() ->> 'email'
        )
    );

CREATE POLICY "Admins can manage all contacts" ON contacts
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.user_type IN ('admin', 'staff')
        )
    );

-- Add trigger for contacts updated_at
CREATE OR REPLACE FUNCTION update_contacts_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_contacts_updated_at
    BEFORE UPDATE ON contacts
    FOR EACH ROW
    EXECUTE FUNCTION update_contacts_updated_at();

-- Update existing visit_format options to include overnight options
-- Note: We keep backward compatibility by not changing existing enum values
-- The visit_type field will be the primary way to distinguish visit types

-- Add helpful indexes
CREATE INDEX IF NOT EXISTS idx_visits_visit_type ON visits(visit_type);
CREATE INDEX IF NOT EXISTS idx_visits_arrival_date ON visits(arrival_date_time);
CREATE INDEX IF NOT EXISTS idx_visits_departure_date ON visits(departure_date_time);
CREATE INDEX IF NOT EXISTS idx_contacts_visit_id ON contacts(visit_id);
CREATE INDEX IF NOT EXISTS idx_contacts_type ON contacts(contact_type);

-- Create updated view for visits with contacts
CREATE OR REPLACE VIEW visits_with_contacts AS
SELECT
    v.*,
    COALESCE(
        json_agg(
            json_build_object(
                'id', c.id,
                'contact_type', c.contact_type,
                'full_name', c.full_name,
                'email', c.email,
                'phone', c.phone,
                'position', c.position,
                'is_primary', c.is_primary
            )
            ORDER BY c.contact_type, c.is_primary DESC
        ) FILTER (WHERE c.id IS NOT NULL),
        '[]'::json
    ) AS contacts
FROM visits v
LEFT JOIN contacts c ON c.visit_id = v.id
GROUP BY v.id;

-- Grant permissions
GRANT SELECT, INSERT ON contacts TO anon;
GRANT ALL ON contacts TO authenticated;
GRANT SELECT ON visits_with_contacts TO anon, authenticated;

-- Verify the changes
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'visits'
AND column_name IN ('visit_type', 'number_of_nights', 'arrival_date_time', 'departure_date_time')
ORDER BY column_name;