-- « Qui l'a dit ? » : duels en temps réel, 1 contre 1
--
-- Déroulé :
--   1. create_duel()      → le joueur 1 obtient un code à partager
--   2. join_duel(code)    → le joueur 2 rejoint, la partie démarre
--   3. duel_state(id)     → état courant (question en cours, scores, révélation)
--   4. submit_duel_answer → réponse ; quand les deux ont répondu (ou que le temps
--                           est écoulé), on passe à la question suivante
--   5. abandon_duel(id)   → abandon : l'adversaire gagne
--
-- Les clients s'abonnent en Realtime aux changements de la ligne `duels`
-- (scores, question courante, qui a répondu) et rappellent duel_state().
-- La bonne réponse n'est jamais exposée avant que le joueur ait répondu.

alter table public.profiles
  add column duels_played integer not null default 0,
  add column duels_won integer not null default 0;

create table public.duels (
  id uuid primary key default gen_random_uuid(),
  code text unique not null default upper(substr(md5(gen_random_uuid()::text), 1, 6)),
  player1 uuid not null references auth.users(id) on delete cascade,
  player2 uuid references auth.users(id) on delete cascade,
  status text not null default 'waiting'
    check (status in ('waiting', 'active', 'finished', 'abandoned')),
  theme text,
  -- Règles v1 (à valider) : 7 citations, 15 secondes par réponse
  question_count integer not null default 7,
  answer_seconds integer not null default 15,
  current_position integer not null default 0,
  current_served_at timestamptz,          -- début de la question courante (peut être dans le futur : compte à rebours)
  p1_answered integer not null default 0, -- dernière position répondue par chaque joueur
  p2_answered integer not null default 0,
  score1 integer not null default 0,
  score2 integer not null default 0,
  winner uuid references auth.users(id),
  abandoned_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  started_at timestamptz,
  finished_at timestamptz,
  constraint distinct_players check (player2 is null or player2 <> player1)
);
create index on public.duels (player1);
create index on public.duels (player2);

create table public.duel_questions (
  duel_id uuid not null references public.duels(id) on delete cascade,
  position integer not null,
  quote_id uuid not null references public.quotes(id) on delete cascade,
  option_a uuid not null references public.personalities(id),
  option_b uuid not null references public.personalities(id),
  primary key (duel_id, position)
);

create table public.duel_answers (
  duel_id uuid not null references public.duels(id) on delete cascade,
  position integer not null,
  user_id uuid not null references auth.users(id) on delete cascade,
  chosen_id uuid references public.personalities(id), -- null = temps écoulé
  is_correct boolean not null,
  points integer not null default 0,
  answered_at timestamptz not null default now(),
  primary key (duel_id, position, user_id)
);

alter table public.duels enable row level security;
alter table public.duel_questions enable row level security;
alter table public.duel_answers enable row level security;

-- Les participants voient la ligne du duel (pour Realtime) ; tout le reste passe par les fonctions.
create policy "duel participants" on public.duels for select
  using (auth.uid() in (player1, player2));

alter publication supabase_realtime add table public.duels;

-- ---------------------------------------------------------------------------
-- Fonctions internes
-- ---------------------------------------------------------------------------

-- Fin de duel : vainqueur, points crédités, carte bonus pour le vainqueur
create function public._duel_finish(p_duel uuid, p_abandoned_by uuid default null)
returns void
language plpgsql security definer set search_path = public as $$
declare
  d record;
  v_winner uuid;
  v_card uuid;
