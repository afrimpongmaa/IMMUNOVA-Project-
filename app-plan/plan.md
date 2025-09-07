# Rough DB plan

The app is offline-first, which will require an offline noSQL database. Since it will be updated online, we need to use a relational schema that represents the online db (preferrably Postgres with Supabase)

## Tables

### Users

id references auth.users.id ON CASCADE DELETE

id UUID
full_name 
phone_number
employee_id 
hospital_name




### User settings

user_id REFERENCES users.id ON CASCADE DELETE
push_notifications CHECK IN ("enabled","disabled")
in_app_reminders CHECK IN ("enabled","disabled")
resource_age_grp CHECK IN ("Infants", "Toddlers", "Adoscelents")








### Patient Records

patient_id UUID PK
doc_id references users.id -- Keep track of the what doctor attends to this patient
name - Patient name
dob - Date of Birth
Gender - check in ("M", "F")
Emergency contact number NULL
guardian_name 
guardian_num 
last_time_immunized 


### Vaccines
id UUID
vaccine_name 

### Immunization

id UUID PK
patient_id  REFERENCES patient_records.patient_id
vaccine_id REFERENCES vaccines.id
date_due_taken 
num_doses INT4
immunization_status CHECK IN ("Immunized", "Pending", "Overdue")




# Vaccine Information

vaccine_id REFERENCES vaccines.id ON CASCADE DELETE
diseases_tackled TEXT NOT NULL
dosage_schedule TEXT (/JSONB) NOT NULL
side_effects TEXT NOT NULL





## NOTIFICATIONS

id references users.id -- for a particular doctor
patient_id references patient_records.id
immunization_id REFERENCES immunization.id

# Backend Implementation Options (for Offline-first with local SQLite + Remote Postgres)

1) Supabase (Managed Postgres + PostgREST + Realtime + RLS + Edge Functions)
- What you get:
  - Postgres, automatic REST via PostgREST, Row-Level Security, Realtime channels.
  - Edge Functions (Deno) for custom RPC/sync endpoints, scheduled jobs.
- Pros:
  - Fast to start, built-in auth and RLS, minimal ops, realtime helpful for notifications.
- Cons:
  - No “built-in” bidirectional SQLite sync. You still implement outbox/inbox sync and conflict policy.
- Fit:
  - Excellent; combine PostgREST for CRUD and Edge Functions for delta-sync endpoints.

2) Node.js backend (Fastify/Express/NestJS) + Postgres (pg/Prisma)
- What you get:
  - Fully custom REST/GraphQL endpoints; can design first-class sync: /changes, tombstones, vectors.
- Pros:
  - Maximum control over sync, conflict resolution, batching, migrations, and validation.
- Cons:
  - Higher maintenance and ops; you’ll also need auth, RLS-like enforcement, and rate limiting.

3) Hasura GraphQL Engine on Postgres
- What you get:
  - Instant GraphQL + subscriptions, permissions, actions for custom logic.
- Pros:
  - Great for GraphQL-first apps; subscriptions useful for notifications.
- Cons:
  - Offline sync still custom; permissions model can get complex for multi-tenant medical data.

4) Direct PostgREST (or Supabase’s PostgREST) + Client-managed sync
- What you get:
  - Auto REST over Postgres; you implement delta logic via RPC functions and SQL views.
- Pros:
  - Lightweight; leverage SQL for business rules; minimal backend code.
- Cons:
  - Complex sync logic in SQL/PLpgSQL; testing and versioning harder than app-layer services.

5) Serverless/Edge Functions (Cloudflare Workers, Vercel, Netlify) + Neon/Supabase Postgres
- What you get:
  - Low-latency endpoints near users; can implement custom sync and webhooks.
- Pros:
  - Elastic scale; good DX; pair with cron for periodic tasks.
- Cons:
  - Cold starts and connection management to Postgres need care; still DIY sync.

6) Go/Rust/Elixir gRPC/REST service + Postgres
- Pros:
  - Performance, strong concurrency; good choice for high volume sync and complex conflict rules.
- Cons:
  - Increased complexity; fewer ready-made building blocks vs JS ecosystem.

