-- ============================================================================
-- Cartes « personnalité + citation » : contenu de départ (32 cartes)
--
-- Citations célèbres de la vie politique française, retenues parce qu'elles sont
-- largement documentées (archives audiovisuelles, presse). Rareté selon le
-- retentissement : commune < peu commune < rare < épique < légendaire < mythique.
--
-- À FAIRE PAR L'ÉQUIPE ÉDITORIALE AVANT LE LANCEMENT :
--   - vérifier mot pour mot chaque citation et sa date sur la source d'origine
--     (archives INA, vidéo, compte rendu de l'Assemblée…) ;
--   - renseigner source_url (lien vers la source) et verified_by ;
--   - compléter les crédits photo marqués « Wikimedia Commons ».
-- ============================================================================

insert into public.parties (slug, name, short_name, color, sort_order) values
  ('ps', 'Parti socialiste', 'PS', '#e63a5f', 3)
on conflict (slug) do nothing;

-- Nouvelles personnalités (photos Wikimedia Commons sous licence libre)
insert into public.politicians (slug, name, party_id, image_url, image_credit, image_license, image_source_url)
select v.slug, v.name, (select id from public.parties where slug = v.party),
       'https://commons.wikimedia.org/wiki/Special:FilePath/' || replace(v.file, ' ', '_') || '?width=480',
       v.credit, v.license,
       'https://commons.wikimedia.org/wiki/File:' || replace(v.file, ' ', '_')
from (values
  ('charles-de-gaulle',      'Charles de Gaulle',      null, 'Charles de Gaulle-1963.jpg', 'Ludwig Wegmann (Bundesarchiv)', 'CC BY-SA 3.0 DE'),
  ('francois-mitterrand',    'François Mitterrand',    'ps', 'President François Mitterrand in 1983 (cropped).jpg', 'Comet Photo AG (ETH-Bibliothek Zürich)', 'CC BY-SA 4.0'),
  ('valery-giscard-destaing','Valéry Giscard d''Estaing', null, 'Valéry Giscard d''Estaing (1975) (cropped).jpg', 'Christian Lambiotte (Commission européenne)', 'CC BY 4.0'),
  ('jacques-chirac',         'Jacques Chirac',         null, 'Jacques Chirac (1997) (cropped).jpg', 'Christian Lambiotte (Commission européenne)', 'CC BY 4.0'),
  ('nicolas-sarkozy',        'Nicolas Sarkozy',        'lr', 'Nicolas Sarkozy (cropped).jpg', 'Wikimedia Commons', 'CC BY-SA 2.5'),
  ('francois-hollande',      'François Hollande',      'ps', 'François Hollande 2011.jpg', 'Wikimedia Commons', 'CC BY 2.0'),
  ('lionel-jospin',          'Lionel Jospin',          'ps', 'Lionel Jospin (4553758629).jpg', 'Fondapol', 'CC BY-SA 2.0'),
  ('edouard-balladur',       'Édouard Balladur',       null, 'Édouard Balladur - 1993.jpg', 'Commission européenne', 'CC BY 4.0'),
  ('segolene-royal',         'Ségolène Royal',         'ps', 'Ségolène Royal - Janvier 2012.jpg', 'Wikimedia Commons', null),
  ('simone-veil',            'Simone Veil',            null, 'Simone Veil (1984) (cropped).jpg', 'Rob Croes / Anefo (Nationaal Archief)', 'CC BY-SA 3.0 NL'),
  ('robert-badinter',        'Robert Badinter',        'ps', 'Robert Badinter, 2007 (cropped).jpg', 'Denis (Paris)', 'CC BY-SA 2.0'),
  ('dominique-de-villepin',  'Dominique de Villepin',  null, 'Dominique de Villepin (2010).jpg', 'Georges Seguin (Okki)', 'CC BY-SA 3.0'),
  ('michel-rocard',          'Michel Rocard',          'ps', 'Michel Rocard16 (cropped).JPG', 'Roland Godefroy', null)
) as v(slug, name, party, file, credit, license)
on conflict (slug) do nothing;

-- Fonctions et tags
update public.politicians p set role = v.role, tags = v.tags
from (values
  ('charles-de-gaulle',       'Président de la République (1959-1969)', array['president']),
  ('valery-giscard-destaing', 'Président de la République (1974-1981)', array['president']),
  ('francois-mitterrand',     'Président de la République (1981-1995)', array['president']),
  ('jacques-chirac',          'Président de la République (1995-2007)', array['president']),
  ('nicolas-sarkozy',         'Président de la République (2007-2012)', array['president']),
  ('francois-hollande',       'Président de la République (2012-2017)', array['president']),
  ('emmanuel-macron',         'Président de la République (depuis 2017)', array['president']),
  ('michel-rocard',           'Premier ministre (1988-1991)', array[]::text[]),
  ('edouard-balladur',        'Premier ministre (1993-1995)', array[]::text[]),
  ('lionel-jospin',           'Premier ministre (1997-2002)', array[]::text[]),
  ('dominique-de-villepin',   'Premier ministre (2005-2007)', array[]::text[]),
  ('simone-veil',             'Ministre de la Santé (1974-1979)', array[]::text[]),
  ('robert-badinter',         'Garde des Sceaux (1981-1986)', array[]::text[]),
  ('segolene-royal',          'Candidate à la présidentielle de 2007', array[]::text[]),
  ('marine-le-pen',           'Candidate à la présidentielle (2012, 2017, 2022)', array[]::text[]),
  ('jean-luc-melenchon',      'Candidat à la présidentielle (2012, 2017, 2022)', array[]::text[]),
  ('francois-bayrou',         'Président du MoDem', array[]::text[])
) as v(slug, role, tags)
where p.slug = v.slug;

-- Cartes
insert into public.cards (politician_id, text, said_on, occasion, source_label, theme, rarity, decoy_politician_id, verified)
select (select id from public.politicians where slug = v.who), v.text, v.said_on::date, v.occasion,
       'Source à documenter (archives INA, presse)', v.theme, v.rarity::public.card_rarity,
       (select id from public.politicians where slug = v.decoy), true
from (values
  -- Mythiques
  ('charles-de-gaulle', 'Je vous ai compris !', '1958-06-04', 'Discours au Forum d''Alger', 'discours', 'mythic', 'valery-giscard-destaing'),
  ('valery-giscard-destaing', 'Vous n''avez pas, monsieur Mitterrand, le monopole du cœur.', '1974-05-10', 'Débat télévisé d''entre-deux-tours face à François Mitterrand', 'débats', 'mythic', 'francois-mitterrand'),
  ('jean-luc-melenchon', 'La République, c''est moi !', '2018-10-16', 'Perquisition au siège de La France insoumise', 'petites phrases', 'mythic', 'charles-de-gaulle'),
  ('nicolas-sarkozy', 'Casse-toi alors, pauvre con !', '2008-02-23', 'Salon de l''agriculture, à Paris', 'petites phrases', 'mythic', null),
  -- Légendaires
  ('francois-hollande', 'Moi, président de la République, je ne serai pas le chef de la majorité.', '2012-05-02', 'Débat télévisé d''entre-deux-tours face à Nicolas Sarkozy', 'débats', 'legendary', 'nicolas-sarkozy'),
  ('charles-de-gaulle', 'Paris outragé ! Paris brisé ! Paris martyrisé ! Mais Paris libéré !', '1944-08-25', 'Discours à l''Hôtel de Ville de Paris, le jour de la Libération', 'discours', 'legendary', null),
  ('francois-mitterrand', 'Mais vous avez tout à fait raison, monsieur le Premier ministre.', '1988-04-28', 'Débat télévisé d''entre-deux-tours face à Jacques Chirac', 'débats', 'legendary', 'jacques-chirac'),
  ('jacques-chirac', 'Notre maison brûle et nous regardons ailleurs.', '2002-09-02', 'Discours au Sommet de la Terre, à Johannesburg', 'discours', 'legendary', null),
  ('robert-badinter', 'J''ai l''honneur, au nom du gouvernement de la République, de demander à l''Assemblée nationale l''abolition de la peine de mort en France.', '1981-09-17', 'Discours à l''Assemblée nationale', 'discours', 'legendary', 'simone-veil'),
  -- Épiques
  ('simone-veil', 'Aucune femme ne recourt de gaîté de cœur à l''avortement.', '1974-11-26', 'Discours à l''Assemblée nationale présentant le projet de loi sur l''IVG', 'discours', 'epic', 'robert-badinter'),
  ('dominique-de-villepin', 'Et c''est un vieux pays, la France, d''un vieux continent comme le mien, l''Europe, qui vous le dit aujourd''hui.', '2003-02-14', 'Discours au Conseil de sécurité de l''ONU sur l''Irak', 'discours', 'epic', 'jacques-chirac'),
  ('emmanuel-macron', 'Parce que c''est notre projet !', '2016-12-10', 'Meeting de campagne, porte de Versailles à Paris', 'campagnes', 'epic', null),
  ('emmanuel-macron', 'Nous sommes en guerre.', '2020-03-16', 'Allocution télévisée sur l''épidémie de Covid-19', 'discours', 'epic', null),
  ('francois-hollande', 'Mon véritable adversaire, il n''a pas de nom, pas de visage, pas de parti. […] Cet adversaire, c''est le monde de la finance.', '2012-01-22', 'Meeting de campagne au Bourget', 'campagnes', 'epic', 'jean-luc-melenchon'),
  ('nicolas-sarkozy', 'Dès demain, on va nettoyer au Kärcher la cité.', '2005-06-20', 'Déplacement à La Courneuve, alors ministre de l''Intérieur', 'petites phrases', 'epic', null),
  -- Rares
  ('charles-de-gaulle', 'Vive le Québec libre !', '1967-07-24', 'Discours au balcon de l''hôtel de ville de Montréal', 'discours', 'rare', null),
  ('francois-mitterrand', 'Je crois aux forces de l''esprit et je ne vous quitterai pas.', '1994-12-31', 'Derniers vœux télévisés aux Français', 'discours', 'rare', null),
  ('jacques-chirac', 'Aujourd''hui, on rapporte une histoire abracadabrantesque.', '2000-09-21', 'Entretien télévisé à propos de la « cassette Méry »', 'petites phrases', 'rare', null),
  ('lionel-jospin', 'J''assume pleinement la responsabilité de cet échec et j''en tire les conclusions, en me retirant de la vie politique après la fin de l''élection présidentielle.', '2002-04-21', 'Déclaration au soir du premier tour de la présidentielle', 'campagnes', 'rare', null),
  ('emmanuel-macron', 'On met un pognon de dingue dans des minima sociaux, et les gens ne s''en sortent pas.', '2018-06-12', 'Vidéo diffusée par la communication de l''Élysée', 'petites phrases', 'rare', null),
  ('emmanuel-macron', 'Les non-vaccinés, j''ai très envie de les emmerder.', '2022-01-04', 'Entretien au journal Le Parisien', 'petites phrases', 'rare', null),
  -- Peu communes
  ('edouard-balladur', 'Je vous demande de vous arrêter.', '1995-04-23', 'Soirée du premier tour de la présidentielle, face à ses partisans', 'campagnes', 'uncommon', 'jacques-chirac'),
  ('segolene-royal', 'Qui va sur la Grande Muraille conquiert la bravitude.', '2007-01-06', 'Visite de la Grande Muraille de Chine pendant la campagne présidentielle', 'campagnes', 'uncommon', null),
  ('emmanuel-macron', 'Je traverse la rue, je vous en trouve.', '2018-09-15', 'Journées du patrimoine à l''Élysée, face à un jeune demandeur d''emploi', 'petites phrases', 'uncommon', null),
  ('jean-luc-melenchon', 'Ma personne est sacrée !', '2018-10-16', 'Perquisition au siège de La France insoumise', 'petites phrases', 'uncommon', null),
  ('michel-rocard', 'La France ne peut pas accueillir toute la misère du monde.', '1989-12-03', 'Émission « Sept sur sept » ; la portée exacte de la phrase fait débat', 'petites phrases', 'uncommon', null),
  ('marine-le-pen', 'La France sera dirigée par une femme, ce sera soit moi, soit Mme Merkel.', '2017-05-03', 'Débat télévisé d''entre-deux-tours face à Emmanuel Macron', 'débats', 'uncommon', 'emmanuel-macron'),
  -- Communes
  ('valery-giscard-destaing', 'Au revoir.', '1981-05-19', 'Allocution télévisée de fin de septennat', 'discours', 'common', 'francois-mitterrand'),
  ('nicolas-sarkozy', 'Désormais, quand il y a une grève en France, personne ne s''en aperçoit.', '2008-07-05', 'Conseil national de l''UMP', 'petites phrases', 'common', null),
  ('lionel-jospin', 'Je suis socialiste d''inspiration, mais le projet que je propose au pays n''est pas un projet socialiste.', '2002-02-21', 'Entretien télévisé pendant la campagne présidentielle', 'campagnes', 'common', null),
  ('francois-bayrou', 'Tu ne me fais pas les poches !', '2002-04-09', 'Déplacement à Strasbourg pendant la campagne présidentielle', 'petites phrases', 'common', null),
  ('emmanuel-macron', 'Je ne céderai rien, ni aux fainéants, ni aux cyniques, ni aux extrêmes.', '2017-09-08', 'Discours à Athènes', 'discours', 'common', null)
) as v(who, text, said_on, occasion, theme, rarity, decoy);

-- Boosters : 6 raretés
update public.booster_types
   set weights = '{"common":45,"uncommon":27,"rare":15,"epic":8,"legendary":4,"mythic":1}',
       description = '3 cartes personnalité + citation'
 where kind = 'politicians' and slug <> 'premium';
update public.booster_types
   set weights = '{"common":20,"uncommon":25,"rare":25,"epic":17,"legendary":10,"mythic":3}',
       description = '5 cartes, bien plus de chances de cartes rares'
 where slug = 'premium';

-- Boosters par parti : seulement pour les partis qui ont des cartes
update public.booster_types b set active = exists (
  select 1 from public.cards c join public.politicians p on p.id = c.politician_id
   where p.party_id = b.party_id and c.verified)
 where b.party_id is not null;
insert into public.booster_types (slug, name, description, price, card_count, kind, party_id, weights, sort_order)
select 'parti-ps', 'Booster PS', '3 cartes · Parti socialiste', 400, 3, 'politicians', id,
       '{"common":45,"uncommon":27,"rare":15,"epic":8,"legendary":4,"mythic":1}', 13
from public.parties where slug = 'ps'
on conflict (slug) do nothing;

-- Boosters thématiques
insert into public.booster_types (slug, name, description, price, card_count, kind, tag, theme, weights, sort_order) values
  ('presidents', 'Booster Présidents', '3 cartes de présidents de la Ve République', 500, 3, 'politicians', 'president', null,
   '{"common":40,"uncommon":27,"rare":17,"epic":9,"legendary":5,"mythic":2}', 3),
  ('debats', 'Booster Débats', '3 cartes tirées des débats d''entre-deux-tours', 500, 3, 'politicians', null, 'débats',
   '{"common":40,"uncommon":27,"rare":17,"epic":9,"legendary":5,"mythic":2}', 4)
on conflict (slug) do nothing;

-- Les anciens boosters de citations fictives ne sont plus proposés
update public.booster_types set active = false where kind = 'quotes';
