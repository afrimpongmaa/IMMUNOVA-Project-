-- Create a lightweight trigger function that only updates updated_at
create or replace function public.touch_row_updated_at_only()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

-- New immunization_records table
create table if not exists public.immunization_records (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.patient_records(patient_id) on delete cascade,
  vaccine_id uuid not null references public.vaccines(id) on delete restrict,
  status text, -- nullable by default
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  version int not null default 1
);

create index if not exists idx_immunization_records_patient_id
  on public.immunization_records(patient_id);

create index if not exists idx_immunization_records_vaccine_id
  on public.immunization_records(vaccine_id);

create index if not exists idx_immunization_records_updated_at
  on public.immunization_records(updated_at);

do $$
begin
  if not exists (select 1 from pg_trigger where tgname = 'trg_immunization_records_touch') then
    create trigger trg_immunization_records_touch
    before update on public.immunization_records
    for each row execute procedure public.touch_row();
  end if;
end$$;

-- Clean up patient_records: remove vaccine_id and version (now handled in immunization_records)
-- Drop FK/index if present
do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'patient_records'
      and column_name = 'vaccine_id'
  ) then
    -- drop dependent index if it exists
    if exists (
      select 1 from pg_class c join pg_namespace n on n.oid = c.relnamespace
      where c.relname = 'idx_patient_records_vaccine_id'
        and n.nspname = 'public'
    ) then
      drop index if exists public.idx_patient_records_vaccine_id;
    end if;

    alter table public.patient_records
      drop column if exists vaccine_id;
  end if;
end$$;

-- Drop version column safely and replace trigger to not require it
do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'patient_records'
      and column_name = 'version'
  ) then
    -- Drop old trigger that increments version
    drop trigger if exists trg_patient_records_touch on public.patient_records;

    alter table public.patient_records
      drop column if exists version;

    -- Recreate trigger that only updates updated_at
    create trigger trg_patient_records_touch
    before update on public.patient_records
    for each row execute procedure public.touch_row_updated_at_only();
  else
    -- Ensure trigger exists even if version didn't
    if not exists (select 1 from pg_trigger where tgname = 'trg_patient_records_touch') then
      create trigger trg_patient_records_touch
      before update on public.patient_records
      for each row execute procedure public.touch_row_updated_at_only();
    end if;
  end if;
end$$;
