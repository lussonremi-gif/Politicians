-- Quinze cartes de plus : d'autres personnalités, d'autres citations.
-- Chaque carte a sa propre photo (Wikimedia Commons, licence libre), choisie
-- pour coller au moment : le regard, le décor ou l'allure qu'on a envie de garder.
-- Les phrases sont des formules publiques, datées, déjà reprises par la presse
-- ou les archives (INA, Assemblée nationale, comptes rendus).

insert into public.parties (slug, name, short_name, color, sort_order) values
  ('lo',         'Lutte ouvrière',                  'LO',  '#e10600', 21),
  ('npa',        'Nouveau parti anticapitaliste',   'NPA', '#cc2200', 22),
  ('prg',        'Parti radical de gauche',         'PRG', '#e6b325', 23),
  ('resistons',  'Résistons !',                     'RES', '#2f6b4f', 24)
on conflict (slug) do nothing;

insert into public.politicians (slug, name, party_id, image_url, image_credit, image_license, image_source_url)
select v.slug, v.name, (select id from public.parties where slug = v.party),
       'https://commons.wikimedia.org/wiki/Special:FilePath/' || replace(v.file, ' ', '_') || '?width=480',
       v.credit, v.license,
       'https://commons.wikimedia.org/wiki/File:' || replace(v.file, ' ', '_')
from (values
  ('georges-clemenceau',    'Georges Clemenceau',     null,        'CLEMENCEAU, Georges, Nadar, GALLICA.jpg', 'Paul Nadar', 'CC0'),
  ('pierre-mendes-france',  'Pierre Mendès France',   null,        'Mendès-France Harcourt (1948).jpg', 'Studio Harcourt', 'Domaine public'),
  ('arlette-laguiller',     'Arlette Laguiller',      'lo',        'Arlette Laguiller.jpg', 'Lutte ouvrière', 'Domaine public'),
  ('christiane-taubira',    'Christiane Taubira',     'prg',       'Christiane Taubira par Claude Truong-Ngoc juin 2013.jpg', 'Claude Truong-Ngoc', 'CC BY-SA 4.0'),
  ('jean-pierre-raffarin',  'Jean-Pierre Raffarin',   'lr',        'Jean-Pierre Raffarin par Claude Truong-Ngoc 2013.jpg', 'Claude Truong-Ngoc', 'CC BY-SA 3.0'),
  ('francois-fillon',       'François Fillon',        'lr',        'François Fillon IMG 3362 (cropped).jpg', 'Rama', 'CC BY-SA 2.0 FR'),
  ('philippe-poutou',       'Philippe Poutou',        'npa',       'Philippe Poutou 2011 (cropped).jpg', 'Photothèque Rouge / JMB', 'CC BY'),
  ('jean-pierre-chevenement','Jean-Pierre Chevènement', null,      'Jean-Pierre Chevènement (5).JPG', 'Rémi Jouan', 'CC BY 4.0'),
  ('jean-lassalle',         'Jean Lassalle',          'resistons', 'Jean Lassalle 2017.jpg', 'Antoine Lamielle', 'CC BY-SA 4.0'),
  ('georges-marchais',      'Georges Marchais',       'pcf',       'Georges Marchais.JPG', 'David Boeno', 'CC BY-SA 3.0'),
  ('alain-juppe',           'Alain Juppé',            'lr',        'Alain Juppé-2016 (cropped).jpg', 'Etienne Ansotte / Union européenne', 'CC BY 4.0')
) as v(slug, name, party, file, credit, license)
on conflict (slug) do nothing;

-- Si la migration passe avant le seed, LR et PCF n'existent pas encore : on rattache dès qu'ils sont là.
update public.politicians p set party_id = (select id from public.parties where slug = v.party)
from (values
  ('arlette-laguiller', 'lo'),
  ('christiane-taubira', 'prg'),
  ('jean-pierre-raffarin', 'lr'),
  ('francois-fillon', 'lr'),
  ('philippe-poutou', 'npa'),
  ('jean-lassalle', 'resistons'),
  ('georges-marchais', 'pcf'),
  ('alain-juppe', 'lr')
) as v(slug, party)
where p.slug = v.slug and p.party_id is null
  and exists (select 1 from public.parties where slug = v.party);

