-- 12-character, 72-bit invitation codes and a controlled join operation.
create or replace function getaway.new_invite_code()
returns text language sql volatile set search_path = ''
as $$ select translate(rtrim(encode(extensions.gen_random_bytes(9),'base64'),'='),'+/','-_') $$;
alter table public.getaway_trips alter column invite_code set default getaway.new_invite_code();
create or replace function public.getaway_join_trip(p_code text)
returns uuid language plpgsql security definer set search_path = ''
as $$
declare v_user uuid := auth.uid(); v_trip uuid;
begin
 if v_user is null then raise exception 'Sign in to join'; end if;
 if length(p_code)<12 or length(p_code)>100 then raise exception 'Invalid invitation'; end if;
 select t.id into v_trip from public.getaway_trips t where t.invite_code=p_code;
 if v_trip is null then raise exception 'Invitation not found'; end if;
 insert into public.getaway_members(trip_id,user_id,role)
 values(v_trip,v_user,'member') on conflict(trip_id,user_id) do nothing;
 return v_trip;
end $$;
revoke all on function public.getaway_join_trip(text) from public,anon;
grant execute on function public.getaway_join_trip(text) to authenticated;
