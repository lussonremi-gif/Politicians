-- Ajout d'un ami par code ou par pseudo (le code reste prioritaire en cas d'égalité)

create or replace function public.add_friend(p_friend_code text)
returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_user uuid := auth.uid();
  v_raw text := trim(p_friend_code);
  v_friend record;
begin
  if v_user is null then raise exception 'not authenticated'; end if;
  if v_raw = '' then raise exception 'friend not found'; end if;
  select id, username into v_friend
    from (
      select id, username
        from profiles
       where friend_code = upper(v_raw)
          or lower(username) = lower(v_raw)
       order by case when friend_code = upper(v_raw) then 0 else 1 end
       limit 1
    ) match;
  if not found then raise exception 'friend not found'; end if;
  if v_friend.id = v_user then raise exception 'cannot add yourself'; end if;
  insert into friendships (user_id, friend_id) values (v_user, v_friend.id), (v_friend.id, v_user)
  on conflict do nothing;
  return jsonb_build_object('id', v_friend.id, 'username', v_friend.username);
end $$;
