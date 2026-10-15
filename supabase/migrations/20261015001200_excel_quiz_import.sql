-- « Qui l'a dit ? » : import de la base « Quiz citations candidats 2027 » (Excel du 15 octobre 2026)
--
-- - Cartes à collectionner : uniquement des personnalités politiques (candidats 2027 et anciens
--   responsables), citations de fiabilité « Solide » seulement, avec leur source.
-- - Pièges du quiz : répliques de films, de livres et phrases de célébrités. Elles servent de questions
--   (« un politique ou pas ? ») mais ne donnent jamais de carte : cards.collectible = false.
-- - Les 20 paires thématiques de l'Excel deviennent des pièges choisis (decoy_politician_id).
-- - Les citations déjà en base, le roman de Bruno Le Maire et les auteurs collectifs sont écartés.

alter table public.cards add column if not exists collectible boolean not null default true;

insert into public.parties (slug, name, short_name, color, sort_order) values
  ('dlf',              'Debout la France',     'DLF', '#0d378a', 30),
  ('patriotes',        'Les Patriotes',        'LP',  '#1d3b8b', 31),
  ('nouvelle-energie', 'Nouvelle Énergie',     'NE',  '#00a3e0', 32),
  ('lapres',           'L''Après',             'APR', '#c9462c', 33),
  ('debout',           'Debout !',             'DEB', '#e4572e', 34),
  ('france-humaniste', 'La France humaniste',  'FH',  '#5b6ee1', 35)
on conflict (slug) do nothing;

-- Nouvelles personnalités politiques (photo Wikimedia Commons, licence libre)
insert into public.politicians (slug, name, party_id, role, kind, image_url, image_credit, image_license, image_source_url)
select v.slug, v.name, (select id from public.parties where slug = v.party), v.role, 'politician',
       'https://commons.wikimedia.org/wiki/Special:FilePath/' || replace(v.file, ' ', '_') || '?width=480',
       v.credit, v.license, 'https://commons.wikimedia.org/wiki/File:' || replace(v.file, ' ', '_')
from (values
  ('bruno-le-maire', 'Bruno Le Maire', null, 'Ministre de l''Économie (2017-2024)', 'Bruno le maire (2300963920).jpg', 'Bruno Le Maire (Flickr)', 'CC BY 2.0'),
  ('clementine-autain', 'Clémentine Autain', 'lapres', 'Députée de Seine-Saint-Denis', 'Clementine-Autain.jpg', 'Io', 'CC BY-SA 4.0'),
  ('david-lisnard', 'David Lisnard', 'nouvelle-energie', 'Maire de Cannes', 'David Lisnard - 2013.jpg', 'Frantogian', 'CC BY-SA 3.0'),
  ('florian-philippot', 'Florian Philippot', 'patriotes', 'Président des Patriotes', 'Florian Philippot.jpg', 'Wikimedia Commons', 'CC BY 4.0'),
  ('francois-ruffin', 'François Ruffin', 'debout', 'Député de la Somme', 'François Ruffin.jpg', 'Thinkerview', 'CC BY-SA 4.0'),
  ('jerome-guedj', 'Jérôme Guedj', 'ps', 'Député de l''Essonne', 'Jérôme Guedj 2010.jpg', 'Audrey AK', 'CC BY-SA 2.0'),
  ('nathalie-arthaud', 'Nathalie Arthaud', 'lo', 'Porte-parole de Lutte ouvrière', 'Nathalie Arthaud 2012.jpg', 'Nicolas Richoffer', 'CC BY-SA 4.0'),
  ('nicolas-dupont-aignan', 'Nicolas Dupont-Aignan', 'dlf', 'Président de Debout la France', 'Nicolas Dupont-Aignan, homme politique français (cropped).jpg', 'Debout la France', 'CC BY-SA 4.0'),
  ('olivier-faure', 'Olivier Faure', 'ps', 'Premier secrétaire du PS', 'Portrait d''Olivier Faure.jpg', 'Wikimedia Commons', 'CC BY-SA 2.0'),
  ('edgar-faure', 'Edgar Faure', null, 'Président du Conseil (1952, 1955-1956)', 'Edgar Faure 1955.jpg', 'Wikimedia Commons', 'Wikimedia Commons')
) as v(slug, name, party, role, file, credit, license)
on conflict (slug) do nothing;

-- Villepin : sa formation pour 2027
update public.politicians set party_id = (select id from public.parties where slug = 'france-humaniste')
 where slug = 'dominique-de-villepin' and party_id is null;

-- Personnalités hors politique (pièges uniquement)
insert into public.politicians (slug, name, role, kind, image_url, image_credit, image_license, image_source_url)
select v.slug, v.name, v.role, 'personality',
       'https://commons.wikimedia.org/wiki/Special:FilePath/' || replace(v.file, ' ', '_') || '?width=480',
       v.credit, v.license, 'https://commons.wikimedia.org/wiki/File:' || replace(v.file, ' ', '_')
from (values
  ('jean-claude-van-damme', 'Jean-Claude Van Damme', 'Acteur', 'Jean-Claude Van Damme 2012.jpg', 'Georges Biard', 'CC BY-SA 3.0'),
  ('eric-cantona', 'Éric Cantona', 'Footballeur et acteur', 'Eric Cantona Cannes 2009.jpg', 'Georges Biard', 'CC BY-SA 3.0'),
  ('raymond-domenech', 'Raymond Domenech', 'Sélectionneur des Bleus (2004-2010)', 'Raymond Domenech.jpg', 'Wikimedia Commons', 'Wikimedia Commons'),
  ('bernard-tapie', 'Bernard Tapie', 'Homme d''affaires', 'Bernard Tapie 2012.JPG', 'JJ Georges', 'CC BY-SA 3.0'),
  ('gerard-depardieu', 'Gérard Depardieu', 'Acteur', 'Gérard Depardieu Cannes 2010.jpg', 'Georges Biard', 'CC BY-SA 3.0'),
  ('zlatan-ibrahimovic', 'Zlatan Ibrahimović', 'Footballeur', 'Zlatan Ibrahimovic.jpg', 'Pascal Kirchmair', 'CC BY-SA 3.0'),
  ('kylian-mbappe', 'Kylian Mbappé', 'Footballeur', 'Kylian Mbappé.jpg', 'Wikimedia Commons', 'CC BY-SA 3.0'),
  ('johnny-hallyday', 'Johnny Hallyday', 'Chanteur', 'Johnny Hallyday en 2009 à Bruxelles.jpg', 'Michaël Bemelmans', 'CC BY-SA 4.0'),
  ('gims', 'Gims', 'Chanteur', 'Maître Gims Cannes 2016.jpg', 'Georges Biard', 'CC BY-SA 3.0'),
  ('coluche', 'Coluche', 'Humoriste (candidat en 1980)', 'Coluche (cropped).jpg', 'Martino75', 'CC BY-SA 3.0')
) as v(slug, name, role, file, credit, license)
on conflict (slug) do nothing;

-- Personnages de fiction : pas de photo (droits des films), l'œuvre sert de description
insert into public.politicians (slug, name, role, kind) values
  ('fiction-georges-abitbol', 'Georges Abitbol', 'La Classe américaine (1993)', 'personality'),
  ('fiction-godefroy-de-montmirail', 'Godefroy de Montmirail', 'Les Visiteurs (1993)', 'personality'),
  ('fiction-hubert-bonisseur-de-la-bath-oss-117', 'Hubert Bonisseur de La Bath (OSS 117)', 'OSS 117 : Le Caire, nid d''espions (2006)', 'personality'),
  ('fiction-hubert-voix-off', 'Hubert (voix off)', 'La Haine (1995)', 'personality'),
  ('fiction-jean-claude-dusse', 'Jean-Claude Dusse', 'Les Bronzés font du ski (1979)', 'personality'),
  ('fiction-le-glaude-ou-le-bombe', 'Le Glaude ou Le Bombé', 'La Soupe aux choux (1981)', 'personality'),
  ('fiction-le-roi-premier-asteroide', 'Le roi (premier astéroïde)', 'Le Petit Prince, Saint-Exupéry (1943)', 'personality'),
  ('fiction-monsieur-jourdain', 'Monsieur Jourdain', 'Le Bourgeois gentilhomme, Molière (1670)', 'personality'),
  ('fiction-otis-le-scribe', 'Otis (le scribe)', 'Astérix et Obélix : Mission Cléopâtre (2002)', 'personality'),
  ('fiction-patrick-chirac', 'Patrick Chirac', 'Camping (2006)', 'personality'),
  ('fiction-pere-ubu', 'Père Ubu', 'Ubu roi, Alfred Jarry (1896)', 'personality'),
  ('fiction-tartuffe', 'Tartuffe', 'Le Tartuffe, Molière (1669)', 'personality'),
  ('fiction-un-truand', 'Un truand', 'Les Tontons flingueurs (1963)', 'personality'),
  ('fiction-v', 'V', 'V pour Vendetta (2005, VF)', 'personality')
on conflict (slug) do nothing;

-- Citations
insert into public.cards (politician_id, text, said_on, occasion, source_label, source_url, theme, rarity,
                          decoy_politician_id, collectible, verified)
