-- ENABLE EXTENSIONS
create extension if not exists "pgcrypto";
create extension if not exists "uuid-ossp";

-- SYNC/TRACKING TRIGGER
create or replace function public.touch_row()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  if tg_op = 'UPDATE' then
    new.version := coalesce(old.version, 1) + 1;
  end if;
  return new;
end;
$$;

-- HOSPITALS (new master table)
create table if not exists public.hospitals (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  region text not null,
  city text,
  category text not null, -- Teaching, Regional, Public, Private, Military, Psychiatric, Children, Polyclinic
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  version int not null default 1
);
create trigger trg_hospitals_touch
before update on public.hospitals
for each row execute procedure public.touch_row();

-- USERS (profile table) - replace hospital_name with hospital_id FK
create table if not exists public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  phone_number text,
  employee_id text unique,
  hospital_id uuid references public.hospitals(id) on delete set null, -- changed
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  version int not null default 1
);
create trigger trg_users_touch
before update on public.users
for each row execute procedure public.touch_row();

-- USER SETTINGS
create table if not exists public.user_settings (
  user_id uuid primary key references public.users(id) on delete cascade,
  push_notifications boolean not null default true,
  in_app_reminders boolean not null default true,
  resource_age_grp text not null default 'Infants'
    check (resource_age_grp in ('Infants','Toddlers','Adolescents')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  version int not null default 1
);
create trigger trg_user_settings_touch
before update on public.user_settings
for each row execute procedure public.touch_row();

-- PATIENT RECORDS (add vaccine_id FK to vaccines)
create table if not exists public.patient_records (
  patient_id uuid primary key default gen_random_uuid(),
  doc_id uuid not null references public.users(id) on delete restrict,
  name text not null,
  dob date not null,
  gender char(1) not null check (gender in ('M','F')),
  emergency_contact_number text,
  guardian_name text,
  guardian_num text,
  last_time_immunized date,
  vaccine_id uuid references public.vaccines(id) on delete set null, -- added
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  version int not null default 1
);
create index if not exists idx_patient_records_doc_id on public.patient_records(doc_id);
create index if not exists idx_patient_records_updated_at on public.patient_records(updated_at);
create index if not exists idx_patient_records_vaccine_id on public.patient_records(vaccine_id); -- added
create trigger trg_patient_records_touch
before update on public.patient_records
for each row execute procedure public.touch_row();

-- VACCINES
create table if not exists public.vaccines (
  id uuid primary key default gen_random_uuid(),
  vaccine_name text not null unique,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  version int not null default 1
);
create index if not exists idx_vaccines_updated_at on public.vaccines(updated_at);
create trigger trg_vaccines_touch
before update on public.vaccines
for each row execute procedure public.touch_row();

-- IMMUNIZATIONS
create table if not exists public.immunizations (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.patient_records(patient_id) on delete cascade,
  vaccine_id uuid not null references public.vaccines(id) on delete restrict,
  date_due_taken date,
  num_doses int not null default 1,
  immunization_status text not null check (immunization_status in ('Immunized','Pending','Overdue')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  version int not null default 1
);
create index if not exists idx_immunizations_patient_id on public.immunizations(patient_id);
create index if not exists idx_immunizations_updated_at on public.immunizations(updated_at);
create trigger trg_immunizations_touch
before update on public.immunizations
for each row execute procedure public.touch_row();

-- VACCINE INFORMATION
create table if not exists public.vaccine_information (
  vaccine_id uuid primary key references public.vaccines(id) on delete cascade,
  diseases_tackled text not null,
  dosage_schedule jsonb not null, -- store schedules as structured JSON
  side_effects text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  version int not null default 1
);
create index if not exists idx_vaccine_info_updated_at on public.vaccine_information(updated_at);
create trigger trg_vaccine_info_touch
before update on public.vaccine_information
for each row execute procedure public.touch_row();

-- NOTIFICATIONS
create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  patient_id uuid references public.patient_records(patient_id) on delete set null,
  immunization_id uuid references public.immunizations(id) on delete set null,
  title text not null,
  body text not null,
  priority text not null default 'low' check (priority in ('low','medium','high')),
  read_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  version int not null default 1
);
create index if not exists idx_notifications_user_id on public.notifications(user_id);
create index if not exists idx_notifications_updated_at on public.notifications(updated_at);
create trigger trg_notifications_touch
before update on public.notifications
for each row execute procedure public.touch_row();

-- RPC: resolve email by employee_id for login (SECURITY DEFINER, limited scope)
create or replace function public.get_email_by_employee(p_employee_id text)
returns text
language sql
security definer
set search_path = public
as $$
  select au.email
  from public.users u
  join auth.users au on au.id = u.id
  where u.employee_id = p_employee_id
  limit 1
$$;

-- tighten and grant execute
revoke all on function public.get_email_by_employee(text) from public;
grant execute on function public.get_email_by_employee(text) to anon, authenticated;

-- RLS
alter table public.hospitals enable row level security; -- added
alter table public.users enable row level security;
alter table public.user_settings enable row level security;
alter table public.patient_records enable row level security;
alter table public.vaccines enable row level security;
alter table public.immunizations enable row level security;
alter table public.vaccine_information enable row level security;
alter table public.notifications enable row level security;

-- POLICIES

-- users: a user can read/update their own profile
drop policy if exists users_select_self on public.users;
create policy users_select_self on public.users
  for select using (id = auth.uid());

drop policy if exists users_update_self on public.users;
create policy users_update_self on public.users
  for update using (id = auth.uid());

-- user_settings: owner can CRUD
drop policy if exists user_settings_owner_all on public.user_settings;
create policy user_settings_owner_all on public.user_settings
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- patient_records: doctor owns their patients
drop policy if exists patient_records_doctor_all on public.patient_records;
create policy patient_records_doctor_all on public.patient_records
  for all using (doc_id = auth.uid()) with check (doc_id = auth.uid());

-- vaccines & vaccine_information: read-only to authenticated users
drop policy if exists vaccines_read_all on public.vaccines;
create policy vaccines_read_all on public.vaccines
  for select to authenticated using (true);

drop policy if exists vaccine_info_read_all on public.vaccine_information;
create policy vaccine_info_read_all on public.vaccine_information
  for select to authenticated using (true);

-- immunizations: allowed if the patient belongs to the doctor
drop policy if exists immunizations_patient_owned on public.immunizations;
create policy immunizations_patient_owned on public.immunizations
  for all using (
    exists (
      select 1 from public.patient_records p
      where p.patient_id = immunizations.patient_id
        and p.doc_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.patient_records p
      where p.patient_id = immunizations.patient_id
        and p.doc_id = auth.uid()
    )
  );

-- notifications: visible/update only to recipient
drop policy if exists notifications_owner_read on public.notifications;
create policy notifications_owner_read on public.notifications
  for select using (user_id = auth.uid());

drop policy if exists notifications_owner_update on public.notifications;
create policy notifications_owner_update on public.notifications
  for update using (user_id = auth.uid());

-- hospitals: read-only to authenticated
drop policy if exists hospitals_read_all on public.hospitals;
-- Allow both authenticated and anon clients to read hospitals (needed for signup page)
create policy hospitals_read_all on public.hospitals
  for select to authenticated, anon using (true);

-- OPTIONAL: create profile row on auth user signup (updated to set hospital_id)
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  meta_hospital_id uuid;
  meta_hospital_name text;
begin
  meta_hospital_id := nullif(new.raw_user_meta_data->>'hospital_id','')::uuid;
  meta_hospital_name := nullif(new.raw_user_meta_data->>'hospital_name','');

  if meta_hospital_id is null and meta_hospital_name is not null then
    select h.id
      into meta_hospital_id
      from public.hospitals h
     where lower(h.name) = lower(meta_hospital_name)
        or lower(h.name) like '%' || lower(meta_hospital_name) || '%'
     order by case when lower(h.name) = lower(meta_hospital_name) then 0 else 1 end
     limit 1;
  end if;

  insert into public.users (id, full_name, phone_number, employee_id, hospital_id)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name',''),
    new.raw_user_meta_data->>'phone_number',
    new.raw_user_meta_data->>'employee_id',
    meta_hospital_id
  )
  on conflict (id) do nothing;

  insert into public.user_settings(user_id)
  values (new.id)
  on conflict (user_id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- NOTE: Ensure the VACCINES section appears before PATIENT RECORDS in this file.