begin
  select * into d from duels where id = p_duel for update;
  if d.status not in ('active', 'waiting') then return; end if;

  if p_abandoned_by is not null then
    v_winner := case when p_abandoned_by = d.player1 then d.player2 else d.player1 end;
  elsif d.score1 > d.score2 then v_winner := d.player1;
  elsif d.score2 > d.score1 then v_winner := d.player2;
  end if; -- égalité : pas de vainqueur

  update duels
     set status = case when p_abandoned_by is null then 'finished' else 'abandoned' end,
         winner = v_winner, abandoned_by = p_abandoned_by, finished_at = now()
   where id = p_duel;

  if d.player2 is null then return; end if; -- duel jamais commencé

  -- Les points marqués pendant le duel sont crédités aux deux joueurs
  update profiles set points = points + d.score1, total_points_earned = total_points_earned + d.score1,
                      duels_played = duels_played + 1
   where id = d.player1;
  update profiles set points = points + d.score2, total_points_earned = total_points_earned + d.score2,
                      duels_played = duels_played + 1
   where id = d.player2;

  -- Victoire : bonus de 200 points et une carte (tirée parmi les citations du duel).
  -- Sur abandon, le bonus n'est accordé que si au moins la moitié du duel a été jouée
  -- (évite de cumuler des victoires en créant et abandonnant des duels).
  if v_winner is not null and (p_abandoned_by is null or d.current_position * 2 > d.question_count) then
    update profiles set points = points + 200, total_points_earned = total_points_earned + 200,
                        duels_won = duels_won + 1
     where id = v_winner;
    select dq.quote_id into v_card from duel_questions dq where dq.duel_id = p_duel order by random() limit 1;
    if v_card is not null then
      insert into user_cards (user_id, quote_id) values (v_winner, v_card)
      on conflict (user_id, quote_id) do update set copies = user_cards.copies + 1;
    end if;
  end if;
end $$;

-- Avance le duel : temps écoulé → réponses manquantes comptées fausses ;
-- les deux joueurs ont répondu → question suivante (après 3 s de révélation).
create function public._duel_tick(p_duel uuid)
returns void
language plpgsql security definer set search_path = public as $$
declare
  d record;
  v_expired boolean;
begin
  select * into d from duels where id = p_duel for update;
  if d.status <> 'active' then return; end if;

  v_expired := now() > d.current_served_at + make_interval(secs => d.answer_seconds);

  if v_expired then
    insert into duel_answers (duel_id, position, user_id, chosen_id, is_correct, points)
    select d.id, d.current_position, u, null, false, 0
      from unnest(array[d.player1, d.player2]) u
    on conflict do nothing;
    update duels set p1_answered = d.current_position, p2_answered = d.current_position where id = d.id;
  elsif d.p1_answered < d.current_position or d.p2_answered < d.current_position then
    return;
  end if;

  if d.current_position >= d.question_count then
    perform _duel_finish(d.id);
  else
    update duels
       set current_position = d.current_position + 1,
           current_served_at = now() + interval '3 seconds'
     where id = d.id;
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- API
-- ---------------------------------------------------------------------------
create function public.create_duel(p_theme text default null, p_question_count integer default 7)
returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_user uuid := auth.uid();
  v_duel duels;
  v_n integer;
begin
  if v_user is null then raise exception 'not authenticated'; end if;

  -- Un seul duel en attente par joueur
  update duels set status = 'abandoned', finished_at = now()
   where player1 = v_user and status = 'waiting';

  insert into duels (player1, theme, question_count)
  values (v_user, p_theme, least(greatest(p_question_count, 3), 15))
  returning * into v_duel;

  -- Même série de citations pour les deux joueurs
  insert into duel_questions (duel_id, position, quote_id, option_a, option_b)
  select v_duel.id, row_number() over (), pq.quote_id, pq.option_a, pq.option_b
    from _pick_questions(v_duel.question_count, p_theme) pq;
  get diagnostics v_n = row_count;
  if v_n = 0 then raise exception 'no playable quotes'; end if;
  update duels set question_count = v_n where id = v_duel.id;

  return jsonb_build_object('id', v_duel.id, 'code', v_duel.code);
end $$;

create function public.join_duel(p_code text)
returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_user uuid := auth.uid();
  d record;
begin
  if v_user is null then raise exception 'not authenticated'; end if;
  select * into d from duels where code = upper(trim(p_code)) for update;
  if not found then raise exception 'duel not found'; end if;
  if d.player1 = v_user or d.player2 = v_user then return d.id; end if;
  if d.status <> 'waiting' then raise exception 'duel unavailable'; end if;

  update duels
     set player2 = v_user, status = 'active', started_at = now(),
         current_position = 1, current_served_at = now() + interval '3 seconds'
   where id = d.id;
  return d.id;
