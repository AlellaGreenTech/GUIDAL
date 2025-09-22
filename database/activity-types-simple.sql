-- Activity Types Table
-- Required for the activities system

CREATE TABLE IF NOT EXISTS activity_types (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  slug TEXT NOT NULL UNIQUE,
  description TEXT,
  color TEXT DEFAULT '#388e3c',
  icon TEXT
);

-- Insert initial activity types
INSERT INTO activity_types (name, slug, description, color, icon)
SELECT * FROM (VALUES
  ('School Visits', 'school-visits', 'Educational visits for schools and groups', '#2e7d32', '🏫'),
  ('Workshops', 'workshops', 'Hands-on learning workshops', '#388e3c', '🔧'),
  ('Events', 'events', 'Special events and community gatherings', '#4caf50', '🌱'),
  ('Special Lunches', 'lunches', 'Culinary experiences with educational components', '#66bb6a', '🍷'),
  ('Camps', 'camps', 'Multi-day learning experiences', '#81c784', '🏕️')
) AS t(name, slug, description, color, icon)
WHERE NOT EXISTS (SELECT 1 FROM activity_types WHERE activity_types.slug = t.slug);

-- Grant permissions
GRANT SELECT ON activity_types TO anon, authenticated;
