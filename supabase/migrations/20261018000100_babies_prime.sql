-- « Qui l'a dit ? » : catégorie « Babies » et carte Marine Tondelier Prime
--
-- - « babies » se place au-dessus de légendaire. Une seule carte pour l'instant :
--   Marine Tondelier Prime.
-- - Elle ne se trouve que dans le booster le moins rare (Booster Commun) : 3 % de chances
--   par booster, en remplacement de la dernière carte (celle qui est révélée en dernier).
-- - Elle n'apparaît jamais ailleurs : ni dans les autres boosters, ni dans le quiz, ni comme
--   récompense de duel.
-- (La valeur d'enum est ajoutée par la migration précédente « babies_rarity » :
--   alter type public.card_rarity add value if not exists 'babies'.)

create or replace function public._rarity_rank(p public.card_rarity)
returns integer language sql immutable as $$
  select case p when 'common' then 0 when 'uncommon' then 0 when 'rare' then 1
                when 'epic' then 2 when 'legendary' then 3 when 'mythic' then 3 when 'babies' then 5 end;
$$;

update public.politicians set role = 'Secrétaire nationale des Écologistes'
 where slug = 'marine-tondelier' and role is null;

insert into public.cards (politician_id, text, said_on, occasion, source_label, source_url, theme, rarity,
                          collectible, verified, image_url, image_credit, image_license, image_source_url)
select p.id,
       'Depuis qu''il existe un compte Twitter dédié à mes vestes vertes, j''ai un peu la pression',
       null, 'Carte Prime : la veste verte la plus célèbre de la politique (juillet 2024)',
       'L''Info Durable (Libération)',
       'https://www.linfodurable.fr/la-veste-verte-de-marine-tondelier-nouveau-vetement-star-en-politique-46097',
       'prime', 'babies', true, true,
       'https://commons.wikimedia.org/wiki/Special:FilePath/20210819_tondelier.m-cr3.jpg?width=640',
       'Wikimedia Commons', 'Wikimedia Commons',
       'https://commons.wikimedia.org/wiki/File:20210819_tondelier.m-cr3.jpg'
  from public.politicians p
 where p.slug = 'marine-tondelier'
   and not exists (select 1 from public.cards c where c.rarity = 'babies' and c.politician_id = p.id);

-- Quiz : jamais la carte Prime
create or replace function public._pick_rounds(p_count integer, p_theme text)
returns table (card_id uuid, option_a uuid, option_b uuid)
language plpgsql volatile security definer set search_path = public as $$
declare
  r record;
  v_decoy uuid;
begin
  for r in
    select c.id, c.politician_id, c.decoy_politician_id
      from cards c
     where c.verified and c.rarity <> 'babies' and (p_theme is null or c.theme = p_theme)
     order by random()
     limit p_count
  loop
    v_decoy := r.decoy_politician_id;
    if v_decoy is null then
      select p.id into v_decoy from politicians p
       where p.id <> r.politician_id and p.kind = 'politician'
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

-- Boosters : la carte Prime seulement dans le Booster Commun, 3 % de chances
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
  v_prime uuid;
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
     where c.verified and c.collectible and c.rarity <> 'babies'
       and (v_b.party_id is null or p.party_id = v_b.party_id)
       and (v_b.tag is null or v_b.tag = any (p.tags))
       and (v_b.theme is null or c.theme = v_b.theme)
  ) then raise exception 'empty booster'; end if;

  v_weights := coalesce(v_b.weights,
    jsonb_build_object('common', v_b.weight_common, 'rare', v_b.weight_rare, 'legendary', v_b.weight_legendary));

  if p_slug = 'rarete-commune' and random() < 0.03 then
    select c.id into v_prime from cards c where c.rarity = 'babies' and c.verified order by random() limit 1;
  end if;

  update profiles set points = points - v_b.price where id = v_user;

  for i in 1..v_b.card_count loop
    if i = v_b.card_count and v_prime is not null then
      v_id := v_prime;
    else
      v_rarity := _roll_rarity(v_weights);
      if i = v_b.card_count and v_b.guarantee is not null
         and _rarity_rank(v_rarity) < _rarity_rank(v_b.guarantee) then
        v_rarity := v_b.guarantee;
      end if;
      if v_rarity in ('uncommon') then v_rarity := 'common'; end if;
      if v_rarity in ('mythic', 'babies') then v_rarity := 'legendary'; end if;

      select c.id into v_id
        from cards c join politicians p on p.id = c.politician_id
       where c.verified and c.collectible and c.rarity <> 'babies'
         and (v_b.party_id is null or p.party_id = v_b.party_id)
         and (v_b.tag is null or v_b.tag = any (p.tags))
         and (v_b.theme is null or c.theme = v_b.theme)
       order by abs(_rarity_rank(c.rarity) - _rarity_rank(v_rarity)), _rarity_rank(c.rarity), random()
       limit 1;
    end if;

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

update public.booster_types set description = '3 cartes… et peut-être la carte Prime Babies'
 where slug = 'rarete-commune';
