-- « Qui l'a dit ? » : stockage des portraits (lecture publique, écriture réservée aux éditeurs)
-- Ne déposer que des images dont les droits sont acquis ; renseigner ensuite personalities.image_url.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('portraits', 'portraits', true, 2097152, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do nothing;

create policy "editors upload portraits" on storage.objects for insert to authenticated
  with check (bucket_id = 'portraits' and public.is_editor());
create policy "editors update portraits" on storage.objects for update to authenticated
  using (bucket_id = 'portraits' and public.is_editor());
create policy "editors delete portraits" on storage.objects for delete to authenticated
  using (bucket_id = 'portraits' and public.is_editor('admin'));