update public.politicians p set role = v.role
from (values
  ('georges-clemenceau',     'Président du Conseil (1917-1920)'),
  ('pierre-mendes-france',   'Président du Conseil (1954-1955)'),
  ('arlette-laguiller',      'Porte-parole de Lutte ouvrière (1973-2008)'),
  ('christiane-taubira',     'Garde des Sceaux (2012-2016)'),
  ('jean-pierre-raffarin',   'Premier ministre (2002-2005)'),
  ('francois-fillon',        'Premier ministre (2007-2012)'),
  ('philippe-poutou',        'Candidat à la présidentielle (2012, 2017, 2022)'),
  ('jean-pierre-chevenement','Ministre à plusieurs reprises (1981-2000)'),
  ('jean-lassalle',          'Député des Pyrénées-Atlantiques (2002-2022)'),
  ('georges-marchais',       'Secrétaire général du PCF (1972-1994)'),
  ('alain-juppe',            'Premier ministre (1995-1997)'),
  ('edouard-philippe',       'Premier ministre (2017-2020)'),
  ('gabriel-attal',          'Premier ministre (2024)'),
  ('fabien-roussel',         'Secrétaire national du PCF')
) as v(slug, role)
where p.slug = v.slug and p.role is null;

insert into public.cards (
  politician_id, text, said_on, occasion, source_label, source_url, theme, rarity,
  decoy_politician_id, verified, image_url, image_credit, image_license, image_source_url
)
select (select id from public.politicians where slug = v.who),
       v.text, v.said_on::date, v.occasion, v.source_label, v.source_url, v.theme, v.rarity::public.card_rarity,
       (select id from public.politicians where slug = v.decoy), true,
       'https://commons.wikimedia.org/wiki/Special:FilePath/' || replace(v.file, ' ', '_') || '?width=640',
       v.credit, v.license,
       'https://commons.wikimedia.org/wiki/File:' || replace(v.file, ' ', '_')
