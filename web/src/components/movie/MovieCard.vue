<!-- src/components/movie/MovieCard.vue -->
<template>
  <article
    class="movie-card"
    :class="{ 'movie-card--recommended': isRecommended, 'movie-card--touch': isTouchActive }"
    @click="handleCardClick"
    @touchstart.passive="handleTouchStart"
    @touchend.passive="handleTouchEnd"
    @touchcancel.passive="handleTouchEnd"
  >
    <div class="poster-wrap">
      <img
        v-if="posterUrl"
        :src="posterUrl"
        :srcset="posterSrcSet"
        sizes="(max-width: 600px) 45vw, 220px"
        :alt="movie.title"
        loading="lazy"
        decoding="async"
      />
      <div v-else class="poster-placeholder">No Image</div>
      <div class="poster-overlay" :class="{ 'poster-overlay--touch': isTouchActive }">
        <h3 class="overlay-title">{{ movie.title }}</h3>
        <p v-if="overviewText" class="overlay-overview">{{ overviewText }}</p>
        <div class="overlay-actions">
          <button
            type="button"
            class="wishlist-btn"
            :aria-pressed="!!isWishlisted"
            @click.stop="handleWishlistClick"
          >
            {{ isWishlisted ? '위시리스트 해제' : '위시리스트 담기' }}
          </button>
          <RouterLink class="detail-link" :to="`/movies/${movie.id}`">상세 보기</RouterLink>
        </div>
      </div>
    </div>
  </article>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue'
import type { TmdbMovie } from '@/services/tmdb'

const props = defineProps<{
  movie: TmdbMovie
  isWishlisted?: boolean
  isRecommended?: boolean
}>()

const emit = defineEmits<{
  (e: 'toggle-wishlist', movie: TmdbMovie): void
  (e: 'toggle-recommend', movie: TmdbMovie): void
}>()

const posterUrl = computed(() =>
  props.movie.poster_path ? `https://image.tmdb.org/t/p/w500${props.movie.poster_path}` : null,
)
const posterSrcSet = computed(() =>
  props.movie.poster_path
    ? `https://image.tmdb.org/t/p/w342${props.movie.poster_path} 342w, https://image.tmdb.org/t/p/w500${props.movie.poster_path} 500w`
    : undefined,
)
const overviewText = computed(() => {
  const text = props.movie.overview?.trim()
  if (!text) return ''
  return text.length > 90 ? `${text.slice(0, 90)}...` : text
})

const isTouchActive = ref(false)
let touchTimer: number | null = null

function handleCardClick() {
  emit('toggle-recommend', props.movie)
}

function handleWishlistClick() {
  emit('toggle-wishlist', props.movie)
}

function handleTouchStart() {
  if (touchTimer !== null) {
    window.clearTimeout(touchTimer)
    touchTimer = null
  }
  isTouchActive.value = true
}

function handleTouchEnd() {
  touchTimer = window.setTimeout(() => {
    isTouchActive.value = false
    touchTimer = null
  }, 120)
}
</script>

<style scoped>
.movie-card {
  position: relative;
  width: 100%;
  min-width: 140px;
  cursor: pointer;
  transition: transform 0.25s ease, box-shadow 0.25s ease;
  border-radius: 1rem;
  will-change: transform, box-shadow;
  transform: translateZ(0);
}

.poster-wrap {
  border-radius: 1rem;
  overflow: hidden;
  background: #111827;
  aspect-ratio: 2 / 3;
  position: relative;
}

.poster-wrap img {
  display: block;
  width: 100%;
  height: 100%;
  object-fit: cover;
  transition: transform 0.25s ease, filter 0.25s ease;
  will-change: transform;
}

.poster-placeholder {
  width: 100%;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #777;
  font-size: 0.8rem;
  text-transform: uppercase;
  letter-spacing: 0.15em;
}

.poster-overlay {
  position: absolute;
  inset: 0;
  padding: 1rem;
  display: flex;
  flex-direction: column;
  justify-content: flex-end;
  gap: 0.35rem;
  background: linear-gradient(180deg, rgba(3, 7, 18, 0) 20%, rgba(3, 7, 18, 0.85) 100%);
  opacity: 0;
  transform: translateY(20px);
  transition: opacity 0.25s ease, transform 0.25s ease;
  pointer-events: none;
}

.overlay-title {
  margin: 0;
  font-size: 1rem;
  color: #fff;
}

.overlay-overview {
  font-size: 0.78rem;
  line-height: 1.4;
  color: #e5e5e5;
}

.overlay-actions {
  display: flex;
  flex-wrap: wrap;
  gap: 0.4rem;
}

.movie-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 12px 35px rgba(0, 0, 0, 0.45);
}

.movie-card--touch {
  transform: scale(0.98);
  box-shadow: 0 8px 25px rgba(0, 0, 0, 0.35);
}

.movie-card:hover img {
  transform: scale(1.06);
  filter: brightness(0.85);
}

.movie-card:hover .poster-overlay,
.movie-card--touch .poster-overlay {
  opacity: 1;
  transform: translateY(0);
  pointer-events: auto;
}

.movie-card--recommended::after {
  content: '추천';
  position: absolute;
  top: 0.6rem;
  right: 0.6rem;
  width: 42px;
  height: 26px;
  border-radius: 50%;
  background: var(--color-accent);
  color: #fff;
  font-size: 0.85rem;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 6px 20px rgba(229, 9, 20, 0.35);
}

.wishlist-btn {
  border-radius: 999px;
  border: 1px solid rgba(255, 255, 255, 0.35);
  background: rgba(15, 23, 42, 0.7);
  color: #fff;
  font-size: 0.75rem;
  padding: 0.25rem 0.8rem;
  cursor: pointer;
  transition: background-color 0.2s ease, color 0.2s ease;
}

[data-theme='light'] .movie-card .wishlist-btn {
  background: rgba(248, 250, 252, 0.9);
  border-color: rgba(15, 23, 42, 0.2);
  color: #111827;
}

.wishlist-btn:hover {
  background: var(--color-accent);
  color: #fff;
}

.detail-link {
  align-self: flex-start;
  border-radius: 999px;
  border: 1px solid rgba(255, 255, 255, 0.35);
  background: rgba(15, 23, 42, 0.7);
  padding: 0.25rem 0.8rem;
  font-size: 0.75rem;
  color: #fff;
  transition: background-color 0.2s ease, color 0.2s ease;
  will-change: background-color, color;
}

[data-theme='light'] .movie-card .detail-link {
  background: rgba(248, 250, 252, 0.9);
  border-color: rgba(15, 23, 42, 0.2);
  color: #111827;
}

.detail-link:hover {
  background: var(--color-accent);
  color: #fff;
}

@media (max-width: 640px) {
  .movie-card {
    min-width: unset;
  }

  .poster-overlay {
    padding: 0.75rem;
  }
}
</style>
