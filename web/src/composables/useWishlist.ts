import { ref } from 'vue'
import { doc, getDoc, setDoc } from 'firebase/firestore'
import { onAuthStateChanged } from 'firebase/auth'
import type { TmdbMovie } from '@/services/tmdb'
import { auth, db } from '@/services/firebase'
import { ensureAuthReady } from '@/services/auth'

export interface WishlistMovie {
  id: number
  title: string
  poster_path: string | null
}

class WishlistManager {
  wishlist = ref<WishlistMovie[]>([])
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
        await this.loadWishlist()
      } else {
        this.wishlist.value = []
      }
    })
  }

  private async loadWishlist() {
    if (!this.currentUserId) {
      this.wishlist.value = []
      return
    }

    this.loading.value = true
    this.error.value = null
    try {
      const docRef = doc(db, 'wishlists', this.currentUserId)
      const snap = await getDoc(docRef)
      const items = snap.exists() ? ((snap.data().items as WishlistMovie[]) ?? []) : []
      this.wishlist.value = items
    } catch (err: unknown) {
      this.error.value = err instanceof Error ? err.message : '위시리스트를 불러오지 못했습니다.'
      this.wishlist.value = []
    } finally {
      this.loading.value = false
    }
  }

  isInWishlist(movieId: number): boolean {
    return this.wishlist.value.some((m) => m.id === movieId)
  }

  async toggleWishlist(movie: TmdbMovie) {
    if (!this.isAuthReady || !this.currentUserId) {
      throw new Error('로그인이 필요합니다.')
    }

    const exists = this.isInWishlist(movie.id)
    const updated = exists
      ? this.wishlist.value.filter((item) => item.id !== movie.id)
      : [
          ...this.wishlist.value,
          {
            id: movie.id,
            title: movie.title,
            poster_path: movie.poster_path ?? null,
          },
        ]

    const docRef = doc(db, 'wishlists', this.currentUserId)
    await setDoc(docRef, { items: updated }, { merge: true })
    this.wishlist.value = updated
  }
}

const manager = new WishlistManager()

export function useWishlist() {
  return {
    wishlist: manager.wishlist,
    loading: manager.loading,
    error: manager.error,
    toggleWishlist: manager.toggleWishlist.bind(manager),
    isInWishlist: manager.isInWishlist.bind(manager),
  }
}
