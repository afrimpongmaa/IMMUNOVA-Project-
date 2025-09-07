-- Hospitals master table (idempotent)
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

-- Ensure touch trigger exists for hospitals
do $$
begin
  if not exists (select 1 from pg_trigger where tgname = 'trg_hospitals_touch') then
    create trigger trg_hospitals_touch
    before update on public.hospitals
    for each row execute procedure public.touch_row();
  end if;
end$$;

-- Seed hospitals (idempotent via ON CONFLICT DO NOTHING)

-- Greater Accra Region (Accra/Tema/La/Pantang/Legon)
insert into public.hospitals (name, region, city, category) values
  ('Korle Bu Teaching Hospital', 'Greater Accra', 'Accra', 'Teaching'),
  ('University of Ghana Hospital (Legon)', 'Greater Accra', 'Legon', 'Teaching'),
  ('Greater Accra Regional Hospital (Ridge Regional Hospital)', 'Greater Accra', 'Accra', 'Regional'),
  ('37 Military Hospital', 'Greater Accra', 'Accra', 'Military'),
  ('Accra Psychiatric Hospital', 'Greater Accra', 'Accra', 'Psychiatric'),
  ('La General Hospital', 'Greater Accra', 'La', 'Public'),
  ('Tema General Hospital', 'Greater Accra', 'Tema', 'Public'),
  ('Police Hospital', 'Greater Accra', 'Accra', 'Public'),
  ('Pantang Hospital', 'Greater Accra', 'Pantang', 'Psychiatric'),
  ('Princess Marie Louise Hospital (Children''s Hospital)', 'Greater Accra', 'Accra', 'Children'),
  ('Nyaho Medical Centre', 'Greater Accra', 'Accra', 'Private'),
  ('The Trust Hospital', 'Greater Accra', 'Accra', 'Private'),
  ('Lister Hospital & Fertility Centre', 'Greater Accra', 'Accra', 'Private'),
  ('Airport Women''s Hospital', 'Greater Accra', 'Accra', 'Private'),
  ('Del International Hospital', 'Greater Accra', 'Accra', 'Private'),
  ('Narh-Bita Hospital', 'Greater Accra', 'Tema', 'Private'),
  ('Vision Hospital', 'Greater Accra', 'Accra', 'Private'),
  ('Impact Medical and Diagnostic Centre', 'Greater Accra', 'Accra', 'Private'),
  ('Achimota Hospital', 'Greater Accra', 'Accra', 'Private'),
  ('Hill Top Surgical Hospital', 'Greater Accra', 'Accra', 'Private'),
  ('North Ridge Clinic', 'Greater Accra', 'Accra', 'Private'),
  ('Shalom Medical Center', 'Greater Accra', 'Accra', 'Private'),
  ('Holy Trinity Hospital', 'Greater Accra', 'Accra', 'Private'),
  ('St John''s Hospital & Fertility Centre', 'Greater Accra', 'Accra', 'Private'),
  ('Medifem Hospital', 'Greater Accra', 'Accra', 'Private'),
  ('North Legon Hospital', 'Greater Accra', 'Accra', 'Private'),
  ('Bemuah Royal Hospital', 'Greater Accra', 'Accra', 'Private'),
  ('1st Global Hospital', 'Greater Accra', 'Accra', 'Private'),
  ('Finney Hospital and Fertility Centre', 'Greater Accra', 'Accra', 'Private'),
  ('Lapaz Community Hospital', 'Greater Accra', 'Accra', 'Private'),
  ('Manna Mission Hospital', 'Greater Accra', 'Accra', 'Private'),
  ('Crown Medical Centre', 'Greater Accra', 'Accra', 'Private'),
  ('Eden Family Hospital', 'Greater Accra', 'Accra', 'Private'),
  ('C&J General Hospital', 'Greater Accra', 'Accra', 'Private'),
  ('Provita Specialist Hospital', 'Greater Accra', 'Accra', 'Private'),
  ('Jubail Specialist Hospital', 'Greater Accra', 'Accra', 'Private'),
  ('Tema Women''s Hospital', 'Greater Accra', 'Tema', 'Private'),
  ('Valco Hospital', 'Greater Accra', 'Tema', 'Private'),
  ('Tema Polyclinic', 'Greater Accra', 'Tema', 'Polyclinic')
on conflict (name) do nothing;

-- Ashanti Region (Kumasi)
insert into public.hospitals (name, region, city, category) values
  ('Komfo Anokye Teaching Hospital (KATH)', 'Ashanti', 'Kumasi', 'Teaching'),
  ('West End Hospital', 'Ashanti', 'Kumasi', 'Private'),
  ('Asafo-Boakye Specialist Hospital', 'Ashanti', 'Kumasi', 'Private')
on conflict (name) do nothing;

-- Northern Region (Tamale)
insert into public.hospitals (name, region, city, category) values
  ('Tamale Teaching Hospital', 'Northern', 'Tamale', 'Teaching'),
  ('Tamale Central Hospital', 'Northern', 'Tamale', 'Public')
on conflict (name) do nothing;

-- Central Region (Cape Coast)
insert into public.hospitals (name, region, city, category) values
  ('Cape Coast Teaching Hospital', 'Central', 'Cape Coast', 'Teaching'),
  ('Central Regional Hospital', 'Central', 'Cape Coast', 'Regional')
on conflict (name) do nothing;

-- Eastern Region (Koforidua)
insert into public.hospitals (name, region, city, category) values
  ('Eastern Regional Hospital (Koforidua)', 'Eastern', 'Koforidua', 'Regional')
on conflict (name) do nothing;

-- Western Region (Sekondi-Takoradi)
insert into public.hospitals (name, region, city, category) values
  ('Effia Nkwanta Regional Hospital (Sekondi-Takoradi)', 'Western', 'Sekondi-Takoradi', 'Regional')
on conflict (name) do nothing;

-- Upper East Region (Bolgatanga)
insert into public.hospitals (name, region, city, category) values
  ('Upper East Regional Hospital (Bolgatanga)', 'Upper East', 'Bolgatanga', 'Regional')
on conflict (name) do nothing;

-- Upper West Region (Wa)
insert into public.hospitals (name, region, city, category) values
  ('Upper West Regional Hospital (Wa)', 'Upper West', 'Wa', 'Regional')
on conflict (name) do nothing;

-- Volta Region (Ho)
insert into public.hospitals (name, region, city, category) values
  ('Ho Teaching Hospital', 'Volta', 'Ho', 'Teaching'),
  ('Volta Regional Hospital', 'Volta', 'Ho', 'Regional')
on conflict (name) do nothing;

-- Brong Ahafo Region (Sunyani)
insert into public.hospitals (name, region, city, category) values
  ('Brong Ahafo Regional Hospital (Sunyani)', 'Brong Ahafo', 'Sunyani', 'Regional')
on conflict (name) do nothing;

-- Add FK column to users -> hospitals (safe if run multiple times)
alter table public.users
  add column if not exists hospital_id uuid references public.hospitals(id) on delete set null;

-- If user_bio table exists, ensure it references hospitals too (idempotent)
do $$
begin
  if exists (select 1 from information_schema.tables where table_schema='public' and table_name='user_bio') then
    alter table public.user_bio
      add column if not exists hospital_id uuid references public.hospitals(id) on delete set null;
  end if;
end$$;

-- Add FK column to patient_records -> vaccines and index (safe if run multiple times)
alter table public.patient_records
  add column if not exists vaccine_id uuid references public.vaccines(id) on delete set null;

create index if not exists idx_patient_records_vaccine_id
  on public.patient_records(vaccine_id);