from (values
  -- Mythique : le Tigre, regard planté
  ('georges-clemenceau',
   'Politique intérieure, je fais la guerre ; politique étrangère, je fais la guerre.',
   '1918-03-08', 'Discours à la Chambre des députés', 'Assemblée nationale',
   'https://www2.assemblee-nationale.fr/decouvrir-l-assemblee/histoire/grands-discours-parlementaires/georges-clemenceau-8-mars-1918',
   'discours', 'mythic', 'charles-de-gaulle',
   'Georges Clemenceau 1.jpg', 'Bain News Service', 'Domaine public'),

  -- Légendaires
  ('pierre-mendes-france',
   'Gouverner, c''est choisir.',
   '1953-06-03', 'Discours d''investiture à l''Assemblée nationale', 'Assemblée nationale',
   'https://www2.assemblee-nationale.fr/decouvrir-l-assemblee/histoire/grands-discours-parlementaires/pierre-mendes-france-3-juin-1953',
   'discours', 'legendary', 'charles-de-gaulle',
   'Pierre Mendès France 1968.jpg', 'Auteur inconnu (Nationaal Archief)', 'CC BY-SA 3.0 NL'),

  ('arlette-laguiller',
   'Travailleuses, travailleurs !',
   '1974-05-03', 'Campagne officielle du premier tour : « c''est à vous que je m''adresse particulièrement ce soir »', 'INA',
   'https://www.ina.fr/ina-eclaire-actu/video/i12044401/arlette-laguiller-travailleuses-travailleurs',
   'campagnes', 'legendary', 'philippe-poutou',
   'Arlette Laguiller.jpg', 'Lutte ouvrière', 'Domaine public'),

  ('christiane-taubira',
   'Parfois résister c''est rester, parfois résister c''est partir.',
   '2016-01-27', 'Message publié le matin de sa démission du gouvernement', 'franceinfo',
   'https://www.franceinfo.fr/politique/parfois-resister-c-est-partir-declare-christiane-taubira-sur-twitter-apres-sa-demission_1704123.html',
   'petites phrases', 'legendary', 'robert-badinter',
   'Christiane Taubira - Royal & Zapatero''s meeting in Toulouse for the 2007 French presidential election 0529 2007-04-19.jpg',
   'Guillaume Paumier', 'CC BY-SA 3.0'),

  ('jean-pierre-raffarin',
   'Notre route est droite, mais la pente est forte.',
   '2002-07-03', 'Déclaration de politique générale à l''Assemblée nationale', 'INA',
   'https://www.ina.fr/ina-eclaire-actu/video/i05139881/jean-pierre-raffarin-notre-route-est-droite-mais-la-pente-est-forte',
   'discours', 'legendary', 'jacques-chirac',
   'Jean-Pierre Raffarin par Claude Truong-Ngoc 2013.jpg', 'Claude Truong-Ngoc', 'CC BY-SA 3.0'),

  -- Épiques
  ('francois-fillon',
   'Qui imagine un seul instant le général de Gaulle mis en examen ?',
   '2016-08-28', 'Discours de rentrée à Sablé-sur-Sarthe, pendant la primaire de la droite', 'Le Figaro',
   'https://www.lefigaro.fr/politique/le-scan/2016/08/28/25001-20160828ARTFIG00105-la-charge-de-fillon-qui-imagine-de-gaulle-mis-en-examen.php',
   'campagnes', 'epic', 'nicolas-sarkozy',
   'François Fillon IMG 3362 (cropped).jpg', 'Rama', 'CC BY-SA 2.0 FR'),

  ('philippe-poutou',
   'Nous, quand on est convoqué par la police, nous n''avons pas d''immunité ouvrière, on y va.',
   '2017-04-04', 'Débat des onze candidats, sur BFMTV et CNews', 'BFMTV',
   'https://www.bfmtv.com/politique/elections/on-n-a-pas-d-immunite-ouvriere-la-charge-de-philippe-poutou-contre-marine-le-pen_AN-201704040099.html',
   'débats', 'epic', 'jean-luc-melenchon',
   'Philippe Poutou à la Marche contre la vie chère et l''inaction climatique.jpg', 'Rémi Simonnin', 'CC BY-SA 4.0'),

  ('jean-pierre-chevenement',
   'Un ministre, ça ferme sa gueule. Si ça veut l''ouvrir, ça démissionne.',
   '1983-03-22', 'Le jour de sa démission du gouvernement ; il a confirmé la formule en 1989', 'franceinfo',
   'https://www.radiofrance.fr/franceinfo/podcasts/histoires-d-info/un-ministre-ca-demissionne-ou-ca-ferme-sa-gueule-petite-histoire-d-une-petite-phrase-2068423',
   'petites phrases', 'epic', 'michel-rocard',
   'Jean-Pierre Chevènement (1).JPG', 'Rémi Jouan', 'CC BY-SA 3.0'),

  -- Rares
  ('jean-lassalle',
   'Je suis fils de berger, frère de berger et je l''ai été moi-même.',
   '2017-04-04', 'Débat des onze candidats, sur BFMTV et CNews', 'Les Echos',
   'https://www.lesechos.fr/2017/04/debat-qui-etes-vous-la-reponse-des-11-candidats-165138',
   'débats', 'rare', 'francois-bayrou',
   'Jean Lassalle 05.jpg', 'Antoine Lamielle', 'CC BY-SA 4.0'),

  ('georges-marchais',
   'Le bilan des pays socialistes est globalement positif.',
   '1979-05-13', 'Résolution du XXIIIe congrès du PCF, à Saint-Ouen, qu''il a portée', 'XXIIIe congrès du PCF',
   null,
   'discours', 'rare', 'francois-mitterrand',
   'Georges Marchais.JPG', 'David Boeno', 'CC BY-SA 3.0'),

  ('alain-juppe',
   'Je reste droit dans mes bottes et je ferai mon travail.',
   '1995-07-06', 'Journal de 20 heures de TF1, sur le loyer de son logement', 'INA',
   'https://www.ina.fr/ina-eclaire-actu/video/i09167777/alain-juppe-je-reste-droit-dans-mes-bottes-et-je-ferai-mon-travail',
   'petites phrases', 'rare', 'jacques-chirac',
   'Alain Juppé.jpg', 'Hien Le', 'CC BY 2.0'),

  ('fabien-roussel',
   'Un bon vin, une bonne viande, un bon fromage : c''est la gastronomie française.',
   '2022-01-11', 'Entretien sur France 3, pendant la campagne présidentielle', 'TF1',
   'https://www.tf1.fr/tmc/quotidien-avec-yann-barthes/videos/fabien-roussel-du-vin-du-fromage-de-la-viande-et-une-belle-polemique-65071309.html',
   'campagnes', 'rare', 'jean-luc-melenchon',
   'Fabien Roussel au 40e congrès du PCF à Lille.jpg', 'NakaraZn', 'CC0'),

  ('edouard-philippe',
   'Nous allons devoir vivre avec le virus.',
   '2020-04-28', 'Présentation du plan de déconfinement à l''Assemblée nationale', 'info.gouv.fr',
   'https://www.info.gouv.fr/discours/11518-discours-de-m-edouard-philippe-premier-ministre-presentation-de-la-strategie-nationale-de',
   'discours', 'rare', 'emmanuel-macron',
   'Édouard Philippe - 2021 (cropped).jpg', 'Jérémy Barande', 'CC BY-SA 2.0'),

  ('nicolas-sarkozy',
   'Travailler plus pour gagner plus.',
   '2007-06-29', 'Déplacement à Lyon : « Travaillez plus pour gagner plus, voilà la martingale gagnante »', 'Le Monde',
   'https://www.lemonde.fr/societe/article/2007/06/30/nicolas-sarkozy-assure-le-service-apres-vente-du-travailler-plus_930012_3224.html',
   'campagnes', 'rare', 'francois-fillon',
   'Nicolas Sarkozy (September 1, 2011).jpg', 'Antonis Samaras', 'CC BY-SA 2.0'),

  -- Commune : la carte « jeune génération »
  ('gabriel-attal',
   'L''école est la mère des batailles.',
   '2024-01-09', 'Sur le perron de Matignon, le jour de sa nomination ; reprise le 30 janvier à l''Assemblée', 'Vie publique',
   'https://www.vie-publique.fr/discours/292847-declaration-de-politique-generale-gabriel-attal-30012024',
   'discours', 'common', 'emmanuel-macron',
   'Gabriel Attal 2023 (cropped).jpg', 'DHS / gouvernement des États-Unis', 'Domaine public')
) as v(who, text, said_on, occasion, source_label, source_url, theme, rarity, decoy, file, credit, license)
where not exists (select 1 from public.cards c where c.text = v.text);

