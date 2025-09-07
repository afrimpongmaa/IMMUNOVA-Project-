-- Use the storage admin role for storage.* objects when available
-- If this fails due to lack of permission to SET ROLE, run these statements in the Supabase SQL Editor instead.
do $$
begin
  begin
    execute 'set local role supabase_storage_admin';
  exception when others then
    -- ignore if we cannot assume the role
    null;
  end;
end$$;

-- Ensure user-profiles bucket exists and is public
insert into storage.buckets (id, name, public)
values ('user-profiles', 'user-profiles', true)
on conflict (id) do nothing;

-- Note: RLS is enabled by default on storage.objects in Supabase projects.
-- Skipping ALTER TABLE to avoid ownership errors in some environments.

-- Public read access to avatars in user-profiles
drop policy if exists "Public read user-profiles" on storage.objects;
create policy "Public read user-profiles"
on storage.objects for select
using (bucket_id = 'user-profiles');

-- Authenticated users can upload only to their own UID prefix
drop policy if exists "Users can upload to their prefix" on storage.objects;
create policy "Users can upload to their prefix"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'user-profiles'
  and split_part(name, '/', 1) = auth.uid()::text
);

-- Authenticated users can update only files in their own UID prefix
drop policy if exists "Users can update their prefix" on storage.objects;
create policy "Users can update their prefix"
on storage.objects for update to authenticated
using (
  bucket_id = 'user-profiles'
  and split_part(name, '/', 1) = auth.uid()::text
)
with check (
  bucket_id = 'user-profiles'
  and split_part(name, '/', 1) = auth.uid()::text
);

-- Authenticated users can delete only files in their own UID prefix
drop policy if exists "Users can delete their prefix" on storage.objects;
create policy "Users can delete their prefix"
on storage.objects for delete to authenticated
using (
  bucket_id = 'user-profiles'
  and split_part(name, '/', 1) = auth.uid()::text
);

-- Reset any role change done above
reset role;
