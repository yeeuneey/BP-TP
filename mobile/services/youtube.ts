import Constants from 'expo-constants'

export interface YoutubeVideo {
  id: string
  title: string
  channelTitle?: string
  thumbnail?: string
}

const extra = Constants.expoConfig?.extra as { youtubeApiKey?: string } | undefined
const API_KEY = process.env.EXPO_PUBLIC_YOUTUBE_API_KEY ?? extra?.youtubeApiKey
const BASE_URL = 'https://www.googleapis.com/youtube/v3'

async function request(endpoint: string, params: Record<string, string | number>) {
  if (!API_KEY) {
    console.warn('Missing YouTube API key; skipping trailer fetch')
    return { items: [] }
  }

  const url = new URL(`${BASE_URL}${endpoint}`)
  Object.entries(params).forEach(([key, value]) => url.searchParams.set(key, String(value)))
  url.searchParams.set('key', API_KEY)

  const res = await fetch(url.toString())
  if (!res.ok) {
    const text = await res.text()
    throw new Error(`YouTube error ${res.status}: ${text}`)
  }
  return res.json() as Promise<{ items: any[] }>
}

export async function fetchTrailerVideos(query = 'official movie trailer', maxResults = 6): Promise<YoutubeVideo[]> {
  const data = await request('/search', {
    part: 'snippet',
    q: query,
    maxResults,
    type: 'video',
    videoEmbeddable: 'true',
    safeSearch: 'moderate',
  })

  return (
    data.items
      ?.map((item) => {
        const id = item?.id?.videoId as string | undefined
        const snippet = item?.snippet ?? {}
        const thumb =
          snippet?.thumbnails?.maxres?.url ??
          snippet?.thumbnails?.high?.url ??
          snippet?.thumbnails?.medium?.url ??
          snippet?.thumbnails?.default?.url

        if (!id || !snippet?.title) return undefined
        return {
          id,
          title: snippet.title as string,
          channelTitle: snippet.channelTitle as string | undefined,
          thumbnail: thumb as string | undefined,
        }
      })
      .filter((item): item is YoutubeVideo => Boolean(item)) ?? []
  )
}