7) ElectricSQL-style SQLite <-> Postgres sync
- What you get:
  - True CRDT/replication for SQLite with Postgres.
- Caveat:
  - Flutter/Dart support isn’t mature; integration risk for mobile timeline.

8) Appwrite/Firestore/Realm alternatives
- Pros:
  - First-class offline in some (Firestore/Realm).
- Cons:
  - Not Postgres; diverges from your chosen stack and existing schema.

## Recommendation

Pick: Supabase (Postgres + RLS + Realtime) with a thin sync layer via Edge Functions.

Why:
- Keeps Postgres (your target) with strong security using RLS.
- Minimal ops and fast delivery.
- Edge Functions let us define first-class sync endpoints without running a full Node server.
- Realtime channels power in-app notifications when online; local scheduler handles offline reminders.

High-level design:
- Local DB (SQLite) mirrors remote tables + sync columns:
  - id (UUID), created_at, updated_at, deleted_at (nullable), version (int), last_pulled_at (meta), sync_status ('pending','synced','conflict'), changed_by (user_id).
- Outbox pattern:
  - All local inserts/updates/deletes write to an outbox table.
- Sync endpoints (Edge Functions):
  - POST /sync/push: Accept batch of local changes; apply with server-side validation; return per-row status and new versions.
  - GET /sync/pull?since=timestamp: Return remote changes since last pull (including tombstones via deleted_at).
  - GET /bootstrap: First login full pull with pagination.
- Conflict policy:
  - Default “newest-wins” comparing updated_at/version.
  - Domain overrides:
    - Appointments: server wins for time-slot collisions, return 409 with resolution hints.
    - Inventory: server-side transactional counters to prevent negative stock; client retries with patch.
- Security:
  - Supabase Auth + RLS on all tables (scoped to clinician’s org/user).
  - Edge Functions verify JWT, re-check RLS via RPC with SECURITY DEFINER where appropriate.
- Notifications:
  - Remote: use Postgres triggers to insert into notifications table; Realtime broadcasts to user channel.
  - Local: background task scans due immunizations and creates local notifications; merges with remote on next sync.
- Migrations:
  - Add sync columns to your Postgres tables.
  - Create RPC for delta queries (pull) and batch upserts (push).
  - Indexes on updated_at, deleted_at, (user_id, updated_at).

Minimal schema augment (Postgres):
- Common columns:
  - updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
  - deleted_at TIMESTAMPTZ NULL
  - version INT NOT NULL DEFAULT 1
- Triggers:
  - BEFORE UPDATE increment version and set updated_at = now()
- Delta view:
  - SELECT … WHERE updated_at > $since OR deleted_at IS NOT NULL

Sample endpoints contract:
- POST /sync/push
  - body: { tables: { patients: [rows], vaccinations: [rows], … }, clientClock: iso }
  - returns: { results: { patients: [{id, status, serverVersion, serverRow?}]…}, serverClock: iso }
- GET /sync/pull?since=iso
  - returns: { tables: { patients: [rows], … }, serverClock: iso }

This path gets you production-ready fastest, with clear upgrade to a dedicated Node.js service later if needed (you can port Edge Functions into Fastify/NestJS keeping the API surface).

## Supabase Project Setup (Dashboard or CLI)

Option A — Dashboard
1. Go to https://supabase.com/dashboard → New project.
2. Choose org, project name, region; set a strong DB password.
3. From Project Settings → API, copy:
   - Project URL
   - anon public key (client)
   - service_role key (server only; never ship to app)
4. SQL Editor → you can paste the schema below and run once.

Option B — CLI (recommended for migrations in repo)
1. Install CLI:
   - macOS: brew install supabase/tap/supabase
   - Windows: scoop install supabase
   - Linux: see docs
2. In project root:
   - supabase init
   - supabase login
   - supabase link --project-ref YOUR_PROJECT_REF
3. Create a migration:
   - supabase migration new init_schema
   - Put the SQL from “Initial SQL Schema” into the created migration file.
4. Apply locally or to remote:
   - Local (Docker): supabase start → supabase db reset
   - Remote: supabase db push

