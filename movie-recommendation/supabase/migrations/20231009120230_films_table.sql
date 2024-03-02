-- Enable pgvector extension
create extension vector
with
  schema extensions;

-- Create table
create table public.films (
  id integer primary key,
  title text,
  overview text,
  release_date date,
  backdrop_path text,
  embedding vector(1536)
);

-- Enable row level security
alter table public.films enable row level security;

-- Create policy to allow anyone to read the films table
create policy "Fils are public." on public.films for select using (true);
