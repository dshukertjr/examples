-- Enable pgvector extension
create extension vector
with
  schema extensions;

-- Create table
create table public.movies (
  id integer primary key,
  title text,
  overview text,
  release_date date,
  backdrop_path text,
  embedding vector(1536)
);

-- Enable row level security
alter table public.movies enable row level security;

-- Create policy to allow anyone to read the movies table
create policy "Fils are public." on public.movies for select using (true);
 