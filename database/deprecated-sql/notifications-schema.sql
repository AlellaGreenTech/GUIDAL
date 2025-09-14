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

-- Create index for performance
create index idx_notifications_user_id on public.notifications(user_id);
create index idx_notifications_is_read on public.notifications(is_read);

-- Enable RLS
alter table public.notifications enable row level security;

-- RLS policies
create policy "Users can view their own notifications"
  on public.notifications for select
  using (auth.uid() = user_id);

create policy "Users can update their own notifications"
  on public.notifications for update
  using (auth.uid() = user_id);

-- Admin can create notifications
create policy "Admins can create notifications"
  on public.notifications for insert
  with check (
    exists (
      select 1 from public.profiles
      where profiles.id = auth.uid()
      and profiles.user_type = 'admin'
    )
  );

-- Trigger for updated_at
create trigger handle_notifications_updated_at
  before update on public.notifications
  for each row execute procedure public.handle_updated_at();

-- Add database functions for participant count management
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