-- « Qui l'a dit ? » : schéma initial
-- Toute la logique de jeu (vérification des réponses, points, tirage des boosters)
-- s'exécute côté serveur dans des fonctions Postgres, pour que le client ne puisse
-- ni connaître la bonne réponse à l'avance ni s'attribuer des points.

-- ---------------------------------------------------------------------------
-- Types
-- ---------------------------------------------------------------------------
create type public.personality_kind as enum ('candidate', 'other');
create type public.rarity as enum ('common', 'rare', 'legendary');

-- ---------------------------------------------------------------------------
-- Contenu éditorial
-- ---------------------------------------------------------------------------
create table public.personalities (
  id uuid primary key default gen_random_uuid(),
  slug text unique not null,
  name text not null,
  kind public.personality_kind not null,
  description text,            -- « Candidate (parti X) », « Chanteur », …
  party text,
  image_url text,
  is_demo boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.quotes (
  id uuid primary key default gen_random_uuid(),
  text text not null,
  personality_id uuid not null references public.personalities(id) on delete cascade,
  -- Personnalité « piège » proposée en face (discours proche). Si null, tirage aléatoire.
  decoy_personality_id uuid references public.personalities(id) on delete set null,
  said_on date,
  occasion text,               -- « Interview sur France Inter », « Meeting à Lyon », …
  source_label text,
  source_url text,
  theme text,                  -- économie, écologie, sécurité, …
  rarity public.rarity not null default 'common',
  -- Règle éditoriale : seule une citation vérifiée (source contrôlée) est jouable.
  verified boolean not null default false,
  verified_by text,
  is_demo boolean not null default false,
  created_at timestamptz not null default now(),
  constraint decoy_differs check (decoy_personality_id is null or decoy_personality_id <> personality_id)
);
create index on public.quotes (personality_id);
create index on public.quotes (verified, rarity);

-- ---------------------------------------------------------------------------
-- Joueurs
-- ---------------------------------------------------------------------------
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text,
  points integer not null default 0 check (points >= 0),
  total_points_earned integer not null default 0,
  best_streak integer not null default 0,
  games_played integer not null default 0,
  created_at timestamptz not null default now()
);

create table public.user_cards (
  user_id uuid not null references auth.users(id) on delete cascade,
  quote_id uuid not null references public.quotes(id) on delete cascade,
  copies integer not null default 1,
  first_obtained_at timestamptz not null default now(),
  primary key (user_id, quote_id)
);

-- Création automatique du profil (y compris pour les comptes invités anonymes)
create function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  -- Bonus de bienvenue (v1, à valider) : de quoi ouvrir un premier booster
  insert into public.profiles (id, points) values (new.id, 300) on conflict do nothing;
  return new;
end $$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- Parties
-- ---------------------------------------------------------------------------
create table public.game_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  status text not null default 'in_progress' check (status in ('in_progress', 'finished')),
  score integer not null default 0,
  correct_count integer not null default 0,
  streak integer not null default 0,
  max_streak integer not null default 0,
  created_at timestamptz not null default now(),
  finished_at timestamptz
);

create table public.game_questions (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.game_sessions(id) on delete cascade,
  position integer not null,
  quote_id uuid not null references public.quotes(id) on delete cascade,
  option_a uuid not null references public.personalities(id),
  option_b uuid not null references public.personalities(id),
  served_at timestamptz,
  answered_at timestamptz,
  chosen_id uuid references public.personalities(id),
  is_correct boolean,
  points integer,
  unique (session_id, position)
);

-- ---------------------------------------------------------------------------
-- Boosters
-- ---------------------------------------------------------------------------
create table public.booster_types (
  slug text primary key,
  name text not null,
  description text,
  price integer not null check (price >= 0),
  card_count integer not null check (card_count > 0),
  -- Probabilités en pourcentage (somme = 100)
  weight_common integer not null default 70,
  weight_rare integer not null default 25,
  weight_legendary integer not null default 5,
  -- Filtres optionnels : booster thématique par candidat ou par sujet
  personality_id uuid references public.personalities(id) on delete cascade,
  theme text,
  sort_order integer not null default 0,
  constraint weights_sum check (weight_common + weight_rare + weight_legendary = 100)
);