-- Les pièges éditoriaux, une fois que toutes les personnalités du seed existent.
update public.cards c set decoy_politician_id = (select id from public.politicians where slug = v.decoy)
from (values
  ('Politique intérieure, je fais la guerre ; politique étrangère, je fais la guerre.', 'charles-de-gaulle'),
  ('Gouverner, c''est choisir.', 'charles-de-gaulle'),
  ('Travailleuses, travailleurs !', 'philippe-poutou'),
  ('Parfois résister c''est rester, parfois résister c''est partir.', 'robert-badinter'),
  ('Notre route est droite, mais la pente est forte.', 'jacques-chirac'),
  ('Qui imagine un seul instant le général de Gaulle mis en examen ?', 'nicolas-sarkozy'),
  ('Nous, quand on est convoqué par la police, nous n''avons pas d''immunité ouvrière, on y va.', 'jean-luc-melenchon'),
  ('Un ministre, ça ferme sa gueule. Si ça veut l''ouvrir, ça démissionne.', 'michel-rocard'),
  ('Je suis fils de berger, frère de berger et je l''ai été moi-même.', 'francois-bayrou'),
  ('Le bilan des pays socialistes est globalement positif.', 'francois-mitterrand'),
  ('Je reste droit dans mes bottes et je ferai mon travail.', 'jacques-chirac'),
  ('Un bon vin, une bonne viande, un bon fromage : c''est la gastronomie française.', 'jean-luc-melenchon'),
  ('Nous allons devoir vivre avec le virus.', 'emmanuel-macron'),
  ('Travailler plus pour gagner plus.', 'francois-fillon'),
  ('L''école est la mère des batailles.', 'emmanuel-macron')
) as v(text, decoy)
where c.text = v.text and c.decoy_politician_id is null;

insert into public.booster_types (slug, name, description, price, card_count, kind, party_id, weights, sort_order)
select 'parti-' || slug, 'Booster ' || short_name, '3 cartes · ' || name, 400, 3, 'politicians', id,
       '{"common":72,"rare":15,"epic":8,"legendary":4,"mythic":1}', 20 + sort_order
from public.parties
where slug in ('lo', 'npa', 'prg', 'resistons')
on conflict (slug) do nothing;