select (select id from public.politicians where slug = v.who), v.text, v.said_on::date, v.occasion,
       v.source_label, v.source_url, v.theme, v.rarity::public.card_rarity,
       (select id from public.politicians where slug = v.decoy), v.collectible, true
from (values
  -- C001
  ('marine-le-pen', 'Je ne suis absolument pas climatosceptique, mais vous, vous êtes un peu climato-hypocrite', '2022-04-20', 'Débat d''entre-deux-tours face à Macron', 'Public Sénat', 'https://www.publicsenat.fr/actualites/politique/debat-macron-le-pen-climatosceptique-vs-climato-hypocrite-203286', 'candidats 2027', 'epic', null, true),
  -- C003
  ('marine-le-pen', 'Je suis la candidate du pouvoir d''achat, vous êtes le candidat du pouvoir d''acheter', '2017-05-03', 'Débat d''entre-deux-tours 2017', 'Public Sénat', 'https://www.publicsenat.fr/actualites/politique/debat-presidentiel-les-10-phrases-marquantes-60057', 'candidats 2027', 'rare', null, true),
  -- C004
  ('marine-le-pen', 'Il y aura tous mes chats et ils prennent de la place.', '2022-03-16', 'Face à Baba (C8) : l''Élysée serait-il trop grand pour une femme seule ?', 'La DH', 'https://www.dhnet.be/lifestyle/people/marine-le-pen-en-couple-elle-repond-sans-detour-dans-face-a-baba-623311239978e25398412b60', 'candidats 2027', 'rare', 'fiction-patrick-chirac', true),
  -- C006
  ('jordan-bardella', 'Et moi je sais ce qui arrive lorsque Kylian Mbappé quitte le PSG : le club gagne la Ligue des Champions !', '2026-05-12', 'Post sur X en réponse à Mbappé', 'Europe 1', 'https://www.europe1.fr/politique/kylian-mbappe-quitte-le-psg-le-club-gagne-la-ligue-des-champions-jordan-bardella-repond-a-la-star-des-bleus-apres-ses-critiques-du-rn-934142', 'candidats 2027', 'rare', null, true),
  -- C007
  ('jordan-bardella', 'Où est-ce qu''il trouve toute cette énergie ?', null, 'Quelle époque ! (France 2), devant un portrait de Trump ; séquence virale (12/2025)', 'Puremédias', 'https://www.ozap.com/actu/je-lai-atomise-roselyne-bachelot-reagit-a-sa-sequence-virale-avec-jordan-bardella-dans-quelle-epoque-sur-france-2/653011', 'candidats 2027', 'common', null, true),
  -- C010
  ('jordan-bardella', 'Ce livre n''est ni un essai, ni un programme : il est le reflet de mon existence.', '2024-11-09', 'Autobiographie « Ce que je cherche », écrite à 29 ans', 'Europe 1 (AFP)', 'https://www.europe1.fr/node/19185', 'candidats 2027', 'rare', 'fiction-v', true),
  -- C011
  ('eric-zemmour', 'Ça ne rigole plus, là ? Poussez-vous ! Reculez !', '2021-10-20', 'Salon Milipol : pointe un fusil vers des journalistes, puis rit', 'La DH', 'https://www.dhnet.be/actu/monde/2021/10/20/quand-eric-zemmour-samuse-a-tirer-sur-la-presse-les-images-polemiques-WLLMBTSDVVHHNJTMSF7YV2CGZI/', 'candidats 2027', 'epic', null, true),
  -- C015
  ('eric-zemmour', 'C''était une interview d''un procureur.', '2021-11-30', 'En sortant du 20h de TF1', 'Europe 1', 'https://www.europe1.fr/politique/zemmour-au-20h-une-attitude-denfant-gate-4080128', 'candidats 2027', 'common', null, true),
  -- C016
  ('bruno-retailleau', 'J''ai trois priorités : rétablir l''ordre, la seconde rétablir l''ordre, la troisième rétablir l''ordre', '2024-09-23', 'Passation de pouvoir place Beauvau', 'Public Sénat', 'https://www.publicsenat.fr/actualites/politique/bruno-retailleau-nouveau-ministre-de-linterieur-promet-le-retablissement-de-lordre-et-la-fermete', 'candidats 2027', 'epic', 'jacques-chirac', true),
  -- C018
  ('bruno-retailleau', 'J''irai jusqu''au bout, et je mettrai mes tripes, mon cœur sur la table', '2026-06-20', 'Premier grand meeting de campagne, parc Floral', 'Public Sénat', 'https://www.publicsenat.fr/actualites/politique/presidentielle-jirai-jusquau-bout-de-lelection-pour-remettre-la-france-a-lendroit-clame-bruno-retailleau-a-son-premier-grand-meeting', 'candidats 2027', 'common', null, true),
  -- C019
  ('bruno-retailleau', 'Je ne prétendrai jamais à être Jupiter.', '2026-06-20', 'Même meeting, pique contre la présidence « jupitérienne »', 'Public Sénat', 'https://www.publicsenat.fr/actualites/politique/presidentielle-jirai-jusquau-bout-de-lelection-pour-remettre-la-france-a-lendroit-clame-bruno-retailleau-a-son-premier-grand-meeting', 'candidats 2027', 'rare', null, true),
  -- C020
  ('david-lisnard', 'Il faut savoir se faire désirer dans la vie.', '2026-10-13', 'RMC/BFMTV : arrive en retard pour la 2e fois chez Apolline de Malherbe', 'Puremédias', 'https://www.ozap.com/actu/cest-la-2e-fois-que-vous-me-faites-le-coup-apolline-de-malherbe-epingle-david-lisnard-arrive-en-retard-a-leur-interview-sur-rmc-et-bfmtv/657433', 'candidats 2027', 'common', null, true),
  -- C021
  ('david-lisnard', 'Il n''y aura pas de Notre-Dame du carburant.', '2026-04-29', 'Sud Radio, sur la crise des carburants', 'Sud Radio', 'https://www.sudradio.fr/linvite-politique/david-lisnard-il-faut-rompre-avec-la-dysfonction-publique', 'candidats 2027', 'common', null, true),
  -- C022
  ('david-lisnard', 'Il n''y a pas de solution miracle, parce que les miracles, c''est quand même rare dans l''histoire.', '2026-04-29', 'Même interview', 'Sud Radio', 'https://www.sudradio.fr/linvite-politique/david-lisnard-il-faut-rompre-avec-la-dysfonction-publique', 'candidats 2027', 'rare', 'jean-pierre-raffarin', true),
  -- C023
  ('david-lisnard', 'Il faut un seul candidat de droite. Il faut arrêter le en même temps !', '2025-04-02', 'Sud Radio, sur 2027 (avant de se déclarer lui-même)', 'Sud Radio', 'https://www.sudradio.fr/linvite-politique/le-rn-a-un-projet-socialiste-affirme-david-lisnard', 'candidats 2027', 'common', null, true),
  -- C024
  ('nicolas-dupont-aignan', 'Quelqu''un peut aller à côté ? Y a un bruit à côté...', '2012-04-12', 'Conférence de presse perturbée par les ébats bruyants des voisins', 'Puremédias', 'https://www.ozap.com/actu/pendant-une-conference-de-presse-de-nicolas-dupont-aignan-ses-voisins-font-l-amour/440385', 'candidats 2027', 'rare', null, true),
  -- C025
  ('nicolas-dupont-aignan', 'Je donne 2 jours à la chaîne TF1 pour inviter tous les candidats et pour permettre aux Français de trancher.', '2017-03-18', 'Quitte en direct le JT de TF1', 'Puremédias', 'https://www.ozap.com/actu/nicolas-dupont-aignan-quitte-brusquement-le-20-heures-de-tf1/522029', 'candidats 2027', 'common', 'fiction-un-truand', true),
  -- C026
  ('nicolas-dupont-aignan', 'Le général De Gaulle s''était adapté aux moyens de l''époque.', '2017-03-23', 'Justifie son passage chez Hanouna en le comparant à l''appel du 18 juin', 'Puremédias', 'https://www.ozap.com/actu/gilles-bornstein-a-nicolas-dupont-aignan-comparer-l-appel-du-18-juin-a-tpmp-c-est-gonfle/522399', 'candidats 2027', 'common', null, true),
  -- C027
  ('nicolas-dupont-aignan', 'Je suis très cinéma.', '2017-04-11', 'BuzzFeed News, sur ses goûts culturels', 'BuzzFeed News', 'https://www.buzzfeed.com/fr/davidperrotin/nicolas-dupont-aignan-a-buzzfeed-demain-ce-sera-le-pen', 'candidats 2027', 'common', null, true),
  -- C028
  ('florian-philippot', 'On m''a dit que j''étais vice-président à rien...', '2017-09-21', 'France 2, annonce son départ du FN', 'Sud Radio', 'https://www.sudradio.fr/politique/collard-philippot-ne-confondez-pas-un-coup-de-petard-avec-un-coup-de-tonnerre', 'candidats 2027', 'rare', null, true),
  -- C029
  ('florian-philippot', 'Quand nous ferons notre propre Frexit, nous aurons de l''expérience.', '2019-10-31', 'Sud Radio, sur les reports du Brexit', 'Sud Radio', 'https://www.sudradio.fr/societe/florian-philippot-quand-nous-ferons-le-frexit-nous-aurons-de-lexperience', 'candidats 2027', 'common', null, true),
  -- C030
  ('florian-philippot', 'Je veux détruire l''UE avant qu''elle nous détruise', '2024-06-04', 'Public Sénat, campagne des européennes', 'Public Sénat', 'https://www.publicsenat.fr/actualites/politique/europeennes-je-veux-detruire-lue-avant-quelle-nous-detruise-explique-florian-philippot-les-patriotes', 'candidats 2027', 'rare', null, true),
  -- C031
  ('florian-philippot', 'Ah non, je vous trouve plus drôle qu''avant, pour le coup', '2016-09-13', 'Le Petit Journal (Canal+), à Cyrille Eldin', 'Puremédias', 'https://www.ozap.com/actu/florian-philippot-prefere-le-petit-journal-de-cyrille-eldin-a-celui-de-yann-barthes/507126', 'candidats 2027', 'common', null, true),
  -- C032
  ('edouard-philippe', 'Si vous pensez qu''il faut être un playboy en France pour être élu, j''ai quand même quelques contre-exemples…', '2023-03-27', 'Sur Quotidien (TMC), interrogé sur sa transformation physique et 2027', 'Tendance Ouest', 'https://www.tendanceouest.com/actualite-414558-le-havre-si-vous-pensez-qu-il-faut-etre-un-playboy-pour-etre-elu-edouard-philippe-remporte-le-prix-de-l-humour-politique', 'candidats 2027', 'rare', 'jacques-chirac', true),
  -- C033
  ('edouard-philippe', 'Bon, je vais pas le masquer, je vais pas me mettre une perruque !', '2023-03-27', 'Quotidien, sur sa perte de cheveux et de barbe', 'Europe 1', 'https://www.europe1.fr/emissions/telescopages/interview-dedouard-philippe-dans-quotidien-la-politique-ne-tient-parfois-qua-un-cheveux-4174762', 'candidats 2027', 'common', null, true),
  -- C034
  ('edouard-philippe', 'Si vous trouvez que ça me fait une sale gueule et bah j''y peux rien.', '2023-03-27', 'Quotidien, sur les réactions à son nouveau physique', 'Europe 1', 'https://www.europe1.fr/emissions/telescopages/interview-dedouard-philippe-dans-quotidien-la-politique-ne-tient-parfois-qua-un-cheveux-4174762', 'candidats 2027', 'common', null, true),
  -- C035
  ('edouard-philippe', 'Non, seulement les emmerdes', null, 'Réponse à un journaliste demandant si tout « remonte à Matignon » (Été 2018)', 'Puremédias', 'https://www.ozap.com/actu/edouard-philippe-remporte-le-prix-de-l-humour-politique-grace-a-ses-emmerdes/577205', 'candidats 2027', 'common', null, true),
  -- C036
  ('edouard-philippe', 'Je vous suis de près monsieur Lenglet. Vous êtes mon avenir en la matière', '2017-09-28', 'L''Émission politique (France 2), vanne sur la calvitie du journaliste', 'Puremédias', 'https://www.ozap.com/actu/echange-improbable-entre-edouard-philippe-et-francois-lenglet-sur-leur-coupe-de-cheveux/538037', 'candidats 2027', 'common', null, true),
  -- C039
  ('gabriel-attal', '[…] le plus jeune président de la République de l''histoire nomme le plus jeune Premier ministre de l''histoire', '2024-01-09', 'Passation de pouvoirs à Matignon', 'info.gouv.fr', 'https://www.info.gouv.fr/actualite/passation-de-pouvoirs-entre-elisabeth-borne-et-gabriel-attal', 'candidats 2027', 'rare', null, true),
  -- C040
  ('gabriel-attal', '[…] elle rime avec sursaut, elle rime avec audace, elle rime avec grandeur.', '2024-01-09', 'Passation de pouvoirs, sur la France', 'info.gouv.fr', 'https://www.info.gouv.fr/actualite/passation-de-pouvoirs-entre-elisabeth-borne-et-gabriel-attal', 'candidats 2027', 'common', 'fiction-otis-le-scribe', true),
  -- C041
  ('gabriel-attal', 'Tu casses, tu répares ; tu salis, tu nettoies ; tu défies l''autorité, on t''apprend à la respecter.', '2024-01-30', 'Déclaration de politique générale, délinquance des mineurs', 'LCP', 'https://lcp.fr/actualites/justice-des-mineurs-l-assemblee-a-commence-a-debattre-de-la-proposition-de-loi-de', 'candidats 2027', 'epic', null, true),
  -- C042
  ('gabriel-attal', 'Déverrouiller, désmicardiser, débureaucratiser. Oui, mais dans un seul objectif: réarmer notre pays', '2024-01-30', 'Déclaration de politique générale', 'LCP', 'https://lcp.fr/index%2Ephp/actualites/desmicardiser-debureaucratiser-deverrouiller-les-principales-annonces-de-gabriel-attal-a', 'candidats 2027', 'common', null, true),
  -- C043
  ('gabriel-attal', 'On ne vient pas sans prévenir, on paye', '2024-01-30', 'Annonce de la « taxe lapin » pour les rendez-vous médicaux manqués', 'LCP', 'https://lcp.fr/index%2Ephp/actualites/desmicardiser-debureaucratiser-deverrouiller-les-principales-annonces-de-gabriel-attal-a', 'candidats 2027', 'common', 'fiction-pere-ubu', true),
  -- C044
  ('gabriel-attal', 'La République contre-attaque', '2024-04-18', 'Discours de Viry-Châtillon sur la violence des jeunes', 'Les Nouvelles Calédoniennes (AFP)', 'https://www.lnc.nc/article/france/politique/attal-sonne-la-mobilisation-generale-contre-la-violence-des-jeunes-et-defend-son-bilan', 'candidats 2027', 'epic', 'fiction-godefroy-de-montmirail', true),
  -- C045
  ('gabriel-attal', 'Je ne rate aucun épisode de ''Koh-Lanta'' et je rêve depuis tout petit de participer à ''Fort Boyard''', '2018-08-02', 'Interview de l''été de Paris Match, alors député', 'Puremédias', 'https://www.ozap.com/actu/-fort-boyard-gabriel-attal-la-republique-en-marche-reve-de-participer-a-l-emission/564184', 'candidats 2027', 'common', 'raymond-domenech', true),
  -- C051
  ('bruno-le-maire', 'Nous allons provoquer l''effondrement de l''économie russe', '2022-03-01', 'France Info, sanctions après l''invasion de l''Ukraine', 'Public Sénat', 'https://www.publicsenat.fr/article/politique/guerre-economique-totale-les-senateurs-appellent-bruno-le-maire-a-changer-de-ton', 'candidats 2027', 'epic', null, true),
  -- C052
  ('bruno-le-maire', 'Quand je vois que je suis le problème, j''appelle le Premier ministre et je lui dis : ''Je me casse, pas de problème''', '2025-10-07', 'Interview Brut, renoncement au ministère des Armées', 'Public Sénat', 'https://www.publicsenat.fr/actualites/politique/gouvernement-lecornu-quand-je-vois-que-je-suis-le-probleme-je-me-casse-explique-bruno-le-maire', 'candidats 2027', 'common', null, true),
  -- C053
  ('bruno-le-maire', 'C''est quoi ce délit de sale gueule ?', '2025-10-07', 'Interview Brut, sur les attaques qu''il a subies', 'Public Sénat', 'https://www.publicsenat.fr/actualites/politique/gouvernement-lecornu-quand-je-vois-que-je-suis-le-probleme-je-me-casse-explique-bruno-le-maire', 'candidats 2027', 'common', null, true),
  -- C054
  ('bruno-le-maire', 'La France ne risque pas la mort subite, la France risque la mort lente', '2024-12-12', 'Audition à l''Assemblée sur le dérapage du déficit', 'LCP', 'https://lcp.fr/actualites/commission-d-enquete-sur-le-deficit-public-en-sept-jours-avec-la-censure-vous-avez-fait', 'candidats 2027', 'rare', 'fiction-hubert-voix-off', true),
  -- C055
  ('bruno-le-maire', 'Cette Assemblée taxe, dépense, censure.', '2024-12-12', 'Même audition, contre les députés', 'LCP', 'https://lcp.fr/actualites/commission-d-enquete-sur-le-deficit-public-en-sept-jours-avec-la-censure-vous-avez-fait', 'candidats 2027', 'rare', null, true),
  -- C056
  ('bruno-le-maire', '[…] à aucune seconde, à aucun instant, à aucun moment, je n''envisage la défaite, jamais.', '2016-03-01', 'Sud Radio, primaire de la droite (il finira à ~2,4 %)', 'Sud Radio', 'https://www.sudradio.fr/politique/bruno-le-maire-a-aucun-moment-je-nenvisage-la-defaite', 'candidats 2027', 'rare', 'fiction-jean-claude-dusse', true),
  -- C058
  ('dominique-de-villepin', 'Dans ce temple des Nations unies, nous sommes les gardiens d''un idéal, nous sommes les gardiens d''une conscience', '2003-02-14', 'Même discours à l''ONU', 'Le Courrier de l''Atlas', 'https://www.lecourrierdelatlas.com/dominique-de-villepin-et-le-monde-arabe-ce-quil-faut-savoir/', 'candidats 2027', 'epic', null, true),
  -- C059
  ('dominique-de-villepin', 'Le loup a pris beaucoup de coups, il fait peur.', '2025-12-17', 'RTL : il se compare au loup de la pub de Noël d''Intermarché', 'Brut', 'https://www.brut.media/fr/articles/presidentielle-dominique-de-villepin-affirme-avoir-toute-son-energie-tendue-vers-2027', 'candidats 2027', 'common', null, true),
  -- C060
  ('dominique-de-villepin', 'Le plus grand risque que nous prendrions, c''est de baisser les bras et d''avoir peur. La peur, ça se renifle.', '2026-01-19', 'Lundi C''est Politique (LCP), sur Trump et le Groenland', 'LCP', 'https://lcp.fr/actualites/dominique-de-villepin-nous-voulons-etre-presents-en-2027-429413', 'candidats 2027', 'common', 'eric-cantona', true),
  -- C061
  ('dominique-de-villepin', 'Je mesure 1,91 m, donc je ne rentre dans aucune case.', null, 'Réponse à « êtes-vous de gauche ou de droite ? » (2025 (non daté))', 'Le Courrier de l''Atlas', 'https://www.lecourrierdelatlas.com/dominique-de-villepin-et-le-monde-arabe-ce-quil-faut-savoir/', 'candidats 2027', 'common', null, true),
  -- C062
  ('dominique-de-villepin', 'Vous avez une certaine intuition, monsieur Ardisson', '2011-01-08', 'Salut les Terriens (Canal+), esquive sur une candidature en 2012', 'Puremédias', 'https://www.ozap.com/actu/candidature-villepin-presidentielle-intuition-thierry-ardisson/389560', 'candidats 2027', 'common', null, true),
  -- C066
  ('jean-luc-melenchon', 'Est-ce que quelqu''un peut me poser une question en français et à peu près compréhensible ?', '2018-10-17', 'Se moque de l''accent toulousain d''une journaliste', 'Public Sénat', 'https://www.publicsenat.fr/actualites/politique/face-a-melenchon-des-elus-prennent-la-defense-de-l-accent-du-sud-134569', 'candidats 2027', 'legendary', null, true),
  -- C067
  ('jean-luc-melenchon', 'Où je suis ? À Lyon et maintenant … à Paris !', '2017-02-05', 'Meeting en hologramme, à Lyon et projeté à Aubervilliers', 'Politis', 'https://www.politis.fr/articles/2017/02/melenchon-il-est-venu-le-temps-des-hologrammes-36252', 'candidats 2027', 'common', null, true),
  -- C068
  ('jean-luc-melenchon', 'Je veux parler du titre du Parisien, petite cervelle, pas de la prostitution', null, 'Répond à un étudiant en journalisme (04/2010)', 'Puremédias', 'https://www.ozap.com/actu/jean-luc-melenchon-coups-gueule-clash-video-television-politique-best/402168', 'candidats 2027', 'rare', null, true),
  -- C069
  ('jean-luc-melenchon', 'Il n''y a pas de pages à colorier dans mon livre', null, 'En meeting, pique contre Laurence Ferrari (2011)', 'Puremédias', 'https://www.ozap.com/actu/jean-luc-melenchon-coups-gueule-clash-video-television-politique-best/402168', 'candidats 2027', 'common', null, true),
  -- C070
  ('jean-luc-melenchon', 'Ai-je jamais fait autre chose ?', '2019-06-23', 'Réponse à « Va-t-il parler ? » devant l''assemblée de LFI', 'Europe 1', 'https://www.europe1.fr/politique/melenchon-reaffirme-son-role-de-chef-de-file-devant-ses-militants-3906154', 'candidats 2027', 'common', null, true),
  -- C072
  ('segolene-royal', 'Il faut arrêter de manger du Nutella, par exemple', '2015-06-15', 'Ministre de l''Écologie, au Petit Journal, sur l''huile de palme', 'Puremédias', 'https://www.ozap.com/actu/segolene-royal-appelle-au-boycott-du-nutella/470177', 'candidats 2027', 'rare', null, true),
  -- C073
  ('segolene-royal', 'C''est un monument de l''histoire, d''abord, Fidel Castro', '2016-12-03', 'Aux obsèques de Fidel Castro à Santiago de Cuba', 'Tendance Ouest (AFP)', 'https://www.tendanceouest.com/actualite-204411-a-cuba-segolene-royal-defend-le-bilan-de-fidel-castro', 'candidats 2027', 'rare', null, true),
  -- C075
  ('fabien-roussel', 'La station d''essence est le seul endroit en France où celui qui tient le pistolet est aussi celui qui se fait braquer', '2022-03-14', 'Blague sur le prix des carburants, sur TF1 ; prix Humour et Politique 2022', 'The Local (AFP)', 'https://www.thelocal.fr/20221207/revealed-frances-funniest-politicians-and-their-best-jokes', 'candidats 2027', 'rare', null, true),
  -- C076
  ('fabien-roussel', 'Franchement, vous n''allez pas me parler du sexe des escalopes quand même !', '2022-08-30', 'Europe 1, après Sandrine Rousseau sur le barbecue et la virilité', 'L''Info Durable (AFP)', 'https://www.linfodurable.fr/barbecue-symbole-de-virilite-bayou-daccord-roussel-refuse-quon-parle-du-sexe-des-escalopes-33793', 'candidats 2027', 'common', null, true),
  -- C077
  ('fabien-roussel', 'C''est coco et cocorico !', '2022-03-10', 'Slogan au meeting du Cirque d''Hiver', 'Public Sénat', 'https://www.publicsenat.fr/actualites/politique/en-meeting-au-cirque-d-hiver-fabien-roussel-celebre-sa-france-coco-et-cocorico', 'candidats 2027', 'rare', null, true),
  -- C078
  ('fabien-roussel', 'On appellera ça le dividende citoyen, le ''rousselement'' de l''économie', '2022-03-10', 'Même meeting, sur une taxe des profits', 'Public Sénat', 'https://www.publicsenat.fr/actualites/politique/en-meeting-au-cirque-d-hiver-fabien-roussel-celebre-sa-france-coco-et-cocorico', 'candidats 2027', 'common', null, true),
  -- C079
  ('fabien-roussel', 'On a fait les Trente Glorieuses, moi je voudrais les Trente Heureuses', '2022-01-24', 'Punchline, Europe 1', 'Europe 1', 'https://www.europe1.fr/node/88831', 'candidats 2027', 'common', null, true),
  -- C080
  ('fabien-roussel', 'Mon système est révolutionnaire et écologique. Il est écolo coco !', '2022-02-18', 'Public Sénat, sur la viande', 'Public Sénat', 'https://www.publicsenat.fr/actualites/politique/alimentation-fabien-roussel-defend-son-systeme-ecolo-coco-194209', 'candidats 2027', 'common', null, true),
  -- C081
  ('francois-ruffin', 'Il faut que Macron enlève les bouchons qu''il a dans les oreilles et qu''il entende le peuple', '2018-11-24', 'LCI, pendant les Gilets jaunes', 'L''Info Durable (AFP)', 'https://www.linfodurable.fr/ruffin-lfi-il-faut-que-macron-enleve-les-bouchons-quil-dans-les-oreilles-7645', 'candidats 2027', 'rare', null, true),
  -- C082
  ('francois-ruffin', 'Macron c''est Marie-Antoinette au moment de la Révolution française.', '2018-11-24', 'Même période des Gilets jaunes', 'L''Info Durable (AFP)', 'https://www.linfodurable.fr/ruffin-lfi-il-faut-que-macron-enleve-les-bouchons-quil-dans-les-oreilles-7645', 'candidats 2027', 'rare', null, true),
  -- C083
  ('francois-ruffin', 'Quelles nouvelles mesures comptez-vous prendre pour que tous nos amis fortunés puissent changer leur faïencerie ?', '2018-06-19', 'Question au gouvernement sur la vaisselle de l''Élysée', 'Europe 1', 'https://www.europe1.fr/politique/echange-acide-a-lassemblee-entre-ruffin-et-griveaux-sur-la-vaisselle-de-lelysee-et-les-riches-3687284', 'candidats 2027', 'common', 'fiction-pere-ubu', true),
  -- C084
  ('francois-ruffin', 'Les pauvres coûtent trop cher', '2018-06-19', 'Même intervention, employé par ironie', 'Europe 1', 'https://www.europe1.fr/politique/echange-acide-a-lassemblee-entre-ruffin-et-griveaux-sur-la-vaisselle-de-lelysee-et-les-riches-3687284', 'candidats 2027', 'common', null, true),
  -- C085
  ('marine-tondelier', 'Depuis qu''il existe un compte Twitter dédié à mes vestes vertes, j''ai un peu la pression', null, 'Confidence à Libération sur sa veste verte (07/2024)', 'L''Info Durable (Libération)', 'https://www.linfodurable.fr/la-veste-verte-de-marine-tondelier-nouveau-vetement-star-en-politique-46097', 'candidats 2027', 'common', null, true),
  -- C086
  ('marine-tondelier', 'Vous allez nous laisser parler 5 minutes ça va vous faire du bien', '2024-07-07', 'France 2, soirée électorale, face à J.-P. Tanguy', 'Puremédias', 'https://www.ozap.com/actu/-ca-fait-deux-ans-que-je-prends-sur-moi-marine-tondelier-revient-sur-son-echange-muscle-avec-jean-philippe-tanguy-sur-france-2/644985', 'candidats 2027', 'common', null, true),
  -- C087
  ('marine-tondelier', 'Je souffre en vous écoutant à chaque seconde je confirme', '2024-07-07', 'Même soirée, face à Tanguy', 'Puremédias', 'https://www.ozap.com/actu/-vous-on-vous-a-assez-entendu-marine-tondelier-les-ecologistes-enchaine-les-tacles-contre-jean-philippe-tanguy-rn-lors-de-la-soiree-legislatives-de-france-2/644794', 'candidats 2027', 'common', null, true),
  -- C088
  ('marine-tondelier', 'Mais je m''en fous ! J''en ai marre !', '2024-11-18', 'BFMTV, excédée par une question sur Mélenchon', 'Puremédias', 'https://www.ozap.com/actu/jen-ai-marre-excedee-sur-bfmtv-marine-tondelier-sagace-face-a-perrine-storme-yves-threard-et-christophe-barbier-apres-une-question-sur-jean-luc-melenchon/647661', 'candidats 2027', 'common', null, true),
  -- C089
  ('marine-tondelier', 'Je ne viens pas sur les plateaux pour commenter les phrases abracadabrantesques des uns et des autres !', '2024-11-18', 'Même émission BFMTV', 'Puremédias', 'https://www.ozap.com/actu/jen-ai-marre-excedee-sur-bfmtv-marine-tondelier-sagace-face-a-perrine-storme-yves-threard-et-christophe-barbier-apres-une-question-sur-jean-luc-melenchon/647661', 'candidats 2027', 'common', null, true),
  -- C090
  ('raphael-glucksmann', 'La vérité, c''est qu''en matière de pastèques, Yann Moix peut donner des leçons à la terre entière !', '2019-04-08', 'LCI, ironie sur l''écrivain Yann Moix', 'Puremédias', 'https://www.ozap.com/actu/raphael-glucksmann-en-matiere-de-pasteques-yann-moix-peut-donner-des-lecons-a-la-terre-entiere/577064', 'candidats 2027', 'rare', null, true),
  -- C091
  ('raphael-glucksmann', 'Concentrez-vous sur l''extrême-droite et lâchez-moi les baskets !', '2024-05-27', 'Débat des européennes sur BFMTV, face à Manon Aubry', 'Puremédias', 'https://www.ozap.com/actu/-lachez-moi-les-baskets-furieux-raphael-glucksmann-riposte-apres-des-attaques-de-manon-aubry-sur-bfmtv/644147', 'candidats 2027', 'common', 'fiction-georges-abitbol', true),
  -- C092
  ('raphael-glucksmann', 'Mon nom est Raphaël Glucksmann', '2024-05-27', 'Même débat, il se présente en plein échange', 'Puremédias', 'https://www.ozap.com/actu/-lachez-moi-les-baskets-furieux-raphael-glucksmann-riposte-apres-des-attaques-de-manon-aubry-sur-bfmtv/644147', 'candidats 2027', 'common', null, true),
  -- C093
  ('raphael-glucksmann', 'J''appelle ça la politique Tiktok', '2024-05-23', 'Sud Radio, sur le débat Attal-Bardella', 'Sud Radio', 'https://www.sudradio.fr/linvite-politique/attal-et-bardella-cest-la-politique-tiktok-affirme-raphael-glucksmann', 'candidats 2027', 'common', null, true),
  -- C094
  ('olivier-faure', 'Mon fils, j''arrive après, je suis à la télévision, là !', '2020-05-05', 'Duplex sur CNews pendant le confinement, interrompu par son fils', 'Puremédias', 'https://www.ozap.com/actu/le-duplex-d-olivier-faure-sur-cnews-interrompu-par-son-fils/592699', 'candidats 2027', 'rare', null, true),
  -- C095
  ('olivier-faure', 'Voilà, ça c''est les miracles du confinement', '2020-05-05', 'Sa conclusion après l''interruption', 'Puremédias', 'https://www.ozap.com/actu/le-duplex-d-olivier-faure-sur-cnews-interrompu-par-son-fils/592699', 'candidats 2027', 'common', null, true),
  -- C096
  ('olivier-faure', 'Est-ce qu''on a envie de payer la redevance pour vous avoir, vous, dans le poste de télévision ?', '2018-11-24', 'On n''est pas couché, tacle à Charles Consigny', 'Puremédias', 'https://www.ozap.com/actu/olivier-faure-a-charles-consigny-est-ce-qu-on-a-envie-de-payer-la-redevance-pour-vous-voir-a-la-television/571181', 'candidats 2027', 'common', null, true),
  -- C097
  ('clementine-autain', 'Je n''ai pas regardé précisément ce point 62, vous êtes en train de...', '2017-04-13', 'Franceinfo : découvre en direct une mesure du programme qu''elle défend', 'Puremédias', 'https://www.ozap.com/actu/clementine-autain-decouvre-en-direct-sur-franceinfo-une-mesure-de-jean-luc-melenchon/524144', 'candidats 2027', 'common', null, true),
  -- C098
  ('clementine-autain', 'Vous pourriez rabaisser votre caquet', '2022-06-12', 'TF1, soirée des législatives, clash avec Rachida Dati', 'La Libre Belgique', 'https://www.lalibre.be/international/europe/elections-france/2022/06/13/rabaissez-un-peu-votre-caquet-rachida-dati-et-clementine-autain-signent-le-clash-de-la-soiree-des-legislatives-video-Q5QHIVPH7JAZPOXVNG3LBMPZTU/', 'candidats 2027', 'common', null, true),
  -- C099
  ('jerome-guedj', 'Pardon, mais c''est l''arroseur arrosé.', '2026-02-12', 'Sud Radio, commentaire politique', 'Sud Radio', 'https://www.sudradio.fr/linvite-politique/jerome-guedj-il-y-a-quelque-chose-qui-derange-de-genant-dans-la-nomination-damelie-de-montchalin', 'candidats 2027', 'common', null, true),
  -- C100
  ('jerome-guedj', 'On crève de l''ambiguité', null, 'France Inter, sur sa candidature (09/2026)', 'Brut (AFP)', 'https://www.brut.media/fr/articles/le-depute-jerome-guedj-ps-annonce-sa-candidature-a-lelection-presidentielle-de-2027-sans-passer-par-la-primaire', 'candidats 2027', 'common', null, true),
  -- C101
  ('nathalie-arthaud', 'Les actionnaires qui ne font rien de leurs dix doigts ne coûtent jamais trop cher aux patrons', '2012-02-11', 'Déplacement de campagne à Besançon', 'maCommune.info', 'https://www.macommune.info/presidentielle-travailleuses-travailleurs-le-retour-66478', 'candidats 2027', 'common', null, true),
  -- C102
  ('nathalie-arthaud', 'Les travailleurs ont la force en eux', '2012-02-11', 'Même déplacement', 'maCommune.info', 'https://www.macommune.info/presidentielle-travailleuses-travailleurs-le-retour-66478', 'candidats 2027', 'common', null, true),
  -- C103
  ('nathalie-arthaud', 'Moi, je me présente sans faire de promesse électoraliste.', '2017-03-11', 'On n''est pas couché (France 2)', 'Sud Radio', 'https://www.sudradio.fr/politique/nathalie-arthaud-en-appelle-aux-travailleurs-et-egratigne-melenchon', 'candidats 2027', 'common', null, true),
  -- C104
  ('fiction-hubert-bonisseur-de-la-bath-oss-117', 'C''est notre Raïs à nous : c''est M. René Coty. Un grand homme. Il marquera l''Histoire.', null, 'Vante le président français de l''époque à ses interlocuteurs égyptiens', '10h26 (ex-Topito)', 'https://www.10h26.com/top-meilleure-replique-jean-dujardin', 'pièges', 'common', 'jean-luc-melenchon', false),
  -- C106
  ('fiction-godefroy-de-montmirail', 'Que trépasse si je faiblis !', null, 'Cri de guerre du chevalier, après « Montjoie, Saint-Denis ! »', 'RTBF', 'https://www.rtbf.be/article/les-visiteurs-ont-30-ans-okay-11141172', 'pièges', 'common', 'gabriel-attal', false),
  -- C108
  ('fiction-otis-le-scribe', 'Mais vous savez, moi je ne crois pas qu''il y ait de bonnes ou de mauvaises situations.', null, 'Début de son monologue sur le métier de scribe', '75 secondes', 'https://www.75secondes.fr/culture/top-20-des-repliques-legendaires-de-mission-cleopatre', 'pièges', 'common', 'gabriel-attal', false),
  -- C109
  ('fiction-jean-claude-dusse', 'Oublie que t''as aucune chance. On sait jamais, sur un malentendu ça peut marcher.', null, 'Conseil de drague', 'Citation-celebre.com', 'https://www.citation-celebre.com/citations/84536', 'pièges', 'common', 'bruno-le-maire', false),
  -- C111
  ('fiction-un-truand', 'J''vous préviens qu''on a la puissance de feu d''un croiseur et des flingues de concours.', null, 'Menace pendant une confrontation armée', 'Citation-celebre.com', 'https://www.citation-celebre.com/citations/83411', 'pièges', 'common', 'nicolas-dupont-aignan', false),
  -- C117
  ('fiction-hubert-voix-off', 'Le problème ce n''est pas la chute, c''est l''atterrissage.', null, 'Chute de la parabole de « la société qui tombe »', 'Citation-celebre.com', 'https://www.citation-celebre.com/citations/94280', 'pièges', 'common', 'bruno-le-maire', false),
  -- C118
  ('fiction-georges-abitbol', 'Le train de tes injures roule sur le rail de mon indifférence.', null, 'Réponse dédaigneuse aux insultes de John Wayne', 'Citation-celebre.com', 'https://www.citation-celebre.com/citations/82842', 'pièges', 'common', 'raphael-glucksmann', false),
  -- C121
  ('fiction-patrick-chirac', 'Tu vois, la liberté c''est de pouvoir manger des carottes rapées dans l''emballage.', null, 'Le campeur des Flots Bleus explique sa philosophie', 'Citation-celebre.com', 'https://www.citation-celebre.com/citations/82805', 'pièges', 'common', 'marine-le-pen', false),
  -- C125
  ('fiction-v', 'Les gouvernements devraient avoir peur du peuple.', null, 'Fin de « Les peuples ne devraient pas avoir peur de leurs gouvernements. »', 'Citation-celebre.com', 'https://www.citation-celebre.com/citations/87534', 'pièges', 'common', 'jordan-bardella', false),
  -- C129
  ('fiction-le-roi-premier-asteroide', 'Il faut exiger de chacun ce que chacun peut donner', null, 'Chap. X, le roi explique ses ordres', 'Texte du Petit Prince', 'https://www.cmls.polytechnique.fr/perso/tringali/documents/st_exupery_le_petit_prince.pdf', 'pièges', 'common', null, false),
  -- C130
  ('fiction-pere-ubu', 'Pour enrichir le royaume je vais faire périr tous les Nobles et prendre leurs biens', null, 'Ce qu''il annonce après avoir pris le trône', 'Wikipédia', 'https://fr.wikipedia.org/wiki/Ubu_roi', 'pièges', 'common', 'francois-ruffin', false),
  -- C131
  ('fiction-pere-ubu', 'Au moins, promettez-moi de bien payer les impôts.', null, 'À ses nouveaux sujets', 'Wikipédia', 'https://fr.wikipedia.org/wiki/Ubu_roi', 'pièges', 'common', 'gabriel-attal', false),
  -- C132
  ('fiction-pere-ubu', 'Ne crains rien, ma douce enfant, j''irai moi-même de village en village recueillir les impôts.', null, 'Rassure Mère Ubu sur ses finances', 'Wikipédia', 'https://fr.wikipedia.org/wiki/Ubu_roi', 'pièges', 'common', null, false),
  -- C133
  ('fiction-tartuffe', 'Ce n''est pas pécher que pécher en silence', null, 'L''hypocrite à Elmire (acte IV)', 'Wikipédia', 'https://fr.wikipedia.org/wiki/Le_Tartuffe_ou_l%27Imposteur', 'pièges', 'common', null, false),
  -- C134
  ('fiction-monsieur-jourdain', 'Il y a plus de quarante ans que je dis de la prose sans que j''en susse rien', null, 'Acte II, sc. 4 : il découvre qu''il parle en prose', 'Wikipédia', 'https://fr.wikipedia.org/wiki/Le_Bourgeois_gentilhomme', 'pièges', 'common', null, false),
  -- C135
  ('fiction-monsieur-jourdain', 'Suivez-moi, que j''aille un peu montrer mon habit par la ville.', null, 'Acte III, sc. 1 : veut parader dans son habit neuf', 'Wikipédia', 'https://fr.wikipedia.org/wiki/Le_Bourgeois_gentilhomme', 'pièges', 'common', null, false),
  -- C138
  ('fiction-le-glaude-ou-le-bombe', 'On sait se tenir. On ne pète que dehors. On a déjà été au restaurant !', null, 'Les deux paysans assurent savoir se tenir', 'Citation-celebre.com', 'https://www.citation-celebre.com/citations/84055', 'pièges', 'common', 'fabien-roussel', false),
  -- C141
  ('jacques-chirac', 'Ces pays ont perdu une bonne occasion de se taire', '2003-02-18', 'Vise les pays de l''Est alignés sur les États-Unis (Irak)', 'Public Sénat (AFP)', 'https://www.publicsenat.fr/actualites/politique/les-phrases-cultes-de-jacques-chirac-145879', 'petites phrases', 'epic', null, true),
  -- C142
  ('jacques-chirac', 'Je décide et il exécute', '2004-07-14', 'Recadre son ministre des Finances Nicolas Sarkozy', 'Public Sénat (AFP)', 'https://www.publicsenat.fr/actualites/politique/les-phrases-cultes-de-jacques-chirac-145879', 'petites phrases', 'legendary', 'bruno-retailleau', true),
  -- C143
  ('jacques-chirac', 'Ce n''est pas qu''elles se dégonflent, c''est qu''elles font pschitt', '2001-07-14', 'Interview télévisée sur des accusations visant ses voyages', 'Public Sénat (AFP)', 'https://www.publicsenat.fr/actualites/politique/les-phrases-cultes-de-jacques-chirac-145879', 'petites phrases', 'epic', null, true),
  -- C144
  ('jacques-chirac', 'En un mot, ce n''est pas la fusion mais ce n''est pas non plus la fission.', '1997-06-17', 'Conférence de presse avec Jospin sur la cohabitation', 'Public Sénat (AFP)', 'https://www.publicsenat.fr/actualites/politique/les-phrases-cultes-de-jacques-chirac-145879', 'petites phrases', 'common', null, true),
  -- C145
  ('jacques-chirac', 'Peut-être qu''en le pratiquant jeune, j''aurais pu faire du sumo', '1998-01-28', 'Interview à L''Équipe', 'Public Sénat (AFP)', 'https://www.publicsenat.fr/actualites/politique/les-phrases-cultes-de-jacques-chirac-145879', 'petites phrases', 'rare', 'edouard-philippe', true),
  -- C146
  ('jacques-chirac', 'Je peux dire que je voterai Hollande!', '2011-06-11', 'Boutade en Corrèze', 'Public Sénat (AFP)', 'https://www.publicsenat.fr/actualites/politique/les-phrases-cultes-de-jacques-chirac-145879', 'petites phrases', 'common', null, true),
  -- C147
  ('jacques-chirac', 'Je suis un mangeur de pomme.', null, 'Campagne présidentielle au symbole de la pomme (1995)', 'RTBF', 'https://www.rtbf.be/article/jacques-chirac-en-10-phrases-cultes-videos-9410107', 'petites phrases', 'rare', null, true),
  -- C148
  ('jacques-chirac', 'Un chef, c''est fait pour cheffer.', null, 'Rapporté dans « C''est mon avis et je le partage » (P. Vandel, Grasset) (1995)', 'Wikiquote (source livre)', 'https://fr.wikiquote.org/wiki/Jacques_Chirac', 'petites phrases', 'epic', null, true),
  -- C152
  ('jean-pierre-raffarin', 'The yes needs the no to win against the no', null, 'Campagne du référendum européen (2005)', 'INA', 'https://mediaclip.ina.fr/fr/i19094525-jean-pierre-raffarin-the-yes-needs-the-no-to-win-against-the-no.html', 'petites phrases', 'epic', null, true),
  -- C153
  ('jean-pierre-raffarin', 'Les jeunes sont destinés à devenir des adultes', null, 'Raffarinade (années 2000)', 'Public Sénat', 'https://www.publicsenat.fr/actualites/politique/jean-pierre-raffarin-et-ses-meilleures-raffarinades-75235', 'petites phrases', 'rare', 'david-lisnard', true),
  -- C154
  ('jean-pierre-raffarin', 'Le citoyen est un piéton de la République', null, 'Raffarinade (années 2000)', 'Public Sénat', 'https://www.publicsenat.fr/actualites/politique/jean-pierre-raffarin-et-ses-meilleures-raffarinades-75235', 'petites phrases', 'rare', null, true),
  -- C155
  ('jean-pierre-raffarin', 'L''avenir est une suite de quotidiens', null, 'Raffarinade (années 2000)', 'Public Sénat', 'https://www.publicsenat.fr/actualites/politique/jean-pierre-raffarin-et-ses-meilleures-raffarinades-75235', 'petites phrases', 'rare', null, true),
  -- C156
  ('edgar-faure', 'Ce n''est pas la girouette qui tourne, c''est le vent', null, 'Réponse aux accusations d''opportunisme (IVe/Ve République)', 'Hérodote', 'https://www.herodote.net/Les_bons_mots_de_la_IVe_Republique-synthese-1759-312.php', 'petites phrases', 'epic', null, true),
  -- C157
  ('edgar-faure', 'J''ai été en l''espace de 24 heures renversé, dissout et exclu', null, 'Après la dissolution et son exclusion du Parti radical (12/1955)', 'Hérodote', 'https://www.herodote.net/Les_bons_mots_de_la_IVe_Republique-synthese-1759-312.php', 'petites phrases', 'rare', null, true),
  -- C158
  ('edgar-faure', 'Lorsqu''un problème est difficile, il faut toujours recourir à une solution compliquée', null, 'Maxime tirée de ses mémoires', 'Hérodote', 'https://www.herodote.net/Les_bons_mots_de_la_IVe_Republique-synthese-1759-312.php', 'petites phrases', 'common', null, true),
  -- C159
  ('edgar-faure', 'Avoir toujours raison, c''est un grand tort', null, 'Titre du premier tome de ses mémoires (1982)', 'Hérodote', 'https://www.herodote.net/Les_bons_mots_de_la_IVe_Republique-synthese-1759-312.php', 'petites phrases', 'common', null, true),
  -- C161
  ('coluche', 'Jusqu''à présent la France était coupée en deux, avec moi elle sera pliée en quatre !', null, 'Slogan de sa candidature à la présidentielle (1980)', 'Paris Match Belgique', 'https://www.parismatch.be/actualites/people/2025/02/02/la-story-match-le-jour-ou-coluche-sest-presente-comme-candidat-a-lelection-presidentielle-5TBPCWMX4FDW7HBCIVLK5UIRLM/', 'pièges', 'common', 'eric-zemmour', false),
  -- C162
  ('coluche', 'Le seul candidat qui n''a pas de raison de mentir', null, 'Signature de son affiche de candidature (1980)', 'Paris Match Belgique', 'https://www.parismatch.be/actualites/people/2025/02/02/la-story-match-le-jour-ou-coluche-sest-presente-comme-candidat-a-lelection-presidentielle-5TBPCWMX4FDW7HBCIVLK5UIRLM/', 'pièges', 'common', null, false),
  -- C163
  ('jean-claude-van-damme', 'Nous devons nous battre, chacun à sa place et dans son domaine de prédilection, pour un monde meilleur.', '2023-11-12', 'Interview à Paris Match Belgique', 'Paris Match Belgique', 'https://www.parismatch.be/culture/cinema/2023/11/12/il-faut-savoir-encaisser-lavis-des-gens-qui-vous-caricaturent-pour-jcvd-lautoderision-est-dans-son-adn-72YHXHN7EBBZNJJ3W3L64XQE3E/', 'pièges', 'common', null, false),
  -- C164
  ('jean-claude-van-damme', 'Nous avons besoin d''une énergie positivement contagieuse.', '2023-11-12', 'Même interview', 'Paris Match Belgique', 'https://www.parismatch.be/culture/cinema/2023/11/12/il-faut-savoir-encaisser-lavis-des-gens-qui-vous-caricaturent-pour-jcvd-lautoderision-est-dans-son-adn-72YHXHN7EBBZNJJ3W3L64XQE3E/', 'pièges', 'common', null, false),
  -- C165
  ('jean-claude-van-damme', 'Il faut réellement adopter une démarche plus sage et éclairée pour le futur.', '2023-11-12', 'Même interview', 'Paris Match Belgique', 'https://www.parismatch.be/culture/cinema/2023/11/12/il-faut-savoir-encaisser-lavis-des-gens-qui-vous-caricaturent-pour-jcvd-lautoderision-est-dans-son-adn-72YHXHN7EBBZNJJ3W3L64XQE3E/', 'pièges', 'common', null, false),
  -- C166
  ('jean-claude-van-damme', 'Non, je n''ai qu''une pensée. Piou !', '2024-12-22', 'Sept à huit (TF1), « combien de pensées dans votre tête ? »', 'Puremédias', 'https://www.ozap.com/actu/il-y-a-combien-de-pensees-dans-votre-tete-audrey-crespo-mara-deconcertee-par-jean-claude-van-damme-pendant-son-interview-dans-sept-a-huit-sur-tf1/648089', 'pièges', 'common', 'segolene-royal', false),
  -- C167
  ('jean-claude-van-damme', 'Il faut simplement prendre le dictionnaire.', null, 'Sept à huit, sur le sens de « aware » (07/2021)', 'La DH', 'https://www.dhnet.be/medias/television/2021/07/12/jean-claude-van-damme-revele-le-sens-de-son-expression-culte-aware-dont-la-france-sest-moquee-3D75CIOKV5GEHMSAH6M7QGKOPI/', 'pièges', 'common', null, false),
  -- C168
  ('eric-cantona', 'Quand les mouettes suivent le chalutier, c''est parce qu''elles pensent que les sardines vont être jetées à la mer.', '1995-03-31', 'Seule phrase de sa conférence de presse après son kung-fu kick', 'Irish Times', 'https://irishtimes-irishtimes-prod.cdn.arcpublishing.com/sport/soccer/2024/03/27/it-just-came-out-eric-cantona-reveals-inspiration-for-1995-seagulls-comment', 'pièges', 'common', 'dominique-de-villepin', false),
  -- C169
  ('eric-cantona', 'Le système est bâti sur le pouvoir des banques. Donc il peut être détruit par les banques', '2010-10-06', 'Presse Océan, appel à retirer son argent des banques', 'MoneyVox (AFP)', 'https://www.moneyvox.fr/actu/20972/un-appel-de-cantona-a-retirer-son-argent-des-banques-fait-du-buzz', 'pièges', 'common', null, false),
  -- C170
  ('raymond-domenech', 'J''ai qu''un seul projet, c''est d''épouser Estelle.', '2008-06-17', 'M6, juste après l''élimination à l''Euro', 'FFLose', 'https://fflose.com/euro-2008-quand-domenech-faisait-sa-demande-en-mariage', 'pièges', 'common', 'gabriel-attal', false),
  -- C173
  ('bernard-tapie', 'J''ai menti de bonne foi.', null, 'Procès VA-OM (1995)', 'Larousse', 'https://www.larousse.fr/archives/journaux_annee/1996/134/chronique_judiciaire', 'pièges', 'common', null, false),
  -- C174
  ('gerard-depardieu', 'Je vous rends mon passeport et ma carte de Sécurité sociale dont je ne me suis jamais servi.', '2012-12-16', 'Lettre à J.-M. Ayrault dans le JDD', 'Puremédias (JDD)', 'https://www.ozap.com/actu/depardieu-apostrophe-jean-marc-ayrault-je-vous-rends-mon-passeport-et-ma-carte-de-securite-sociale/444577', 'pièges', 'common', null, false),
  -- C175
  ('gerard-depardieu', 'Nous n''avons plus la même patrie', '2012-12-16', 'Même lettre', 'Puremédias (JDD)', 'https://www.ozap.com/actu/depardieu-apostrophe-jean-marc-ayrault-je-vous-rends-mon-passeport-et-ma-carte-de-securite-sociale/444577', 'pièges', 'common', 'dominique-de-villepin', false),
  -- C176
  ('gerard-depardieu', 'Je ne demande pas à être approuvé, je pourrais au moins être respecté !', '2012-12-16', 'Même lettre', 'Puremédias (JDD)', 'https://www.ozap.com/actu/depardieu-apostrophe-jean-marc-ayrault-je-vous-rends-mon-passeport-et-ma-carte-de-securite-sociale/444577', 'pièges', 'common', null, false),
  -- C177
  ('zlatan-ibrahimovic', 'Je suis venu ici comme en roi et j''en repars comme une légende. Mais je reviendrai !', '2016-05-13', 'Message d''adieu au PSG', 'La DH', 'https://www.dhnet.be/sports/football/mercato/2016/05/13/zlatan-quitte-le-psg-je-suis-arrive-comme-un-roi-je-pars-comme-une-legende-videos-W7Q2KPTM55GL3LYGQJN2AZHDH4/', 'pièges', 'common', null, false),
  -- C178
  ('kylian-mbappe', 'On est dans un moment crucial dans l''histoire de notre pays', '2024-06-16', 'Conférence de presse à l''Euro', 'La Libre (L''Équipe)', 'https://www.lalibre.be/sports/football/euro/2024/06/18/polemique-autour-des-propos-de-kylian-mbappe-voici-ce-que-personne-navait-entendu-lors-de-la-conference-de-presse-IJTCGDVQANDBBBVV4IXTOFTAHQ/', 'pièges', 'common', null, false),
  -- C179
  ('kylian-mbappe', 'Non, parce que c''est des idées qui divisent et je suis contre la division.', '2024-06-16', 'Même conférence de presse', 'La Libre (L''Équipe)', 'https://www.lalibre.be/sports/football/euro/2024/06/18/polemique-autour-des-propos-de-kylian-mbappe-voici-ce-que-personne-navait-entendu-lors-de-la-conference-de-presse-IJTCGDVQANDBBBVV4IXTOFTAHQ/', 'pièges', 'common', null, false),
  -- C180
  ('johnny-hallyday', 'Je ne me mêlerai plus jamais ouvertement de politique', '2012-04-24', 'Interview au Républicain Lorrain', 'Puremédias', 'https://www.ozap.com/actu/johnny-hallyday-je-ne-me-melerai-plus-jamais-ouvertement-de-politique/440552', 'pièges', 'common', null, false),
  -- C181
  ('gims', 'L''Afrique, c''est Wakanda, bordel ! À l''époque de l''empire de Koush, il y avait de l''électricité', null, 'Interview YouTube Oui Hustle (04/2023)', 'Paris Match Belgique', 'https://www.parismatch.be/actualites/people/2023/04/16/gims-et-sa-theorie-de-lelectricite-dans-les-pyramides-tourne-en-ridicule-sur-twitter-OXGZVKLGJRHXBGX4ICFPMME6GI/', 'pièges', 'common', null, false)
) as v(who, text, said_on, occasion, source_label, source_url, theme, rarity, decoy, collectible)
where not exists (select 1 from public.cards c where c.text = v.text);