create table public.booster_openings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  booster_slug text not null references public.booster_types(slug),
  price_paid integer not null,
  quote_ids uuid[] not null,
  opened_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------
alter table public.personalities enable row level security;
alter table public.quotes enable row level security;
alter table public.profiles enable row level security;
alter table public.user_cards enable row level security;
alter table public.game_sessions enable row level security;
alter table public.game_questions enable row level security;
alter table public.booster_types enable row level security;
alter table public.booster_openings enable row level security;

create policy "personalities are public" on public.personalities for select using (true);
create policy "booster types are public" on public.booster_types for select using (true);

-- Une citation (et donc son auteur) n'est lisible que si le joueur possède la carte :
-- impossible de récupérer les réponses du jeu via l'API.
create policy "quotes readable when owned" on public.quotes for select
  using (exists (select 1 from public.user_cards uc
                 where uc.quote_id = quotes.id and uc.user_id = auth.uid()));

create policy "own profile read" on public.profiles for select using (id = auth.uid());
create policy "own profile username" on public.profiles for update
  using (id = auth.uid()) with check (id = auth.uid());
-- Seule la colonne username est modifiable par le joueur
revoke update on public.profiles from anon, authenticated;
grant update (username) on public.profiles to authenticated;

create policy "own cards" on public.user_cards for select using (user_id = auth.uid());
create policy "own sessions" on public.game_sessions for select using (user_id = auth.uid());
create policy "own openings" on public.booster_openings for select using (user_id = auth.uid());
-- game_questions : aucun accès direct, tout passe par les fonctions ci-dessous.

-- ---------------------------------------------------------------------------
-- Statistiques publiques (pour le compteur de collection, sans révéler les réponses)
-- ---------------------------------------------------------------------------
create function public.collection_totals()
returns table (rarity public.rarity, total bigint)
language sql stable security definer set search_path = public as $$
  select q.rarity, count(*) from public.quotes q where q.verified group by q.rarity;
$$;

-- ---------------------------------------------------------------------------
-- Jeu : démarrer une partie
-- ---------------------------------------------------------------------------
create function public.start_game(p_question_count integer default 10)
returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_user uuid := auth.uid();
  v_session uuid;
  v_quote record;
  v_decoy uuid;
  v_pos integer := 0;
begin
  if v_user is null then raise exception 'not authenticated'; end if;
  p_question_count := least(greatest(p_question_count, 1), 20);

  -- Abandon des éventuelles parties en cours
  update game_sessions set status = 'finished', finished_at = now()
   where user_id = v_user and status = 'in_progress';

  insert into game_sessions (user_id) values (v_user) returning id into v_session;

  for v_quote in
    select q.id, q.personality_id, q.decoy_personality_id
      from quotes q
      join personalities p on p.id = q.personality_id
     where q.verified and p.kind = 'candidate'
     order by random()
     limit p_question_count
  loop
    -- Le piège éditorial s'il existe, sinon une autre personnalité au hasard
    v_decoy := v_quote.decoy_personality_id;
    if v_decoy is null then
      select id into v_decoy from personalities
       where id <> v_quote.personality_id
       order by (kind = 'other') desc, random() limit 1;
    end if;
    if v_decoy is null then continue; end if;

    v_pos := v_pos + 1;
    -- Ordre d'affichage aléatoire des deux propositions
    if random() < 0.5 then
      insert into game_questions (session_id, position, quote_id, option_a, option_b)
      values (v_session, v_pos, v_quote.id, v_quote.personality_id, v_decoy);
    else
      insert into game_questions (session_id, position, quote_id, option_a, option_b)
      values (v_session, v_pos, v_quote.id, v_decoy, v_quote.personality_id);
    end if;
  end loop;

  if v_pos = 0 then
    raise exception 'no playable quotes';
  end if;

  update profiles set games_played = games_played + 1 where id = v_user;
  return v_session;
end $$;

-- ---------------------------------------------------------------------------
-- Jeu : question suivante (horodatée côté serveur pour le bonus de rapidité)
-- ---------------------------------------------------------------------------
create function public.next_question(p_session uuid)
returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_q record;
  v_total integer;
  v_s record;
