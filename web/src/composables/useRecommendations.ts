// src/composables/useRecommendations.ts
import { ref } from 'vue'
import { onAuthStateChanged } from 'firebase/auth'
import { doc, getDoc, setDoc } from 'firebase/firestore'
import type { TmdbMovie } from '@/services/tmdb'
import { auth, db } from '@/services/firebase'
import { ensureAuthReady } from '@/services/auth'

const LEGACY_STORAGE_KEY = 'recommendedMovies'
const COLLECTION_NAME = 'recommended'

export interface RecommendedMovie {
  id: number
  title: string
  poster_path: string | null
  poster?: string | null
}

class RecommendationManager {
  recommendations = ref<RecommendedMovie[]>([])
  loading = ref(false)
  error = ref<string | null>(null)
  private currentUserId: string | null = null
  private isAuthReady = false

  constructor() {
    this.bootstrapAuthListener()
  }

  private async bootstrapAuthListener() {
    await ensureAuthReady()
    onAuthStateChanged(auth, async (user) => {
      this.currentUserId = user?.uid ?? null
      this.isAuthReady = true
      if (user) {
        await this.load()
      } else {
        this.recommendations.value = []
      }
    })
  }

  private normalize(items: RecommendedMovie[]): RecommendedMovie[] {
    return items.map((item) => ({
      ...item,
      poster_path: item.poster_path ?? this.extractPosterPath(item.poster),
    }))
  }

  private extractPosterPath(poster?: string | null) {
    if (!poster) return null
    const match = poster.match(/image\.tmdb\.org\/t\/p\/[^/]+(\/.+)$/)
    return match?.[1] ?? null
  }

  private readLegacy(): RecommendedMovie[] {
    const raw = localStorage.getItem(LEGACY_STORAGE_KEY)
    if (!raw) return []
    try {
      return JSON.parse(raw) as RecommendedMovie[]
    } catch {
      return []
    }
  }

  private async load() {
    if (!this.currentUserId) {
      this.recommendations.value = []
      return
    }

    this.loading.value = true
    this.error.value = null
    try {
      const docRef = doc(db, COLLECTION_NAME, this.currentUserId)
      const snap = await getDoc(docRef)
      const remoteItems = snap.exists() ? ((snap.data().items as RecommendedMovie[]) ?? []) : []
      const merged = this.mergeWithLegacy(remoteItems)
      const normalized = this.normalize(merged)

      if (normalized.length !== remoteItems.length) {
        await setDoc(docRef, { items: normalized }, { merge: true })
      }

      this.recommendations.value = normalized
    } catch (err: unknown) {
      this.error.value = err instanceof Error ? err.message : '추천 목록을 불러오지 못했습니다.'
      this.recommendations.value = []
    } finally {
      this.loading.value = false
    }
  }

  private mergeWithLegacy(remote: RecommendedMovie[]): RecommendedMovie[] {
    const legacy = this.readLegacy()
    if (!legacy.length) return remote

    const map = new Map<number, RecommendedMovie>()
    remote.forEach((item) => map.set(item.id, item))
    legacy.forEach((item) => {
      if (!map.has(item.id)) {
        map.set(item.id, item)
      }
    })

    // Clear legacy storage after first sync
    localStorage.removeItem(LEGACY_STORAGE_KEY)
    return Array.from(map.values())
  }

  private async persist() {
    if (!this.currentUserId) return
    const docRef = doc(db, COLLECTION_NAME, this.currentUserId)
    await setDoc(docRef, { items: this.recommendations.value }, { merge: true })
  }

  isRecommended(movieId: number) {
    return this.recommendations.value.some((movie) => movie.id === movieId)
  }

  async toggleRecommendation(movie: TmdbMovie) {
    if (!this.isAuthReady || !this.currentUserId) {
      throw new Error('로그인이 필요합니다.')
    }

    const exists = this.isRecommended(movie.id)
    const payload: RecommendedMovie = {
      id: movie.id,
      title: movie.title,
      poster_path: movie.poster_path ?? null,
      poster: movie.poster_path ? `https://image.tmdb.org/t/p/w500${movie.poster_path}` : null,
    }

    const updated = exists
      ? this.recommendations.value.filter((item) => item.id !== movie.id)
      : [...this.recommendations.value, payload]

    this.recommendations.value = updated
    await this.persist()
  }
}

const manager = new RecommendationManager()

export function useRecommendations() {
  return {
    recommendations: manager.recommendations,
    loading: manager.loading,
    error: manager.error,
    toggleRecommendation: manager.toggleRecommendation.bind(manager),
    isRecommended: manager.isRecommended.bind(manager),
  }
}
