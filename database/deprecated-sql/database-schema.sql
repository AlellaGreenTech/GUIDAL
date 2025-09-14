-- GUIDAL Database Schema for Supabase
-- Designed for scalability and future growth

-- Enable necessary extensions
create extension if not exists "uuid-ossp";

-- Schools table (must be created first due to foreign key dependency)
create table public.schools (
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
create table public.profiles (
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
create table public.activity_types (
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
create table public.activities (
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
create table public.activity_registrations (
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

-- School visits (extends activities with school-specific data)
create table public.school_visits (
  id uuid default uuid_generate_v4() primary key,
  activity_id uuid references public.activities(id) on delete cascade not null,
  school_id uuid references public.schools(id) not null,
  teacher_name text,
  teacher_email text,
  teacher_phone text,
  student_count integer not null,
  grade_level text,
  access_code text unique,
  special_instructions text,
  lunch_required boolean default false,
  transport_details text,
  emergency_contact text,
  visit_coordinator uuid references public.profiles(id),
  confirmation_sent boolean default false,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- Station assignments for school visits
create table public.visit_stations (
  id uuid default uuid_generate_v4() primary key,
  school_visit_id uuid references public.school_visits(id) on delete cascade not null,
  station_name text not null,
  start_time time,
  end_time time,
  instructor text,
  max_students integer,
  learning_objectives text[],
  materials_needed text[],
  created_at timestamp with time zone default now()
);

-- Credit transactions
create table public.credit_transactions (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  activity_id uuid references public.activities(id),
  transaction_type text not null check (transaction_type in ('earned', 'spent', 'awarded', 'deducted')),
  amount integer not null,
  description text,
  created_at timestamp with time zone default now()
);

-- Blog posts for content management
create table public.blog_posts (
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
create table public.products (
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
create table public.orders (
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
create table public.order_items (
  id uuid default uuid_generate_v4() primary key,
  order_id uuid references public.orders(id) on delete cascade not null,
  product_id uuid references public.products(id) not null,
  quantity integer not null default 1,
  unit_price numeric(10,2) not null,
  total_price numeric(10,2) not null,
  created_at timestamp with time zone default now()
);

-- Create indexes for performance
create index idx_profiles_school_id on public.profiles(school_id);
create index idx_profiles_user_type on public.profiles(user_type);
create index idx_activities_type on public.activities(activity_type_id);
create index idx_activities_date on public.activities(date_time);
create index idx_activities_status on public.activities(status);
create index idx_registrations_activity on public.activity_registrations(activity_id);
create index idx_registrations_user on public.activity_registrations(user_id);
create index idx_credit_transactions_user on public.credit_transactions(user_id);
create index idx_blog_posts_published on public.blog_posts(published, published_at);

-- Set up Row Level Security (RLS)
alter table public.profiles enable row level security;
alter table public.schools enable row level security;
alter table public.activities enable row level security;
alter table public.activity_registrations enable row level security;
alter table public.school_visits enable row level security;
alter table public.credit_transactions enable row level security;
alter table public.blog_posts enable row level security;
alter table public.products enable row level security;
alter table public.orders enable row level security;

-- Basic RLS policies (can be refined later)
create policy "Public profiles are viewable by everyone" on public.profiles for select using (true);
create policy "Users can update own profile" on public.profiles for update using (auth.uid() = id);

create policy "Activities are viewable by everyone" on public.activities for select using (status = 'published');
create policy "Only admins can modify activities" on public.activities for all using (
  exists (select 1 from public.profiles where profiles.id = auth.uid() and profiles.user_type = 'admin')
);

create policy "Users can view their own registrations" on public.activity_registrations for select using (auth.uid() = user_id);
create policy "Users can register for activities" on public.activity_registrations for insert using (auth.uid() = user_id);

-- Functions for automatic timestamp updates
create or replace function public.handle_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

-- Create triggers for updated_at
create trigger handle_updated_at before update on public.profiles for each row execute procedure public.handle_updated_at();
create trigger handle_updated_at before update on public.schools for each row execute procedure public.handle_updated_at();
create trigger handle_updated_at before update on public.activities for each row execute procedure public.handle_updated_at();
create trigger handle_updated_at before update on public.activity_registrations for each row execute procedure public.handle_updated_at();
create trigger handle_updated_at before update on public.school_visits for each row execute procedure public.handle_updated_at();
create trigger handle_updated_at before update on public.blog_posts for each row execute procedure public.handle_updated_at();
create trigger handle_updated_at before update on public.products for each row execute procedure public.handle_updated_at();
create trigger handle_updated_at before update on public.orders for each row execute procedure public.handle_updated_at();

-- Insert initial activity types
insert into public.activity_types (name, slug, description, color, icon) values
('School Visits', 'school-visits', 'Educational visits for schools and groups', '#2e7d32', '🏫'),
('Workshops', 'workshops', 'Hands-on learning workshops', '#388e3c', '🔧'),
('Events', 'events', 'Special events and community gatherings', '#4caf50', '🌱'),
('Special Lunches', 'lunches', 'Culinary experiences with educational components', '#66bb6a', '🍷'),
('Camps', 'camps', 'Multi-day learning experiences', '#81c784', '🏕️');