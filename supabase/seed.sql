-- ============================================================================
-- DONNÉES DE DÉMONSTRATION — ENTIÈREMENT FICTIVES
-- Personnalités et citations inventées pour tester le jeu. Elles ne doivent
-- jamais être confondues avec de vraies déclarations : elles sont marquées
-- is_demo = true et affichées avec un bandeau « Démo » dans l'application.
-- Pour passer en production :  delete from public.personalities where is_demo;
-- ============================================================================

insert into public.personalities (slug, name, kind, description, is_demo) values
  ('demo-camille-exemple', 'Camille Exemple', 'candidate', 'Candidate fictive (démo)', true),
  ('demo-louis-fictif',    'Louis Fictif',    'candidate', 'Candidat fictif (démo)',  true),
  ('demo-nora-modele',     'Nora Modèle',     'candidate', 'Candidate fictive (démo)', true),
  ('demo-paul-prototype',  'Paul Prototype',  'candidate', 'Candidat fictif (démo)',  true),
  ('demo-lea-chanson',     'Léa Chanson',     'other',     'Chanteuse fictive (démo)', true),
  ('demo-marc-scene',      'Marc Scène',      'other',     'Acteur fictif (démo)',     true),
  ('demo-victor-ancien',   'Victor Ancien',   'other',     'Ancien ministre fictif (démo)', true),
  ('demo-ada-histoire',    'Ada Histoire',    'other',     'Figure historique fictive (démo)', true);

-- Même nombre de cartes et mêmes raretés pour chaque candidat (règle de neutralité)
with p as (select slug, id from public.personalities)
insert into public.quotes
  (text, personality_id, decoy_personality_id, said_on, occasion, source_label, theme, rarity, verified, is_demo)
