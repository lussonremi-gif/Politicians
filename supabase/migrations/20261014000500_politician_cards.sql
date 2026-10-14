-- « Qui l'a dit ? » : collection de personnalités politiques
--
-- Chaque personnalité existe en plusieurs versions (une carte par année marquante).
-- Règle de rareté, identique pour tous (neutralité) : plus la version est ancienne,
-- plus elle est rare. Chaque personnalité a une version légendaire, une rare et une
-- commune (« Saison 2026 »).
-- Les boosters de personnalités se déclinent en classique, premium et par parti.

create table public.parties (
  id uuid primary key default gen_random_uuid(),
  slug text unique not null,
  name text not null,
  short_name text not null,
  color text not null,          -- couleur d'accent (hexadécimal)
  sort_order integer not null default 0
);

create table public.politicians (
  id uuid primary key default gen_random_uuid(),
  slug text unique not null,
  name text not null,
  party_id uuid references public.parties(id) on delete set null,
  -- Photo : uniquement sous licence libre (Wikimedia Commons) ou droits acquis
  image_url text,
  image_credit text,
  image_license text,
  image_source_url text,
  -- Lien éventuel vers la personnalité du jeu de citations
  personality_id uuid references public.personalities(id) on delete set null,
  created_at timestamptz not null default now()
);

create table public.politician_cards (
  id uuid primary key default gen_random_uuid(),
  politician_id uuid not null references public.politicians(id) on delete cascade,
  year integer not null,
  title text not null,          -- « Élu président de la République », « Saison 2026 »…
  party_label text,             -- étiquette à l'époque (ex. « Front national » en 2017)
  rarity public.rarity not null,
  created_at timestamptz not null default now(),
  unique (politician_id, year)
);
create index on public.politician_cards (rarity);

create table public.user_politician_cards (
  user_id uuid not null references auth.users(id) on delete cascade,
  card_id uuid not null references public.politician_cards(id) on delete cascade,
  copies integer not null default 1,
  first_obtained_at timestamptz not null default now(),
  primary key (user_id, card_id)
);

alter table public.parties enable row level security;
alter table public.politicians enable row level security;
alter table public.politician_cards enable row level security;
alter table public.user_politician_cards enable row level security;

-- Le catalogue est public (album de collection) ; seule la possession est privée.
create policy "parties are public" on public.parties for select using (true);
create policy "politicians are public" on public.politicians for select using (true);
create policy "politician cards are public" on public.politician_cards for select using (true);
create policy "own politician cards" on public.user_politician_cards for select using (user_id = auth.uid());

create policy "admins manage parties" on public.parties for all
  using (public.is_editor('admin')) with check (public.is_editor('admin'));
create policy "editors manage politicians" on public.politicians for all
  using (public.is_editor()) with check (public.is_editor());
create policy "editors manage politician cards" on public.politician_cards for all
  using (public.is_editor('verifier')) with check (public.is_editor('verifier'));

-- ---------------------------------------------------------------------------
-- Boosters : type de contenu et filtre par parti
-- ---------------------------------------------------------------------------
alter table public.booster_openings rename column quote_ids to card_ids;

alter table public.booster_types
  add column kind text not null default 'quotes' check (kind in ('quotes', 'politicians')),
  add column party_id uuid references public.parties(id) on delete cascade;

create or replace function public.open_booster(p_slug text)
returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_user uuid := auth.uid();
  v_b record;
  v_points integer;
  v_roll integer;
  v_rarity public.rarity;
  v_id uuid;
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

  if v_b.kind = 'politicians' then
    if not exists (
      select 1 from politician_cards c join politicians p on p.id = c.politician_id
       where v_b.party_id is null or p.party_id = v_b.party_id
    ) then raise exception 'empty booster'; end if;
  elsif not exists (
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

    if v_b.kind = 'politicians' then
      -- Tirage dans la rareté obtenue (repli sur une autre rareté si le parti n'en a pas)
      select c.id into v_id from politician_cards c join politicians p on p.id = c.politician_id
       where v_b.party_id is null or p.party_id = v_b.party_id
       order by (c.rarity = v_rarity) desc, random()
       limit 1;

      insert into user_politician_cards (user_id, card_id) values (v_user, v_id)
      on conflict (user_id, card_id) do update set copies = user_politician_cards.copies + 1
      returning (xmax = 0) into v_new;

      v_cards := v_cards || (
        select jsonb_build_object(
          'type', 'politician', 'card_id', c.id, 'rarity', c.rarity, 'year', c.year,
          'title', c.title, 'party_label', c.party_label,
          'name', p.name, 'politician_slug', p.slug,
          'party_name', pa.name, 'party_short', pa.short_name, 'party_color', pa.color,
          'image_url', p.image_url, 'image_credit', p.image_credit,
          'image_license', p.image_license, 'image_source_url', p.image_source_url,
          'new', v_new)
        from politician_cards c
        join politicians p on p.id = c.politician_id
        left join parties pa on pa.id = p.party_id
        where c.id = v_id);
    else
      select q.id into v_id from quotes q
       where q.verified
         and (v_b.personality_id is null or q.personality_id = v_b.personality_id)
         and (v_b.theme is null or q.theme = v_b.theme)
       order by (q.rarity = v_rarity) desc, random()
       limit 1;

      insert into user_cards (user_id, quote_id) values (v_user, v_id)
      on conflict (user_id, quote_id) do update set copies = user_cards.copies + 1
      returning (xmax = 0) into v_new;

      v_cards := v_cards || (
        select jsonb_build_object(
          'type', 'quote', 'quote_id', q.id, 'text', q.text, 'rarity', q.rarity,
          'author', p.name, 'author_description', p.description,
          'said_on', q.said_on, 'occasion', q.occasion,
          'source_label', q.source_label, 'source_url', q.source_url,
          'theme', q.theme, 'is_demo', q.is_demo, 'new', v_new)
        from quotes q join personalities p on p.id = q.personality_id
        where q.id = v_id);
    end if;

    v_ids := v_ids || v_id;
  end loop;

  insert into booster_openings (user_id, booster_slug, price_paid, card_ids)
  values (v_user, p_slug, v_b.price, v_ids);

  return jsonb_build_object('kind', v_b.kind, 'cards', v_cards, 'points_left', v_points - v_b.price);
end $$;

revoke execute on function public.open_booster(text) from public, anon;
grant execute on function public.open_booster(text) to authenticated;
