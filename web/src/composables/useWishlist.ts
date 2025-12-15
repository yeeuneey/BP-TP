// src/composables/useWishlist.ts
import { ref } from 'vue'
import type { TmdbMovie } from '@/services/tmdb'

const STORAGE_KEY = 'movieWishlist'

export interface WishlistMovie {
  id: number
  title: string
  poster_path: string | null
}

class WishlistManager {
  wishlist = ref<WishlistMovie[]>([])

  constructor() {
    this.loadWishlist()
  }

  private loadWishlist() {
    const raw = localStorage.getItem(STORAGE_KEY)
    if (raw) {
      try {
        this.wishlist.value = JSON.parse(raw) as WishlistMovie[]
      } catch {
        this.wishlist.value = []
      }
    }
  }

  private saveWishlist() {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(this.wishlist.value))
  }

  isInWishlist(movieId: number): boolean {
    return this.wishlist.value.some((m) => m.id === movieId)
  }

  toggleWishlist(movie: TmdbMovie) {
    const index = this.wishlist.value.findIndex((item) => item.id === movie.id)
    if (index === -1) {
      this.wishlist.value.push({
        id: movie.id,
        title: movie.title,
        poster_path: movie.poster_path,
      })
    } else {
      this.wishlist.value.splice(index, 1)
    }
    this.saveWishlist()
  }
}

// 싱글톤 비슷하게 한 번만 만들고 재사용
const manager = new WishlistManager()

export function useWishlist() {
  return {
    wishlist: manager.wishlist,
    toggleWishlist: manager.toggleWishlist.bind(manager),
    isInWishlist: manager.isInWishlist.bind(manager),
  }
}
