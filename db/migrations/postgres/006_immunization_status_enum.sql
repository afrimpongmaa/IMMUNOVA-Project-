do $$
begin
  if not exists (select 1 from pg_type where typname = 'immunization_status') then
    create type public.immunization_status as enum ('pending','immunized','overdue');
  end if;
end$$;

-- Migrate column to enum; coerce existing values or default to pending
alter table if exists public.immunization_records
  alter column status type public.immunization_status using
    case
      when status is null then null
      when lower(status) in ('pending','immunized','overdue') then lower(status)::public.immunization_status
      else 'pending'::public.immunization_status
    end;

update public.immunization_records
set status = 'pending'
where status is null;

alter table if exists public.immunization_records
  alter column status set default 'pending',
  alter column status set not null;

create index if not exists idx_immunization_records_status
  on public.immunization_records(status);
