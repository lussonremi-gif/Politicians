-- Carte Prime : on reprend la photo habituelle de Marine Tondelier (celle de sa fiche).
update public.cards
   set image_url = null, image_credit = null, image_license = null, image_source_url = null
 where rarity = 'babies';
