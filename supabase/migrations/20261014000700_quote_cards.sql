-- « Qui l'a dit ? » : une carte = une personnalité + une de ses citations
--
-- Les mêmes cartes servent au jeu (solo, chrono, duel) et à la collection :
-- une citation affichée, deux personnalités proposées, il faut trouver qui l'a dite.
-- Six niveaux de rareté, selon le retentissement de la citation.
-- Migration non destructive : les anciennes tables (quotes, personalities,
-- politician_cards…) restent en place mais ne sont plus utilisées par l'application.

create type public.card_rarity as enum ('common', 'uncommon', 'rare', 'epic', 'legendary', 'mythic');

alter table public.politicians
  add column role text,                               -- « Président de la République (1981-1995) »
  add column tags text[] not null default '{}';       -- ex. {president}

create table public.cards (
  id uuid primary key default gen_random_uuid(),
  politician_id uuid not null references public.politicians(id) on delete cascade,
  text text not null,
  said_on date,
  occasion text,
  source_label text,
  source_url text,
  theme text,                                         -- débats, discours, campagnes, petites phrases
  rarity public.card_rarity not null default 'common',
  -- Personnalité « piège » proposée en face (même débat, même époque…). Sinon tirage au hasard.
  decoy_politician_id uuid references public.politicians(id) on delete set null,
  verified boolean not null default false,
  verified_by uuid references auth.users(id) on delete set null,
  verified_at timestamptz,
  created_at timestamptz not null default now(),
  constraint card_decoy_differs check (decoy_politician_id is null or decoy_politician_id <> politician_id)
);
create index on public.cards (politician_id);
create index on public.cards (verified, rarity);

create table public.user_collection (
  user_id uuid not null references auth.users(id) on delete cascade,
  card_id uuid not null references public.cards(id) on delete cascade,
  copies integer not null default 1,
  first_obtained_at timestamptz not null default now(),
  primary key (user_id, card_id)
);

create table public.game_rounds (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.game_sessions(id) on delete cascade,
  position integer not null,
  card_id uuid not null references public.cards(id) on delete cascade,
  option_a uuid not null references public.politicians(id),
  option_b uuid not null references public.politicians(id),
  served_at timestamptz,
  answered_at timestamptz,
  chosen_id uuid references public.politicians(id),
  is_correct boolean,
  points integer,
  unique (session_id, position)
);

create table public.duel_rounds (
  duel_id uuid not null references public.duels(id) on delete cascade,
  position integer not null,
  card_id uuid not null references public.cards(id) on delete cascade,
  option_a uuid not null references public.politicians(id),
  option_b uuid not null references public.politicians(id),
  primary key (duel_id, position)
);

create table public.duel_round_answers (
  duel_id uuid not null references public.duels(id) on delete cascade,
  position integer not null,
  user_id uuid not null references auth.users(id) on delete cascade,
  chosen_id uuid references public.politicians(id),  -- null = temps écoulé
  is_correct boolean not null,
  points integer not null default 0,
  answered_at timestamptz not null default now(),
  primary key (duel_id, position, user_id)
);

alter table public.cards enable row level security;
alter table public.user_collection enable row level security;
alter table public.game_rounds enable row level security;
alter table public.duel_rounds enable row level security;
alter table public.duel_round_answers enable row level security;

-- Une carte (citation + auteur) n'est lisible que si on la possède : impossible
-- de récupérer les réponses du jeu via l'API. L'album passe par my_album().
create policy "cards readable when owned" on public.cards for select
  using (public.is_editor() or exists (select 1 from public.user_collection uc
                                       where uc.card_id = cards.id and uc.user_id = auth.uid()));
create policy "contributors insert card drafts" on public.cards for insert
  with check (public.is_editor() and (not verified or public.is_editor('verifier')));
create policy "editors update cards" on public.cards for update
  using (public.is_editor() and (not verified or public.is_editor('verifier')))
  with check (not verified or public.is_editor('verifier'));
create policy "verifiers delete cards" on public.cards for delete using (public.is_editor('verifier'));
create policy "own collection" on public.user_collection for select using (user_id = auth.uid());
-- game_rounds, duel_rounds, duel_round_answers : accès uniquement via les fonctions.