-- Anciennes cartes : une photo par citation quand la même personne en a plusieurs.
-- (Macron en avait déjà une par phrase.)
update public.cards c set
  image_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/' || replace(v.file, ' ', '_') || '?width=640',
  image_credit = v.credit,
  image_license = v.license,
  image_source_url = 'https://commons.wikimedia.org/wiki/File:' || replace(v.file, ' ', '_')
from (values
  ('Je vous ai compris !', 'Photo PLM+CDG 1.jpg', 'Auteur inconnu', 'CC0'),
  ('Paris outragé ! Paris brisé ! Paris martyrisé ! Mais Paris libéré !', 'De Gaulle-OWI (3x4 cropped).jpg', 'Office of War Information', 'Domaine public'),
  ('Vive le Québec libre !', 'Charles de Gaulle-1963.jpg', 'Ludwig Wegmann (Bundesarchiv)', 'CC BY-SA 3.0 DE'),
  ('Vous n''avez pas, monsieur Mitterrand, le monopole du cœur.', 'Valéry Giscard d''Estaing, energy crisis summit at Elysée, 1974.jpg', 'Christian Lambiotte / Commission européenne', 'CC BY 4.0'),
  ('Au revoir.', 'Valéry Giscard d''Estaing 1981 (1).jpg', 'Rob Croes / Anefo', 'CC0'),
  ('La République, c''est moi !', 'Jean-Luc Mélenchon 2017.jpg', 'MathieuMD', 'CC BY-SA 4.0'),
  ('Ma personne est sacrée !', 'Jean-Luc Mélenchon (Place au Peuple) 001 (redécoupé).jpg', 'Place au Peuple', 'CC BY-SA 2.0'),
  ('Casse-toi alors, pauvre con !', 'Nicolas Sarkozy (2008).jpg', 'Aleph', 'CC BY-SA 2.5'),
  ('Dès demain, on va nettoyer au Kärcher la cité.', 'Nicolas Sarkozy, French Minister of the Interior - 2003.jpg', 'Christian Lambiotte / Commission européenne', 'CC BY 4.0'),
  ('Désormais, quand il y a une grève en France, personne ne s''en aperçoit.', 'Nicolas Sarkozy, 2007.jpg', 'Jean-Louis Aubert', 'CC BY-SA 2.0'),
  ('Moi, président de la République, je ne serai pas le chef de la majorité.', 'François Hollande (1).JPG', 'Rémi Jouan', 'CC BY-SA 3.0'),
  ('Mon véritable adversaire, il n''a pas de nom, pas de visage, pas de parti. […] Cet adversaire, c''est le monde de la finance.', 'François Hollande (2007).jpg', 'Guillaume Paumier', 'CC BY-SA 2.5'),
  ('Mais vous avez tout à fait raison, monsieur le Premier ministre.', 'François Mitterrand, 1984.jpg', 'Gino Zamboni / Commission européenne', 'CC BY 4.0'),
  ('Je crois aux forces de l''esprit et je ne vous quitterai pas.', 'François Mitterrand, Strasbourg, dec. 1989, 1.jpg', 'Christian Lambiotte / Commission européenne', 'CC BY 4.0'),
  ('Notre maison brûle et nous regardons ailleurs.', 'Jacques Chirac, 1999.jpg', 'David Scull', 'Domaine public'),
  ('Aujourd''hui, on rapporte une histoire abracadabrantesque.', 'Jacques Chirac1.jpg', 'Roland Godefroy', 'CC BY 3.0'),
  ('J''assume pleinement la responsabilité de cet échec et j''en tire les conclusions, en me retirant de la vie politique après la fin de l''élection présidentielle.', 'Lionel Jospin, mai 2014, Rennes, France (cropped).jpg', 'Édouard Hue', 'CC BY-SA 4.0'),
  ('Je suis socialiste d''inspiration, mais le projet que je propose au pays n''est pas un projet socialiste.', 'Lionel Jospin, le 30 septembre 1997.jpg', 'Moulins58', 'CC BY-SA 3.0')
) as v(text, file, credit, license)
where c.text = v.text;

update public.booster_types b set active = exists (
  select 1 from public.cards c join public.politicians p on p.id = c.politician_id
   where p.party_id = b.party_id and c.verified)
 where b.party_id is not null;
