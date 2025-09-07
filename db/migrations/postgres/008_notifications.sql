-- Notifications table and RLS
-- Creates per-user notifications tied to patients. Severity can be 'mild' or 'critical'.

-- Ensure pgcrypto for gen_random_uuid()
create extension if not exists pgcrypto;

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  patient_id uuid references public.patient_records(patient_id) on delete set null,
  severity text not null check (severity in ('mild','critical')),
  content text not null,
  created_at timestamptz not null default now(),
  read_at timestamptz
);

create index if not exists idx_notifications_user_created
  on public.notifications(user_id, created_at desc);

alter table public.notifications enable row level security;

-- Allow users to read only their own notifications
create policy if not exists notifications_select_own
  on public.notifications
  for select
  to authenticated
  using (user_id = auth.uid());

-- Allow users to update (e.g., mark as read) only their own notifications
create policy if not exists notifications_update_own
  on public.notifications
  for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- Optional: allow clients to create notifications for themselves (not required for service role)
create policy if not exists notifications_insert_self
  on public.notifications
  for insert
  to authenticated
  with check (user_id = auth.uid());

-- No delete policy (service role bypasses RLS if needed)
