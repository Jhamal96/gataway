-- The Getaway Crew 2.0: authorization foundation (STAGING ONLY)
-- This migration creates isolated v2 tables. It does not migrate Floot users,
-- assign a platform owner, or modify existing production tables.
begin;

create schema if not exists getaway_v2;

create table if not exists getaway_v2.platform_admins (
  user_id uuid primary key references auth.users(id) on delete restrict,
  role text not null check (role in ('primary_owner','delegated_admin')),
  granted_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  revoked_at timestamptz,
  expires_at timestamptz,
  constraint owner_not_temporary check (role <> 'primary_owner' or (expires_at is null and revoked_at is null))
);
create unique index if not exists getaway_v2_one_primary_owner
  on getaway_v2.platform_admins (role) where role='primary_owner';

create table if not exists getaway_v2.trips (
  id uuid primary key default gen_random_uuid(),
  title text not null check (length(trim(title)) between 1 and 120),
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now()
);

create table if not exists getaway_v2.trip_members (
  trip_id uuid not null references getaway_v2.trips(id) on delete cascade,
  user_id uuid not null references auth.users(id),
  role text not null default 'traveler'
    check (role in ('trip_owner','lead_organizer','organizer','assistant_organizer','traveler')),
  created_at timestamptz not null default now(),
  primary key (trip_id,user_id)
);

create table if not exists getaway_v2.permission_grants (
  id uuid primary key default gen_random_uuid(),
  subject_user_id uuid not null references auth.users(id),
  trip_id uuid references getaway_v2.trips(id) on delete cascade,
  permission text not null check (permission in (
    'manage_organizers','grant_permissions','revoke_permissions',
    'edit_trip','edit_budget','edit_itinerary','manage_bookings',
    'vote_approvals','decide_approvals','view_audit'
  )),
  granted_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  expires_at timestamptz,
  revoked_at timestamptz,
  constraint valid_expiry check (expires_at is null or expires_at > created_at)
);
create index if not exists getaway_v2_grants_subject
  on getaway_v2.permission_grants(subject_user_id,trip_id,permission);

create table if not exists getaway_v2.audit_events (
  id bigint generated always as identity primary key,
  actor_id uuid references auth.users(id),
  trip_id uuid references getaway_v2.trips(id) on delete set null,
  event_type text not null,
  subject_user_id uuid references auth.users(id),
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

-- Deny direct client access until reviewed SECURITY DEFINER RPCs or a
-- trusted server API enforce owner-only delegation, revocation, and expiry.
alter table getaway_v2.platform_admins enable row level security;
alter table getaway_v2.trips enable row level security;
alter table getaway_v2.trip_members enable row level security;
alter table getaway_v2.permission_grants enable row level security;
alter table getaway_v2.audit_events enable row level security;
revoke all on schema getaway_v2 from public, anon, authenticated;
revoke all on all tables in schema getaway_v2 from public, anon, authenticated;
commit;