## Flutter wiring (quick pointers)
- Add dependency: supabase_flutter: ^2
- Initialize early (e.g., in main):
  - Supabase.initialize(url: 'YOUR_SUPABASE_URL', anonKey: 'YOUR_ANON_KEY')
- Keep service_role key only in server-side code (Edge Functions), not in the app.

## Initial SQL Schema (Postgres on Supabase)

Notes
- Includes sync-friendly columns (created_at, updated_at, deleted_at, version).
- Uses RLS with sensible defaults.
- “users” mirrors auth.users via FK and an onboarding trigger.

```sql
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

-- USERS (profile table)
create table if not exists public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  phone_number text,
  employee_id text unique,
  hospital_name text,
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

-- PATIENT RECORDS
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
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  version int not null default 1
);
create index if not exists idx_patient_records_doc_id on public.patient_records(doc_id);
create index if not exists idx_patient_records_updated_at on public.patient_records(updated_at);
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

-- RLS
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

-- OPTIONAL: create profile row on auth user signup
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.users (id, full_name, phone_number, employee_id, hospital_name)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name',''),
    new.raw_user_meta_data->>'phone_number',
    new.raw_user_meta_data->>'employee_id',
    new.raw_user_meta_data->>'hospital_name'
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
```

## How to apply
- SQL Editor: paste the SQL and run.
- CLI migrations:
  - supabase migration new init_schema
  - paste SQL into the new file
  - supabase db push (remote) or supabase db reset (local)

## Local initialization checklist

- Supabase (local):
  - supabase start
  - supabase db push
  - supabase status
- Supabase (remote):
  - supabase link --project-ref xrvntkufeisfdujjzxrn
  - supabase db push
- Secrets for Edge Functions (remote and local):
  - supabase secrets set --env-file ./supabase/.env
  - .env content (do not commit):
    SUPABASE_URL=https://xrvntkufeisfdujjzxrn.supabase.co
    SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inhydm50a3VmZWlzZmR1amp6eHJuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTcwODM4MjQsImV4cCI6MjA3MjY1OTgyNH0.OO4uNfBMxqiYA2G1NbmIgzvFeHbuR2OnVSjL05KUH9E
    SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inhydm50a3VmZWlzZmR1amp6eHJuIiwicm9zZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzA4MzgyNCwiZXhwIjoyMDcyNjU5ODI0fQ.N09cwQdwdeWe6ipC-faAv4SH7a-BhzAcZBNgvg6jgjI
- Flutter:
  - Add deps: supabase_flutter: ^2, sqflite: ^2, path: ^1, path_provider: ^2
  - Initialize Supabase early in main() with URL and anon key (keep service role only in Edge Functions).

## Seed reference data (vaccines + info)

Paste and run in SQL Editor or place in a migration/seed file.

