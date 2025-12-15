// src/composables/useRecommendations.ts
import { ref } from 'vue'
import type { TmdbMovie } from '@/services/tmdb'

const STORAGE_KEY = 'recommendedMovies'

export interface RecommendedMovie {
  id: number
  title: string
  poster_path: string | null
}

class RecommendationManager {
  recommendations = ref<RecommendedMovie[]>([])

  constructor() {
    this.load()
  }

  private load() {
    const raw = localStorage.getItem(STORAGE_KEY)
    if (!raw) return
    try {
      this.recommendations.value = JSON.parse(raw) as RecommendedMovie[]
    } catch {
      this.recommendations.value = []
    }
  }

  private persist() {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(this.recommendations.value))
  }

  isRecommended(movieId: number) {
    return this.recommendations.value.some((movie) => movie.id === movieId)
  }

  toggleRecommendation(movie: TmdbMovie) {
    const index = this.recommendations.value.findIndex((item) => item.id === movie.id)
    if (index === -1) {
      this.recommendations.value.push({
        id: movie.id,
        title: movie.title,
        poster_path: movie.poster_path,
      })
    } else {
      this.recommendations.value.splice(index, 1)
    }
    this.persist()
  }
}

const manager = new RecommendationManager()

export function useRecommendations() {
  return {
    recommendations: manager.recommendations,
    toggleRecommendation: manager.toggleRecommendation.bind(manager),
    isRecommended: manager.isRecommended.bind(manager),
  }
}
