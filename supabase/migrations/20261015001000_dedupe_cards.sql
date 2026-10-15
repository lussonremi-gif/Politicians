-- Doublons entre deux lots de cartes ajoutés en parallèle : on garde les versions
-- sourcées (lien vers la source) de 20261015000900_more_quote_cards et on retire
-- du jeu les autres (verified = false : non jouables, mais rien n'est supprimé).
update public.cards set verified = false
 where text in (
   'Gouverner, c''est choisir, si difficiles que soient les choix.',
   'Qui imagine le général de Gaulle mis en examen ?',
   'Nous, quand on est convoqué par la police, on n''a pas d''immunité ouvrière.'
 )
   and exists (select 1 from public.cards c2 where c2.text in (
     'Gouverner, c''est choisir.',
     'Qui imagine un seul instant le général de Gaulle mis en examen ?',
     'Nous, quand on est convoqué par la police, nous n''avons pas d''immunité ouvrière, on y va.'));
