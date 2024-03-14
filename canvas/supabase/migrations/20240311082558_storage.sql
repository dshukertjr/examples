-- file size limit of 5MB
insert into storage.buckets
    (id, name, public, file_size_limit, allowed_mime_types)
    values ('canvas_objects', 'canvas_objects', true, 5242880, '{"image/jpg","image/jpeg","image/png"}');
create policy "Users can select storage objects" on storage.objects for select using (bucket_id = 'canvas_objects');
create policy "Users can insert storage objects" on storage.objects for insert with check (bucket_id = 'canvas_objects');
create policy "Users can update storage objects" on storage.objects for update using (bucket_id = 'canvas_objects');
create policy "Users can delete storage objects" on storage.objects for delete using (bucket_id = 'canvas_objects');