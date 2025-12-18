<template>
  <main class="popular-page page-shell">
    <header class="page-header">
      <div>
        <p class="page-eyebrow">TMDB Highlights</p>
        <h1>인기 영화 탐색</h1>
        <p class="page-subtitle">표와 카드, 두 가지 뷰로 원하는 방식에 맞게 살펴보세요.</p>
      </div>
      <div class="view-toggle">
        <button
          type="button"
          :class="['toggle-btn', viewMode === 'table' ? 'active' : '']"
          @click="switchMode('table')"
        >
          Table View
        </button>
        <button
          type="button"
          :class="['toggle-btn', viewMode === 'infinite' ? 'active' : '']"
          @click="switchMode('infinite')"
        >
          Infinite Scroll
        </button>
      </div>
    </header>

    <section v-if="viewMode === 'table'" class="panel infinite-view">
      <LoaderSpinner v-if="tableState.loading" />
      <p v-else-if="tableState.error" class="error-text">{{ tableState.error }}</p>
      <template v-else>
        <div class="info-bar">
          <p>페이지를 넘기며 인기 영화를 카드 형식으로 둘러보세요.</p>
        </div>
        <div class="movie-grid">
          <MovieCard
            v-for="movie in tableState.movies"
            :key="movie.id"
            :movie="movie"
            :is-wishlisted="isInWishlist(movie.id)"
            :is-recommended="false"
            @toggle-wishlist="toggleWishlist"
          />
        </div>

        <div class="pagination">
          <button
            type="button"
            class="page-btn"
            :disabled="tableState.page <= 1"
            @click="changeTablePage(tableState.page - 1)"
          >
            이전
          </button>
          <span class="page-info">
            {{ tableState.page }} / {{ tableState.totalPages }}
          </span>
          <button
            type="button"
            class="page-btn"
            :disabled="tableState.page >= tableState.totalPages"
            @click="changeTablePage(tableState.page + 1)"
          >
            다음
          </button>
        </div>
      </template>
    </section>

    <section v-else class="panel table-view">
      <div class="info-bar">
        <p>스크롤을 내리면 자동으로 다음 인기 영화가 이어집니다.</p>
      </div>

      <div class="infinite-feed">
        <article
          v-for="movie in infiniteState.movies"
          :key="movie.id"
          class="feed-card"
        >
          <RouterLink
            class="feed-thumb"
            :to="`/movies/${movie.id}`"
            @click.stop
          >
            <img
              v-if="movie.poster_path"
              :src="getPosterUrl(movie.poster_path)"
              :alt="movie.title"
              loading="lazy"
              decoding="async"
            />
            <div v-else class="feed-thumb__placeholder">No Image</div>
          </RouterLink>

          <div class="feed-body">
            <div class="feed-heading">
              <h3 class="feed-title">{{ movie.title }}</h3>
              <span class="feed-score">
                {{ movie.vote_average?.toFixed(1) ?? '-' }}
              </span>
            </div>
            <p class="feed-meta">
              <span>{{ movie.release_date ?? '개봉일 정보 없음' }}</span>
              <span class="recommend-state recommend-state--off">추천 없음</span>
            </p>
            <p v-if="movie.overview" class="feed-overview">
              {{ getOverviewSnippet(movie.overview) }}
            </p>
            <div class="feed-actions">
              <button
                type="button"
                class="feed-action-btn"
                @click.stop="toggleWishlist(movie)"
              >
                {{ isInWishlist(movie.id) ? '위시리스트 해제' : '담기' }}
              </button>
            </div>
          </div>

          <RouterLink
            class="feed-detail"
            :to="`/movies/${movie.id}`"
            @click.stop
          >
            상세
          </RouterLink>
        </article>
      </div>

      <LoaderSpinner v-if="infiniteState.loading" class="feed-loader" />
      <p v-else-if="infiniteState.error" class="error-text">{{ infiniteState.error }}</p>
      <p v-else-if="infiniteState.isEnd" class="end-text">
        모든 인기 목록을 확인했습니다!
      </p>

      <button
        v-if="showTopButton"
        class="top-btn"
        type="button"
        @click="scrollToTop"
      >
        Top
      </button>
    </section>

  </main>