values
  ('Le travail doit toujours mieux payer que l''inaction.', (select id from p where slug='demo-camille-exemple'), (select id from p where slug='demo-victor-ancien'), '2026-03-12', 'Meeting fictif à Lille', 'Source de démonstration', 'économie', 'common', true, true),
  ('Chaque commune mérite un médecin à moins de vingt minutes.', (select id from p where slug='demo-camille-exemple'), null, '2026-05-02', 'Interview radio fictive', 'Source de démonstration', 'santé', 'common', true, true),
  ('On ne protège pas la planète en punissant ceux qui roulent pour aller travailler.', (select id from p where slug='demo-camille-exemple'), (select id from p where slug='demo-marc-scene'), '2026-06-18', 'Débat télévisé fictif', 'Source de démonstration', 'écologie', 'rare', true, true),
  ('La France n''est jamais aussi grande que lorsqu''elle doute d''elle-même.', (select id from p where slug='demo-camille-exemple'), (select id from p where slug='demo-ada-histoire'), '2026-09-01', 'Discours fictif de rentrée', 'Source de démonstration', 'institutions', 'legendary', true, true),

  ('Un euro investi dans l''école, c''est dix euros économisés demain.', (select id from p where slug='demo-louis-fictif'), (select id from p where slug='demo-lea-chanson'), '2026-02-20', 'Visite fictive d''un lycée', 'Source de démonstration', 'éducation', 'common', true, true),
  ('La sécurité est la première des libertés, mais pas la seule.', (select id from p where slug='demo-louis-fictif'), (select id from p where slug='demo-victor-ancien'), '2026-04-09', 'Entretien fictif dans la presse régionale', 'Source de démonstration', 'sécurité', 'common', true, true),
  ('Je préfère une vérité qui dérange à une promesse qui rassure.', (select id from p where slug='demo-louis-fictif'), (select id from p where slug='demo-marc-scene'), '2026-07-05', 'Émission politique fictive', 'Source de démonstration', 'institutions', 'rare', true, true),
  ('Le climat n''attend pas le calendrier électoral.', (select id from p where slug='demo-louis-fictif'), (select id from p where slug='demo-lea-chanson'), '2026-08-22', 'Université d''été fictive', 'Source de démonstration', 'écologie', 'legendary', true, true),

  ('Nos agriculteurs nourrissent le pays, le pays doit les respecter.', (select id from p where slug='demo-nora-modele'), (select id from p where slug='demo-victor-ancien'), '2026-02-28', 'Salon fictif de l''agriculture', 'Source de démonstration', 'agriculture', 'common', true, true),
  ('Une réforme qu''on n''explique pas est une réforme qu''on perd.', (select id from p where slug='demo-nora-modele'), null, '2026-04-30', 'Conférence de presse fictive', 'Source de démonstration', 'institutions', 'common', true, true),
  ('Il faut produire en France ce que nous consommons en France.', (select id from p where slug='demo-nora-modele'), (select id from p where slug='demo-ada-histoire'), '2026-06-03', 'Visite fictive d''usine', 'Source de démonstration', 'économie', 'rare', true, true),
  ('La jeunesse n''est pas un problème à gérer, c''est une chance à saisir.', (select id from p where slug='demo-nora-modele'), (select id from p where slug='demo-lea-chanson'), '2026-09-15', 'Meeting fictif à Bordeaux', 'Source de démonstration', 'jeunesse', 'legendary', true, true),

  ('Simplifier l''administration, c''est rendre du temps aux Français.', (select id from p where slug='demo-paul-prototype'), (select id from p where slug='demo-victor-ancien'), '2026-03-03', 'Tribune fictive', 'Source de démonstration', 'institutions', 'common', true, true),
  ('Un logement digne n''est pas un luxe.', (select id from p where slug='demo-paul-prototype'), (select id from p where slug='demo-lea-chanson'), '2026-05-14', 'Déplacement fictif en banlieue', 'Source de démonstration', 'logement', 'common', true, true),
  ('L''Europe doit être une puissance, pas seulement un marché.', (select id from p where slug='demo-paul-prototype'), (select id from p where slug='demo-ada-histoire'), '2026-07-14', 'Interview fictive à la télévision', 'Source de démonstration', 'europe', 'rare', true, true),
  ('On ne gouverne pas un pays avec des sondages, mais avec une boussole.', (select id from p where slug='demo-paul-prototype'), (select id from p where slug='demo-marc-scene'), '2026-10-01', 'Grand oral fictif', 'Source de démonstration', 'institutions', 'legendary', true, true),

  ('Sur scène comme ailleurs, il faut oser la sincérité.', (select id from p where slug='demo-lea-chanson'), null, '2025-11-20', 'Interview fictive dans un magazine', 'Source de démonstration', 'culture', 'common', true, true),
  ('Le public ne pardonne jamais l''ennui.', (select id from p where slug='demo-marc-scene'), null, '2025-06-10', 'Festival fictif', 'Source de démonstration', 'culture', 'common', true, true),
  ('Gouverner, c''est choisir entre deux mécontentements.', (select id from p where slug='demo-victor-ancien'), null, '2019-01-15', 'Mémoires fictifs', 'Source de démonstration', 'institutions', 'rare', true, true),
  ('Un peuple qui oublie son histoire se condamne à la réécrire.', (select id from p where slug='demo-ada-histoire'), null, '1900-01-01', 'Lettre fictive', 'Source de démonstration', 'histoire', 'legendary', true, true);

-- Boosters (prix et probabilités v1, à valider avec l'équipe)
insert into public.booster_types (slug, name, description, price, card_count, weight_common, weight_rare, weight_legendary, theme, sort_order) values
  ('classique', 'Booster classique', '3 cartes, toutes personnalités', 300, 3, 70, 25, 5, null, 1),
  ('premium',   'Booster premium',   '5 cartes, plus de chances de rares', 800, 5, 50, 38, 12, null, 2),
  ('ecologie',  'Booster Écologie',  '3 cartes sur le thème de l''écologie', 400, 3, 70, 25, 5, 'écologie', 3),
  ('institutions', 'Booster Institutions', '3 cartes sur les institutions', 400, 3, 70, 25, 5, 'institutions', 4);

-- Un booster thématique par candidat
insert into public.booster_types (slug, name, description, price, card_count, personality_id, sort_order)
select 'candidat-' || slug, 'Booster ' || name, '3 cartes de ' || name, 400, 3, id, 10
from public.personalities where kind = 'candidate';
