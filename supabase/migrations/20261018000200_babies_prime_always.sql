-- Marine Tondelier Prime : désormais 100 % de chances dans le Booster Commun
-- (toujours en dernière carte, celle révélée en dernier).
-- On ne touche qu'au seuil de tirage de open_booster : random() < 0.03 devient « toujours ».
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

  if p_slug = 'rarete-commune' then
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

update public.booster_types set description = '3 cartes, dont la carte Prime Babies garantie'
 where slug = 'rarete-commune';