```sql
-- Seed vaccines
insert into public.vaccines (id, vaccine_name) values
  (gen_random_uuid(), 'BCG') on conflict do nothing;
insert into public.vaccines (id, vaccine_name) values
  (gen_random_uuid(), 'Hepatitis B') on conflict do nothing;
insert into public.vaccines (id, vaccine_name) values
  (gen_random_uuid(), 'OPV') on conflict do nothing;
insert into public.vaccines (id, vaccine_name) values
  (gen_random_uuid(), 'DTP') on conflict do nothing;
insert into public.vaccines (id, vaccine_name) values
  (gen_random_uuid(), 'Hib') on conflict do nothing;
insert into public.vaccines (id, vaccine_name) values
  (gen_random_uuid(), 'PCV') on conflict do nothing;
insert into public.vaccines (id, vaccine_name) values
  (gen_random_uuid(), 'Rotavirus') on conflict do nothing;
insert into public.vaccines (id, vaccine_name) values
  (gen_random_uuid(), 'Measles/MMR') on conflict do nothing;
insert into public.vaccines (id, vaccine_name) values
  (gen_random_uuid(), 'Yellow Fever') on conflict do nothing;

-- Attach basic vaccine information (example schedules)
with v as (select id, vaccine_name from public.vaccines)
insert into public.vaccine_information (vaccine_id, diseases_tackled, dosage_schedule, side_effects)
select
  v.id,
  case v.vaccine_name
    when 'BCG' then 'Tuberculosis'
    when 'Hepatitis B' then 'Hepatitis B'
    when 'OPV' then 'Poliomyelitis'
    when 'DTP' then 'Diphtheria, Tetanus, Pertussis'
    when 'Hib' then 'Haemophilus influenzae type b'
    when 'PCV' then 'Pneumococcal disease'
    when 'Rotavirus' then 'Rotavirus gastroenteritis'
    when 'Measles/MMR' then 'Measles, Mumps, Rubella'
    when 'Yellow Fever' then 'Yellow fever'
    else 'N/A'
  end as diseases_tackled,
  case v.vaccine_name
    when 'BCG' then jsonb_build_object('doses', jsonb_build_array(jsonb_build_object('age','At birth')))
    when 'Hepatitis B' then jsonb_build_object('doses', jsonb_build_array(
      jsonb_build_object('age','At birth'),
      jsonb_build_object('age','6 weeks'),
      jsonb_build_object('age','10 weeks'),
      jsonb_build_object('age','14 weeks')
    ))
    when 'OPV' then jsonb_build_object('doses', jsonb_build_array(
      jsonb_build_object('age','6 weeks'),
      jsonb_build_object('age','10 weeks'),
      jsonb_build_object('age','14 weeks')
    ))
    when 'DTP' then jsonb_build_object('doses', jsonb_build_array(
      jsonb_build_object('age','6 weeks'),
      jsonb_build_object('age','10 weeks'),
      jsonb_build_object('age','14 weeks'),
      jsonb_build_object('age','15-18 months','type','booster')
    ))
    when 'Hib' then jsonb_build_object('doses', jsonb_build_array(
      jsonb_build_object('age','6 weeks'),
      jsonb_build_object('age','10 weeks'),
      jsonb_build_object('age','14 weeks')
    ))
    when 'PCV' then jsonb_build_object('doses', jsonb_build_array(
      jsonb_build_object('age','6 weeks'),
      jsonb_build_object('age','10 weeks'),
      jsonb_build_object('age','14 weeks')
    ))
    when 'Rotavirus' then jsonb_build_object('doses', jsonb_build_array(
      jsonb_build_object('age','6 weeks'),
      jsonb_build_object('age','10 weeks')
    ))
    when 'Measles/MMR' then jsonb_build_object('doses', jsonb_build_array(
      jsonb_build_object('age','9 months'),
      jsonb_build_object('age','15 months')
    ))
    when 'Yellow Fever' then jsonb_build_object('doses', jsonb_build_array(
      jsonb_build_object('age','9 months')
    ))
    else jsonb_build_object('doses', '[]'::jsonb)
  end as dosage_schedule,
  'Common mild fever, soreness at injection site' as side_effects
from v
on conflict (vaccine_id) do nothing;
```

## Sync RPCs (server-side delta APIs)

Compact RPCs the Edge Functions will call. They enforce access by user_id.