-- Les paires de l'Excel donnent aussi un piège aux citations déjà en base
update public.cards c set decoy_politician_id = (select id from public.politicians where slug = v.decoy)
from (values
  ('La République, c''est moi', 'fiction-hubert-bonisseur-de-la-bath-oss-117'),
  ('Qui va sur la Grande Muraille', 'jean-claude-van-damme'),
  ('Un bon vin, une bonne viande', 'fiction-le-glaude-ou-le-bombe'),
  ('Et c''est un vieux pays, la France', 'gerard-depardieu')
) as v(prefix, decoy)
where c.text like v.prefix || '%' and c.collectible;


-- ---------------------------------------------------------------------------
-- Les pièges (collectible = false) ne donnent jamais de carte
-- ---------------------------------------------------------------------------

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
    'party_name', pa.name, 'party_short', pa.short_name, 'party_color', pa.color,
    'collectible', c.collectible, 'kind', p.kind)
  from cards c
  join politicians p on p.id = c.politician_id
  left join parties pa on pa.id = p.party_id
  where c.id = p_card;
$$;

create or replace function public.submit_answer(p_question uuid, p_choice uuid)
returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_user uuid := auth.uid();
  v_q record;
  v_s record;
  v_author uuid;
  v_collectible boolean;
  v_correct boolean;
  v_elapsed numeric;
  v_speed integer := 0;
  v_mult numeric := 1;
  v_points integer := 0;
  v_streak integer;
  v_new_card boolean := false;
