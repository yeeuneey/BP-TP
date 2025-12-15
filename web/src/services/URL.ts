// src/services/URL.ts
export const TMDB_BASE_URL = 'https://api.themoviedb.org/3'
export const TMDB_IMAGE_BASE_URL = 'https://image.tmdb.org/t/p'

export const TMDB_ENDPOINTS = {
  popular: '/movie/popular',
  nowPlaying: '/movie/now_playing',
  discover: '/discover/movie',
  search: '/search/movie',
  genres: '/genre/movie/list',
  detail: (id: number) => `/movie/${id}`,
} as const

export const TMDB_IMAGE_SIZES = {
  thumbnail: 'w200',
  card: 'w342',
  poster: 'w500',
  backdrop: 'original',
} as const

export function buildImageUrl(path?: string | null, size: string = TMDB_IMAGE_SIZES.poster) {
  if (!path) return ''
  return `${TMDB_IMAGE_BASE_URL}/${size}${path}`
}
