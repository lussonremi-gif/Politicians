-- Photo propre à chaque carte (à défaut, le portrait de la personnalité).
-- Le palier « peu commune » est retiré : ces cartes deviennent communes,
-- et leur part dans les boosters est reversée aux communes.

alter table public.cards
  add column if not exists image_url text,
  add column if not exists image_credit text,
  add column if not exists image_license text,
  add column if not exists image_source_url text;

update public.cards set rarity = 'common' where rarity = 'uncommon';

update public.booster_types
   set weights = (weights - 'uncommon') || jsonb_build_object(
         'common',
         coalesce((weights ->> 'common')::numeric, 0) + coalesce((weights ->> 'uncommon')::numeric, 0)
       )
 where weights ? 'uncommon';

update public.cards c set
  image_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/' || replace(v.file, ' ', '_') || '?width=640',
  image_credit = v.credit,
  image_license = v.license,
  image_source_url = 'https://commons.wikimedia.org/wiki/File:' || replace(v.file, ' ', '_')
from (values
  ('Parce que c''est notre projet !', 'Emmanuel Macron (11 décembre 2014) (2) (cropped).jpg', 'OFFICIAL LEWEB PHOTOS', 'CC BY 2.0'),
  ('Nous sommes en guerre.', 'Emmanuel Macron 2020.jpg', 'U.S. Department of State', 'Domaine public'),
  ('On met un pognon de dingue dans des minima sociaux, et les gens ne s''en sortent pas.', 'Emmanuel Macron in Washington - 2018 (26809923797) (cropped).jpg', 'U.S. Department of State', 'Domaine public'),
  ('Les non-vaccinés, j''ai très envie de les emmerder.', 'Emmanuel Macron (2022-02-07) (cropped).jpg', 'Presidential Executive Office of Russia', 'CC BY 4.0'),
  ('Je traverse la rue, je vous en trouve.', 'Emmanuel Macron in November 2018 (cropped).jpg', 'The Kremlin, Moscow', 'CC BY 4.0'),
  ('Je ne céderai rien, ni aux fainéants, ni aux cyniques, ni aux extrêmes.', 'Emmanuel Macron (32605283887) (cropped).jpg', 'Jacques Paquier', 'CC BY 2.0')
) as v(text, file, credit, license)
where c.text = v.text;

create or replace function public._rarity_rank(p public.card_rarity)
returns integer language sql immutable as $$
  select case p when 'common' then 0 when 'uncommon' then 0 when 'rare' then 1
                when 'epic' then 2 when 'legendary' then 3 when 'mythic' then 4 end;
$$;

create or replace function public._card_json(p_card uuid)
returns jsonb language sql stable security definer set search_path = public as $$
  select jsonb_build_object(
    'card_id', c.id, 'text', c.text, 'rarity', c.rarity, 'theme', c.theme,
    'said_on', c.said_on, 'occasion', c.occasion,
    'source_label', c.source_label, 'source_url', c.source_url,
    'politician_id', p.id, 'politician_slug', p.slug, 'name', p.name, 'role', p.role,
    'image_url', coalesce(c.image_url, p.image_url),
    'image_credit', coalesce(c.image_credit, p.image_credit),
    'image_license', coalesce(c.image_license, p.image_license),
    'image_source_url', coalesce(c.image_source_url, p.image_source_url),
    'party_name', pa.name, 'party_short', pa.short_name, 'party_color', pa.color)
  from cards c
  join politicians p on p.id = c.politician_id
  left join parties pa on pa.id = p.party_id
  where c.id = p_card;
$$;

create or replace function public.my_album()
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
         coalesce(c.image_url, p.image_url),
         coalesce(c.image_credit, p.image_credit),
         coalesce(c.image_license, p.image_license),
         coalesce(c.image_source_url, p.image_source_url),
         pa.name, pa.short_name, pa.color, pa.sort_order
    from cards c
    join politicians p on p.id = c.politician_id
    left join parties pa on pa.id = p.party_id
    left join user_collection uc on uc.card_id = c.id and uc.user_id = auth.uid()
   where c.verified
   order by p.name, public._rarity_rank(c.rarity) desc;
$$;
