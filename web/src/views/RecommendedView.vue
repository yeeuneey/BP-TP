<template>
  <main class="recommended-page page-shell">
    <header class="page-header">
      <p class="page-eyebrow">My Recommendations</p>
      <h1>추천한 영화</h1>
      <p class="page-subtitle">
        카드 클릭으로 추천한 영화들을 한 곳에서 확인하고 필요하면 다시 취소할 수 있어요.
      </p>
    </header>

    <section class="panel recommended-panel">
      <p v-if="loading" class="info-text">추천 목록을 불러오는 중입니다...</p>
      <p v-else-if="!recommendations.length" class="empty-text">
        아직 추천한 영화가 없습니다. 메인, 인기, 검색 페이지에서 카드를 클릭해 추천을 추가해 보세요.
      </p>

      <div v-else class="recommended-grid">
        <article
          v-for="movie in recommendations"
          :key="movie.id"
          class="recommended-card"
        >
          <img
            v-if="getPosterSrc(movie)"
            :src="getPosterSrc(movie)"
            :alt="movie.title"
            loading="lazy"
          />
          <div v-else class="recommended-card__placeholder">No Image</div>

          <div class="recommended-card__body">
            <div>
              <h3>{{ movie.title }}</h3>
              <p class="recommended-card__meta">TMDB #{{ movie.id }}</p>
            </div>
            <button type="button" class="remove-btn" @click="handleRemove(movie.id)">
              추천 취소
            </button>
          </div>
        </article>
      </div>

      <p v-if="!loading && recommendations.length" class="info-text">
        추천 목록은 계정에 저장되어 웹과 앱에서 동일하게 확인할 수 있습니다.
      </p>
    </section>
  </main>
</template>

<script setup lang="ts">
import { useRecommendations, type RecommendedMovie } from '@/composables/useRecommendations'
import type { TmdbMovie } from '@/services/tmdb'

const { recommendations, loading, toggleRecommendation } = useRecommendations()

function getPosterSrc(movie: RecommendedMovie) {
  if (movie.poster_path) return `https://image.tmdb.org/t/p/w300${movie.poster_path}`
  if (movie.poster) return movie.poster
  return ''
}

function handleRemove(movieId: number) {
  const movie = recommendations.value.find((item) => item.id === movieId)
  if (!movie) return

  const payload: TmdbMovie = {
    id: movie.id,
    title: movie.title,
    poster_path: movie.poster_path,
    overview: '',
  }
  toggleRecommendation(payload)
}
</script>

<style scoped>
.recommended-page {
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

.recommended-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));
  gap: 1rem;
}

.recommended-card {
  background: var(--color-card);
  border-radius: var(--radius-md);
  border: 1px solid rgba(255, 255, 255, 0.08);
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

.recommended-card img,
.recommended-card__placeholder {
  width: 100%;
  height: 320px;
  object-fit: cover;
  background: #111827;
}

.recommended-card__placeholder {
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--color-muted);
  text-transform: uppercase;
  letter-spacing: 0.15em;
}

.recommended-card__body {
  padding: var(--space-md);
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-sm);
}

.recommended-card__body h3 {
  margin: 0;
  font-size: 1rem;
}

.recommended-card__meta {
  margin: 0.2rem 0 0;
  font-size: 0.85rem;
  color: var(--color-muted);
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
}

.remove-btn:hover {
  transform: translateY(-1px);
  box-shadow: 0 4px 14px rgba(229, 9, 20, 0.4);
}

.info-text {
  margin-top: 1rem;
  font-size: 0.85rem;
  color: var(--color-muted);
}

@media (max-width: 640px) {
  .recommended-card img,
  .recommended-card__placeholder {
    height: 260px;
  }
}
</style>
