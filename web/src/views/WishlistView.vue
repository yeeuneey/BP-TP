<template>
  <main class="wishlist-page page-shell">
    <header class="page-header">
      <p class="page-eyebrow">My Collection</p>
      <h1>Wishlist</h1>
      <p class="page-subtitle">
        마음에 드는 영화를 담아두고 기기 간에 동기화해 보세요.
      </p>
    </header>

    <section class="panel wishlist-panel">
      <p v-if="!wishlist.length" class="empty-text">
        아직 위시리스트가 비어 있어요. 영화를 찾아 <strong>Wishlist</strong> 버튼을 눌러보세요.
      </p>

      <div v-else class="wishlist-grid">
        <article
          v-for="movie in wishlist"
          :key="movie.id"
          class="wishlist-card"
        >
          <img
            v-if="getPosterSrc(movie)"
            :src="getPosterSrc(movie)"
            :alt="movie.title"
            loading="lazy"
          />
          <div v-else class="wishlist-card__placeholder">No Image</div>

          <div class="wishlist-card__body">
            <div>
              <h3>{{ movie.title }}</h3>
              <p class="wishlist-card__meta">TMDB #{{ movie.id }}</p>
              <p class="wishlist-card__meta wishlist-card__meta--highlight">담은 영화</p>
            </div>
            <div class="wishlist-card__actions">
              <button type="button" class="remove-btn" @click="handleRemove(movie.id)">
                삭제
              </button>
              <button type="button" class="recommend-btn" disabled>
                추천 기능 없음
              </button>
            </div>
          </div>
        </article>
      </div>

      <p v-if="wishlist.length" class="info-text">
        위시리스트는 Firestore에 저장되어 로그인한 기기 간에 동기화됩니다.
      </p>
    </section>
  </main>
</template>

<script setup lang="ts">
import { useWishlist, type WishlistMovie } from '@/composables/useWishlist'

const { wishlist, toggleWishlist } = useWishlist()

function getPosterSrc(movie: WishlistMovie) {
  if (movie.poster_path) return `https://image.tmdb.org/t/p/w300${movie.poster_path}`
  if (movie.poster) return movie.poster
  return ''
}

function buildPayload(movieId: number) {
  const movie = wishlist.value.find((item) => item.id === movieId)
  if (!movie) return null

  const payload = {
    id: movie.id,
    title: movie.title,
    poster_path: movie.poster_path,
    overview: '',
  }
  return payload
}

function handleRemove(movieId: number) {
  const payload = buildPayload(movieId)
  if (!payload) return
  toggleWishlist(payload)
}
</script>

<style scoped>
.wishlist-page {
  display: flex;
  flex-direction: column;
  gap: var(--space-lg);
}

.page-header h1 {
  margin: 0.3rem 0 0;
}

.page-eyebrow {
  text-transform: uppercase;
  letter-spacing: 0.2em;
  color: var(--color-muted);
  margin: 0;
  font-size: 0.8rem;
}

.page-subtitle {
  color: var(--color-muted);
  margin: 0.4rem 0 0;
}

.empty-text {
  margin: 1rem 0 0;
  font-size: 0.95rem;
  color: var(--color-muted);
}

.wishlist-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));
  gap: 1rem;
}

.wishlist-card {
  background: var(--color-card);
  border-radius: var(--radius-md);
  border: 1px solid rgba(255, 255, 255, 0.08);
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

.wishlist-card img,
.wishlist-card__placeholder {
  width: 100%;
  height: 320px;
  object-fit: cover;
  background: #111827;
}

.wishlist-card__placeholder {
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--color-muted);
  text-transform: uppercase;
  letter-spacing: 0.15em;
}

.wishlist-card__body {
  padding: var(--space-md);
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-sm);
}

.wishlist-card__body h3 {
  margin: 0;
  font-size: 1rem;
}

.wishlist-card__meta {
  margin: 0.2rem 0 0;
  font-size: 0.85rem;
  color: var(--color-muted);
}

.wishlist-card__meta--highlight {
  color: var(--color-accent);
  font-weight: 600;
  margin-top: 0.1rem;
}

.wishlist-card__actions {
  display: flex;
  gap: 0.5rem;
  flex-wrap: wrap;
}

.remove-btn {
  border-radius: 999px;
  border: none;
  background: var(--color-accent);
  color: #fff;
  font-size: 0.85rem;
  padding: 0.35rem 1.1rem;
  cursor: pointer;
  transition: transform 0.15s ease, box-shadow 0.15s ease;
  will-change: transform, box-shadow;
}

.remove-btn:hover {
  transform: translateY(-1px);
  box-shadow: 0 4px 14px rgba(229, 9, 20, 0.4);
}

.recommend-btn {
  border-radius: 999px;
  border: 1px solid var(--color-border);
  background: transparent;
  color: #fff;
  font-size: 0.85rem;
  padding: 0.35rem 1.1rem;
  cursor: pointer;
  transition: transform 0.15s ease, box-shadow 0.15s ease, background 0.15s ease;
}

.recommend-btn:hover {
  transform: translateY(-1px);
  box-shadow: 0 4px 14px rgba(229, 9, 20, 0.2);
  background: rgba(255, 255, 255, 0.04);
}

.info-text {
  margin-top: 1rem;
  font-size: 0.85rem;
  color: var(--color-muted);
}

@media (max-width: 640px) {
  .wishlist-card img,
  .wishlist-card__placeholder {
    height: 260px;
  }
}
</style>
