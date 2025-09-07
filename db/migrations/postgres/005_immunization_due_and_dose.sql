-- Enum for immunization dose
do $$
begin
  if not exists (select 1 from pg_type where typname = 'immunization_dose') then
    create type public.immunization_dose as enum ('1st','2nd','3rd','4th','5th','Booster');
  end if;
end$$;

-- Add date_due and dose to immunization_records
alter table if exists public.immunization_records
  add column if not exists date_due date,
  add column if not exists dose public.immunization_dose;

-- Helpful index for due-date queries
create index if not exists idx_immunization_records_date_due
  on public.immunization_records(date_due);

-- Enable RLS for immunization_records and allow owner-doctor to CRUD
alter table if exists public.immunization_records enable row level security;

drop policy if exists immunization_records_patient_owned on public.immunization_records;
create policy immunization_records_patient_owned on public.immunization_records
  for all
  to authenticated
  using (
    exists (
      select 1 from public.patient_records p
      where p.patient_id = public.immunization_records.patient_id
        and p.doc_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.patient_records p
      where p.patient_id = public.immunization_records.patient_id
        and p.doc_id = auth.uid()
    )
  );

-- Add immunization_status enum and enforce default 'pending' on status
do $$
begin
  if not exists (select 1 from pg_type where typname = 'immunization_status') then
    create type public.immunization_status as enum ('pending','immunized','overdue');
  end if;
end$$;

alter table if exists public.immunization_records
  add column if not exists status public.immunization_status;

update public.immunization_records
set status = 'pending'
where status is null;

alter table if exists public.immunization_records
  alter column status set default 'pending',
  alter column status set not null;

create index if not exists idx_immunization_records_status
  on public.immunization_records(status);
