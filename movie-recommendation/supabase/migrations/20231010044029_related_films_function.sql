-- Set index on embedding column
create index on films using hnsw (embedding vector_cosine_ops);

-- Create function to find related films
create or replace function get_related_film(embedding vector(1536), film_id integer)
returns setof films
language sql
as $$
    select *
    from films
    where id != film_id
    order by films.embedding <=> get_related_film.embedding
    limit 6;
$$ security invoker;