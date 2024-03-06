-- Set index on embedding column
create index on movies using hnsw (embedding vector_cosine_ops);

-- Create function to find related movies
create or replace function get_related_movie(embedding vector(1536), movie_id integer)
returns setof movies
language sql
as $$
    select *
    from movies
    where id != movie_id
    order by movies.embedding <=> get_related_movie.embedding
    limit 6;
$$ security invoker;