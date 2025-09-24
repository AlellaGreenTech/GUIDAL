-- Accommodations Table for Overnight Visits
-- Run this in Supabase SQL Editor with admin permissions

-- Create accommodations table with flexible schema
CREATE TABLE IF NOT EXISTS accommodations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,

    -- Basic information
    name TEXT NOT NULL,
    nickname TEXT, -- AKA name (e.g., "The Tent", "The Caravan")
    description TEXT,

    -- Physical specifications
    size_m2 NUMERIC(8,2), -- Size in square meters

    -- Capacity information
    max_adults INTEGER DEFAULT 0,
    max_children INTEGER DEFAULT 0,
    max_total_occupancy INTEGER DEFAULT 0,

    -- Room configuration (flexible JSON for different layouts)
    room_configuration JSONB DEFAULT '{}', -- e.g., {"bedrooms": 2, "bathrooms": 1, "common_areas": 1}
    sleeping_arrangements JSONB DEFAULT '{}', -- e.g., {"double_beds": 1, "single_beds": 2, "bunk_beds": 0}

    -- Amenities (flexible array for easy filtering)
    amenities TEXT[] DEFAULT '{}', -- e.g., ["heating", "air_conditioning", "internet", "kitchen"]

    -- Utilities and features
    has_electricity BOOLEAN DEFAULT false,
    has_heating BOOLEAN DEFAULT false,
    has_air_conditioning BOOLEAN DEFAULT false,
    has_internet BOOLEAN DEFAULT false,
    has_kitchen BOOLEAN DEFAULT false,
    has_bathroom BOOLEAN DEFAULT false,
    has_shower BOOLEAN DEFAULT false,
    has_hot_water BOOLEAN DEFAULT false,

    -- Pricing and availability
    price_per_night NUMERIC(10,2) DEFAULT 0,
    price_per_person_per_night NUMERIC(10,2) DEFAULT 0,
    is_available BOOLEAN DEFAULT true,

    -- Images and media
    primary_image TEXT, -- Main accommodation image
    gallery_images TEXT[] DEFAULT '{}', -- Additional images

    -- Seasonal information
    available_seasons TEXT[] DEFAULT '{"spring", "summer", "autumn", "winter"}',
    climate_notes TEXT, -- e.g., "cool in summer, warm in winter"

    -- Booking and management
    requires_advance_booking BOOLEAN DEFAULT true,
    minimum_stay_nights INTEGER DEFAULT 1,
    maximum_stay_nights INTEGER DEFAULT 30,
    cleaning_time_hours INTEGER DEFAULT 2, -- Time needed between bookings

    -- Administrative fields
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'maintenance', 'retired')),
    internal_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add RLS (Row Level Security)
ALTER TABLE accommodations ENABLE ROW LEVEL SECURITY;

-- Allow public to view available accommodations
CREATE POLICY "Anyone can view available accommodations" ON accommodations
    FOR SELECT USING (is_available = true AND status = 'active');

-- Allow admins to manage all accommodations
CREATE POLICY "Admins can manage all accommodations" ON accommodations
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.user_type IN ('admin', 'staff')
        )
    );

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_accommodations_status ON accommodations(status);
CREATE INDEX IF NOT EXISTS idx_accommodations_available ON accommodations(is_available);
CREATE INDEX IF NOT EXISTS idx_accommodations_capacity ON accommodations(max_total_occupancy);
CREATE INDEX IF NOT EXISTS idx_accommodations_amenities ON accommodations USING gin(amenities);

-- Add trigger for updated_at
CREATE OR REPLACE FUNCTION update_accommodations_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_accommodations_updated_at
    BEFORE UPDATE ON accommodations
    FOR EACH ROW
    EXECUTE FUNCTION update_accommodations_updated_at();

