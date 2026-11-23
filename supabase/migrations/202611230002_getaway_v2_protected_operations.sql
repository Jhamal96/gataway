-- Getaway Crew 2.0 protected operations: isolated staging migration.
-- Apply only after reviewing migration 202611230001. No automatic owner bootstrap.
begin;

create or replace function getaway_v2.is_primary_owner(p_actor uuid)
returns boolean language sql stable security definer
set search_path = '' as $$
  select p_actor is not null and exists (
    select 1 from getaway_v2.platform_admins a
    where a.user_id = p_actor and a.role = 'primary_owner'
      and a.revoked_at is null and a.expires_at is null
  );
$$;

create or replace function getaway_v2.has_permission(
  p_actor uuid, p_permission text, p_trip uuid default null
) returns boolean language sql stable security definer
set search_path = '' as $$
  select getaway_v2.is_primary_owner(p_actor)
    or (p_actor is not null and exists (
      select 1 from getaway_v2.permission_grants g
      where g.subject_user_id = p_actor
        and g.permission = p_permission
        and g.revoked_at is null
        and (g.expires_at is null or g.expires_at > now())
        and (g.trip_id is null or g.trip_id = p_trip)
    ));
$$;

-- Only the verified primary owner can grant, extend, or revoke delegated
-- privileges. Calls must run in a trusted authenticated context; do not
-- expose these functions to untrusted clients until reviewed and tested.
create or replace function getaway_v2.owner_grant_permission(
  p_subject uuid, p_permission text, p_trip uuid default null,
  p_expires_at timestamptz default null
) returns uuid language plpgsql security definer
set search_path = '' as $$
declare
  v_actor uuid := auth.uid();
  v_id uuid;
begin
  if not getaway_v2.is_primary_owner(v_actor) then
    raise exception 'not authorized' using errcode = '42501';
  end if;
  if p_subject is null or p_subject = v_actor then
    raise exception 'invalid permission recipient';
  end if;
  if p_expires_at is not null and p_expires_at <= now() then
    raise exception 'expiry must be in the future';
  end if;
  if p_permission not in (
    'manage_organizers','grant_permissions','revoke_permissions',
    'edit_trip','edit_budget','edit_itinerary','manage_bookings',
    'vote_approvals','decide_approvals','view_audit'
  ) then
    raise exception 'unsupported permission';
  end if;
  insert into getaway_v2.permission_grants
    (subject_user_id,trip_id,permission,granted_by,expires_at)
  values (p_subject,p_trip,p_permission,v_actor,p_expires_at)
  returning id into v_id;
  insert into getaway_v2.audit_events
    (actor_id,trip_id,event_type,subject_user_id,details)
  values (v_actor,p_trip,'permission.granted',p_subject,
    jsonb_build_object('grant_id',v_id,'permission',p_permission,'expires_at',p_expires_at));
  return v_id;
end;
$$;

create or replace function getaway_v2.owner_revoke_permission(p_grant uuid)
returns boolean language plpgsql security definer
set search_path = '' as $$
declare
  v_actor uuid := auth.uid();
  v_row getaway_v2.permission_grants%rowtype;
begin
  if not getaway_v2.is_primary_owner(v_actor) then
    raise exception 'not authorized' using errcode = '42501';
  end if;
  update getaway_v2.permission_grants
     set revoked_at = now()
   where id = p_grant and revoked_at is null
   returning * into v_row;
  if not found then return false; end if;
  insert into getaway_v2.audit_events
    (actor_id,trip_id,event_type,subject_user_id,details)
  values (v_actor,v_row.trip_id,'permission.revoked',v_row.subject_user_id,
    jsonb_build_object('grant_id',p_grant,'permission',v_row.permission));
  return true;
end;
$$;

create or replace function getaway_v2.owner_extend_permission(
  p_grant uuid, p_expires_at timestamptz default null
) returns boolean language plpgsql security definer
set search_path = '' as $$
declare
  v_actor uuid := auth.uid();
  v_row getaway_v2.permission_grants%rowtype;
begin
  if not getaway_v2.is_primary_owner(v_actor) then
    raise exception 'not authorized' using errcode = '42501';
  end if;
  if p_expires_at is not null and p_expires_at <= now() then
    raise exception 'expiry must be in the future';
  end if;
  update getaway_v2.permission_grants
     set expires_at = p_expires_at
   where id = p_grant and revoked_at is null
   returning * into v_row;
  if not found then return false; end if;
  insert into getaway_v2.audit_events
    (actor_id,trip_id,event_type,subject_user_id,details)
  values (v_actor,v_row.trip_id,'permission.extended',v_row.subject_user_id,
    jsonb_build_object('grant_id',p_grant,'expires_at',p_expires_at));
  return true;
end;
$$;

-- Defense in depth: no API invocation permissions are granted yet.
revoke all on function getaway_v2.is_primary_owner(uuid) from public,anon,authenticated;
revoke all on function getaway_v2.has_permission(uuid,text,uuid) from public,anon,authenticated;
revoke all on function getaway_v2.owner_grant_permission(uuid,text,uuid,timestamptz) from public,anon,authenticated;
revoke all on function getaway_v2.owner_revoke_permission(uuid) from public,anon,authenticated;
revoke all on function getaway_v2.owner_extend_permission(uuid,timestamptz) from public,anon,authenticated;
commit;
