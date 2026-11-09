-- Independent Getaway Crew migration staging.
-- Kept in a private schema: no browser roles, no changes to existing auth accounts.
create schema if not exists getaway;
revoke all on schema getaway from public, anon, authenticated;
create table if not exists getaway.legacy_users (
  floot_user_id bigint primary key,
  email text not null,
  display_name text not null default '',
  supabase_user_id uuid unique references auth.users(id) on delete set null,
  claim_verified_at timestamptz,
  migrated_at timestamptz not null default now()
);
create table if not exists getaway.legacy_trips (
  id uuid primary key,
  floot_owner_id bigint not null references getaway.legacy_users(floot_user_id),
  payload jsonb not null,
  migrated_at timestamptz not null default now()
);
create table if not exists getaway.legacy_members (
  trip_id uuid not null references getaway.legacy_trips(id),
  floot_user_id bigint not null references getaway.legacy_users(floot_user_id),
  payload jsonb not null,
  primary key(trip_id,floot_user_id)
);
create table if not exists getaway.legacy_records (
  id uuid primary key,
  trip_id uuid not null references getaway.legacy_trips(id),
  floot_author_id bigint not null references getaway.legacy_users(floot_user_id),
  payload jsonb not null
);
create table if not exists getaway.legacy_responses (
  record_id uuid not null references getaway.legacy_records(id),
  floot_user_id bigint not null references getaway.legacy_users(floot_user_id),
  payload jsonb not null,
  primary key(record_id,floot_user_id)
);
create table if not exists getaway.legacy_attachments (
  id uuid primary key,
  record_id uuid not null references getaway.legacy_records(id),
  floot_author_id bigint not null references getaway.legacy_users(floot_user_id),
  payload jsonb not null,
  file_migrated boolean not null default false
);
alter table getaway.legacy_users enable row level security;
alter table getaway.legacy_trips enable row level security;
alter table getaway.legacy_members enable row level security;
alter table getaway.legacy_records enable row level security;
alter table getaway.legacy_responses enable row level security;
alter table getaway.legacy_attachments enable row level security;
revoke all on all tables in schema getaway from public, anon, authenticated;
-- No RLS policies by design: staging is admin-only and never exposed via Data API.