</template>

<script setup lang="ts">
import { onMounted, onBeforeUnmount, reactive, ref } from 'vue'
import LoaderSpinner from '@/components/common/LoaderSpinner.vue'
import MovieCard from '@/components/movie/MovieCard.vue'
import { fetchPopularMovies, type TmdbMovie } from '@/services/tmdb'
import { useWishlist } from '@/composables/useWishlist'

type ViewMode = 'table' | 'infinite'

const viewMode = ref<ViewMode>('table')
const { toggleWishlist, isInWishlist } = useWishlist()

interface TableState {
  page: number
  totalPages: number
  movies: TmdbMovie[]
  loading: boolean
  error: string | null
}

const tableState = reactive<TableState>({
  page: 1,
  totalPages: 1,
  movies: [],
  loading: true,
  error: null,
})

interface InfiniteState {
  page: number
  totalPages: number
  movies: TmdbMovie[]
  loading: boolean
  error: string | null
  isEnd: boolean
}

const infiniteState = reactive<InfiniteState>({
  page: 1,
  totalPages: 1,
  movies: [],
  loading: false,
  error: null,
  isEnd: false,
})

const showTopButton = ref(false)
const MIN_INFINITE_LOADING_MS = 450
let hasLoadedFirstInfinitePage = false

function getPosterUrl(path: string) {
  return `https://image.tmdb.org/t/p/w200${path}`
}

function getOverviewSnippet(overview?: string) {
  const text = overview?.trim()
  if (!text) return ''
  return text.length > 120 ? `${text.slice(0, 120)}...` : text
}

function delay(ms: number) {
  return new Promise((resolve) => {
    window.setTimeout(resolve, ms)
  })
}

async function loadTablePage(page: number) {
  tableState.loading = true
  tableState.error = null
  try {
    const res = await fetchPopularMovies(page)
    tableState.movies = res.results
    tableState.page = res.page
    tableState.totalPages = Math.min(res.total_pages, 500)
  } catch (err) {
    console.error(err)
    tableState.error = '인기 영화를 불러오지 못했습니다.'
  } finally {
    tableState.loading = false
  }
}

function changeTablePage(page: number) {
  if (page < 1 || page > tableState.totalPages) return
  void loadTablePage(page)
}

async function loadMoreInfinite() {
  if (infiniteState.loading || infiniteState.isEnd) return

  infiniteState.loading = true
  infiniteState.error = null
  try {
    const nextPage = hasLoadedFirstInfinitePage ? infiniteState.page + 1 : 1
    const [res] = await Promise.all([
      fetchPopularMovies(nextPage),
      delay(MIN_INFINITE_LOADING_MS),
    ])

    hasLoadedFirstInfinitePage = true
    infiniteState.page = res.page
    infiniteState.totalPages = Math.min(res.total_pages, 500)

    if (res.results.length === 0 || res.page >= infiniteState.totalPages) {
      infiniteState.isEnd = true
    }

    infiniteState.movies.push(...res.results)
  } catch (err) {
    console.error(err)
    infiniteState.error = '다음 영화를 불러오지 못했습니다.'
  } finally {
    infiniteState.loading = false
  }
}

function switchMode(mode: ViewMode) {
  viewMode.value = mode

  if (mode === 'table' && tableState.movies.length === 0 && !tableState.loading) {
    void loadTablePage(1)
  }
  if (
    mode === 'infinite' &&
    infiniteState.movies.length === 0 &&
    !infiniteState.loading
  ) {
    void loadMoreInfinite()
  }
}