begin
  select * into v_s from game_sessions where id = p_session and user_id = auth.uid();
  if not found then raise exception 'session not found'; end if;

  select count(*) into v_total from game_questions where session_id = p_session;

  select gq.*, q.text as quote_text, q.is_demo,
         pa.name as a_name, pa.description as a_desc, pa.image_url as a_img,
         pb.name as b_name, pb.description as b_desc, pb.image_url as b_img
    into v_q
    from game_questions gq
    join quotes q on q.id = gq.quote_id
    join personalities pa on pa.id = gq.option_a
    join personalities pb on pb.id = gq.option_b
   where gq.session_id = p_session and gq.answered_at is null
   order by gq.position limit 1;

  if not found or v_s.status = 'finished' then
    return jsonb_build_object('done', true, 'total', v_total,
      'score', v_s.score, 'correct', v_s.correct_count, 'max_streak', v_s.max_streak);
  end if;

  if v_q.served_at is null then
    update game_questions set served_at = now() where id = v_q.id;
  end if;

  return jsonb_build_object(
    'done', false,
    'question_id', v_q.id,
    'position', v_q.position,
    'total', v_total,
    'quote', v_q.quote_text,
    'is_demo', v_q.is_demo,
    'score', v_s.score,
    'streak', v_s.streak,
    'options', jsonb_build_array(
      jsonb_build_object('id', v_q.option_a, 'name', v_q.a_name, 'description', v_q.a_desc, 'image_url', v_q.a_img),
      jsonb_build_object('id', v_q.option_b, 'name', v_q.b_name, 'description', v_q.b_desc, 'image_url', v_q.b_img)
    )
  );
end $$;

