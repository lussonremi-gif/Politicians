-- « Qui l'a dit ? » : quatre raretés (légendaire au sommet), boosters par rareté, 100 000 crédits de bienvenue
--
-- 1. Plus de « mythique » : les 5 citations mythiques deviennent légendaires, et seules les
--    5 légendaires les plus cultes le restent ; les autres légendaires passent épiques.
--    (La valeur 'mythic' reste dans l'enum card_rarity, elle n'est simplement plus utilisée.)
-- 2. La boutique ne propose plus que des boosters par rareté. Chacun garantit au moins une
--    carte de sa rareté (colonne guarantee) ; les anciens boosters sont désactivés.
-- 3. Les nouveaux joueurs reçoivent 100 000 crédits.

-- 1. Raretés -----------------------------------------------------------------
update public.cards set rarity = 'epic'
 where rarity = 'legendary'
   and not (text like 'Mais vous avez tout à fait raison%'
         or text like 'Notre maison brûle%'
         or text like 'Moi, président de la République%'
         or text like 'Paris outragé%'
         or text like 'J''ai l''honneur, au nom du gouvernement%');

update public.cards set rarity = 'legendary' where rarity = 'mythic';

-- 2. Boosters par rareté -----------------------------------------------------
alter table public.booster_types add column if not exists guarantee public.card_rarity;

update public.booster_types set active = false where active and slug not like 'rarete-%';

insert into public.booster_types
  (slug, name, description, price, card_count, weight_common, weight_rare, weight_legendary,
   kind, active, sort_order, weights, guarantee)
values
  ('rarete-commune', 'Booster Commun', '3 cartes, surtout des petites phrases', 250, 3, 75, 18, 7,
   'politicians', true, 1, '{"common":75,"rare":18,"epic":6,"legendary":1}', null),
  ('rarete-rare', 'Booster Rare', '3 cartes, au moins une rare', 500, 3, 45, 40, 15,
   'politicians', true, 2, '{"common":45,"rare":40,"epic":12,"legendary":3}', 'rare'),
  ('rarete-epique', 'Booster Épique', '3 cartes, au moins une épique', 750, 3, 20, 40, 40,
   'politicians', true, 3, '{"common":20,"rare":40,"epic":32,"legendary":8}', 'epic'),
  ('rarete-legendaire', 'Booster Légendaire', '3 cartes, au moins une légendaire', 1000, 3, 10, 30, 60,
   'politicians', true, 4, '{"common":10,"rare":30,"epic":40,"legendary":20}', 'legendary')
on conflict (slug) do update set
  name = excluded.name, description = excluded.description, price = excluded.price,
  card_count = excluded.card_count, weights = excluded.weights, guarantee = excluded.guarantee,
  active = true, sort_order = excluded.sort_order;

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
    -- La dernière carte (révélée en dernier) respecte la garantie du booster
    if i = v_b.card_count and v_b.guarantee is not null
       and _rarity_rank(v_rarity) < _rarity_rank(v_b.guarantee) then
      v_rarity := v_b.guarantee;
    end if;
    if v_rarity in ('uncommon') then v_rarity := 'common'; end if;
    if v_rarity in ('mythic') then v_rarity := 'legendary'; end if;

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

-- 3. 100 000 crédits de bienvenue -------------------------------------------
create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, points) values (new.id, 100000) on conflict do nothing;
  return new;
end $$;