```sql
-- PULL: get changes since timestamp for a given user
create or replace function public.get_changes(u_id uuid, since timestamptz)
returns jsonb
language sql
security definer
set search_path = public
as $$
  select jsonb_build_object(
    'patient_records', coalesce((
      select jsonb_agg(p) from public.patient_records p
      where p.doc_id = u_id
        and (p.updated_at > since or p.deleted_at is not null)
    ), '[]'::jsonb),
    'immunizations', coalesce((
      select jsonb_agg(i) from public.immunizations i
      where exists (
        select 1 from public.patient_records p
        where p.patient_id = i.patient_id and p.doc_id = u_id
      ) and (i.updated_at > since or i.deleted_at is not null)
    ), '[]'::jsonb),
    'notifications', coalesce((
      select jsonb_agg(n) from public.notifications n
      where n.user_id = u_id and (n.updated_at > since or n.deleted_at is not null)
    ), '[]'::jsonb),
    'vaccines', coalesce((
      select jsonb_agg(v) from public.vaccines v
      where v.updated_at > since or v.deleted_at is not null
    ), '[]'::jsonb),
    'vaccine_information', coalesce((
      select jsonb_agg(vi) from public.vaccine_information vi
      where vi.updated_at > since or vi.deleted_at is not null
    ), '[]'::jsonb)
  );
$$;

-- PUSH: apply batched upserts/deletes from client outbox
-- Payload shape: { patients: [...], immunizations: [...], notifications: [...] }
create or replace function public.apply_changes(u_id uuid, payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  results jsonb := '{}'::jsonb;
  r jsonb;
begin
  -- patients
  for r in select * from jsonb_array_elements(coalesce(payload->'patients','[]'::jsonb)) loop
    if (r->>'deleted_at') is not null then
      update public.patient_records
        set deleted_at = coalesce((r->>'deleted_at')::timestamptz, now())
      where patient_id = (r->>'patient_id')::uuid and doc_id = u_id;
    else
      insert into public.patient_records as p (
        patient_id, doc_id, name, dob, gender,
        emergency_contact_number, guardian_name, guardian_num, last_time_immunized
      ) values (
        coalesce((r->>'patient_id')::uuid, gen_random_uuid()),
        u_id,
        r->>'name',
        (r->>'dob')::date,
        substr(coalesce(r->>'gender','M'),1,1),
        r->>'emergency_contact_number',
        r->>'guardian_name',
        r->>'guardian_num',
        nullif(r->>'last_time_immunized','')::date
      )
      on conflict (patient_id) do update
      set name = excluded.name,
          dob = excluded.dob,
          gender = excluded.gender,
          emergency_contact_number = excluded.emergency_contact_number,
          guardian_name = excluded.guardian_name,
          guardian_num = excluded.guardian_num
      where p.doc_id = u_id;
    end if;
  end loop;

  -- immunizations
  for r in select * from jsonb_array_elements(coalesce(payload->'immunizations','[]'::jsonb)) loop
    if (r->>'deleted_at') is not null then
      update public.immunizations
        set deleted_at = coalesce((r->>'deleted_at')::timestamptz, now())
      where id = (r->>'id')::uuid and exists (
        select 1 from public.patient_records p
        where p.patient_id = public.immunizations.patient_id and p.doc_id = u_id
      );
    else
      insert into public.immunizations as i (
        id, patient_id, vaccine_id, date_due_taken, num_doses, immunization_status
      ) values (
        coalesce((r->>'id')::uuid, gen_random_uuid()),
        (r->>'patient_id')::uuid,
        (r->>'vaccine_id')::uuid,
        nullif(r->>'date_due_taken','')::date,
        coalesce((r->>'num_doses')::int, 1),
        r->>'immunization_status'
      )
      on conflict (id) do update
      set patient_id = excluded.patient_id,
          vaccine_id = excluded.vaccine_id,
          date_due_taken = excluded.date_due_taken,
          num_doses = excluded.num_doses,
          immunization_status = excluded.immunization_status
      where exists (
        select 1 from public.patient_records p
        where p.patient_id = public.immunizations.patient_id and p.doc_id = u_id
      );
    end if;
  end loop;

  return jsonb_build_object('status','ok');
end;
$$;
```

## Edge Functions (sync-pull, sync-push)

- Create functions:
  - supabase functions new sync-pull
  - supabase functions new sync-push
- Set secrets (done above) and deploy:
  - supabase functions serve --env-file ./supabase/.env
  - supabase functions deploy sync-pull
  - supabase functions deploy sync-push

Example sync-pull (Deno):

```ts
// supabase/functions/sync-pull/index.ts
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req) => {
  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const client = createClient(supabaseUrl, serviceKey, { auth: { persistSession: false } });

  const url = new URL(req.url);
  const since = url.searchParams.get("since") ?? "1970-01-01T00:00:00Z";
  const jwt = req.headers.get("authorization")?.replace("Bearer ", "");

  if (!jwt) return new Response("Unauthorized", { status: 401 });

  const { data: u, error: ue } = await client.auth.getUser(jwt);
  if (ue || !u?.user) return new Response("Unauthorized", { status: 401 });

  const { data, error } = await client.rpc("get_changes", { u_id: u.user.id, since });
  if (error) return new Response(JSON.stringify({ error: error.message }), { status: 400 });

  return new Response(JSON.stringify({ tables: data, serverClock: new Date().toISOString() }), {
    headers: { "content-type": "application/json" },
  });
});
```

