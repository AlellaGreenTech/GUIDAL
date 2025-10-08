-- Create table for family visit requests

CREATE TABLE IF NOT EXISTS family_visit_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    contact_name TEXT NOT NULL,
    contact_email TEXT NOT NULL,
    contact_phone TEXT NOT NULL,
    preferred_date DATE NOT NULL,
    alternate_date DATE,
    number_of_adults INTEGER NOT NULL DEFAULT 1,
    number_of_children INTEGER DEFAULT 0,
    children_ages TEXT,
    interests TEXT[],
    special_needs TEXT,
    additional_comments TEXT,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'completed', 'cancelled')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add indexes
CREATE INDEX IF NOT EXISTS idx_family_visit_requests_email ON family_visit_requests(contact_email);
CREATE INDEX IF NOT EXISTS idx_family_visit_requests_preferred_date ON family_visit_requests(preferred_date);
CREATE INDEX IF NOT EXISTS idx_family_visit_requests_status ON family_visit_requests(status);

-- Enable RLS
ALTER TABLE family_visit_requests ENABLE ROW LEVEL SECURITY;

-- Allow public insert (for form submissions)
CREATE POLICY "Allow public insert" ON family_visit_requests
    FOR INSERT TO anon
    WITH CHECK (true);

-- Allow authenticated users to view all
CREATE POLICY "Allow authenticated read" ON family_visit_requests
    FOR SELECT TO authenticated
    USING (true);

-- Allow authenticated users to update
CREATE POLICY "Allow authenticated update" ON family_visit_requests
    FOR UPDATE TO authenticated
    USING (true);

COMMENT ON TABLE family_visit_requests IS 'Family farm visit booking requests';
COMMENT ON COLUMN family_visit_requests.interests IS 'Array of topics the family is interested in';
COMMENT ON COLUMN family_visit_requests.children_ages IS 'Comma-separated ages of children';
