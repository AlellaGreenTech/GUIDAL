-- Supabase Storage Setup for GUIDAL
-- Run this in your Supabase SQL editor to set up storage buckets

-- Create storage buckets
insert into storage.buckets (id, name, public) values
('avatars', 'avatars', true),
('activity-images', 'activity-images', true),
('documents', 'documents', false);

-- Create storage policies for avatars bucket (public)
create policy "Avatar images are publicly accessible"
  on storage.objects for select
  using ( bucket_id = 'avatars' );

create policy "Users can upload their own avatar"
  on storage.objects for insert
  with check ( bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1] );

create policy "Users can update their own avatar"
  on storage.objects for update
  using ( bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1] );

create policy "Users can delete their own avatar"
  on storage.objects for delete
  using ( bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1] );

-- Create storage policies for activity-images bucket (public)
create policy "Activity images are publicly accessible"
  on storage.objects for select
  using ( bucket_id = 'activity-images' );

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

-- Create storage policies for documents bucket (private)
create policy "Users can view their own documents"
  on storage.objects for select
  using ( bucket_id = 'documents' AND auth.uid()::text = (storage.foldername(name))[1] );

create policy "Users can upload their own documents"
  on storage.objects for insert
  with check ( bucket_id = 'documents' AND auth.uid()::text = (storage.foldername(name))[1] );

create policy "Users can update their own documents"
  on storage.objects for update
  using ( bucket_id = 'documents' AND auth.uid()::text = (storage.foldername(name))[1] );

create policy "Users can delete their own documents"
  on storage.objects for delete
  using ( bucket_id = 'documents' AND auth.uid()::text = (storage.foldername(name))[1] );

-- Admins can view all documents
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