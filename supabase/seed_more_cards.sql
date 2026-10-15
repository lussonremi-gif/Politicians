-- ============================================================================
-- Extension du contenu : nouvelles personnalités, pièges hors politique,
-- 17 nouvelles cartes et photos d'époque par carte.
-- À vérifier par l'équipe éditoriale (texte exact, date, source, crédits photo).
-- ============================================================================

insert into public.parties (slug, name, short_name, color, sort_order) values
  ('npa', 'Nouveau Parti anticapitaliste', 'NPA', '#b5121b', 0)
on conflict (slug) do nothing;

-- Nouvelles personnalités politiques
insert into public.politicians (slug, name, party_id, role, image_url, image_credit, image_license, image_source_url, image_focus)
select v.slug, v.name, (select id from public.parties where slug = v.party), v.role,
       'https://commons.wikimedia.org/wiki/Special:FilePath/' || replace(v.file, ' ', '_') || '?width=480',
       v.credit, v.license, 'https://commons.wikimedia.org/wiki/File:' || replace(v.file, ' ', '_'), v.focus
from (values
  ('laurent-fabius',       'Laurent Fabius',       'ps',  'Premier ministre (1984-1986)', 'Laurent Fabius (2001 cropped).jpg', 'Fonds monétaire international', null, null),
  ('francois-fillon',      'François Fillon',      'lr',  'Premier ministre (2007-2012)', 'François Fillon 2010 (cropped).jpg', 'Marie-Lan Nguyen', 'CC BY 3.0', null),
  ('pierre-mendes-france', 'Pierre Mendès France', null,  'Président du Conseil (1954-1955)', 'Pierre Mendès-France 1932.jpg', 'Mondial Photo-Presse (Gallica)', 'Domaine public', null),
  ('jean-jaures',          'Jean Jaurès',          null,  'Député socialiste, fondateur de L''Humanité', 'Jean Jaurès, 1904, by Nadar.jpg', 'Nadar (Gallica)', 'Domaine public', 'center 18%'),
  ('manuel-valls',         'Manuel Valls',         'ps',  'Premier ministre (2014-2016)', '52 Manuel Valls.JPG', 'Wikimedia Commons', 'CC BY-SA 3.0', null),
  ('philippe-poutou',      'Philippe Poutou',      'npa', 'Candidat à la présidentielle (2012, 2017, 2022)', 'Philippe Poutou 2020 (cropped).png', 'Patrice Calatayu', null, null)
) as v(slug, name, party, role, file, credit, license, focus)
on conflict (slug) do nothing;

-- Personnalités hors politique (ou étrangères) : uniquement des pièges
insert into public.politicians (slug, name, kind, role, image_url, image_credit, image_license, image_source_url, image_focus)
select v.slug, v.name, 'personality', v.role,
       'https://commons.wikimedia.org/wiki/Special:FilePath/' || replace(v.file, ' ', '_') || '?width=480',
       v.credit, v.license, 'https://commons.wikimedia.org/wiki/File:' || replace(v.file, ' ', '_'), v.focus
from (values
  ('greta-thunberg',     'Greta Thunberg',     'Militante pour le climat', 'Greta Thunberg, March 2020 (cropped).jpg', 'Parlement européen', 'CC BY 2.0', null),
  ('didier-deschamps',   'Didier Deschamps',   'Champion du monde de football (1998, 2018)', 'Didier Deschamps 2011 (cropped).jpeg', 'Mustapha Ennaimi', 'CC BY 2.0', null),
  ('albert-camus',       'Albert Camus',       'Écrivain, prix Nobel de littérature 1957', 'Albert Camus, gagnant de prix Nobel, portrait en buste, posé au bureau, faisant face à gauche, cigarette de tabagisme.jpg', 'United Press International (Library of Congress)', 'Domaine public', null),
  ('celine-dion',        'Céline Dion',        'Chanteuse', 'Céline Dion en 2013 (cropped).JPG', 'Wikimedia Commons', 'CC BY-SA 3.0', null),
  ('donald-trump',       'Donald Trump',       'Président des États-Unis', 'Donald Trump official portrait (3x4a).jpg', 'Maison Blanche', 'Domaine public', null),
  ('gisele-halimi',      'Gisèle Halimi',      'Avocate et militante féministe', 'Gisele Halimi - Huma-2008 2.jpg', 'Olivier Tétard', 'CC BY-SA 3.0', null),
  ('philippe-etchebest', 'Philippe Etchebest', 'Chef cuisinier et animateur de télévision', 'Philippe Etchebest in 2018.png', 'Wikimedia Commons', 'CC BY 3.0', null),
  ('napoleon-bonaparte', 'Napoléon Bonaparte', 'Empereur des Français (1804-1815)', 'Jacques-Louis David - The Emperor Napoleon in His Study at the Tuileries - Google Art Project.jpg', 'Jacques-Louis David (National Gallery of Art)', 'Domaine public', 'center 12%')
) as v(slug, name, role, file, credit, license, focus)
on conflict (slug) do nothing;

