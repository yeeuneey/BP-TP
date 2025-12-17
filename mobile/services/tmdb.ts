import Constants from 'expo-constants'

export interface TmdbMovie {
  id: number
  title: string
  overview: string
  poster_path: string | null
  vote_average?: number
  release_date?: string
}

const extra = Constants.expoConfig?.extra as { tmdbApiKey?: string } | undefined
const API_KEY = process.env.EXPO_PUBLIC_TMDB_API_KEY ?? extra?.tmdbApiKey
const BASE_URL = 'https://api.themoviedb.org/3'
const LANG = 'ko-KR'

if (!API_KEY) {
  throw new Error('Missing TMDB API key')
}

async function request<T>(endpoint: string, params: Record<string, string | number> = {}) {
  const url = new URL(`${BASE_URL}${endpoint}`)
  url.searchParams.set('api_key', API_KEY)
  url.searchParams.set('language', LANG)
  Object.entries(params).forEach(([k, v]) => url.searchParams.set(k, String(v)))

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
export const searchMovies = (query: string) =>
  request<TmdbResponse>('/search/movie', { query }).then((r) => r.results)

// Use a smaller width to reduce payload and speed up scrolling.
export const posterUrl = (path: string | null) =>
  path ? `https://image.tmdb.org/t/p/w342${path}` : undefined
