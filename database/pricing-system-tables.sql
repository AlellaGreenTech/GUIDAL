-- Pricing System Tables
-- Standard pricing and school-specific overrides

-- Standard pricing configuration
CREATE TABLE IF NOT EXISTS pricing_config (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,

    -- Standard pricing
    visit_price_child DECIMAL(10,2) NOT NULL DEFAULT 10.00,
    visit_price_adult DECIMAL(10,2) NOT NULL DEFAULT 10.00,
    meal_price_child DECIMAL(10,2) NOT NULL DEFAULT 10.00,
    meal_price_adult DECIMAL(10,2) NOT NULL DEFAULT 10.00,

    -- VAT settings
    vat_rate DECIMAL(5,2) NOT NULL DEFAULT 21.00, -- 21%

    -- Metadata
    effective_from TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Only one active pricing config at a time
    is_active BOOLEAN DEFAULT true
);

-- School-specific pricing overrides
CREATE TABLE IF NOT EXISTS school_pricing_overrides (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,

    -- School identification
    school_name TEXT NOT NULL,
    school_email TEXT, -- Optional: link to specific contact

    -- Override pricing (NULL means use standard pricing)
    visit_price_child DECIMAL(10,2),
    visit_price_adult DECIMAL(10,2),
    meal_price_child DECIMAL(10,2),
    meal_price_adult DECIMAL(10,2),

    -- Special terms
    discount_percentage DECIMAL(5,2), -- Optional: 10% = 10.00
    notes TEXT, -- Special agreements, bulk discounts, etc.

    -- Validity period
    valid_from TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    valid_until TIMESTAMP WITH TIME ZONE, -- NULL = no expiry

    -- Metadata
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT true,

    -- Unique constraint per school (only one active override)
    UNIQUE(school_name, is_active) DEFERRABLE INITIALLY DEFERRED
);

-- Invoice generation tracking
CREATE TABLE IF NOT EXISTS invoices (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,

    -- Invoice identification
    invoice_number TEXT UNIQUE NOT NULL, -- Format: 2024-11-27b
    invoice_date DATE DEFAULT CURRENT_DATE,

    -- Link to visit request
    visit_request_id UUID, -- FK to visit_requests table when created

    -- School information
    school_name TEXT NOT NULL,
    school_address TEXT,
    contact_person TEXT,
    contact_email TEXT,

    -- Activity details
    activity_date DATE,
    visit_description TEXT DEFAULT 'Tour & Activities at Can Picard',

    -- Participant counts
    student_count INTEGER NOT NULL DEFAULT 0,
    adult_count INTEGER NOT NULL DEFAULT 0,
    meal_student_count INTEGER NOT NULL DEFAULT 0,
    meal_adult_count INTEGER NOT NULL DEFAULT 0,

    -- Pricing used (snapshot at time of invoice)
    visit_price_child DECIMAL(10,2) NOT NULL,
    visit_price_adult DECIMAL(10,2) NOT NULL,
    meal_price_child DECIMAL(10,2) NOT NULL,
    meal_price_adult DECIMAL(10,2) NOT NULL,

    -- Calculations
    visit_subtotal DECIMAL(10,2) NOT NULL,
    meal_subtotal DECIMAL(10,2) NOT NULL,
    subtotal DECIMAL(10,2) NOT NULL,
    vat_rate DECIMAL(5,2) NOT NULL,
    vat_amount DECIMAL(10,2) NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,

    -- Payment tracking
    status TEXT DEFAULT 'pending' CHECK (status IN ('draft', 'sent', 'paid', 'overdue', 'cancelled')),
    payment_date DATE,
    payment_method TEXT,
    payment_reference TEXT,

    -- Metadata
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add RLS policies
ALTER TABLE pricing_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE school_pricing_overrides ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;

-- Pricing config policies
CREATE POLICY "Admins can manage pricing config" ON pricing_config
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM user_profiles
            WHERE user_profiles.user_id = auth.uid()
            AND user_profiles.role IN ('admin', 'staff')
        )
    );

-- School pricing overrides policies
CREATE POLICY "Admins can manage school pricing" ON school_pricing_overrides
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM user_profiles
            WHERE user_profiles.user_id = auth.uid()
            AND user_profiles.role IN ('admin', 'staff')
        )
    );

-- Invoice policies
CREATE POLICY "Admins can manage invoices" ON invoices
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM user_profiles
            WHERE user_profiles.user_id = auth.uid()
            AND user_profiles.role IN ('admin', 'staff')
        )
    );

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_pricing_config_active ON pricing_config(is_active);
CREATE INDEX IF NOT EXISTS idx_school_pricing_school_name ON school_pricing_overrides(school_name);
CREATE INDEX IF NOT EXISTS idx_school_pricing_active ON school_pricing_overrides(is_active);
CREATE INDEX IF NOT EXISTS idx_invoices_number ON invoices(invoice_number);
CREATE INDEX IF NOT EXISTS idx_invoices_school ON invoices(school_name);
CREATE INDEX IF NOT EXISTS idx_invoices_status ON invoices(status);
CREATE INDEX IF NOT EXISTS idx_invoices_date ON invoices(invoice_date);

-- Update triggers
CREATE TRIGGER update_pricing_config_updated_at
    BEFORE UPDATE ON pricing_config
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_school_pricing_updated_at
    BEFORE UPDATE ON school_pricing_overrides
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_invoices_updated_at
    BEFORE UPDATE ON invoices
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Insert default pricing configuration
INSERT INTO pricing_config (
    visit_price_child,
    visit_price_adult,
    meal_price_child,
    meal_price_adult,
    vat_rate,
    is_active
) VALUES (
    10.00, -- €10 per child visit
    10.00, -- €10 per adult visit
    10.00, -- €10 per child meal
    10.00, -- €10 per adult meal
    21.00, -- 21% VAT
    true
) ON CONFLICT DO NOTHING;

-- Grant permissions
GRANT SELECT, INSERT, UPDATE ON pricing_config TO authenticated;
GRANT SELECT, INSERT, UPDATE ON school_pricing_overrides TO authenticated;
GRANT SELECT, INSERT, UPDATE ON invoices TO authenticated;