begin
  select gr.* into v_q
    from game_rounds gr
    join game_sessions s on s.id = gr.session_id
   where gr.id = p_question and s.user_id = v_user and s.status = 'in_progress'
   for update of gr;
  if not found then raise exception 'question not found'; end if;
  if v_q.answered_at is not null then raise exception 'already answered'; end if;
  if v_q.served_at is null then raise exception 'question not served'; end if;
  if p_choice is null or p_choice not in (v_q.option_a, v_q.option_b) then raise exception 'invalid choice'; end if;

  select * into v_s from game_sessions where id = v_q.session_id for update;
  if v_s.ends_at is not null and now() > v_s.ends_at + interval '2 seconds' then
    update game_sessions set status = 'finished', finished_at = now() where id = v_s.id;
    raise exception 'time is up';
  end if;

  select politician_id, collectible into v_author, v_collectible from cards where id = v_q.card_id;
  v_correct := (p_choice = v_author);
  v_elapsed := extract(epoch from (now() - v_q.served_at));

  if v_correct then
    v_streak := v_s.streak + 1;
    v_speed := greatest(0, round(50 * (1 - v_elapsed / 15.0)))::integer;
    v_mult := case when v_streak >= 5 then 2 when v_streak >= 3 then 1.5 else 1 end;
    v_points := round((100 + v_speed) * v_mult)::integer;

    if v_collectible then
      insert into user_collection (user_id, card_id) values (v_user, v_q.card_id)
      on conflict (user_id, card_id) do update set copies = user_collection.copies + 1
      returning (xmax = 0) into v_new_card;
    end if;
  else
    v_streak := 0;
  end if;

  update game_rounds
     set answered_at = now(), chosen_id = p_choice, is_correct = v_correct, points = v_points
   where id = v_q.id;

  update game_sessions
     set score = score + v_points,
         correct_count = correct_count + (case when v_correct then 1 else 0 end),
         streak = v_streak,
         max_streak = greatest(max_streak, v_streak)
   where id = v_s.id;

  update profiles
     set points = points + v_points,
         total_points_earned = total_points_earned + v_points,
         best_streak = greatest(best_streak, v_streak)
   where id = v_user;

  if not exists (select 1 from game_rounds where session_id = v_s.id and answered_at is null) then
    update game_sessions set status = 'finished', finished_at = now() where id = v_s.id;
  end if;

  return jsonb_build_object(
    'correct', v_correct,
    'answer_id', v_author,
    'points', v_points,
    'speed_bonus', v_speed,
    'multiplier', v_mult,
    'streak', v_streak,
    'new_card', v_new_card,
    'card', _card_json(v_q.card_id)
  );