-- Boosters : probabilités sur 6 raretés (jsonb, en %) et filtre par tag de personnalité
alter table public.booster_types
  add column weights jsonb,
  add column tag text;

-- ---------------------------------------------------------------------------
-- Fonctions utilitaires
-- ---------------------------------------------------------------------------
create function public._rarity_rank(p public.card_rarity)
returns integer language sql immutable as $$
  select case p when 'common' then 0 when 'uncommon' then 1 when 'rare' then 2
                when 'epic' then 3 when 'legendary' then 4 when 'mythic' then 5 end;
$$;

-- Tire une rareté selon des probabilités en % (ex. {"common":45,"rare":15,…})
create function public._roll_rarity(p_weights jsonb)
returns public.card_rarity language plpgsql volatile as $$
declare
  v_roll numeric := random() * 100;
  v_acc numeric := 0;
  r public.card_rarity;
begin
  foreach r in array enum_range(null::public.card_rarity) loop
    v_acc := v_acc + coalesce((p_weights ->> r::text)::numeric, 0);
    if v_roll < v_acc then return r; end if;
  end loop;
  return 'common';
end $$;

-- Représentation JSON complète d'une carte (recto + verso)
create function public._card_json(p_card uuid)
returns jsonb language sql stable security definer set search_path = public as $$
  select jsonb_build_object(
    'card_id', c.id, 'text', c.text, 'rarity', c.rarity, 'theme', c.theme,
    'said_on', c.said_on, 'occasion', c.occasion,
    'source_label', c.source_label, 'source_url', c.source_url,
    'politician_id', p.id, 'politician_slug', p.slug, 'name', p.name, 'role', p.role,
    'image_url', p.image_url, 'image_credit', p.image_credit,
    'image_license', p.image_license, 'image_source_url', p.image_source_url,
    'party_name', pa.name, 'party_short', pa.short_name, 'party_color', pa.color)
  from cards c
  join politicians p on p.id = c.politician_id
  left join parties pa on pa.id = p.party_id
  where c.id = p_card;
$$;

create function public._option_json(p_politician uuid)
returns jsonb language sql stable security definer set search_path = public as $$
  select jsonb_build_object('id', p.id, 'name', p.name, 'description', p.role, 'image_url', p.image_url,
                            'party_short', pa.short_name, 'party_color', pa.color)
  from politicians p left join parties pa on pa.id = p.party_id
  where p.id = p_politician;
$$;

