-- Add Top-Level Activity Categories
-- These are high-level categories that users primarily care about

-- Add the four main top-level categories
INSERT INTO public.activity_categories (name, slug, description, image_url, display_order) VALUES
  ('School Field Trip', 'school-field-trip', 'Educational group visits for schools with hands-on learning activities', 'https://images.unsplash.com/photo-1503676260728-1c00da094a0b?w=600&h=400&fit=crop', -4),
  ('Family Farm Visit', 'family-farm-visit', 'Family-friendly farm experiences and activities for all ages', 'https://images.unsplash.com/photo-1560493676-04071c5f467b?w=600&h=400&fit=crop', -3),
  ('Events', 'events', 'Special events, seasonal celebrations, and community gatherings', 'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=600&h=400&fit=crop', -2),
  ('Special Lunches', 'special-lunches', 'Farm-to-table dining experiences and culinary activities', 'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=600&h=400&fit=crop', -1)
ON CONFLICT (slug) DO UPDATE SET
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  image_url = EXCLUDED.image_url,
  display_order = EXCLUDED.display_order;

-- Show all categories ordered
SELECT name, slug, display_order
FROM public.activity_categories
ORDER BY display_order;
