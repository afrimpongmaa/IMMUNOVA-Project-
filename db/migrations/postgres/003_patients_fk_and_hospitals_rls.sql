-- Ensure hospitals table has permissive read policy for all external roles
alter table if exists public.hospitals enable row level security;

drop policy if exists hospitals_read_all on public.hospitals;
create policy hospitals_read_all on public.hospitals
  for select
  to anon, authenticated
  using (true);

-- Ensure patient_records.doc_id references public.users(id)
do $$
begin
  -- Drop known constraint name if it exists (safe; will re-add)
  if exists (
    select 1 from pg_constraint
    where conname = 'patient_records_doc_id_fkey'
      and conrelid = 'public.patient_records'::regclass
  ) then
    alter table public.patient_records
      drop constraint patient_records_doc_id_fkey;
  end if;

  -- Recreate FK constraint pointing to public.users(id)
  alter table public.patient_records
    add constraint patient_records_doc_id_fkey
    foreign key (doc_id) references public.users(id) on delete restrict;
exception
  when duplicate_object then
    -- Constraint already exists from a previous run; ignore
    null;
end$$;

-- Optional: ensure supporting indexes exist (no-op if already present)
create index if not exists idx_patient_records_doc_id
  on public.patient_records(doc_id);