-- ---------------------------------------------------------------------------
-- Jeu : répondre
-- Barème v1 (à valider avec l'équipe) :
--   100 points par bonne réponse
--   + bonus de rapidité jusqu'à 50 points (dégressif sur 15 secondes)
--   × 1,5 à partir de 3 bonnes réponses d'affilée, × 2 à partir de 5
-- Chaque bonne réponse ajoute la carte de la citation à la collection.
-- ---------------------------------------------------------------------------
create function public.submit_answer(p_question uuid, p_choice uuid)
returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_user uuid := auth.uid();
  v_q record;
  v_s record;
  v_correct boolean;
  v_elapsed numeric;
  v_speed integer := 0;
  v_mult numeric := 1;
  v_points integer := 0;
  v_streak integer;
  v_new_card boolean := false;
  v_quote record;
  v_author record;
begin
  select gq.* into v_q
    from game_questions gq
    join game_sessions s on s.id = gq.session_id
   where gq.id = p_question and s.user_id = v_user and s.status = 'in_progress'
   for update of gq;
  if not found then raise exception 'question not found'; end if;
  if v_q.answered_at is not null then raise exception 'already answered'; end if;
  if v_q.served_at is null then raise exception 'question not served'; end if;
  if p_choice not in (v_q.option_a, v_q.option_b) then raise exception 'invalid choice'; end if;

  select * into v_quote from quotes where id = v_q.quote_id;
  select * into v_author from personalities where id = v_quote.personality_id;
  select * into v_s from game_sessions where id = v_q.session_id for update;

  v_correct := (p_choice = v_quote.personality_id);
  v_elapsed := extract(epoch from (now() - v_q.served_at));

  if v_correct then
    v_streak := v_s.streak + 1;
    v_speed := greatest(0, round(50 * (1 - v_elapsed / 15.0)))::integer;
    v_mult := case when v_streak >= 5 then 2 when v_streak >= 3 then 1.5 else 1 end;
    v_points := round((100 + v_speed) * v_mult)::integer;

    insert into user_cards (user_id, quote_id) values (v_user, v_quote.id)
    on conflict (user_id, quote_id) do update set copies = user_cards.copies + 1
    returning (xmax = 0) into v_new_card;
  else
    v_streak := 0;
  end if;

  update game_questions
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

  -- Fin de partie si plus aucune question
  if not exists (select 1 from game_questions where session_id = v_s.id and answered_at is null) then
    update game_sessions set status = 'finished', finished_at = now() where id = v_s.id;
  end if;

  return jsonb_build_object(
    'correct', v_correct,
    'answer_id', v_author.id,
    'points', v_points,
    'speed_bonus', v_speed,
    'multiplier', v_mult,
    'streak', v_streak,
    'new_card', v_new_card,
    'card', jsonb_build_object(
      'quote_id', v_quote.id,
      'text', v_quote.text,
      'rarity', v_quote.rarity,
      'author', v_author.name,
      'author_description', v_author.description,
      'said_on', v_quote.said_on,
      'occasion', v_quote.occasion,
      'source_label', v_quote.source_label,
      'source_url', v_quote.source_url,
      'theme', v_quote.theme,
      'is_demo', v_quote.is_demo
    )
  );
end $$;

-- ---------------------------------------------------------------------------
-- Boosters : ouverture
-- ---------------------------------------------------------------------------
create function public.open_booster(p_slug text)
returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_user uuid := auth.uid();
  v_b record;
  v_points integer;
  v_roll integer;
  v_rarity public.rarity;
  v_quote_id uuid;
  v_ids uuid[] := '{}';
  v_cards jsonb := '[]';
  v_new boolean;
  i integer;
begin
  if v_user is null then raise exception 'not authenticated'; end if;
  select * into v_b from booster_types where slug = p_slug;
  if not found then raise exception 'booster not found'; end if;

  select points into v_points from profiles where id = v_user for update;
  if v_points < v_b.price then raise exception 'not enough points'; end if;

  -- Vérifie qu'il existe au moins une carte tirable
  if not exists (
    select 1 from quotes q where q.verified
      and (v_b.personality_id is null or q.personality_id = v_b.personality_id)
      and (v_b.theme is null or q.theme = v_b.theme)
  ) then
    raise exception 'empty booster';
  end if;

  update profiles set points = points - v_b.price where id = v_user;

  for i in 1..v_b.card_count loop
    v_roll := floor(random() * 100)::integer; -- 0..99
    v_rarity := case
      when v_roll < v_b.weight_legendary then 'legendary'
      when v_roll < v_b.weight_legendary + v_b.weight_rare then 'rare'
      else 'common' end;

    -- Tirage dans la rareté obtenue, avec repli sur n'importe quelle rareté si vide
    select q.id into v_quote_id from quotes q
     where q.verified
       and (v_b.personality_id is null or q.personality_id = v_b.personality_id)
       and (v_b.theme is null or q.theme = v_b.theme)
     order by (q.rarity = v_rarity) desc, random()
     limit 1;

    insert into user_cards (user_id, quote_id) values (v_user, v_quote_id)
    on conflict (user_id, quote_id) do update set copies = user_cards.copies + 1
    returning (xmax = 0) into v_new;

    v_ids := v_ids || v_quote_id;
    v_cards := v_cards || (
      select jsonb_build_object(
        'quote_id', q.id, 'text', q.text, 'rarity', q.rarity,
        'author', p.name, 'author_description', p.description,
        'said_on', q.said_on, 'occasion', q.occasion,
        'source_label', q.source_label, 'source_url', q.source_url,
        'theme', q.theme, 'is_demo', q.is_demo, 'new', v_new)
      from quotes q join personalities p on p.id = q.personality_id
      where q.id = v_quote_id);
  end loop;

  insert into booster_openings (user_id, booster_slug, price_paid, quote_ids)
  values (v_user, p_slug, v_b.price, v_ids);

  return jsonb_build_object('cards', v_cards, 'points_left', v_points - v_b.price);
end $$;

-- Les fonctions de jeu ne sont appelables que par un utilisateur connecté (invité compris)
revoke execute on function public.start_game(integer) from public, anon;
revoke execute on function public.next_question(uuid) from public, anon;
revoke execute on function public.submit_answer(uuid, uuid) from public, anon;
revoke execute on function public.open_booster(text) from public, anon;
grant execute on function public.start_game(integer) to authenticated;
grant execute on function public.next_question(uuid) to authenticated;
grant execute on function public.submit_answer(uuid, uuid) to authenticated;
grant execute on function public.open_booster(text) to authenticated;
grant execute on function public.collection_totals() to anon, authenticated;