end $$;

create function public.duel_state(p_duel uuid)
returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_user uuid := auth.uid();
  d record;
  v_me integer;
  v_question jsonb;
  v_reveal jsonb;
  v_my_answered integer;
  v_opp_answered integer;
begin
  select * into d from duels where id = p_duel;
  if not found or v_user not in (d.player1, coalesce(d.player2, d.player1)) then
    raise exception 'duel not found';
  end if;

  perform _duel_tick(p_duel);
  select * into d from duels where id = p_duel;

  v_me := case when v_user = d.player1 then 1 else 2 end;
  v_my_answered := case when v_me = 1 then d.p1_answered else d.p2_answered end;
  v_opp_answered := case when v_me = 1 then d.p2_answered else d.p1_answered end;

  -- Question courante (sans la réponse), seulement une fois le compte à rebours écoulé
  if d.status = 'active' and now() >= d.current_served_at and v_my_answered < d.current_position then
    select jsonb_build_object(
      'position', dq.position,
      'quote', q.text,
      'is_demo', q.is_demo,
      'options', jsonb_build_array(
        jsonb_build_object('id', pa.id, 'name', pa.name, 'description', pa.description, 'image_url', pa.image_url),
        jsonb_build_object('id', pb.id, 'name', pb.name, 'description', pb.description, 'image_url', pb.image_url)))
      into v_question
      from duel_questions dq
      join quotes q on q.id = dq.quote_id
      join personalities pa on pa.id = dq.option_a
      join personalities pb on pb.id = dq.option_b
     where dq.duel_id = d.id and dq.position = d.current_position;
  end if;

  -- Révélation de la dernière question à laquelle le joueur a répondu
  if v_my_answered > 0 then
    select jsonb_build_object(
      'position', dq.position,
      'quote', q.text,
      'answer_id', q.personality_id,
      'author', p.name,
      'said_on', q.said_on,
      'occasion', q.occasion,
      'source_label', q.source_label,
      'source_url', q.source_url,
      'mine', (select jsonb_build_object('chosen_id', a.chosen_id, 'correct', a.is_correct, 'points', a.points)
                 from duel_answers a where a.duel_id = d.id and a.position = dq.position and a.user_id = v_user),
      -- La réponse de l'adversaire n'est montrée que s'il a aussi répondu
      'opponent', (select jsonb_build_object('correct', a.is_correct, 'points', a.points)
                     from duel_answers a where a.duel_id = d.id and a.position = dq.position and a.user_id <> v_user))
      into v_reveal
      from duel_questions dq
      join quotes q on q.id = dq.quote_id
      join personalities p on p.id = q.personality_id
     where dq.duel_id = d.id and dq.position = v_my_answered;
  end if;

  return jsonb_build_object(
    'id', d.id,
    'code', d.code,
    'status', d.status,
    'me', v_me,
    'opponent_name', (select coalesce(username, 'Adversaire') from profiles
                       where id = case when v_me = 1 then d.player2 else d.player1 end),
    'has_opponent', d.player2 is not null,
    'question_count', d.question_count,
    'answer_seconds', d.answer_seconds,
    'current_position', d.current_position,
    'served_at', d.current_served_at,
    'deadline', d.current_served_at + make_interval(secs => d.answer_seconds),
    'server_now', now(),
    'my_score', case when v_me = 1 then d.score1 else d.score2 end,
    'opponent_score', case when v_me = 1 then d.score2 else d.score1 end,
    'my_answered', v_my_answered,
    'opponent_answered', v_opp_answered,
    'question', v_question,
    'reveal', v_reveal,
    'winner', case when d.winner is null then null when d.winner = v_user then 'me' else 'opponent' end,
    'abandoned', d.status = 'abandoned'
  );
end $$;

create function public.submit_duel_answer(p_duel uuid, p_position integer, p_choice uuid)
returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_user uuid := auth.uid();
  d record;
  dq record;
  v_author uuid;
  v_correct boolean;
  v_points integer := 0;
  v_elapsed numeric;
