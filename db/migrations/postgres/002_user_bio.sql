-- USER BIO TABLE AND POLICIES
-- Depends on: public.users and touch_row()

create table if not exists public.user_bio (
	user_id uuid primary key references public.users(id) on delete cascade,
	avatar_url text,
	hospital_id uuid references public.hospitals(id) on delete set null,
	specialization text,
	bio text,
	years_experience int,
	languages jsonb, -- e.g., [{"language":"English","proficiency":"Fluent"}]
	certifications jsonb, -- e.g., [{"name":"BLS","issuer":"AHA"}]
	working_hours jsonb, -- e.g., {"days":["Mon","Tue"],"start":"08:00","end":"17:00"}
	created_at timestamptz not null default now(),
	updated_at timestamptz not null default now(),
	deleted_at timestamptz,
	version int not null default 1
);

create trigger trg_user_bio_touch
before update on public.user_bio
for each row execute procedure public.touch_row();

-- RLS
alter table public.user_bio enable row level security;

-- Owner can CRUD their own bio
drop policy if exists user_bio_owner_all on public.user_bio;
create policy user_bio_owner_all on public.user_bio
	for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Optional: allow read by authenticated users to display public profiles
-- Comment out if profiles must be private.
drop policy if exists user_bio_read_all on public.user_bio;
create policy user_bio_read_all on public.user_bio
	for select to authenticated using (true);