end $$;

create or replace function public._duel_finish(p_duel uuid, p_abandoned_by uuid default null)
returns void
language plpgsql security definer set search_path = public as $$
declare
  d record;
  v_winner uuid;
  v_card uuid;
begin
  select * into d from duels where id = p_duel for update;
  if d.status not in ('active', 'waiting') then return; end if;

  if p_abandoned_by is not null then
    v_winner := case when p_abandoned_by = d.player1 then d.player2 else d.player1 end;
  elsif d.score1 > d.score2 then v_winner := d.player1;
  elsif d.score2 > d.score1 then v_winner := d.player2;
  end if;

  update duels
     set status = case when p_abandoned_by is null then 'finished' else 'abandoned' end,
         winner = v_winner, abandoned_by = p_abandoned_by, finished_at = now()
   where id = p_duel;

  if d.player2 is null then return; end if;

  update profiles set points = points + d.score1, total_points_earned = total_points_earned + d.score1,
                      duels_played = duels_played + 1
   where id = d.player1;
  update profiles set points = points + d.score2, total_points_earned = total_points_earned + d.score2,
                      duels_played = duels_played + 1
   where id = d.player2;

  -- Victoire : 200 points et une carte du duel (jamais un piège)
  if v_winner is not null and (p_abandoned_by is null or d.current_position * 2 > d.question_count) then
    update profiles set points = points + 200, total_points_earned = total_points_earned + 200,
                        duels_won = duels_won + 1
     where id = v_winner;
    select dr.card_id into v_card
      from duel_rounds dr join cards c on c.id = dr.card_id
     where dr.duel_id = p_duel and c.collectible
     order by random() limit 1;
    if v_card is not null then
      insert into user_collection (user_id, card_id) values (v_winner, v_card)
      on conflict (user_id, card_id) do update set copies = user_collection.copies + 1;
    end if;
  end if;
