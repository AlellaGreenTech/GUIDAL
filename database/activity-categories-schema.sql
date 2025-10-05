-- Activity Categories Schema
-- This creates a table for activity categories (e.g., Permaculture, Robotics, etc.)
-- and links them to activities via a many-to-many relationship

-- Create activity_categories table
CREATE TABLE IF NOT EXISTS public.activity_categories (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  slug TEXT NOT NULL UNIQUE,
  description TEXT,
  image_url TEXT,
  display_order INTEGER DEFAULT 0,
  active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create junction table for many-to-many relationship between activities and categories
CREATE TABLE IF NOT EXISTS public.activity_category_links (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  activity_id UUID REFERENCES public.activities(id) ON DELETE CASCADE NOT NULL,
  category_id UUID REFERENCES public.activity_categories(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(activity_id, category_id)
);

-- Add indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_activity_categories_slug ON public.activity_categories(slug);
CREATE INDEX IF NOT EXISTS idx_activity_categories_active ON public.activity_categories(active);
CREATE INDEX IF NOT EXISTS idx_activity_category_links_activity ON public.activity_category_links(activity_id);
CREATE INDEX IF NOT EXISTS idx_activity_category_links_category ON public.activity_category_links(category_id);

-- Insert sample categories with Unsplash images
INSERT INTO public.activity_categories (name, slug, description, image_url, display_order) VALUES
  ('Electronics for Sustainability', 'electronics', 'Learn to build electronic solutions for environmental challenges', 'https://images.unsplash.com/photo-1518770660439-4636190af475?w=600&h=400&fit=crop', 1),
  ('Permaculture', 'permaculture', 'Discover sustainable agriculture and ecosystem design principles', 'https://images.unsplash.com/photo-1464226184884-fa280b87c399?w=600&h=400&fit=crop', 2),
  ('Robotics & Gardening', 'robotics', 'Explore automated farming and robotic solutions for agriculture', 'https://images.unsplash.com/photo-1485827404703-89b55fcc595e?w=600&h=400&fit=crop', 3),
  ('Renewable Energy', 'renewable-energy', 'Harness solar, wind, and other clean energy sources', 'https://images.unsplash.com/photo-1509391366360-2e959784a276?w=600&h=400&fit=crop', 4),
  ('Sustainable Construction', 'construction', 'Build with earth, natural materials, and green techniques', 'https://images.unsplash.com/photo-1621905252507-b35492cc74b4?w=600&h=400&fit=crop', 5),
  ('Citizen Science', 'citizen-science', 'Participate in scientific research and data collection', 'https://images.unsplash.com/photo-1532094349884-543bc11b234d?w=600&h=400&fit=crop', 6),
  ('Green Crafts', 'green-crafts', 'Create beautiful items from recycled and natural materials', 'https://images.unsplash.com/photo-1452860606245-08befc0ff44b?w=600&h=400&fit=crop', 7),
  ('Wine & Produce', 'wine-produce', 'Learn about organic viticulture and local food production', 'https://images.unsplash.com/photo-1506377247377-2a5b3b417ebb?w=600&h=400&fit=crop', 8),
  ('Volunteering', 'volunteering', 'Give back to the community and environment through service', 'https://images.unsplash.com/photo-1559027615-cd4628902d4a?w=600&h=400&fit=crop', 9),
  ('Green Engineering', 'green-engineering', 'Design and build sustainable engineering solutions', 'https://images.unsplash.com/photo-1581094794329-c8112a89af12?w=600&h=400&fit=crop', 10)
ON CONFLICT (slug) DO UPDATE SET
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  image_url = EXCLUDED.image_url,
  display_order = EXCLUDED.display_order,
  updated_at = NOW();

-- Enable RLS (Row Level Security)
ALTER TABLE public.activity_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity_category_links ENABLE ROW LEVEL SECURITY;

-- Create policies for public read access
CREATE POLICY "Activity categories are viewable by everyone"
  ON public.activity_categories FOR SELECT
  USING (active = true);

CREATE POLICY "Activity category links are viewable by everyone"
  ON public.activity_category_links FOR SELECT
  USING (true);

-- Create policies for admin/staff insert, update, delete
CREATE POLICY "Only admins can insert activity categories"
  ON public.activity_categories FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid()
      AND user_type IN ('admin', 'staff')
    )
  );

CREATE POLICY "Only admins can update activity categories"
  ON public.activity_categories FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid()
      AND user_type IN ('admin', 'staff')
    )
  );

CREATE POLICY "Only admins can delete activity categories"
  ON public.activity_categories FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid()
      AND user_type IN ('admin', 'staff')
    )
  );

CREATE POLICY "Only admins can manage category links"
  ON public.activity_category_links FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid()
      AND user_type IN ('admin', 'staff')
    )
  );
