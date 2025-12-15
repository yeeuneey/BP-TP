// src/services/tmdb.ts
import axios, { isAxiosError, type AxiosInstance } from 'axios'
import { getStoredTmdbKey } from './auth'
import { TMDB_BASE_URL, TMDB_ENDPOINTS } from './URL'
import { getCachedData, setCachedData } from './cache'

const LANGUAGE = 'ko-KR'
const DEFAULT_CACHE_TTL_MS = 1000 * 60 * 5 // 5분
const DETAIL_CACHE_TTL_MS = 1000 * 60 * 30 // 30분
const GENRE_CACHE_TTL_MS = 1000 * 60 * 60 * 24 // 24시간

export interface TmdbMovie {
  id: number
  title: string
  overview: string
  poster_path: string | null
  vote_average?: number
  release_date?: string
  genre_ids?: number[]
}

export interface TmdbMovieDetail extends TmdbMovie {
  backdrop_path?: string | null
  runtime?: number
  genres?: TmdbGenre[]
  homepage?: string | null
  tagline?: string | null
  status?: string
}

export interface TmdbResponse {
  page: number
  results: TmdbMovie[]
  total_pages: number
}

export interface TmdbGenre {
  id: number
  name: string
}

class TmdbService {
  private readonly client: AxiosInstance
  private readonly language: string
  private readonly envKey = import.meta.env.VITE_TMDB_API_KEY as string | undefined

  constructor(language = LANGUAGE) {
    this.language = language
    this.client = axios.create({
      baseURL: TMDB_BASE_URL,
    })
  }

  private isV4Token(key: string) {
    return key.startsWith('eyJ')
  }

  private getApiKeyOrThrow(): string {
    const key = this.envKey || getStoredTmdbKey()
    if (!key) {
      throw new Error('TMDB API Key가 없습니다. 로그인 화면에서 다시 입력해 주세요.')
    }
    return key
  }

  private buildHeaders(key: string) {
    if (this.isV4Token(key)) {
      return { Authorization: `Bearer ${key}` }
    }
    return {}
  }

  private async request<T>({
    endpoint,
    params = {},
    cacheKey,
    cacheTtl = DEFAULT_CACHE_TTL_MS,
  }: {
    endpoint: string
    params?: Record<string, string | number>
    cacheKey?: string
    cacheTtl?: number
  }): Promise<T> {
    if (cacheKey) {
      const cached = getCachedData<T>(cacheKey)
      if (cached) return cached
    }

    const apiKey = this.getApiKeyOrThrow()
    const finalParams: Record<string, string | number> = {
      language: this.language,
      ...params,
    }

    if (!this.isV4Token(apiKey)) {
      finalParams.api_key = apiKey
    }

    try {
      const { data } = await this.client.get<T>(endpoint, {
        params: finalParams,
        headers: this.buildHeaders(apiKey),
      })

      if (cacheKey) {
        setCachedData(cacheKey, data, cacheTtl)
      }

      return data
    } catch (error) {
      if (isAxiosError(error)) {
        const statusMessage =
          typeof error.response?.data === 'object'
            ? (error.response?.data as { status_message?: string })?.status_message
            : null
        throw new Error(statusMessage ?? 'TMDB 요청이 실패했습니다. 잠시 후 다시 시도해 주세요.')
      }
      throw error
    }
  }

  async fetchPopularMovies(page = 1): Promise<TmdbResponse> {
    return this.request<TmdbResponse>({
      endpoint: TMDB_ENDPOINTS.popular,
      params: { page },
      cacheKey: `popular:${page}`,
    })
  }

  async fetchNowPlayingMovies(page = 1): Promise<TmdbResponse> {
    return this.request<TmdbResponse>({
      endpoint: TMDB_ENDPOINTS.nowPlaying,
      params: { page },
      cacheKey: `now:${page}`,
    })
  }

  async fetchDiscoverMovies(extraParams = '', page = 1): Promise<TmdbResponse> {
    const params: Record<string, string | number> = { page }
    if (extraParams) {
      const search = new URLSearchParams(extraParams.startsWith('&') ? extraParams.slice(1) : extraParams)
      search.forEach((value, key) => {
        params[key] = value
      })
    }

    return this.request<TmdbResponse>({
      endpoint: TMDB_ENDPOINTS.discover,
      params,
      cacheKey: `discover:${page}:${extraParams}`,
    })
  }

  async searchMovies(query: string, page = 1): Promise<TmdbResponse> {
    return this.request<TmdbResponse>({
      endpoint: TMDB_ENDPOINTS.search,
      params: { query, page },
      cacheKey: `search:${query}:${page}`,
    })
  }

  async fetchGenres(): Promise<TmdbGenre[]> {
    const data = await this.request<{ genres: TmdbGenre[] }>({
      endpoint: TMDB_ENDPOINTS.genres,
      cacheKey: 'genres',
      cacheTtl: GENRE_CACHE_TTL_MS,
    })
    return data.genres
  }

  async fetchMovieDetail(movieId: number): Promise<TmdbMovieDetail> {
    return this.request<TmdbMovieDetail>({
      endpoint: TMDB_ENDPOINTS.detail(movieId),
      cacheKey: `detail:${movieId}`,
      cacheTtl: DETAIL_CACHE_TTL_MS,
    })
  }
}

const tmdbService = new TmdbService()

export const fetchPopularMovies = (page = 1) => tmdbService.fetchPopularMovies(page)
export const fetchNowPlayingMovies = (page = 1) => tmdbService.fetchNowPlayingMovies(page)
export const fetchDiscoverMovies = (extraParams = '', page = 1) =>
  tmdbService.fetchDiscoverMovies(extraParams, page)
export const searchMovies = (query: string, page = 1) => tmdbService.searchMovies(query, page)
export const fetchGenres = () => tmdbService.fetchGenres()
export const fetchMovieDetail = (movieId: number) => tmdbService.fetchMovieDetail(movieId)