-- Tirage des manches : une carte vérifiée + le piège éditorial ou une autre personnalité
-- qui a au moins une carte (pour qu'elle ait une photo et soit reconnaissable)
create function public._pick_rounds(p_count integer, p_theme text)
returns table (card_id uuid, option_a uuid, option_b uuid)
language plpgsql volatile security definer set search_path = public as $$
declare
  r record;
  v_decoy uuid;
begin
  for r in
    select c.id, c.politician_id, c.decoy_politician_id
      from cards c
     where c.verified and (p_theme is null or c.theme = p_theme)
     order by random()
     limit p_count
  loop
    v_decoy := r.decoy_politician_id;
    if v_decoy is null then
      select p.id into v_decoy from politicians p
       where p.id <> r.politician_id
         and exists (select 1 from cards c2 where c2.politician_id = p.id and c2.verified)
       order by random() limit 1;
    end if;
    continue when v_decoy is null;
    card_id := r.id;
    if random() < 0.5 then
      option_a := r.politician_id; option_b := v_decoy;
    else
      option_a := v_decoy; option_b := r.politician_id;
    end if;
    return next;
  end loop;
end $$;

-- ---------------------------------------------------------------------------
-- Collection
-- ---------------------------------------------------------------------------
create or replace function public.list_themes()
returns table (theme text, quote_count bigint)
language sql stable security definer set search_path = public as $$
  select c.theme, count(*) from cards c
   where c.verified and c.theme is not null
   group by c.theme order by c.theme;
$$;

create function public.card_totals()
returns table (rarity public.card_rarity, total bigint)
language sql stable security definer set search_path = public as $$
  select c.rarity, count(*) from cards c where c.verified group by c.rarity;
$$;

-- Album : toutes les cartes, le texte de la citation n'étant révélé que pour les cartes possédées
create function public.my_album()
returns table (
  card_id uuid, rarity public.card_rarity, theme text, copies integer,
  text text, said_on date, occasion text, source_label text, source_url text,
  politician_id uuid, politician_slug text, name text, role text,
  image_url text, image_credit text, image_license text, image_source_url text,
  party_name text, party_short text, party_color text, party_sort integer
)
language sql stable security definer set search_path = public as $$
  select c.id, c.rarity, c.theme, coalesce(uc.copies, 0),
         case when uc.card_id is not null then c.text end,
         case when uc.card_id is not null then c.said_on end,
         case when uc.card_id is not null then c.occasion end,
         case when uc.card_id is not null then c.source_label end,
         case when uc.card_id is not null then c.source_url end,
         p.id, p.slug, p.name, p.role,
         p.image_url, p.image_credit, p.image_license, p.image_source_url,
         pa.name, pa.short_name, pa.color, pa.sort_order
    from cards c
    join politicians p on p.id = c.politician_id
    left join parties pa on pa.id = p.party_id
    left join user_collection uc on uc.card_id = c.id and uc.user_id = auth.uid()
   where c.verified
   order by p.name, public._rarity_rank(c.rarity) desc;
$$;

-- ---------------------------------------------------------------------------
-- Jeu solo
-- ---------------------------------------------------------------------------
create or replace function public.start_game(
  p_question_count integer default 10,
  p_theme text default null,
  p_mode text default 'classic'
)
returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_user uuid := auth.uid();
  v_session uuid;
  v_count integer;
begin
  if v_user is null then raise exception 'not authenticated'; end if;
  if p_mode not in ('classic', 'chrono') then raise exception 'invalid mode'; end if;
  v_count := case when p_mode = 'chrono' then 40 else least(greatest(p_question_count, 1), 20) end;

  update game_sessions set status = 'finished', finished_at = now()
   where user_id = v_user and status = 'in_progress';

  insert into game_sessions (user_id, mode, theme, ends_at)
  values (v_user, p_mode, p_theme, case when p_mode = 'chrono' then now() + interval '60 seconds' end)
  returning id into v_session;

  insert into game_rounds (session_id, position, card_id, option_a, option_b)
  select v_session, row_number() over (), pr.card_id, pr.option_a, pr.option_b
    from _pick_rounds(v_count, p_theme) pr;
  get diagnostics v_count = row_count;

  if v_count = 0 then raise exception 'no playable quotes'; end if;

  update profiles set games_played = games_played + 1 where id = v_user;
  return v_session;
end $$;

create or replace function public.next_question(p_session uuid)
returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_q record;
  v_total integer;
  v_s record;
begin
  select * into v_s from game_sessions where id = p_session and user_id = auth.uid();
  if not found then raise exception 'session not found'; end if;

  select count(*) into v_total from game_rounds where session_id = p_session;

  select gr.*, c.text as quote_text, c.rarity
    into v_q
    from game_rounds gr join cards c on c.id = gr.card_id
   where gr.session_id = p_session and gr.answered_at is null
   order by gr.position limit 1;

  if v_s.ends_at is not null and now() > v_s.ends_at and v_s.status = 'in_progress' then
    update game_sessions set status = 'finished', finished_at = now() where id = p_session;
    v_s.status := 'finished';
  end if;

  if v_q.id is null or v_s.status = 'finished' then
    if v_s.mode = 'chrono' then
      select count(*) into v_total from game_rounds where session_id = p_session and answered_at is not null;
    end if;
    return jsonb_build_object('done', true, 'total', v_total, 'mode', v_s.mode,
      'score', v_s.score, 'correct', v_s.correct_count, 'max_streak', v_s.max_streak);
  end if;

  if v_q.served_at is null then
    update game_rounds set served_at = now() where id = v_q.id;
  end if;

  return jsonb_build_object(
    'done', false,
    'mode', v_s.mode,
    'ends_at', v_s.ends_at,
    'question_id', v_q.id,
    'position', v_q.position,
    'total', v_total,
    'quote', v_q.quote_text,
    'is_demo', false,
    'score', v_s.score,
    'streak', v_s.streak,
    'options', jsonb_build_array(_option_json(v_q.option_a), _option_json(v_q.option_b))
  );
end $$;

-- Barème inchangé : 100 pts + bonus de rapidité (50 max sur 15 s), ×1,5 dès 3 d'affilée, ×2 dès 5.
-- Chaque bonne réponse ajoute la carte à la collection.
create or replace function public.submit_answer(p_question uuid, p_choice uuid)
returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_user uuid := auth.uid();
  v_q record;
  v_s record;
  v_author uuid;
  v_correct boolean;
  v_elapsed numeric;
  v_speed integer := 0;
  v_mult numeric := 1;
  v_points integer := 0;
  v_streak integer;
  v_new_card boolean := false;
begin
  select gr.* into v_q
    from game_rounds gr
    join game_sessions s on s.id = gr.session_id
   where gr.id = p_question and s.user_id = v_user and s.status = 'in_progress'
   for update of gr;
  if not found then raise exception 'question not found'; end if;
  if v_q.answered_at is not null then raise exception 'already answered'; end if;
  if v_q.served_at is null then raise exception 'question not served'; end if;
  if p_choice is null or p_choice not in (v_q.option_a, v_q.option_b) then raise exception 'invalid choice'; end if;

  select * into v_s from game_sessions where id = v_q.session_id for update;
  if v_s.ends_at is not null and now() > v_s.ends_at + interval '2 seconds' then
    update game_sessions set status = 'finished', finished_at = now() where id = v_s.id;
    raise exception 'time is up';
  end if;

  select politician_id into v_author from cards where id = v_q.card_id;
  v_correct := (p_choice = v_author);
  v_elapsed := extract(epoch from (now() - v_q.served_at));

  if v_correct then
    v_streak := v_s.streak + 1;
    v_speed := greatest(0, round(50 * (1 - v_elapsed / 15.0)))::integer;
    v_mult := case when v_streak >= 5 then 2 when v_streak >= 3 then 1.5 else 1 end;
    v_points := round((100 + v_speed) * v_mult)::integer;

    insert into user_collection (user_id, card_id) values (v_user, v_q.card_id)
    on conflict (user_id, card_id) do update set copies = user_collection.copies + 1
    returning (xmax = 0) into v_new_card;
  else
    v_streak := 0;
  end if;

  update game_rounds
     set answered_at = now(), chosen_id = p_choice, is_correct = v_correct, points = v_points
   where id = v_q.id;

  update game_sessions
     set score = score + v_points,
         correct_count = correct_count + (case when v_correct then 1 else 0 end),
         streak = v_streak,
         max_streak = greatest(max_streak, v_streak)
   where id = v_s.id;

  update profiles
     set points = points + v_points,
         total_points_earned = total_points_earned + v_points,
         best_streak = greatest(best_streak, v_streak)
   where id = v_user;

  if not exists (select 1 from game_rounds where session_id = v_s.id and answered_at is null) then
    update game_sessions set status = 'finished', finished_at = now() where id = v_s.id;
  end if;

  return jsonb_build_object(
    'correct', v_correct,
    'answer_id', v_author,
    'points', v_points,
    'speed_bonus', v_speed,
    'multiplier', v_mult,
    'streak', v_streak,
    'new_card', v_new_card,
    'card', _card_json(v_q.card_id)
  );
end $$;

-- ---------------------------------------------------------------------------
-- Duels (mêmes cartes)
-- ---------------------------------------------------------------------------
create or replace function public.create_duel(p_theme text default null, p_question_count integer default 7)
returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_user uuid := auth.uid();
  v_duel duels;
  v_n integer;
begin
  if v_user is null then raise exception 'not authenticated'; end if;

  update duels set status = 'abandoned', finished_at = now()
   where player1 = v_user and status = 'waiting';

  insert into duels (player1, theme, question_count)
  values (v_user, p_theme, least(greatest(p_question_count, 3), 15))
  returning * into v_duel;

  insert into duel_rounds (duel_id, position, card_id, option_a, option_b)
  select v_duel.id, row_number() over (), pr.card_id, pr.option_a, pr.option_b
    from _pick_rounds(v_duel.question_count, p_theme) pr;
  get diagnostics v_n = row_count;
  if v_n = 0 then raise exception 'no playable quotes'; end if;
  update duels set question_count = v_n where id = v_duel.id;

  return jsonb_build_object('id', v_duel.id, 'code', v_duel.code);
end $$;

create or replace function public._duel_finish(p_duel uuid, p_abandoned_by uuid default null)
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
  end if;

  update duels
     set status = case when p_abandoned_by is null then 'finished' else 'abandoned' end,
         winner = v_winner, abandoned_by = p_abandoned_by, finished_at = now()
   where id = p_duel;

  if d.player2 is null then return; end if;

  update profiles set points = points + d.score1, total_points_earned = total_points_earned + d.score1,
                      duels_played = duels_played + 1
   where id = d.player1;
  update profiles set points = points + d.score2, total_points_earned = total_points_earned + d.score2,
                      duels_played = duels_played + 1
   where id = d.player2;

  -- Victoire : 200 points et une carte du duel (sur abandon, seulement si plus de la moitié a été jouée)
  if v_winner is not null and (p_abandoned_by is null or d.current_position * 2 > d.question_count) then
    update profiles set points = points + 200, total_points_earned = total_points_earned + 200,
                        duels_won = duels_won + 1
     where id = v_winner;
    select dr.card_id into v_card from duel_rounds dr where dr.duel_id = p_duel order by random() limit 1;
    if v_card is not null then
      insert into user_collection (user_id, card_id) values (v_winner, v_card)
      on conflict (user_id, card_id) do update set copies = user_collection.copies + 1;
    end if;
  end if;
end $$;

create or replace function public._duel_tick(p_duel uuid)
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
    insert into duel_round_answers (duel_id, position, user_id, chosen_id, is_correct, points)
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

create or replace function public.duel_state(p_duel uuid)
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

  if d.status = 'active' and now() >= d.current_served_at and v_my_answered < d.current_position then
    select jsonb_build_object(
      'position', dr.position,
      'quote', c.text,
      'is_demo', false,
      'options', jsonb_build_array(_option_json(dr.option_a), _option_json(dr.option_b)))
      into v_question
      from duel_rounds dr join cards c on c.id = dr.card_id
     where dr.duel_id = d.id and dr.position = d.current_position;
  end if;

  if v_my_answered > 0 then
    select jsonb_build_object(
      'position', dr.position,
      'quote', c.text,
      'answer_id', c.politician_id,
      'author', p.name,
      'said_on', c.said_on,
      'occasion', c.occasion,
      'source_label', c.source_label,
      'source_url', c.source_url,
      'mine', (select jsonb_build_object('chosen_id', a.chosen_id, 'correct', a.is_correct, 'points', a.points)
                 from duel_round_answers a where a.duel_id = d.id and a.position = dr.position and a.user_id = v_user),
      'opponent', (select jsonb_build_object('correct', a.is_correct, 'points', a.points)
                     from duel_round_answers a where a.duel_id = d.id and a.position = dr.position and a.user_id <> v_user))
      into v_reveal
      from duel_rounds dr
      join cards c on c.id = dr.card_id
      join politicians p on p.id = c.politician_id
     where dr.duel_id = d.id and dr.position = v_my_answered;
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

create or replace function public.submit_duel_answer(p_duel uuid, p_position integer, p_choice uuid)
returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_user uuid := auth.uid();
  d record;
  dr record;
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

  select * into dr from duel_rounds where duel_id = d.id and position = p_position;
  if p_choice is null or p_choice not in (dr.option_a, dr.option_b) then raise exception 'invalid choice'; end if;
  if exists (select 1 from duel_round_answers a where a.duel_id = d.id and a.position = p_position and a.user_id = v_user) then
    raise exception 'already answered';
  end if;
  select politician_id into v_author from cards where id = dr.card_id;

  v_correct := p_choice = v_author;
  if v_correct then
    v_elapsed := extract(epoch from (now() - d.current_served_at));
    v_points := 100 + greatest(0, round(50 * (1 - v_elapsed / d.answer_seconds)))::integer;
  end if;

  insert into duel_round_answers (duel_id, position, user_id, chosen_id, is_correct, points)
  values (d.id, p_position, v_user, p_choice, v_correct, v_points);

  if v_user = d.player1 then
    update duels set p1_answered = p_position, score1 = score1 + v_points where id = d.id;
  else
    update duels set p2_answered = p_position, score2 = score2 + v_points where id = d.id;
  end if;

  perform _duel_tick(d.id);
  return duel_state(d.id);
end $$;

-- ---------------------------------------------------------------------------
-- Boosters
-- ---------------------------------------------------------------------------
create or replace function public.open_booster(p_slug text)
returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_user uuid := auth.uid();
  v_b record;
  v_points integer;
  v_weights jsonb;
  v_rarity public.card_rarity;
  v_id uuid;
  v_ids uuid[] := '{}';
  v_cards jsonb := '[]';
  v_new boolean;
  i integer;
begin
  if v_user is null then raise exception 'not authenticated'; end if;
  select * into v_b from booster_types where slug = p_slug and active;
  if not found then raise exception 'booster not found'; end if;
  if v_b.kind <> 'politicians' then raise exception 'empty booster'; end if;

  select points into v_points from profiles where id = v_user for update;
  if v_points < v_b.price then raise exception 'not enough points'; end if;

  if not exists (
    select 1 from cards c join politicians p on p.id = c.politician_id
     where c.verified
       and (v_b.party_id is null or p.party_id = v_b.party_id)
       and (v_b.tag is null or v_b.tag = any (p.tags))
       and (v_b.theme is null or c.theme = v_b.theme)
  ) then raise exception 'empty booster'; end if;

  v_weights := coalesce(v_b.weights,
    jsonb_build_object('common', v_b.weight_common, 'rare', v_b.weight_rare, 'legendary', v_b.weight_legendary));

  update profiles set points = points - v_b.price where id = v_user;

  for i in 1..v_b.card_count loop
    v_rarity := _roll_rarity(v_weights);

    -- Carte de la rareté tirée ; à défaut, la rareté la plus proche
    select c.id into v_id
      from cards c join politicians p on p.id = c.politician_id
     where c.verified
       and (v_b.party_id is null or p.party_id = v_b.party_id)
       and (v_b.tag is null or v_b.tag = any (p.tags))
       and (v_b.theme is null or c.theme = v_b.theme)
     order by abs(_rarity_rank(c.rarity) - _rarity_rank(v_rarity)), _rarity_rank(c.rarity), random()
     limit 1;

    insert into user_collection (user_id, card_id) values (v_user, v_id)
    on conflict (user_id, card_id) do update set copies = user_collection.copies + 1
    returning (xmax = 0) into v_new;

    v_cards := v_cards || (_card_json(v_id) || jsonb_build_object('type', 'card', 'new', v_new));
    v_ids := v_ids || v_id;
  end loop;

  insert into booster_openings (user_id, booster_slug, price_paid, card_ids)
  values (v_user, p_slug, v_b.price, v_ids);

  return jsonb_build_object('kind', 'cards', 'cards', v_cards, 'points_left', v_points - v_b.price);
end $$;

-- Droits d'exécution
revoke execute on function public._rarity_rank(public.card_rarity) from public, anon;
revoke execute on function public._roll_rarity(jsonb) from public, anon, authenticated;
revoke execute on function public._card_json(uuid) from public, anon, authenticated;
revoke execute on function public._option_json(uuid) from public, anon, authenticated;
revoke execute on function public._pick_rounds(integer, text) from public, anon, authenticated;
revoke execute on function public.my_album() from public, anon;
grant execute on function public.my_album() to authenticated;
grant execute on function public.card_totals() to anon, authenticated;
