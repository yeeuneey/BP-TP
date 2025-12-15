<template>
  <main class="detail-page page-shell">
    <section v-if="isLoading" class="panel detail-panel">
      <LoaderSpinner />
    </section>

    <section v-else-if="error" class="panel detail-panel">
      <p class="error-text">{{ error }}</p>
      <RouterLink to="/" class="back-link">홈으로 돌아가기</RouterLink>
    </section>

    <section v-else-if="movie" class="panel detail-panel">
      <div class="detail-hero">
        <img
          v-if="movie.poster_path"
          :src="`https://image.tmdb.org/t/p/w500${movie.poster_path}`"
          :alt="movie.title"
        />
        <div v-else class="detail-placeholder">No Image</div>

        <div class="detail-meta">
          <p class="eyebrow">{{ movie.tagline || 'Movie Detail' }}</p>
          <h1>{{ movie.title }}</h1>
          <p class="detail-info">
            <span>{{ movie.release_date || '미정' }}</span>
            <span v-if="movie.runtime">· {{ movie.runtime }}분</span>
            <span v-if="movie.vote_average">· ⭐ {{ movie.vote_average.toFixed(1) }}</span>
          </p>
          <p class="detail-overview">{{ movie.overview }}</p>

          <div class="detail-actions">
            <button type="button" class="primary" @click="handleWishlist(movie)">
              {{ isInWishlist(movie.id) ? '위시리스트에서 제거' : '위시리스트에 추가' }}
            </button>
            <a
              v-if="movie.homepage"
              class="secondary"
              :href="movie.homepage"
              target="_blank"
              rel="noopener"
            >
              공식 사이트
            </a>
          </div>

          <div class="detail-genres" v-if="movie.genres?.length">
            <span v-for="genre in movie.genres" :key="genre.id">{{ genre.name }}</span>
          </div>
        </div>
      </div>
    </section>
  </main>
</template>

<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useRoute } from 'vue-router'

import LoaderSpinner from '@/components/common/LoaderSpinner.vue'
import { useWishlist } from '@/composables/useWishlist'
import { fetchMovieDetail, type TmdbMovieDetail } from '@/services/tmdb'

const route = useRoute()
const movie = ref<TmdbMovieDetail | null>(null)
const isLoading = ref(true)
const error = ref<string | null>(null)

const { toggleWishlist, isInWishlist } = useWishlist()

async function loadMovie() {
  const id = Number(route.params.id)
  if (!Number.isFinite(id)) {
    error.value = '잘못된 영화 ID입니다.'
    return
  }
  isLoading.value = true
  error.value = null
  try {
    movie.value = await fetchMovieDetail(id)
  } catch (err) {
    console.error(err)
    error.value = '영화 정보를 불러오지 못했습니다.'
  } finally {
    isLoading.value = false
  }
}

function handleWishlist(detail: TmdbMovieDetail) {
  toggleWishlist({
    id: detail.id,
    title: detail.title,
    overview: detail.overview,
    poster_path: detail.poster_path,
    vote_average: detail.vote_average,
    release_date: detail.release_date,
    genre_ids: detail.genre_ids,
  })
}

onMounted(() => {
  window.scrollTo({ top: 0, behavior: 'auto' })
  void loadMovie()
})
</script>

<style scoped>
.detail-page {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  gap: var(--space-lg);
}

.detail-panel {
  min-height: 300px;
}

.detail-hero {
  display: grid;
  grid-template-columns: 260px 1fr;
  gap: var(--space-lg);
}

.detail-hero img,
.detail-placeholder {
  width: 100%;
  border-radius: var(--radius-md);
  object-fit: cover;
}

.detail-placeholder {
  display: flex;
  align-items: center;
  justify-content: center;
  background: #0f172a;
  color: #94a3b8;
  font-size: 0.9rem;
}

.detail-meta h1 {
  margin: 0.25rem 0 0.5rem;
}

.detail-meta .eyebrow {
  text-transform: uppercase;
  color: var(--color-muted);
  letter-spacing: 0.2em;
  font-size: 0.8rem;
  margin: 0;
}

.detail-info {
  margin: 0;
  color: var(--color-muted);
  display: flex;
  gap: 0.5rem;
  flex-wrap: wrap;
}

.detail-overview {
  margin-top: 0.75rem;
  color: #e2e8f0;
  line-height: 1.6;
}

[data-theme='light'] .detail-panel .detail-overview {
  color: #111827;
}

.detail-actions {
  display: flex;
  gap: 0.75rem;
  margin-top: 1rem;
  flex-wrap: wrap;
}

.detail-actions button,
.detail-actions a {
  border-radius: 999px;
  padding: 0.55rem 1.4rem;
  font-weight: 600;
}

.detail-actions .primary {
  border: none;
  background: var(--color-accent);
  color: #fff;
  cursor: pointer;
}

.detail-actions .secondary {
  border: 1px solid rgba(255, 255, 255, 0.4);
  color: #fff;
}

.detail-genres {
  margin-top: 1rem;
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
  color: var(--color-muted);
}

.detail-genres span {
  border: 1px solid rgba(255, 255, 255, 0.15);
  border-radius: 999px;
  padding: 0.25rem 0.8rem;
  font-size: 0.8rem;
}

.back-link {
  display: inline-flex;
  margin-top: 0.75rem;
  color: var(--color-accent);
  font-weight: 600;
}

@media (max-width: 768px) {
  .detail-hero {
    grid-template-columns: 1fr;
  }
}
</style>