function onScroll() {
  const scrollTop = window.pageYOffset || document.documentElement.scrollTop || 0
  const viewportHeight = window.innerHeight
  const fullHeight = document.documentElement.scrollHeight
  const preloadGap = Math.max(80, viewportHeight * 0.1)

  showTopButton.value = scrollTop > 300

  if (viewMode.value === 'infinite' && scrollTop + viewportHeight >= fullHeight - preloadGap) {
    void loadMoreInfinite()
  }
}

function scrollToTop() {
  window.scrollTo({ top: 0, behavior: 'smooth' })
}

onMounted(async () => {
  await Promise.all([loadTablePage(1), loadMoreInfinite()])
  window.addEventListener('scroll', onScroll)
})

onBeforeUnmount(() => {
  window.removeEventListener('scroll', onScroll)
})
</script>

<style scoped>
.popular-page {
  display: flex;
  flex-direction: column;
  gap: var(--space-lg);
}

.page-header {
  display: flex;
  flex-wrap: wrap;
  align-items: flex-start;
  justify-content: space-between;
  gap: var(--space-md);
}

.page-eyebrow {
  text-transform: uppercase;
  letter-spacing: 0.2em;
  color: var(--color-muted);
  margin: 0 0 0.3rem;
  font-size: 0.8rem;
}

.page-header h1 {
  margin: 0;
}

.page-subtitle {
  color: var(--color-muted);
  margin: 0.3rem 0 0;
  font-size: 0.9rem;
}

.view-toggle {
  display: flex;
  gap: 0.5rem;
}

.toggle-btn {
  border-radius: 999px;
  border: 1px solid rgba(148, 163, 184, 0.7);
  background: transparent;
  color: #e5e5e5;
  font-size: 0.85rem;
  padding: 0.4rem 0.9rem;
  cursor: pointer;
  transition: background-color 0.2s ease, color 0.2s ease, transform 0.15s ease;
  will-change: background-color, color, transform;
}

.toggle-btn.active {
  background: var(--color-accent);
  border-color: var(--color-accent);
  color: #fff;
  box-shadow: 0 10px 20px rgba(229, 9, 20, 0.25);
}

[data-theme='light'] .view-toggle .toggle-btn {
  border-color: rgba(15, 23, 42, 0.25);
  color: #1f2937;
  background: rgba(248, 250, 252, 0.85);
}

[data-theme='light'] .view-toggle .toggle-btn:hover:not(.active) {
  background: rgba(15, 23, 42, 0.05);
}

[data-theme='light'] .view-toggle .toggle-btn.active {
  background: var(--color-accent);
  border-color: var(--color-accent);
  color: #fff;
  box-shadow: 0 12px 22px rgba(229, 9, 20, 0.25);
}

.infinite-feed {
  display: flex;
  flex-direction: column;
  gap: 0.85rem;
}

.feed-card {
  display: grid;
  grid-template-columns: auto 1fr auto;
  gap: 0.9rem;
  padding: 0.85rem 1rem;
  border-radius: 1rem;
  background: rgba(15, 23, 42, 0.78);
  border: 1px solid rgba(148, 163, 184, 0.18);
  box-shadow: 0 12px 28px rgba(2, 6, 23, 0.5);
}

.feed-thumb {
  width: 68px;
  height: 96px;
  border-radius: 0.75rem;
  overflow: hidden;
  background: #0f172a;
  flex-shrink: 0;
}

.feed-thumb img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.feed-thumb__placeholder {
  width: 100%;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 0.7rem;
  text-transform: uppercase;
  color: #94a3b8;
}

.feed-body {
  display: flex;
  flex-direction: column;
  justify-content: center;
  gap: 0.45rem;
}

.feed-heading {
  display: flex;
  align-items: baseline;
  gap: 0.6rem;
}

.feed-title {
  margin: 0;
  font-size: 1rem;
}

.feed-score {
  padding: 0.12rem 0.55rem;
  border-radius: 999px;
  border: 1px solid rgba(252, 211, 77, 0.4);
  color: #facc15;
  font-size: 0.75rem;
}

