-- GUIDAL Complete Database Schema for Supabase
-- This file contains all database setup in the correct dependency order
-- Run this single file in your Supabase SQL editor

-- =====================================================
-- SECTION 1: CORE DATABASE SCHEMA
-- =====================================================

-- Enable necessary extensions
create extension if not exists "uuid-ossp";

-- Schools table (must be created first due to foreign key dependency)
create table if not exists public.schools (
  id uuid default uuid_generate_v4() primary key,
  name text not null,
  address text,
  contact_person text,
  contact_email text,
  contact_phone text,
  website text,
  active boolean default true,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- Users table (extends Supabase auth.users)
create table if not exists public.profiles (
  id uuid references auth.users on delete cascade primary key,
  email text unique not null,
  full_name text,
  avatar_url text,
  user_type text not null default 'student' check (user_type in ('student', 'teacher', 'admin', 'staff', 'guest')),
  school_id uuid references public.schools(id),
  credits integer default 0,
  phone text,
  emergency_contact text,
  dietary_restrictions text,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- Activity types for better organization
create table if not exists public.activity_types (
  id uuid default uuid_generate_v4() primary key,
  name text not null unique,
  slug text not null unique,
  description text,
  color text default '#388e3c',
  icon text,
  active boolean default true,
  created_at timestamp with time zone default now()
);

-- Main activities table
create table if not exists public.activities (
  id uuid default uuid_generate_v4() primary key,
  title text not null,
  slug text not null unique,
  description text,
  activity_type_id uuid references public.activity_types(id) not null,
  date_time timestamp with time zone,
  duration_minutes integer,
  location text,
  max_participants integer,
  current_participants integer default 0,
  credits_required integer default 0,
  credits_earned integer default 0,
  price numeric(10,2) default 0,
  featured_image text,
  images text[] default '{}',
  status text default 'published' check (status in ('draft', 'published', 'cancelled', 'completed')),
  requires_login boolean default false,
  age_min integer,
  age_max integer,
  difficulty_level text check (difficulty_level in ('beginner', 'intermediate', 'advanced')),
  special_requirements text,
  what_to_bring text,
  learning_objectives text[],
  instructor text,
  contact_email text,
  contact_phone text,
  created_by uuid references public.profiles(id),
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- Activity registrations/bookings
create table if not exists public.activity_registrations (
  id uuid default uuid_generate_v4() primary key,
  activity_id uuid references public.activities(id) on delete cascade not null,
  user_id uuid references public.profiles(id) on delete cascade not null,
  registration_date timestamp with time zone default now(),
  status text default 'registered' check (status in ('registered', 'confirmed', 'attended', 'no_show', 'cancelled')),
  credits_used integer default 0,
  payment_status text default 'pending' check (payment_status in ('pending', 'paid', 'refunded', 'cancelled')),
  notes text,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now(),
  unique(activity_id, user_id)
);

-- Note: School visits are handled in the unified 'visits' table
-- No separate school_visits table needed - school visits are just a visit_format type

-- Credit transactions
create table if not exists public.credit_transactions (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  activity_id uuid references public.activities(id),
  transaction_type text not null check (transaction_type in ('earned', 'spent', 'awarded', 'deducted')),
  amount integer not null,
  description text,
  created_at timestamp with time zone default now()
);

-- Blog posts for content management
create table if not exists public.blog_posts (
  id uuid default uuid_generate_v4() primary key,
  title text not null,
  slug text not null unique,
  excerpt text,
  content text not null,
  featured_image text,
  author_id uuid references public.profiles(id) not null,
  published boolean default false,
  published_at timestamp with time zone,
  tags text[] default '{}',
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- Product catalog for store
create table if not exists public.products (
  id uuid default uuid_generate_v4() primary key,
  name text not null,
  slug text not null unique,
  description text,
  price numeric(10,2) not null,
  sale_price numeric(10,2),
  stock_quantity integer default 0,
  images text[] default '{}',
  category text,
  tags text[] default '{}',
  active boolean default true,
  digital boolean default false,
  download_url text,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- Orders for store purchases
create table if not exists public.orders (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.profiles(id) not null,
  order_number text unique not null,
  status text default 'pending' check (status in ('pending', 'confirmed', 'shipped', 'delivered', 'cancelled')),
  total_amount numeric(10,2) not null,
  shipping_address jsonb,
  billing_address jsonb,
  payment_method text,
  payment_status text default 'pending',
  notes text,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- Order items
create table if not exists public.order_items (
  id uuid default uuid_generate_v4() primary key,
  order_id uuid references public.orders(id) on delete cascade not null,
  product_id uuid references public.products(id) not null,
  quantity integer not null default 1,
  unit_price numeric(10,2) not null,
  total_price numeric(10,2) not null,
  created_at timestamp with time zone default now()
);

-- =====================================================
-- SECTION 2: NOTIFICATIONS SYSTEM
-- =====================================================

-- Add notifications table for user notifications
create table if not exists public.notifications (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  title text not null,
  message text not null,
  type text default 'info' check (type in ('info', 'success', 'warning', 'error')),
  action_url text,
  is_read boolean default false,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- =====================================================
-- SECTION 3: FUNCTIONS AND TRIGGERS
-- =====================================================

-- Functions for automatic timestamp updates
create or replace function public.handle_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

-- Database functions for participant count management
create or replace function increment_participants(activity_id uuid)
returns void as $$
begin
  update public.activities
  set current_participants = current_participants + 1
  where id = activity_id;
end;
$$ language plpgsql security definer;

create or replace function decrement_participants(activity_id uuid)
returns void as $$
begin
  update public.activities
  set current_participants = greatest(current_participants - 1, 0)
  where id = activity_id;
end;
$$ language plpgsql security definer;

-- =====================================================
-- SECTION 4: INDEXES FOR PERFORMANCE
-- =====================================================

-- Create indexes for performance
create index if not exists idx_profiles_school_id on public.profiles(school_id);
create index if not exists idx_profiles_user_type on public.profiles(user_type);
create index if not exists idx_activities_type on public.activities(activity_type_id);
create index if not exists idx_activities_date on public.activities(date_time);
create index if not exists idx_activities_status on public.activities(status);
create index if not exists idx_registrations_activity on public.activity_registrations(activity_id);
create index if not exists idx_registrations_user on public.activity_registrations(user_id);
create index if not exists idx_credit_transactions_user on public.credit_transactions(user_id);
create index if not exists idx_blog_posts_published on public.blog_posts(published, published_at);
create index if not exists idx_notifications_user_id on public.notifications(user_id);
create index if not exists idx_notifications_is_read on public.notifications(is_read);

-- =====================================================
-- SECTION 5: ROW LEVEL SECURITY (RLS)
-- =====================================================

-- Set up Row Level Security (RLS)
alter table public.profiles enable row level security;
alter table public.schools enable row level security;
alter table public.activities enable row level security;
alter table public.activity_registrations enable row level security;
-- school_visits table removed - using unified visits table instead
alter table public.credit_transactions enable row level security;
alter table public.blog_posts enable row level security;
alter table public.products enable row level security;
alter table public.orders enable row level security;
alter table public.notifications enable row level security;

-- =====================================================
-- SECTION 6: RLS POLICIES
-- =====================================================

-- Basic RLS policies (can be refined later)
drop policy if exists "Public profiles are viewable by everyone" on public.profiles;
create policy "Public profiles are viewable by everyone" on public.profiles for select using (true);

drop policy if exists "Users can update own profile" on public.profiles;
create policy "Users can update own profile" on public.profiles for update using (auth.uid() = id);

drop policy if exists "Activities are viewable by everyone" on public.activities;
create policy "Activities are viewable by everyone" on public.activities for select using (status = 'published');

drop policy if exists "Only admins can modify activities" on public.activities;
drop policy if exists "Admins can insert activities" on public.activities;
drop policy if exists "Admins can update activities" on public.activities;
drop policy if exists "Admins can delete activities" on public.activities;

create policy "Admins can insert activities" on public.activities
  for insert
  with check (
    exists (select 1 from public.profiles where profiles.id = auth.uid() and profiles.user_type = 'admin')
  );

create policy "Admins can update activities" on public.activities
  for update
  using (
    exists (select 1 from public.profiles where profiles.id = auth.uid() and profiles.user_type = 'admin')
  );

create policy "Admins can delete activities" on public.activities
  for delete
  using (
    exists (select 1 from public.profiles where profiles.id = auth.uid() and profiles.user_type = 'admin')
  );

drop policy if exists "Users can view their own registrations" on public.activity_registrations;
create policy "Users can view their own registrations" on public.activity_registrations for select using (auth.uid() = user_id);

drop policy if exists "Users can register for activities" on public.activity_registrations;
create policy "Users can register for activities" on public.activity_registrations for insert with check (auth.uid() = user_id);

-- Notifications RLS policies
drop policy if exists "Users can view their own notifications" on public.notifications;
create policy "Users can view their own notifications"
  on public.notifications for select
  using (auth.uid() = user_id);

drop policy if exists "Users can update their own notifications" on public.notifications;
create policy "Users can update their own notifications"
  on public.notifications for update
  using (auth.uid() = user_id);

-- Admin can create notifications
drop policy if exists "Admins can create notifications" on public.notifications;
create policy "Admins can create notifications"
  on public.notifications for insert
  with check (
    exists (
      select 1 from public.profiles
      where profiles.id = auth.uid()
      and profiles.user_type = 'admin'
    )
  );

-- =====================================================
-- SECTION 7: TRIGGERS
-- =====================================================

-- Create triggers for updated_at
drop trigger if exists handle_updated_at on public.profiles;
create trigger handle_updated_at before update on public.profiles for each row execute procedure public.handle_updated_at();

drop trigger if exists handle_updated_at on public.schools;
create trigger handle_updated_at before update on public.schools for each row execute procedure public.handle_updated_at();

drop trigger if exists handle_updated_at on public.activities;
create trigger handle_updated_at before update on public.activities for each row execute procedure public.handle_updated_at();

drop trigger if exists handle_updated_at on public.activity_registrations;
create trigger handle_updated_at before update on public.activity_registrations for each row execute procedure public.handle_updated_at();

-- school_visits trigger removed - using unified visits table instead

drop trigger if exists handle_updated_at on public.blog_posts;
create trigger handle_updated_at before update on public.blog_posts for each row execute procedure public.handle_updated_at();

drop trigger if exists handle_updated_at on public.products;
create trigger handle_updated_at before update on public.products for each row execute procedure public.handle_updated_at();

drop trigger if exists handle_updated_at on public.orders;
create trigger handle_updated_at before update on public.orders for each row execute procedure public.handle_updated_at();

-- Trigger for notifications updated_at
drop trigger if exists handle_notifications_updated_at on public.notifications;
create trigger handle_notifications_updated_at
  before update on public.notifications
  for each row execute procedure public.handle_updated_at();

-- =====================================================
-- SECTION 8: INITIAL DATA
-- =====================================================

-- Insert initial activity types (only if they don't exist)
insert into public.activity_types (name, slug, description, color, icon)
select * from (values
  ('School Visits', 'school-visits', 'Educational visits for schools and groups', '#2e7d32', '🏫'),
  ('Workshops', 'workshops', 'Hands-on learning workshops', '#388e3c', '🔧'),
  ('Events', 'events', 'Special events and community gatherings', '#4caf50', '🌱'),
  ('Special Lunches', 'lunches', 'Culinary experiences with educational components', '#66bb6a', '🍷'),
  ('Camps', 'camps', 'Multi-day learning experiences', '#81c784', '🏕️')
) as t(name, slug, description, color, icon)
where not exists (select 1 from public.activity_types where activity_types.slug = t.slug);

-- =====================================================
-- SECTION 9: STORAGE SETUP
-- =====================================================

-- Create storage buckets (only if they don't exist)
insert into storage.buckets (id, name, public)
select * from (values
  ('avatars', 'avatars', true),
  ('activity-images', 'activity-images', true),
  ('documents', 'documents', false)
) as t(id, name, public)
where not exists (select 1 from storage.buckets where buckets.id = t.id);

-- Storage policies for avatars bucket (public)
drop policy if exists "Avatar images are publicly accessible" on storage.objects;
create policy "Avatar images are publicly accessible"
  on storage.objects for select
  using ( bucket_id = 'avatars' );

drop policy if exists "Users can upload their own avatar" on storage.objects;
create policy "Users can upload their own avatar"
  on storage.objects for insert
  with check ( bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1] );

drop policy if exists "Users can update their own avatar" on storage.objects;
create policy "Users can update their own avatar"
  on storage.objects for update
  using ( bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1] );

drop policy if exists "Users can delete their own avatar" on storage.objects;
create policy "Users can delete their own avatar"
  on storage.objects for delete
  using ( bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1] );

-- Storage policies for activity-images bucket (public)
drop policy if exists "Activity images are publicly accessible" on storage.objects;
create policy "Activity images are publicly accessible"
  on storage.objects for select
  using ( bucket_id = 'activity-images' );

drop policy if exists "Admins can manage activity images" on storage.objects;
create policy "Admins can manage activity images"
  on storage.objects for insert
  with check (
    bucket_id = 'activity-images' AND
    exists (
      select 1 from public.profiles
      where profiles.id = auth.uid()
      and profiles.user_type = 'admin'
    )
  );

drop policy if exists "Admins can update activity images" on storage.objects;
create policy "Admins can update activity images"
  on storage.objects for update
  using (
    bucket_id = 'activity-images' AND
    exists (
      select 1 from public.profiles
      where profiles.id = auth.uid()
      and profiles.user_type = 'admin'
    )
  );

drop policy if exists "Admins can delete activity images" on storage.objects;
create policy "Admins can delete activity images"
  on storage.objects for delete
  using (
    bucket_id = 'activity-images' AND
    exists (
      select 1 from public.profiles
      where profiles.id = auth.uid()
      and profiles.user_type = 'admin'
    )
  );

-- Storage policies for documents bucket (private)
drop policy if exists "Users can view their own documents" on storage.objects;
create policy "Users can view their own documents"
  on storage.objects for select
  using ( bucket_id = 'documents' AND auth.uid()::text = (storage.foldername(name))[1] );

drop policy if exists "Users can upload their own documents" on storage.objects;
create policy "Users can upload their own documents"
  on storage.objects for insert
  with check ( bucket_id = 'documents' AND auth.uid()::text = (storage.foldername(name))[1] );

drop policy if exists "Users can update their own documents" on storage.objects;
create policy "Users can update their own documents"
  on storage.objects for update
  using ( bucket_id = 'documents' AND auth.uid()::text = (storage.foldername(name))[1] );

drop policy if exists "Users can delete their own documents" on storage.objects;
create policy "Users can delete their own documents"
  on storage.objects for delete
  using ( bucket_id = 'documents' AND auth.uid()::text = (storage.foldername(name))[1] );

-- Admins can view all documents
drop policy if exists "Admins can view all documents" on storage.objects;
create policy "Admins can view all documents"
  on storage.objects for select
  using (
    bucket_id = 'documents' AND
    exists (
      select 1 from public.profiles
      where profiles.id = auth.uid()
      and profiles.user_type = 'admin'
    )
  );