begin
  perform _duel_tick(p_duel);
  select * into d from duels where id = p_duel for update;
  if not found or v_user not in (d.player1, coalesce(d.player2, d.player1)) then
    raise exception 'duel not found';
  end if;
  if d.status <> 'active' or p_position <> d.current_position or now() < d.current_served_at then
    raise exception 'question closed';
  end if;

  select * into dq from duel_questions where duel_id = d.id and position = p_position;
  if p_choice is null or p_choice not in (dq.option_a, dq.option_b) then raise exception 'invalid choice'; end if;
  if exists (select 1 from duel_answers a where a.duel_id = d.id and a.position = p_position and a.user_id = v_user) then
    raise exception 'already answered';
  end if;
  select personality_id into v_author from quotes where id = dq.quote_id;

  v_correct := p_choice = v_author;
  if v_correct then
    v_elapsed := extract(epoch from (now() - d.current_served_at));
    v_points := 100 + greatest(0, round(50 * (1 - v_elapsed / d.answer_seconds)))::integer;
  end if;

  insert into duel_answers (duel_id, position, user_id, chosen_id, is_correct, points)
  values (d.id, p_position, v_user, p_choice, v_correct, v_points);

  if v_user = d.player1 then
    update duels set p1_answered = p_position, score1 = score1 + v_points where id = d.id;
  else
    update duels set p2_answered = p_position, score2 = score2 + v_points where id = d.id;
  end if;

  perform _duel_tick(d.id);
  return duel_state(d.id);
end $$;

create function public.abandon_duel(p_duel uuid)
returns void
language plpgsql security definer set search_path = public as $$
declare
  d record;
begin
  select * into d from duels where id = p_duel;
  if not found or auth.uid() not in (d.player1, coalesce(d.player2, d.player1)) then
    raise exception 'duel not found';
  end if;
  if d.status = 'waiting' then
    update duels set status = 'abandoned', finished_at = now() where id = p_duel;
  elsif d.status = 'active' then
    perform _duel_finish(p_duel, auth.uid());
  end if;
end $$;

-- Historique des duels du joueur
create function public.my_duels(p_limit integer default 20)
returns table (id uuid, status text, created_at timestamptz, opponent_name text,
               my_score integer, opponent_score integer, result text)
language sql stable security definer set search_path = public as $$
  select d.id, d.status, d.created_at,
         coalesce(p.username, 'Adversaire'),
         case when d.player1 = auth.uid() then d.score1 else d.score2 end,
         case when d.player1 = auth.uid() then d.score2 else d.score1 end,
         case when d.status in ('waiting', 'active') then 'en cours'
              when d.winner is null then 'égalité'
              when d.winner = auth.uid() then 'victoire' else 'défaite' end
    from duels d
    left join profiles p on p.id = case when d.player1 = auth.uid() then d.player2 else d.player1 end
   where auth.uid() in (d.player1, d.player2)
   order by d.created_at desc
   limit least(p_limit, 100);
$$;

revoke execute on function public._duel_finish(uuid, uuid) from public, anon, authenticated;
revoke execute on function public._duel_tick(uuid) from public, anon, authenticated;
revoke execute on function public.create_duel(text, integer) from public, anon;
revoke execute on function public.join_duel(text) from public, anon;
revoke execute on function public.duel_state(uuid) from public, anon;
revoke execute on function public.submit_duel_answer(uuid, integer, uuid) from public, anon;
revoke execute on function public.abandon_duel(uuid) from public, anon;
revoke execute on function public.my_duels(integer) from public, anon;
grant execute on function public.create_duel(text, integer) to authenticated;
grant execute on function public.join_duel(text) to authenticated;
grant execute on function public.duel_state(uuid) to authenticated;
grant execute on function public.submit_duel_answer(uuid, integer, uuid) to authenticated;
grant execute on function public.abandon_duel(uuid) to authenticated;
grant execute on function public.my_duels(integer) to authenticated;
