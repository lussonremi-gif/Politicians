-- « Qui l'a dit ? » : constitution et vérification de la base de citations
--
-- Rôles éditoriaux (attribués par un admin dans la table `editors`) :
--   contributor : propose des personnalités et des citations (non vérifiées)
--   verifier    : contrôle la source et valide (verify_quote)
--   admin       : tout, y compris boosters et rôles
-- Seules les citations vérifiées entrent dans le jeu.

create table public.editors (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role text not null check (role in ('contributor', 'verifier', 'admin')),
  created_at timestamptz not null default now()
);
alter table public.editors enable row level security;

create function public.editor_role()
returns text
language sql stable security definer set search_path = public as $$
  select role from editors where user_id = auth.uid();
$$;

create function public.is_editor(p_min_role text default 'contributor')
returns boolean
language sql stable security definer set search_path = public as $$
  select coalesce(
    (select case p_min_role
              when 'contributor' then true
              when 'verifier' then e.role in ('verifier', 'admin')
              when 'admin' then e.role = 'admin'
            end
       from editors e where e.user_id = auth.uid()),
    false);
$$;

create policy "editors read editors" on public.editors for select using (public.is_editor());
create policy "admins manage editors" on public.editors for all
  using (public.is_editor('admin')) with check (public.is_editor('admin'));

-- Personnalités
create policy "editors insert personalities" on public.personalities for insert
  with check (public.is_editor());
create policy "editors update personalities" on public.personalities for update
  using (public.is_editor()) with check (public.is_editor());
create policy "admins delete personalities" on public.personalities for delete
  using (public.is_editor('admin'));

-- Citations : les éditeurs voient tout ; un contributeur ne peut ni créer ni modifier
-- une citation vérifiée.
create policy "editors read quotes" on public.quotes for select using (public.is_editor());
create policy "contributors insert drafts" on public.quotes for insert
  with check (public.is_editor() and (not verified or public.is_editor('verifier')));
create policy "editors update quotes" on public.quotes for update
  using (public.is_editor() and (not verified or public.is_editor('verifier')))
  with check (not verified or public.is_editor('verifier'));
create policy "verifiers delete quotes" on public.quotes for delete
  using (public.is_editor('verifier'));

-- Boosters
create policy "admins manage boosters" on public.booster_types for all
  using (public.is_editor('admin')) with check (public.is_editor('admin'));

-- Validation d'une citation : exige une source, trace qui a vérifié et quand
create function public.verify_quote(p_quote uuid, p_verified boolean default true)
returns void
language plpgsql security definer set search_path = public as $$
declare
  q record;
begin
  if not public.is_editor('verifier') then raise exception 'forbidden'; end if;
  select * into q from quotes where id = p_quote for update;
  if not found then raise exception 'quote not found'; end if;
  if p_verified and (q.source_url is null and q.source_label is null) then
    raise exception 'source required';
  end if;
  if p_verified and q.said_on is null then raise exception 'date required'; end if;
  update quotes
     set verified = p_verified,
         verified_by = case when p_verified then auth.uid() end,
         verified_at = case when p_verified then now() end
   where id = p_quote;
end $$;

-- Tableau de bord de neutralité : cartes vérifiées par candidat et par rareté
create view public.candidate_balance with (security_invoker = true) as
select p.id as personality_id, p.name,
       count(q.id) filter (where q.verified) as verified_total,
       count(q.id) filter (where q.verified and q.rarity = 'common') as common,
       count(q.id) filter (where q.verified and q.rarity = 'rare') as rare,
       count(q.id) filter (where q.verified and q.rarity = 'legendary') as legendary,
       count(q.id) filter (where not q.verified) as pending
  from public.personalities p
  left join public.quotes q on q.personality_id = p.id
 where p.kind = 'candidate'
 group by p.id, p.name;
revoke all on public.candidate_balance from anon;

-- File de vérification
create view public.quotes_to_verify with (security_invoker = true) as
select q.id, q.text, p.name as author, q.said_on, q.occasion, q.source_label, q.source_url,
       q.theme, q.rarity, q.created_at
  from public.quotes q join public.personalities p on p.id = q.personality_id
 where not q.verified
 order by q.created_at;
revoke all on public.quotes_to_verify from anon;

revoke execute on function public.verify_quote(uuid, boolean) from public, anon;
grant execute on function public.verify_quote(uuid, boolean) to authenticated;
grant execute on function public.is_editor(text) to anon, authenticated;
revoke execute on function public.editor_role() from public, anon;
grant execute on function public.editor_role() to authenticated;
