create table canvas_objects (
    id uuid primary key default gen_random_uuid() not null,
    "object" jsonb not null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table canvas_objects enable row level security;
create policy select_canvas_objects on canvas_objects for select using (true);
create policy insert_canvas_objects on canvas_objects for insert with check (true);
create policy update_canvas_objects on canvas_objects for update using (true);