.feed-meta {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
  margin: 0;
  font-size: 0.78rem;
  color: var(--color-muted);
}

.recommend-state {
  padding: 0.1rem 0.45rem;
  border-radius: 0.5rem;
  background: rgba(148, 163, 184, 0.2);
  color: #cbd5f5;
}

.recommend-state--on {
  background: rgba(234, 179, 8, 0.2);
  color: #facc15;
}

.feed-overview {
  margin: 0;
  font-size: 0.78rem;
  color: #cbd5f5;
  line-height: 1.35;
}

.feed-actions {
  display: flex;
  flex-wrap: wrap;
  gap: 0.4rem;
}

.feed-action-btn {
  border-radius: 999px;
  border: none;
  padding: 0.35rem 0.9rem;
  font-size: 0.78rem;
  cursor: pointer;
  background: var(--color-accent);
  color: #fff;
  transition: opacity 0.2s ease;
}

.feed-action-btn--ghost {
  background: transparent;
  border: 1px solid rgba(255, 255, 255, 0.2);
}

.feed-action-btn:hover {
  opacity: 0.85;
}

.feed-detail {
  align-self: center;
  border-radius: 0.6rem;
  border: 1px solid rgba(148, 163, 184, 0.4);
  padding: 0.3rem 0.6rem;
  font-size: 0.75rem;
  color: #e5e5e5;
}

.feed-loader {
  margin-top: 0.5rem;
}

[data-theme='light'] .feed-card {
  background: rgba(248, 250, 252, 0.9);
  border-color: rgba(15, 23, 42, 0.08);
  box-shadow: 0 12px 24px rgba(15, 23, 42, 0.15);
}

[data-theme='light'] .feed-meta {
  color: #475569;
}

[data-theme='light'] .feed-overview {
  color: #1e293b;
}

[data-theme='light'] .feed-action-btn--ghost {
  border-color: rgba(15, 23, 42, 0.2);
  color: #0f172a;
}

[data-theme='light'] .feed-detail {
  border-color: rgba(15, 23, 42, 0.25);
  color: #0f172a;
}

.pagination {
  margin-top: 0.75rem;
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 0.75rem;
}

.page-btn {
  border-radius: 999px;
  border: none;
  background: #1f2937;
  color: #e5e5e5;
  padding: 0.35rem 1.1rem;
  font-size: 0.85rem;
  cursor: pointer;
  transition: background-color 0.2s ease;
  will-change: background-color;
}

.page-btn:disabled {
  opacity: 0.4;
  cursor: default;
}

.movie-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(140px, 1fr));
  gap: 1rem;
}

.info-bar {
  margin-bottom: 0.75rem;
  font-size: 0.85rem;
  color: var(--color-muted);
}

.top-btn {
  position: fixed;
  right: 1.2rem;
  bottom: 1.5rem;
  width: 46px;
  height: 46px;
  border-radius: 999px;
  border: none;
  background: rgba(15, 23, 42, 0.9);
  color: #e5e5e5;
  font-size: 0.9rem;
  cursor: pointer;
  box-shadow: 0 6px 20px rgba(0, 0, 0, 0.7);
  transition: transform 0.15s ease, box-shadow 0.15s ease;
  will-change: transform, box-shadow;
}

.top-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.9);
}

.error-text {
  margin-top: 0.75rem;
  color: #f97373;
  font-size: 0.9rem;
}

.end-text {
  margin-top: 0.75rem;
  font-size: 0.9rem;
  color: var(--color-muted);
}

@media (max-width: 720px) {
  .view-toggle {
    width: 100%;
  }

  .view-toggle .toggle-btn {
    flex: 1;
  }
}

@media (max-width: 640px) {
  .feed-card {
    grid-template-columns: auto 1fr;
  }

  .feed-detail {
    justify-self: flex-start;
    margin-top: 0.35rem;
  }
}
</style>
