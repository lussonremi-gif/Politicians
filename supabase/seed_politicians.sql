-- ============================================================================
-- Collection de personnalités politiques : contenu de départ
--
-- Photos : fichiers Wikimedia Commons sous licence libre (CC0, CC BY, CC BY-SA),
-- affichés via Special:FilePath avec le crédit et la licence au verso de la carte.
-- À FAIRE PAR L'ÉQUIPE ÉDITORIALE : vérifier chaque fiche Commons (auteur, licence)
-- et chaque intitulé de version avant le lancement public.
--
-- Neutralité : 3 versions par personnalité (légendaire = la plus ancienne,
-- rare, commune = « Saison 2026 »), mêmes probabilités pour tous.
-- ============================================================================

insert into public.parties (slug, name, short_name, color, sort_order) values
  ('lfi',           'La France insoumise',     'LFI',   '#c9462c', 1),
  ('pcf',           'Parti communiste français', 'PCF', '#dd0000', 2),
  ('place-publique','Place publique',          'PP',    '#e4007f', 3),
  ('ecologistes',   'Les Écologistes',         'LE',    '#2e9c4b', 4),
  ('renaissance',   'Renaissance',             'RE',    '#e8b100', 5),
  ('modem',         'Mouvement démocrate',     'MoDem', '#f08c00', 6),
  ('horizons',      'Horizons',                'HOR',   '#2f8fa8', 7),
  ('lr',            'Les Républicains',        'LR',    '#1f5fbf', 8),
  ('rn',            'Rassemblement national',  'RN',    '#1b2a6b', 9),
  ('reconquete',    'Reconquête',              'REC',   '#3a3a3a', 10);

-- Helper local : URL de vignette Commons à partir du nom de fichier
create or replace function pg_temp.commons(p_file text) returns text language sql immutable as $$
  select 'https://commons.wikimedia.org/wiki/Special:FilePath/' || replace(p_file, ' ', '_') || '?width=480';
$$;
create or replace function pg_temp.commons_page(p_file text) returns text language sql immutable as $$
  select 'https://commons.wikimedia.org/wiki/File:' || replace(p_file, ' ', '_');
$$;

insert into public.politicians (slug, name, party_id, image_url, image_credit, image_license, image_source_url)
select v.slug, v.name, (select id from public.parties where slug = v.party),
       pg_temp.commons(v.file), v.credit, v.license, pg_temp.commons_page(v.file)
from (values
  ('emmanuel-macron',    'Emmanuel Macron',    'renaissance',    'Emmanuel Macron (cropped).jpg',
     'Arno Mikkor (EU2017EE)', 'CC BY 2.0'),
  ('gabriel-attal',      'Gabriel Attal',      'renaissance',    'Gabriel Attal 2025 (cropped).jpg',
     'Wikimedia Commons', 'CC BY 4.0'),
  ('marine-le-pen',      'Marine Le Pen',      'rn',             'Marine Le Pen 2022 (cropped).jpg',
     'VOX España', 'Domaine public'),
  ('jordan-bardella',    'Jordan Bardella',    'rn',             'Jordan Bardella (cropped).jpg',
     'Parlement européen', 'CC BY 4.0'),
  ('jean-luc-melenchon', 'Jean-Luc Mélenchon', 'lfi',            'Jean-Luc Mélenchon 2022 (cropped).jpg',
     'Thomas Bresson', 'CC BY 4.0'),
  ('edouard-philippe',   'Édouard Philippe',   'horizons',       'Édouard Philippe 2019 (cropped).jpg',
     'Jacques Paquier', 'CC BY 2.0'),
  ('raphael-glucksmann', 'Raphaël Glucksmann', 'place-publique', '2024-03-03 - Congrès du PSE- 105 - Raphael Glucksmann.jpg',
     'Wikimedia Commons', 'CC0'),
  ('bruno-retailleau',   'Bruno Retailleau',   'lr',             'Bruno Retailleau - Ministre de l''Intérieur français (cropped).jpg',
     'Anthony Montardy', 'CC BY 4.0'),
  ('eric-zemmour',       'Éric Zemmour',       'reconquete',     'Portrait d''Éric Zemmour, avril 2022 (cropped).jpg',
     'Anh De France', 'CC0'),
  ('marine-tondelier',   'Marine Tondelier',   'ecologistes',    'Huma2023MarineTondelier.jpg',
     'Wikimedia Commons', 'CC BY 4.0'),
  ('fabien-roussel',     'Fabien Roussel',     'pcf',            'Fabien Roussel 2022.jpg',
     'Wikimedia Commons', 'CC BY-SA 4.0'),
  ('francois-bayrou',    'François Bayrou',    'modem',          'François Bayrou 2025 (cropped).jpg',
     'Commission européenne', 'CC BY 4.0')
) as v(slug, name, party, file, credit, license);

