import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.7'

interface Movie {
  id: number
  title: string
  overview: string
  release_date: string
  backdrop_path: string
}

interface MovieWithEmbedding extends Movie {
  embedding: number[]
}

Deno.serve(async (req) => {
  // Get the environment variables
  // const supabaseUrl = Deno.env.get('SUPABASE_URL') as string
  // const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') as string
  const supabaseUrl = Deno.env.get('SUPABASE_URL') as string
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') as string

  /** API key for TMDB API */
  const tmdbApiKey = Deno.env.get('TMDB_API_KEY')

  /** API key for Open AI API */
  const openAiApiKey = Deno.env.get('OPEN_AI_API_KEY')

  const supabase = createClient(supabaseUrl, serviceKey)

  const year = new URLSearchParams(req.url.split('?')[1]).get('year')

  if (!year) {
    throw new Error('Year is required')
  }

  const moviesWithEmbeddings: MovieWithEmbedding[] = []

  const searchParams = new URLSearchParams()
  searchParams.set('sort_by', 'popularity.desc')
  searchParams.set('page', '1')
  searchParams.set('language', 'en-US')
  searchParams.set('primary_release_year', `${year}`)
  searchParams.set('include_adult', 'false')
  searchParams.set('include_video', 'false')
  searchParams.set('region', 'US')
  searchParams.set('watch_region', 'US')
  searchParams.set('with_original_language', 'en')

  const tmdbResponse = await fetch(
    `https://api.themoviedb.org/3/discover/movie?${searchParams.toString()}`,
    {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${tmdbApiKey}`,
      },
    }
  )

  const tmdbJson = await tmdbResponse.json()

  const tmdbStatus = tmdbResponse.status
  if (!(200 <= tmdbStatus && tmdbStatus <= 299)) {
    throw new Error('Error retrieving data from tmdb API')
  }

  const movies = tmdbJson.results as Movie[]

  for (const movie of movies) {
    const response = await fetch('https://api.openai.com/v1/embeddings', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${openAiApiKey}`,
      },
      body: JSON.stringify({
        input: movie.overview,
        model: 'text-embedding-3-small',
      }),
    })

    const responseData = await response.json()
    if (responseData.error) {
      throw new Error(
        `Error obtaining Open API embedding: ${responseData.error.message}`
      )
    }

    const embedding = responseData.data[0].embedding

    moviesWithEmbeddings.push({
      id: movie.id,
      title: movie.title,
      overview: movie.overview,
      release_date: movie.release_date,
      backdrop_path: movie.backdrop_path,
      embedding,
    })
  }

  const { error } = await supabase.from('movies').upsert(moviesWithEmbeddings)

  if (error) {
    throw new Error(`Error inserting data into supabase: ${error.message}`)
  }

  return new Response(
    JSON.stringify({
      message: `Done!`,
    }),
    {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    }
  )
})
