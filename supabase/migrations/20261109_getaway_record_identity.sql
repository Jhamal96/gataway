-- Prevent moving records between trips or changing their authors on update.
create or replace function getaway.protect_record_identity()
returns trigger language plpgsql set search_path=''
as $$ begin
 if new.trip_id is distinct from old.trip_id or new.author_id is distinct from old.author_id
 then raise exception 'Trip and author cannot be changed'; end if;
 return new;
end $$;
drop trigger if exists getaway_record_identity on public.getaway_records;
create trigger getaway_record_identity before update on public.getaway_records
for each row execute function getaway.protect_record_identity();
drop policy "records author update" on public.getaway_records;
create policy "records author update" on public.getaway_records for update to authenticated
using(author_id=(select auth.uid()) and (getaway.is_trip_member(trip_id) or getaway.is_trip_owner(trip_id)))
with check(author_id=(select auth.uid()) and (getaway.is_trip_member(trip_id) or getaway.is_trip_owner(trip_id)));
