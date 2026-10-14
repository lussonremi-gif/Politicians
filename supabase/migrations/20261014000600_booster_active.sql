-- Boosters désactivables (masqués dans la boutique sans supprimer l'historique d'ouverture)
alter table public.booster_types add column active boolean not null default true;
update public.booster_types set active = false where slug like 'candidat-demo-%';
