-- « Qui l'a dit ? » : photo propre à chaque carte et personnalités hors politique
--
-- - Chaque carte peut avoir sa propre photo (de l'époque de la citation) ; à défaut,
--   la photo de la personnalité est utilisée.
-- - kind = 'personality' : personnalités hors politique (sport, culture…) ou étrangères,
--   proposées uniquement comme « pièges » dans le jeu quand la citation pourrait leur
--   être attribuée. Elles n'ont pas de cartes et n'apparaissent pas dans la collection.
-- - image_focus : cadrage CSS (object-position) pour les photos en pied ou les tableaux.

alter table public.politicians
  add column kind text not null default 'politician' check (kind in ('politician', 'personality')),
  add column image_focus text;

alter table public.cards
  add column image_url text,
  add column image_credit text,
  add column image_license text,
  add column image_source_url text,
  add column image_focus text;

create or replace function public._card_json(p_card uuid)
returns jsonb language sql stable security definer set search_path = public as $$
  select jsonb_build_object(
    'card_id', c.id, 'text', c.text, 'rarity', c.rarity, 'theme', c.theme,
    'said_on', c.said_on, 'occasion', c.occasion,
    'source_label', c.source_label, 'source_url', c.source_url,
    'politician_id', p.id, 'politician_slug', p.slug, 'name', p.name, 'role', p.role,
    'image_url', coalesce(c.image_url, p.image_url),
    'image_credit', case when c.image_url is not null then c.image_credit else p.image_credit end,
    'image_license', case when c.image_url is not null then c.image_license else p.image_license end,
    'image_source_url', coalesce(c.image_source_url, p.image_source_url),
    'image_focus', coalesce(c.image_focus, p.image_focus),
    'fallback_image_url', p.image_url,
    'party_name', pa.name, 'party_short', pa.short_name, 'party_color', pa.color)
  from cards c
  join politicians p on p.id = c.politician_id
  left join parties pa on pa.id = p.party_id
  where c.id = p_card;
$$;

create or replace function public._option_json(p_politician uuid)
returns jsonb language sql stable security definer set search_path = public as $$
  select jsonb_build_object('id', p.id, 'name', p.name, 'description', p.role, 'image_url', p.image_url,
                            'image_focus', p.image_focus, 'kind', p.kind,
                            'party_short', pa.short_name, 'party_color', pa.color)
  from politicians p left join parties pa on pa.id = p.party_id
  where p.id = p_politician;
$$;

-- Piège aléatoire : seulement des personnalités politiques qui ont des cartes ;
-- les personnalités hors politique ne sont proposées que comme pièges choisis.
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
     where c.verified and (p_theme is null or c.theme = p_theme)
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

-- Album (remplace my_album) : photo de la carte, cadrage, citation masquée tant que non obtenue
create function public.collection_album()
returns table (
  card_id uuid, rarity public.card_rarity, theme text, copies integer,
  text text, said_on date, occasion text, source_label text, source_url text,
  politician_id uuid, politician_slug text, name text, role text,
  image_url text, image_credit text, image_license text, image_source_url text, image_focus text,
  fallback_image_url text,
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
         coalesce(c.image_url, p.image_url),
         case when c.image_url is not null then c.image_credit else p.image_credit end,
         case when c.image_url is not null then c.image_license else p.image_license end,
         coalesce(c.image_source_url, p.image_source_url),
         coalesce(c.image_focus, p.image_focus),
         p.image_url,
         pa.name, pa.short_name, pa.color, pa.sort_order
    from cards c
    join politicians p on p.id = c.politician_id
    left join parties pa on pa.id = p.party_id
    left join user_collection uc on uc.card_id = c.id and uc.user_id = auth.uid()
   where c.verified
   order by p.name, public._rarity_rank(c.rarity) desc;
$$;

revoke execute on function public.collection_album() from public, anon;
grant execute on function public.collection_album() to authenticated;
