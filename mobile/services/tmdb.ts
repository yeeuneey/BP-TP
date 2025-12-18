import Constants from 'expo-constants'

export interface TmdbMovie {
  id: number
  title: string
  overview: string
  poster_path: string | null
  vote_average?: number
  release_date?: string
  genre_ids?: number[]
  origin_country?: string[]
  original_language?: string
}

interface TmdbGenre {
  id: number
  name: string
}

export interface TmdbMovieDetails {
  id: number
  title: string
  overview: string
  poster_path: string | null
  vote_average?: number
  release_date?: string
  original_language?: string
  genres?: TmdbGenre[]
  runtime?: number
  production_countries?: { iso_3166_1?: string; name?: string }[]
}

const extra = Constants.expoConfig?.extra as { tmdbApiKey?: string } | undefined
const API_KEY = process.env.EXPO_PUBLIC_TMDB_API_KEY ?? extra?.tmdbApiKey
const BASE_URL = 'https://api.themoviedb.org/3'
const LANG = 'ko-KR'

if (!API_KEY) {
  throw new Error('Missing TMDB API key')
}

async function request<T>(endpoint: string, params: Record<string, string | number | undefined> = {}) {
  const url = new URL(`${BASE_URL}${endpoint}`)
  url.searchParams.set('api_key', API_KEY)
  url.searchParams.set('language', LANG)
  Object.entries(params).forEach(([k, v]) => {
    if (v === undefined || v === '') return
    url.searchParams.set(k, String(v))
  })

  const res = await fetch(url.toString())
  if (!res.ok) {
    const text = await res.text()
    throw new Error(`TMDB error ${res.status}: ${text}`)
  }
  return res.json() as Promise<T>
}

interface TmdbResponse {
  results: TmdbMovie[]
}

export const fetchPopular = (page = 1) =>
  request<TmdbResponse>('/movie/popular', { page }).then((r) => r.results)
export const fetchNowPlaying = () =>
  request<TmdbResponse>('/movie/now_playing', { region: 'KR' }).then((r) => r.results)
export const fetchTopRated = () => request<TmdbResponse>('/movie/top_rated').then((r) => r.results)
export const searchMovies = (query: string, page = 1) =>
  request<TmdbResponse>('/search/movie', { query, page }).then((r) => r.results)
export const fetchMovieDetails = (id: number) =>
  request<TmdbMovieDetails>(`/movie/${id}`, { append_to_response: '' })

export const discoverMovies = (params: {
  page?: number
  sortBy?: string
  withOriginalLanguage?: string
  withGenres?: string
  primaryReleaseDateGte?: string
  primaryReleaseDateLte?: string
}) =>
  request<TmdbResponse>('/discover/movie', {
    page: params.page ?? 1,
    sort_by: params.sortBy ?? 'popularity.desc',
    with_original_language: params.withOriginalLanguage,
    with_genres: params.withGenres,
    'primary_release_date.gte': params.primaryReleaseDateGte,
    'primary_release_date.lte': params.primaryReleaseDateLte,
  }).then((r) => r.results)

// Use a smaller width to reduce payload and speed up scrolling.
export const posterUrl = (path: string | null) =>
  path ? `https://image.tmdb.org/t/p/w342${path}` : undefined
