// src/services/cache.ts
const CACHE_PREFIX = 'tmdb-cache'
const CACHE_VERSION = 'v1'

interface CacheEntry<T> {
  version: string
  expiresAt: number
  data: T
}

function getStorageKey(key: string) {
  return `${CACHE_PREFIX}:${CACHE_VERSION}:${key}`
}

export function getCachedData<T>(key: string): T | null {
  if (typeof window === 'undefined') return null
  try {
    const raw = window.localStorage.getItem(getStorageKey(key))
    if (!raw) return null
    const entry = JSON.parse(raw) as CacheEntry<T>
    if (entry.expiresAt < Date.now()) {
      window.localStorage.removeItem(getStorageKey(key))
      return null
    }
    return entry.data
  } catch (err) {
    console.warn('[cache] failed to parse cache entry', err)
    window.localStorage.removeItem(getStorageKey(key))
    return null
  }
}

export function setCachedData<T>(key: string, data: T, ttlMs: number) {
  if (typeof window === 'undefined') return
  try {
    const entry: CacheEntry<T> = {
      version: CACHE_VERSION,
      expiresAt: Date.now() + ttlMs,
      data,
    }
    window.localStorage.setItem(getStorageKey(key), JSON.stringify(entry))
  } catch (err) {
    console.warn('[cache] failed to store cache entry', err)
  }
}

export function clearCacheByPrefix(prefix: string) {
  if (typeof window === 'undefined') return
  const targetPrefix = `${CACHE_PREFIX}:${CACHE_VERSION}:${prefix}`
  const keys = Object.keys(window.localStorage)
  keys.forEach((key) => {
    if (key.startsWith(targetPrefix)) {
      window.localStorage.removeItem(key)
    }
  })
}
