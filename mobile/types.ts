export type Mode = 'login' | 'signup'
export type TabKey = 'home' | 'popular' | 'search' | 'wishlist'
export type SearchSort = 'popular' | 'latest' | 'rating' | 'title'
export type SearchGenre =
  | 'all'
  | '액션'
  | '어드벤처'
  | '애니메이션'
  | '코미디'
  | '범죄'
  | '드라마'
  | '판타지'
  | '공포'
  | '로맨스'
  | 'SF'
  | '스릴러'
export type SearchLanguage = 'all' | 'ko' | 'en' | 'ja'
export type SearchYearRange = 'all' | '2020+' | '2010s' | '2000s' | '1990s' | 'pre1990'

export interface Movie {
  id: number
  title: string
  overview: string
  poster: string | undefined
  rating?: number
  releaseDate?: string
  runtime?: number
  country?: string
  genres?: string[]
  language?: string
}

export interface WishlistItem {
  id: number
  title: string
  poster: string | undefined
}