-- Versions : légendaire (la plus ancienne), rare, commune (Saison 2026)
insert into public.politician_cards (politician_id, year, title, party_label, rarity)
select (select id from public.politicians where slug = v.slug), v.year, v.title, v.party_label, v.rarity::public.rarity
from (values
  ('emmanuel-macron',    2017, 'Élu président de la République',               'En marche !',              'legendary'),
  ('emmanuel-macron',    2022, 'Réélu président de la République',             'La République en marche',  'rare'),
  ('emmanuel-macron',    2026, 'Saison 2026',                                   'Renaissance',              'common'),

  ('gabriel-attal',      2020, 'Porte-parole du gouvernement',                  'La République en marche',  'legendary'),
  ('gabriel-attal',      2024, 'Premier ministre',                              'Renaissance',              'rare'),
  ('gabriel-attal',      2026, 'Saison 2026',                                   'Renaissance',              'common'),

  ('marine-le-pen',      2017, 'Qualifiée au second tour de la présidentielle', 'Front national',           'legendary'),
  ('marine-le-pen',      2022, 'Qualifiée au second tour de la présidentielle', 'Rassemblement national',   'rare'),
  ('marine-le-pen',      2026, 'Saison 2026',                                   'Rassemblement national',   'common'),

  ('jordan-bardella',    2019, 'Tête de liste aux élections européennes',       'Rassemblement national',   'legendary'),
  ('jordan-bardella',    2024, 'Sa liste arrive en tête des européennes',       'Rassemblement national',   'rare'),
  ('jordan-bardella',    2026, 'Saison 2026',                                   'Rassemblement national',   'common'),

  ('jean-luc-melenchon', 2017, 'Candidat à la présidentielle (4e)',             'La France insoumise',      'legendary'),
  ('jean-luc-melenchon', 2022, 'Candidat à la présidentielle (3e)',             'La France insoumise',      'rare'),
  ('jean-luc-melenchon', 2026, 'Saison 2026',                                   'La France insoumise',      'common'),

  ('edouard-philippe',   2017, 'Nommé Premier ministre',                        null,                       'legendary'),
  ('edouard-philippe',   2021, 'Fonde Horizons',                                'Horizons',                 'rare'),
  ('edouard-philippe',   2026, 'Saison 2026',                                   'Horizons',                 'common'),

  ('raphael-glucksmann', 2019, 'Tête de liste aux élections européennes',       'Place publique',           'legendary'),
  ('raphael-glucksmann', 2024, 'Tête de liste aux élections européennes',       'Place publique',           'rare'),
  ('raphael-glucksmann', 2026, 'Saison 2026',                                   'Place publique',           'common'),

  ('bruno-retailleau',   2024, 'Nommé ministre de l''Intérieur',                'Les Républicains',         'legendary'),
  ('bruno-retailleau',   2025, 'Élu président des Républicains',                'Les Républicains',         'rare'),
  ('bruno-retailleau',   2026, 'Saison 2026',                                   'Les Républicains',         'common'),

  ('eric-zemmour',       2021, 'Fonde Reconquête',                              'Reconquête',               'legendary'),
  ('eric-zemmour',       2022, 'Candidat à la présidentielle',                  'Reconquête',               'rare'),
  ('eric-zemmour',       2026, 'Saison 2026',                                   'Reconquête',               'common'),

  ('marine-tondelier',   2022, 'Élue secrétaire nationale d''EELV',             'EELV',                     'legendary'),
  ('marine-tondelier',   2024, 'Secrétaire nationale des Écologistes',          'Les Écologistes',          'rare'),
  ('marine-tondelier',   2026, 'Saison 2026',                                   'Les Écologistes',          'common'),

  ('fabien-roussel',     2018, 'Élu secrétaire national du PCF',                'Parti communiste français', 'legendary'),
  ('fabien-roussel',     2022, 'Candidat à la présidentielle',                  'Parti communiste français', 'rare'),
  ('fabien-roussel',     2026, 'Saison 2026',                                   'Parti communiste français', 'common'),

  ('francois-bayrou',    2007, 'Candidat à la présidentielle (3e)',             'UDF',                      'legendary'),
  ('francois-bayrou',    2024, 'Nommé Premier ministre',                        'Mouvement démocrate',      'rare'),
  ('francois-bayrou',    2026, 'Saison 2026',                                   'Mouvement démocrate',      'common')
) as v(slug, year, title, party_label, rarity);

-- Boosters de personnalités : les boosters classique et premium passent en personnalités,
-- les boosters de candidats fictifs (démo) sont désactivés, un booster par parti est ajouté.
update public.booster_types
   set kind = 'politicians', description = '3 cartes de personnalités politiques'
 where slug = 'classique';
update public.booster_types
   set kind = 'politicians', description = '5 cartes, plus de chances de légendaires'
 where slug = 'premium';
update public.booster_types set active = false where slug like 'candidat-demo-%';
update public.booster_types set name = 'Citations · ' || replace(name, 'Booster ', ''), sort_order = 50 + sort_order
 where kind = 'quotes' and slug not like 'candidat-demo-%';

insert into public.booster_types (slug, name, description, price, card_count, weight_common, weight_rare, weight_legendary, kind, party_id, sort_order)
select 'parti-' || slug, 'Booster ' || short_name, '3 cartes · ' || name, 400, 3, 70, 25, 5, 'politicians', id, 10 + sort_order
from public.parties;
