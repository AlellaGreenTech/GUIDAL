-- Expand visit types to include workshops and special events
-- This adds support for workshops, special lunches, and events

-- Add new visit types
ALTER TABLE visits DROP CONSTRAINT IF EXISTS visits_visit_type_check;
ALTER TABLE visits ADD CONSTRAINT visits_visit_type_check CHECK (visit_type IN (
    'school-visit',
    'corporate-visit',
    'family-visit',
    'individual-visit',
    'homeschool-visit',
    'university-visit',
    'workshop',
    'special-lunch',
    'event',
    'other'
));

-- Add new visit formats for workshops and events
ALTER TABLE visits DROP CONSTRAINT IF EXISTS visits_visit_format_check;
ALTER TABLE visits ADD CONSTRAINT visits_visit_format_check CHECK (visit_format IN (
    'full-day-with-lunch',
    'morning-with-lunch',
    'morning-no-lunch',
    'afternoon-session',
    'workshop-2hr',
    'workshop-4hr',
    'lunch-only',
    'evening-event',
    'custom'
));

-- Add new educational focuses for workshops
ALTER TABLE visits DROP CONSTRAINT IF EXISTS visits_educational_focus_check;
ALTER TABLE visits ADD CONSTRAINT visits_educational_focus_check CHECK (educational_focus IN (
    'hands-on-permaculture',
    'real-world-science',
    'balanced-mix',
    'iot-automation',
    'sustainability',
    'cooking-workshop',
    'gardening-workshop',
    'technology-workshop',
    'family-experience',
    'team-building',
    'other'
));

-- Create pricing tiers table for different event types
CREATE TABLE IF NOT EXISTS pricing_tiers (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    tier_name TEXT NOT NULL UNIQUE,
    visit_type TEXT NOT NULL,
    visit_format TEXT,
    child_visit_price DECIMAL(10,2) NOT NULL DEFAULT 0,
    adult_visit_price DECIMAL(10,2) NOT NULL DEFAULT 0,
    child_meal_price DECIMAL(10,2) NOT NULL DEFAULT 0,
    adult_meal_price DECIMAL(10,2) NOT NULL DEFAULT 0,
    minimum_group_size INTEGER DEFAULT 1,
    maximum_group_size INTEGER DEFAULT 100,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert default pricing tiers
INSERT INTO pricing_tiers (tier_name, visit_type, visit_format, child_visit_price, adult_visit_price, child_meal_price, adult_meal_price, minimum_group_size, maximum_group_size, description) VALUES

-- School visit pricing (existing)
('School Visits', 'school-visit', NULL, 15.00, 25.00, 8.00, 12.00, 10, 70, 'Standard school group visits'),

-- Workshop pricing
('Technology Workshop', 'workshop', 'workshop-2hr', 20.00, 30.00, 0.00, 0.00, 5, 20, '2-hour hands-on technology workshops'),
('Permaculture Workshop', 'workshop', 'workshop-4hr', 35.00, 45.00, 8.00, 12.00, 5, 25, '4-hour permaculture workshops with lunch'),
('Cooking Workshop', 'workshop', 'workshop-2hr', 25.00, 35.00, 0.00, 0.00, 6, 15, 'Farm-to-table cooking workshops'),

-- Special lunch pricing
('Special Lunch', 'special-lunch', 'lunch-only', 0.00, 0.00, 15.00, 20.00, 4, 50, 'Special lunch experiences only'),
('Lunch & Tour', 'special-lunch', 'morning-with-lunch', 10.00, 15.00, 15.00, 20.00, 4, 30, 'Tour with special lunch'),

-- Family visit pricing
('Family Experience', 'family-visit', 'afternoon-session', 12.00, 18.00, 8.00, 12.00, 2, 8, 'Family-friendly afternoon experiences'),

-- Corporate/team building
('Corporate Team Building', 'corporate-visit', 'custom', 40.00, 40.00, 15.00, 20.00, 8, 40, 'Corporate team building experiences'),

-- Individual visits
('Individual Visit', 'individual-visit', 'custom', 25.00, 25.00, 12.00, 15.00, 1, 4, 'Individual or small group visits');

-- Add pricing tier reference to visits table
ALTER TABLE visits ADD COLUMN IF NOT EXISTS pricing_tier_id UUID REFERENCES pricing_tiers(id);

-- Create trigger to auto-update pricing_tiers updated_at
CREATE OR REPLACE FUNCTION update_pricing_tiers_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_pricing_tiers_updated_at
    BEFORE UPDATE ON pricing_tiers
    FOR EACH ROW
    EXECUTE FUNCTION update_pricing_tiers_updated_at();

-- Show the new pricing structure
SELECT 'Enhanced pricing tiers created!' as info;
SELECT tier_name, visit_type, visit_format, child_visit_price, adult_visit_price, child_meal_price, adult_meal_price
FROM pricing_tiers
ORDER BY visit_type, tier_name;