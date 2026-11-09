-- Independent Getaway Crew tables. All auth accounts remain untouched.
create table if not exists public.getaway_profiles(
 user_id uuid primary key references auth.users(id) on delete cascade,
 display_name text not null default '',
 created_at timestamptz not null default now()
);
create table if not exists public.getaway_trips(
 id uuid primary key default gen_random_uuid(),
 owner_id uuid not null references auth.users(id),
 title text not null check(length(title) between 1 and 120),
 destination text not null default '',
 start_date date,
 end_date date,
 timezone text not null default 'America/New_York',
 currency text not null default 'USD',
 types jsonb not null default '["Weekend getaway"]'::jsonb,
 sections jsonb not null default '["Overview","Crew","Itinerary","Money","Bookings","Checklists"]'::jsonb,
 status text not null default 'Planning',
 budget_cents integer not null default 0 check(budget_cents>=0),
 invite_code text not null unique default encode(gen_random_bytes(9),'hex'),
 created_at timestamptz not null default now(),
 check(end_date is null or start_date is null or end_date>=start_date)
);
create table if not exists public.getaway_members(
 trip_id uuid not null references public.getaway_trips(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade,
 role text not null default 'member' check(role in ('organizer','member')),
 rsvp text not null default 'Pending',
 household text not null default '',
 adults integer not null default 1 check(adults>=0),
 children integer not null default 0 check(children>=0),
 primary key(trip_id,user_id)
);
create table if not exists public.getaway_records(
 id uuid primary key default gen_random_uuid(),
 trip_id uuid not null references public.getaway_trips(id) on delete cascade,
 author_id uuid not null references auth.users(id),
 kind text not null,
 title text not null,
 detail text not null default '',
 day text not null default '',
 time_text text not null default '',
 amount_cents integer not null default 0,
 url text not null default '',
 status text not null default 'Open',
 private boolean not null default false,
 options jsonb not null default '[]'::jsonb,
 splits jsonb not null default '[]'::jsonb,
 deadline text not null default '',
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create table if not exists public.getaway_responses(
 record_id uuid not null references public.getaway_records(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade,
 value text not null,
 primary key(record_id,user_id)
);
create table if not exists public.getaway_attachments(
 id uuid primary key default gen_random_uuid(),
 record_id uuid not null references public.getaway_records(id) on delete cascade,
 author_id uuid not null references auth.users(id),
 storage_path text not null,
 name text not null,
 content_type text not null,
 size_bytes integer not null,
 ready boolean not null default false
);
alter table public.getaway_profiles enable row level security;
alter table public.getaway_trips enable row level security;
alter table public.getaway_members enable row level security;
alter table public.getaway_records enable row level security;
alter table public.getaway_responses enable row level security;
alter table public.getaway_attachments enable row level security;
grant select,insert,update,delete on public.getaway_profiles,public.getaway_trips,public.getaway_members,public.getaway_records,public.getaway_responses,public.getaway_attachments to authenticated;
revoke all on public.getaway_profiles,public.getaway_trips,public.getaway_members,public.getaway_records,public.getaway_responses,public.getaway_attachments from anon;
create policy "profile self select" on public.getaway_profiles for select to authenticated using(user_id=(select auth.uid()));
create policy "profile self insert" on public.getaway_profiles for insert to authenticated with check(user_id=(select auth.uid()));
create policy "profile self update" on public.getaway_profiles for update to authenticated using(user_id=(select auth.uid())) with check(user_id=(select auth.uid()));
-- Use owner predicate and membership checks without recursive member policies.
create policy "trips members select" on public.getaway_trips for select to authenticated using(
 owner_id=(select auth.uid()) or exists(select 1 from public.getaway_members m where m.trip_id=id and m.user_id=(select auth.uid()))
);
create policy "trips owner insert" on public.getaway_trips for insert to authenticated with check(owner_id=(select auth.uid()));
create policy "trips owner update" on public.getaway_trips for update to authenticated using(owner_id=(select auth.uid())) with check(owner_id=(select auth.uid()));
create policy "trips owner delete" on public.getaway_trips for delete to authenticated using(owner_id=(select auth.uid()));
-- Membership reads use direct self or trip ownership; no membership recursion.
create policy "members visible" on public.getaway_members for select to authenticated using(
 user_id=(select auth.uid()) or exists(select 1 from public.getaway_trips t where t.id=trip_id and t.owner_id=(select auth.uid()))
);
create policy "members owner insert" on public.getaway_members for insert to authenticated with check(
 exists(select 1 from public.getaway_trips t where t.id=trip_id and t.owner_id=(select auth.uid()))
);
create policy "members owner update" on public.getaway_members for update to authenticated using(
 exists(select 1 from public.getaway_trips t where t.id=trip_id and t.owner_id=(select auth.uid()))
) with check(exists(select 1 from public.getaway_trips t where t.id=trip_id and t.owner_id=(select auth.uid())));
create policy "members owner delete" on public.getaway_members for delete to authenticated using(
 exists(select 1 from public.getaway_trips t where t.id=trip_id and t.owner_id=(select auth.uid()))
);
create policy "records member read" on public.getaway_records for select to authenticated using(
 exists(select 1 from public.getaway_trips t where t.id=trip_id and (t.owner_id=(select auth.uid()) or exists(select 1 from public.getaway_members m where m.trip_id=t.id and m.user_id=(select auth.uid()))))
 and (not private or author_id=(select auth.uid()) or exists(select 1 from public.getaway_trips t where t.id=trip_id and t.owner_id=(select auth.uid())))
);
create policy "records member insert" on public.getaway_records for insert to authenticated with check(
 author_id=(select auth.uid()) and exists(select 1 from public.getaway_trips t where t.id=trip_id and (t.owner_id=(select auth.uid()) or exists(select 1 from public.getaway_members m where m.trip_id=t.id and m.user_id=(select auth.uid()))))
);
create policy "records author update" on public.getaway_records for update to authenticated using(author_id=(select auth.uid())) with check(author_id=(select auth.uid()));
create policy "records author delete" on public.getaway_records for delete to authenticated using(author_id=(select auth.uid()));
create policy "responses self read" on public.getaway_responses for select to authenticated using(user_id=(select auth.uid()) or exists(select 1 from public.getaway_records r join public.getaway_trips t on t.id=r.trip_id where r.id=record_id and t.owner_id=(select auth.uid())));
create policy "responses self insert" on public.getaway_responses for insert to authenticated with check(user_id=(select auth.uid()) and exists(select 1 from public.getaway_records r where r.id=record_id));
create policy "responses self update" on public.getaway_responses for update to authenticated using(user_id=(select auth.uid())) with check(user_id=(select auth.uid()));
create policy "responses self delete" on public.getaway_responses for delete to authenticated using(user_id=(select auth.uid()));
create policy "attachments member read" on public.getaway_attachments for select to authenticated using(exists(select 1 from public.getaway_records r where r.id=record_id));
create policy "attachments self insert" on public.getaway_attachments for insert to authenticated with check(author_id=(select auth.uid()) and exists(select 1 from public.getaway_records r where r.id=record_id));
create policy "attachments self delete" on public.getaway_attachments for delete to authenticated using(author_id=(select auth.uid()));
