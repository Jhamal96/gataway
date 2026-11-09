-- Resolve cross-table RLS recursion with narrow private helpers.
create or replace function getaway.is_trip_member(p_trip uuid)
returns boolean language sql stable security definer set search_path = ''
as $$ select (select auth.uid()) is not null and exists(
 select 1 from public.getaway_members m where m.trip_id=p_trip and m.user_id=(select auth.uid())
) $$;
create or replace function getaway.is_trip_owner(p_trip uuid)
returns boolean language sql stable security definer set search_path = ''
as $$ select (select auth.uid()) is not null and exists(
 select 1 from public.getaway_trips t where t.id=p_trip and t.owner_id=(select auth.uid())
) $$;
revoke all on function getaway.is_trip_member(uuid) from public,anon;
revoke all on function getaway.is_trip_owner(uuid) from public,anon;
grant usage on schema getaway to authenticated;
grant execute on function getaway.is_trip_member(uuid),getaway.is_trip_owner(uuid) to authenticated;
drop policy "trips members select" on public.getaway_trips;
create policy "trips members select" on public.getaway_trips for select to authenticated using(owner_id=(select auth.uid()) or getaway.is_trip_member(id));
drop policy "members visible" on public.getaway_members;
create policy "members visible" on public.getaway_members for select to authenticated using(user_id=(select auth.uid()) or getaway.is_trip_owner(trip_id));
drop policy "members owner insert" on public.getaway_members;
create policy "members owner insert" on public.getaway_members for insert to authenticated with check(getaway.is_trip_owner(trip_id));
drop policy "members owner update" on public.getaway_members;
create policy "members owner update" on public.getaway_members for update to authenticated using(getaway.is_trip_owner(trip_id)) with check(getaway.is_trip_owner(trip_id));
drop policy "members owner delete" on public.getaway_members;
create policy "members owner delete" on public.getaway_members for delete to authenticated using(getaway.is_trip_owner(trip_id));
drop policy "records member read" on public.getaway_records;
create policy "records member read" on public.getaway_records for select to authenticated using(
 (getaway.is_trip_owner(trip_id) or getaway.is_trip_member(trip_id))
 and (not private or author_id=(select auth.uid()) or getaway.is_trip_owner(trip_id))
);
drop policy "records member insert" on public.getaway_records;
create policy "records member insert" on public.getaway_records for insert to authenticated with check(
 author_id=(select auth.uid()) and (getaway.is_trip_owner(trip_id) or getaway.is_trip_member(trip_id))
);
drop policy "responses self read" on public.getaway_responses;
create policy "responses self read" on public.getaway_responses for select to authenticated using(
 user_id=(select auth.uid()) or exists(select 1 from public.getaway_records r where r.id=record_id and getaway.is_trip_owner(r.trip_id))
);
drop policy "responses self insert" on public.getaway_responses;
create policy "responses self insert" on public.getaway_responses for insert to authenticated with check(
 user_id=(select auth.uid()) and exists(select 1 from public.getaway_records r where r.id=record_id and (getaway.is_trip_owner(r.trip_id) or getaway.is_trip_member(r.trip_id)))
);