-- Insert initial accommodation data
INSERT INTO accommodations (
    name,
    nickname,
    description,
    size_m2,
    max_adults,
    max_children,
    max_total_occupancy,
    room_configuration,
    sleeping_arrangements,
    amenities,
    has_electricity,
    has_heating,
    has_air_conditioning,
    has_internet,
    has_kitchen,
    has_bathroom,
    has_shower,
    has_hot_water,
    climate_notes,
    primary_image,
    price_per_night
) VALUES
(
    'Fort Flappy',
    'The Tent',
    'Military field tent with flexible configuration. Can be set up as up to 4 separate bedrooms or one large communal space.',
    30.00,
    6,
    12,
    12,
    '{"bedrooms": "configurable", "max_bedrooms": 4, "can_be_open_space": true}',
    '{"configuration": "flexible", "max_adults": 6, "max_children": 12, "setup_options": ["4 bedrooms", "1 large space"]}',
    ARRAY['heating', 'air_conditioning', 'electricity', 'fast_internet', 'configurable_layout'],
    true,
    true,
    true,
    true,
    false,
    false,
    false,
    false,
    'Climate controlled with heating and AC',
    'images/accommodations/fort-flappy.jpg',
    0.00
),
(
    'Liberation Lodge',
    'The Caravan',
    'Comfortable caravan with 2 bedrooms, kitchenette, and full bathroom facilities. Perfect for smaller groups or families.',
    null, -- Size not specified
    4,
    4,
    4,
    '{"bedrooms": 2, "bathrooms": 1, "kitchen": 1, "living_area": 1}',
    '{"small_bedroom": {"single_beds": 2, "desk": true, "alternative": "2 single beds"}, "large_bedroom": {"double_bed": 1}}',
    ARRAY['kitchenette', 'bathroom', 'shower', 'hot_water', 'gas_stove', 'electricity'],
    true,
    false,
    false,
    false,
    true,
    true,
    true,
    true,
    'Standard caravan climate',
    'images/accommodations/liberation-lodge.jpg',
    0.00
),
(
    'Dirt Cheap Cabin',
    'The Mud House',
    'Eco-friendly mud house construction. Small but comfortable space with excellent natural climate control.',
    12.00,
    2,
    2,
    2,
    '{"bedrooms": 1, "living_area": 1}',
    '{"beds": "configurable", "max_occupancy": 2}',
    ARRAY['air_conditioning', 'internet', 'natural_climate_control', 'eco_friendly'],
    true,
    false,
    true,
    true,
    false,
    false,
    false,
    false,
    'Cool in summer, warm in winter due to mud construction',
    'images/accommodations/dirt-cheap-cabin.jpg',
    0.00
);

-- Create a view for easy accommodation browsing
CREATE OR REPLACE VIEW available_accommodations AS
SELECT
    a.*,
    CASE
        WHEN a.max_children > a.max_adults THEN 'family_friendly'
        WHEN a.max_adults >= 4 THEN 'group_suitable'
        ELSE 'couples_small_groups'
    END AS accommodation_type,

    -- Calculate total amenity score for sorting
    array_length(a.amenities, 1) AS amenity_count,

    -- Format capacity description
    CASE
        WHEN a.max_children > 0 AND a.max_adults > 0 THEN
            format('Up to %s adults or %s children (max %s total)',
                   a.max_adults, a.max_children, a.max_total_occupancy)
        WHEN a.max_adults > 0 THEN
            format('Up to %s people', a.max_adults)
        ELSE
            format('Up to %s people', a.max_total_occupancy)
    END AS capacity_description

FROM accommodations a
WHERE a.is_available = true
AND a.status = 'active'
ORDER BY a.max_total_occupancy DESC, a.amenity_count DESC;

-- Grant permissions
GRANT SELECT, INSERT ON accommodations TO anon;
GRANT ALL ON accommodations TO authenticated;
GRANT SELECT ON available_accommodations TO anon, authenticated;

-- Show the created accommodations
SELECT
    name,
    nickname,
    size_m2,
    max_adults,
    max_children,
    max_total_occupancy,
    amenities,
    capacity_description
FROM available_accommodations;