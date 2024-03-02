import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.38.0'

interface Film {
  id: number
  title: string
  overview: string
  release_date: string
  backdrop_path: string
}

interface SupabaseFilm extends Film {
  embedding: number[]
}

serve(async (req) => {
  // Get the environment variables
  const supabaseUrl = Deno.env.get('SUPABASE_URL')
  if (!supabaseUrl) {
    return returnError({
      message: 'Environment variable SUPABASE_URL is not set',
    })
  }
  const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
  if (!supabaseServiceKey) {
    return returnError({
      message: 'Environment variable SUPABASE_SERVICE_ROLE_KEY is not set',
    })
  }
  /** API key for TMDB API */
  const tmdbApiKey = Deno.env.get('TMDB_API_KEY')
  if (!tmdbApiKey) {
    return returnError({
      message: 'Environment variable TMDB_KEY is not set',
    })
  }
  /** API key for Open AI API */
  const openAiApiKey = Deno.env.get('OPEN_AI_API_KEY')
  if (!openAiApiKey) {
    return returnError({
      message: 'Environment variable OPEN_AI_API_KEY is not set',
    })
  }

  const supabase = createClient(supabaseUrl, supabaseServiceKey)

  const year = new URLSearchParams(req.url.split('?')[1]).get('year')

  if (!year) {
    return returnError({
      message: 'year parameter was not set',
    })
  }

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
    return returnError({
      message: 'Error retrieving data from tmdb API',
    })
  }

  const films = tmdbJson.results as Film[]

  const filmsWithEmbeddings: SupabaseFilm[] = []

  for (const film of films) {
    const response = await fetch('https://api.openai.com/v1/embeddings', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${openAiApiKey}`,
      },
      body: JSON.stringify({
        input: film.overview,
        model: 'text-embedding-ada-002',
      }),
    })

    const responseData = await response.json()
    if (responseData.error) {
      return returnError({
        message: `Error obtaining Open API embedding: ${responseData.error.message}`,
      })
    }

    const embedding = responseData.data[0].embedding

    filmsWithEmbeddings.push({
      id: film.id,
      title: film.title,
      overview: film.overview,
      release_date: film.release_date,
      backdrop_path: film.backdrop_path,
      embedding,
    })
  }

  const { error } = await supabase.from('films').upsert(filmsWithEmbeddings)

  if (error) {
    return returnError({
      message: error.message,
    })
  }

  return new Response(
    JSON.stringify({
      message: `${filmsWithEmbeddings.length} films added for year ${year}`,
    }),
    {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    }
  )
})

function returnError({
  message,
  status = 400,
}: {
  message: string
  status?: number
}) {
  return new Response(
    JSON.stringify({
      message,
    }),
    {
      status: status,
      headers: { 'Content-Type': 'application/json' },
    }
  )
}