end $$;

-- Boosters : uniquement des cartes à collectionner
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
     where c.verified and c.collectible
       and (v_b.party_id is null or p.party_id = v_b.party_id)
       and (v_b.tag is null or v_b.tag = any (p.tags))
       and (v_b.theme is null or c.theme = v_b.theme)
  ) then raise exception 'empty booster'; end if;

  v_weights := coalesce(v_b.weights,
    jsonb_build_object('common', v_b.weight_common, 'rare', v_b.weight_rare, 'legendary', v_b.weight_legendary));

  update profiles set points = points - v_b.price where id = v_user;

  for i in 1..v_b.card_count loop
    v_rarity := _roll_rarity(v_weights);
    if i = v_b.card_count and v_b.guarantee is not null
       and _rarity_rank(v_rarity) < _rarity_rank(v_b.guarantee) then
      v_rarity := v_b.guarantee;
    end if;
    if v_rarity in ('uncommon') then v_rarity := 'common'; end if;
    if v_rarity in ('mythic') then v_rarity := 'legendary'; end if;

    select c.id into v_id
      from cards c join politicians p on p.id = c.politician_id
     where c.verified and c.collectible
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

-- Album et totaux : les pièges n'en font pas partie
create or replace function public.collection_album()
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
   where c.verified and c.collectible
   order by p.name, public._rarity_rank(c.rarity) desc;
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
   where c.verified and c.collectible
   order by p.name, public._rarity_rank(c.rarity) desc;
$$;

create or replace function public.card_totals()
returns table (rarity public.card_rarity, total bigint)
language sql stable security definer set search_path = public as $$
  select c.rarity, count(*) from cards c where c.verified and c.collectible group by c.rarity;
$$;
