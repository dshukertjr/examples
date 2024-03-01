create extension vector with schema extensions;

create table if not exists public.posts (
    id uuid primary key not null default gen_random_uuid(),
    content text not null,
    created_at timestamp with time zone not null default now(),
    embedding vector(768),
    open_ai_embedding vector(1536)
);

-- Enable realtime
alter publication supabase_realtime add table public.posts;

create index on public.posts using hnsw (embedding vector_cosine_ops);

-- Create function to find related posts
create or replace function get_related_posts(
    embedding vector(768),
    open_ai_embedding vector(1536),
    post_id uuid,
    match_threshold float,
    match_count int
)
returns table (
    id posts.id%type,
    content posts.content%type,
    created_at posts.created_at%type,
    embedding posts.embedding%type,
    open_ai_embedding posts.open_ai_embedding%type,
    similarity float,
    open_ai_similarity float
)
language sql
as $$
    select
        *,
        1 - (posts.embedding <=> get_related_posts.embedding) as similarity,
        1 - (posts.open_ai_embedding <=> get_related_posts.open_ai_embedding) as open_ai_similarity
    from posts
    where id != post_id
        and posts.embedding <=> get_related_posts.embedding < 1 - match_threshold
    order by posts.embedding <=> get_related_posts.embedding
    limit match_count;
$$ security invoker;