-- Nouvelles cartes
insert into public.cards (politician_id, text, said_on, occasion, source_label, theme, rarity, decoy_politician_id, verified)
select (select id from public.politicians where slug = v.who), v.text, v.said_on::date, v.occasion,
       'Source à documenter (archives INA, presse)', v.theme, v.rarity::public.card_rarity,
       (select id from public.politicians where slug = v.decoy), true
from (values
  ('jean-jaures', 'Le courage, c''est de chercher la vérité et de la dire.', '1903-07-30', 'Discours à la jeunesse, au lycée d''Albi', 'discours', 'legendary', 'albert-camus'),
  ('jacques-chirac', 'La France, patrie des Lumières et des Droits de l''homme, terre d''accueil et d''asile, la France, ce jour-là, accomplissait l''irréparable.', '1995-07-16', 'Discours de commémoration de la rafle du Vél'' d''Hiv', 'discours', 'legendary', 'francois-mitterrand'),
  ('francois-mitterrand', 'C''est quand même ennuyeux que, dans l''intervalle, vous soyez devenu, vous, l''homme du passif.', '1981-05-05', 'Débat télévisé d''entre-deux-tours face à Valéry Giscard d''Estaing', 'débats', 'legendary', 'valery-giscard-destaing'),
  ('pierre-mendes-france', 'Gouverner, c''est choisir, si difficiles que soient les choix.', '1953-06-03', 'Discours devant l''Assemblée nationale, candidat à la présidence du Conseil', 'discours', 'epic', 'napoleon-bonaparte'),
  ('jacques-chirac', 'Ce soir, je ne suis pas le Premier ministre et vous n''êtes pas le président de la République.', '1988-04-28', 'Débat télévisé d''entre-deux-tours face à François Mitterrand', 'débats', 'epic', 'francois-mitterrand'),
  ('laurent-fabius', 'Je vous rappelle que vous parlez au Premier ministre de la France.', '1985-10-27', 'Débat télévisé face à Jacques Chirac', 'débats', 'epic', 'jacques-chirac'),
  ('francois-fillon', 'Qui imagine le général de Gaulle mis en examen ?', '2016-08-28', 'Discours de rentrée à Sablé-sur-Sarthe', 'campagnes', 'epic', 'nicolas-sarkozy'),
  ('francois-hollande', 'La France est en guerre.', '2015-11-16', 'Discours devant le Parlement réuni en Congrès à Versailles, après les attentats du 13 novembre', 'discours', 'epic', 'emmanuel-macron'),
  ('francois-fillon', 'Je suis à la tête d''un État qui est en situation de faillite sur le plan financier.', '2007-09-21', 'Déplacement en Corse, alors Premier ministre', 'petites phrases', 'rare', 'nicolas-sarkozy'),
  ('emmanuel-macron', 'Je suis votre chef.', '2017-07-13', 'Discours aux armées, à l''hôtel de Brienne', 'discours', 'rare', 'didier-deschamps'),
  ('emmanuel-macron', 'Une gare, c''est un lieu où on croise les gens qui réussissent et les gens qui ne sont rien.', '2017-06-29', 'Inauguration de Station F, à Paris', 'petites phrases', 'rare', null),
  ('charles-de-gaulle', 'La réforme oui, la chienlit non.', '1968-05-19', 'Propos tenus pendant Mai 68, rapportés par le gouvernement', 'petites phrases', 'rare', null),
  ('philippe-poutou', 'Nous, quand on est convoqué par la police, on n''a pas d''immunité ouvrière.', '2017-04-04', 'Débat télévisé entre les onze candidats à la présidentielle', 'débats', 'rare', 'marine-le-pen'),
  ('emmanuel-macron', 'Make our planet great again.', '2017-06-01', 'Allocution après l''annonce du retrait américain de l''accord de Paris sur le climat', 'discours', 'uncommon', 'donald-trump'),
  ('emmanuel-macron', 'Qu''ils viennent me chercher.', '2018-07-24', 'Réunion des députés de la majorité pendant l''affaire Benalla', 'petites phrases', 'uncommon', null),
  ('nicolas-sarkozy', 'Vous êtes un petit calomniateur.', '2012-05-02', 'Débat télévisé d''entre-deux-tours face à François Hollande', 'débats', 'uncommon', 'francois-hollande'),
  ('manuel-valls', 'Moi, j''aime l''entreprise !', '2014-08-27', 'Université d''été du Medef', 'petites phrases', 'common', 'emmanuel-macron')
) as v(who, text, said_on, occasion, theme, rarity, decoy);