Example sync-push (Deno):

```ts
// supabase/functions/sync-push/index.ts
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req) => {
  if (req.method !== "POST") return new Response("Method Not Allowed", { status: 405 });

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const client = createClient(supabaseUrl, serviceKey, { auth: { persistSession: false } });

  const jwt = req.headers.get("authorization")?.replace("Bearer ", "");
  if (!jwt) return new Response("Unauthorized", { status: 401 });

  const { data: u, error: ue } = await client.auth.getUser(jwt);
  if (ue || !u?.user) return new Response("Unauthorized", { status: 401 });

  const body = await req.json().catch(() => ({}));
  const payload = body?.tables ?? {};

  const { data, error } = await client.rpc("apply_changes", { u_id: u.user.id, payload });
  if (error) return new Response(JSON.stringify({ error: error.message }), { status: 400 });

  return new Response(JSON.stringify({ result: data, serverClock: new Date().toISOString() }), {
    headers: { "content-type": "application/json" },
  });
});
```

Client usage (when online):
- Pull: GET https://xrvntkufeisfdujjzxrn.supabase.co/functions/v1/sync-pull?since=ISO with Authorization: Bearer <user_jwt>
- Push: POST https://xrvntkufeisfdujjzxrn.supabase.co/functions/v1/sync-push with { tables: { patients: [...], immunizations: [...] } }

## Notifications automation (overdue/upcoming)

Create server-side logic to insert notifications without duplicates.

```sql
create or replace function public.ensure_immunization_notifications()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  -- Upcoming (within 3 days)
  insert into public.notifications (user_id, patient_id, immunization_id, title, body, priority)
  select p.doc_id, p.patient_id, i.id,
         'Upcoming immunization',
         'Immunization due on ' || coalesce(i.date_due_taken::text,'(unscheduled)'),
         'medium'
  from public.immunizations i
  join public.patient_records p on p.patient_id = i.patient_id
  where i.immunization_status = 'Pending'
    and i.deleted_at is null
    and i.date_due_taken is not null
    and i.date_due_taken <= (now() + interval '3 days')
    and i.date_due_taken >= now()
    and not exists (
      select 1 from public.notifications n
      where n.immunization_id = i.id and n.title = 'Upcoming immunization'
    );

  -- Overdue
  insert into public.notifications (user_id, patient_id, immunization_id, title, body, priority)
  select p.doc_id, p.patient_id, i.id,
         'Overdue immunization',
         'Immunization overdue since ' || i.date_due_taken::text,
         'high'
  from public.immunizations i
  join public.patient_records p on p.patient_id = i.patient_id
  where i.immunization_status in ('Pending','Overdue')
    and i.deleted_at is null
    and i.date_due_taken is not null
    and i.date_due_taken < now()
    and not exists (
      select 1 from public.notifications n
      where n.immunization_id = i.id and n.title = 'Overdue immunization'
    );
end;
$$;

-- Run on every change to immunizations
drop trigger if exists trg_immun_notifications on public.immunizations;
create trigger trg_immun_notifications
after insert or update on public.immunizations
for each statement execute procedure public.ensure_immunization_notifications();
```

Optional: schedule periodic check via Edge Scheduler:
- supabase functions deploy sync-pull (any deployed function qualifies)
- In Dashboard → Edge Functions → Schedules → add a cron calling a light function that executes select ensure_immunization_notifications();

## Flutter wiring (client)

- Initialize Supabase in main (anon key only). Store last sync timestamp in local SQLite and implement:
  - On connectivity gained: call sync-pull(since), apply to SQLite; then send outbox via sync-push.
  - Map JSON fields to your SQLite schema (same columns as Postgres).

## Next tasks

- Mirror the schema in local SQLite (with created_at, updated_at, deleted_at, version, sync_status).
- Implement outbox tables per entity and a small sync manager service.
- Add indexes on updated_at locally for faster merges.
- Write small integration tests for RPCs and Edge Functions.




