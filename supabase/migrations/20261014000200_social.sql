-- « Qui l'a dit ? » : pseudo, amis, classement entre amis

alter table public.profiles
  add column friend_code text unique not null default upper(substr(md5(gen_random_uuid()::text), 1, 8)),
  add constraint username_format check (username is null or username ~ '^[[:alnum:]_ .À-ÿ-]{2,20}$');
create unique index profiles_username_unique on public.profiles (lower(username));

create table public.friendships (
  user_id uuid not null references auth.users(id) on delete cascade,
  friend_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, friend_id),
  check (user_id <> friend_id)
);
alter table public.friendships enable row level security;
create policy "own friendships" on public.friendships for select using (user_id = auth.uid());

-- Ajout d'un ami par son code (lien réciproque)
create function public.add_friend(p_friend_code text)
returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_user uuid := auth.uid();
  v_friend record;
begin
  if v_user is null then raise exception 'not authenticated'; end if;
  select id, username into v_friend from profiles where friend_code = upper(trim(p_friend_code));
  if not found then raise exception 'friend not found'; end if;
  if v_friend.id = v_user then raise exception 'cannot add yourself'; end if;
  insert into friendships (user_id, friend_id) values (v_user, v_friend.id), (v_friend.id, v_user)
  on conflict do nothing;
  return jsonb_build_object('id', v_friend.id, 'username', v_friend.username);
end $$;

create function public.remove_friend(p_friend uuid)
returns void
language sql security definer set search_path = public as $$
  delete from friendships
   where (user_id = auth.uid() and friend_id = p_friend)
      or (user_id = p_friend and friend_id = auth.uid());
$$;

-- Classement entre amis (le joueur + ses amis), sans exposer d'autres données
create function public.friends_leaderboard()
returns table (user_id uuid, username text, total_points_earned integer, best_streak integer,
               cards bigint, duels_won integer, is_me boolean)
language sql stable security definer set search_path = public as $$
  select p.id, coalesce(p.username, 'Joueur anonyme'), p.total_points_earned, p.best_streak,
         (select count(*) from user_cards uc where uc.user_id = p.id),
         p.duels_won, p.id = auth.uid()
    from profiles p
   where p.id = auth.uid()
      or p.id in (select f.friend_id from friendships f where f.user_id = auth.uid())
   order by p.total_points_earned desc;
$$;

revoke execute on function public.add_friend(text) from public, anon;
revoke execute on function public.remove_friend(uuid) from public, anon;
revoke execute on function public.friends_leaderboard() from public, anon;
grant execute on function public.add_friend(text) to authenticated;
grant execute on function public.remove_friend(uuid) to authenticated;
grant execute on function public.friends_leaderboard() to authenticated;