-- Pièges hors politique pour des cartes existantes
update public.cards c set decoy_politician_id = (select id from public.politicians where slug = v.decoy)
from (values
  ('Notre maison brûle et nous regardons ailleurs.', 'greta-thunberg'),
  ('Aucune femme ne recourt de gaîté de cœur à l''avortement.', 'gisele-halimi'),
  ('Vive le Québec libre !', 'celine-dion'),
  ('Je traverse la rue, je vous en trouve.', 'philippe-etchebest'),
  ('Nous sommes en guerre.', 'francois-hollande')
) as v(text, decoy)
where c.text = v.text;

-- Photos d'époque par carte (repli automatique sur la photo de la personnalité)
update public.cards c
   set image_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/' || replace(v.file, ' ', '_') || '?width=480',
       image_source_url = 'https://commons.wikimedia.org/wiki/File:' || replace(v.file, ' ', '_'),
       image_credit = v.credit, image_license = v.license
from (values
  ('Paris outragé ! Paris brisé ! Paris martyrisé ! Mais Paris libéré !', 'De Gaulle-OWI.jpg', 'Office of War Information (Library of Congress)', 'Domaine public'),
  ('Au revoir.', 'Valéry Giscard d''Estaing 1981 (1).jpg', 'Wikimedia Commons', null),
  ('Ce soir, je ne suis pas le Premier ministre et vous n''êtes pas le président de la République.', 'Jacques Chirac 1980.jpg', 'Wikimedia Commons', null),
  ('Dès demain, on va nettoyer au Kärcher la cité.', 'Nicolas Sarkozy en meeting à Vélizy-Villacoublay - 061014.jpg', 'Wikimedia Commons', null),
  ('Vous êtes un petit calomniateur.', 'Nicolas Sarkozy in 2010.jpg', 'Wikimedia Commons', null),
  ('Moi, président de la République, je ne serai pas le chef de la majorité.', 'François Hollande 2012.JPG', 'Wikimedia Commons', null),
  ('La France est en guerre.', 'Francois Hollande 2015.jpeg', 'Wikimedia Commons', null),
  ('Nous sommes en guerre.', 'Emmanuel Macron June 2022 (cropped).jpg', 'Présidence de l''Ukraine', 'CC BY 4.0'),
  ('Les non-vaccinés, j''ai très envie de les emmerder.', 'Emmanuel Macron June 2022 (cropped).jpg', 'Présidence de l''Ukraine', 'CC BY 4.0'),
  ('La France sera dirigée par une femme, ce sera soit moi, soit Mme Merkel.', 'Marine Le Pen (2017-03-24) 01 cropped.jpg', 'Kremlin.ru', 'CC BY 4.0'),
  ('La République, c''est moi !', 'Jean-Luc Mélenchon 2017.jpg', 'Wikimedia Commons', null),
  ('Ma personne est sacrée !', 'Jean-Luc Mélenchon 2017.jpg', 'Wikimedia Commons', null),
  ('Et c''est un vieux pays, la France, d''un vieux continent comme le mien, l''Europe, qui vous le dit aujourd''hui.', 'Dominique De Villepin prononce un discours à l''ONU contre la guerre en Irak.jpg', 'Wikimedia Commons', null),
  ('Qui va sur la Grande Muraille conquiert la bravitude.', 'Ségolène Royal - Royal & Zapatero''s meeting in Toulouse for the 2007 French presidential election 0627 2007-04-19.jpg', 'Wikimedia Commons', null),
  ('Tu ne me fais pas les poches !', 'François Bayrou (4369005502) (cropped).jpg', 'Régions Démocrates 2010', 'CC BY 2.0'),
  ('Qui imagine le général de Gaulle mis en examen ?', 'Dédicace F Fillon 06297 (cropped).JPG', 'G. Garitan', 'CC BY-SA 4.0')
) as v(text, file, credit, license)
where c.text = v.text;

-- Booster du NPA s'il a des cartes
insert into public.booster_types (slug, name, description, price, card_count, kind, party_id, weights, sort_order)
select 'parti-npa', 'Booster NPA', '3 cartes · Nouveau Parti anticapitaliste', 400, 3, 'politicians', id,
       '{"common":45,"uncommon":27,"rare":15,"epic":8,"legendary":4,"mythic":1}', 10
from public.parties where slug = 'npa'
on conflict (slug) do nothing;
