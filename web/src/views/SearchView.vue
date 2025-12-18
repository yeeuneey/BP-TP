<template>
  <main class="search-page page-shell">
    <header class="page-header">
      <div>
        <p class="page-eyebrow">Search & Filter</p>
        <h1>원하는 영화를 찾아보세요</h1>
        <p class="page-subtitle">
          키워드, 장르, 평점, 정렬까지 조건에 맞는 작품을 바로 확인할 수 있습니다.
        </p>
      </div>
    </header>

    <section class="panel filter-bar">
      <div class="filter-grid">
        <label class="field">
          <span class="field-label">
            <FontAwesomeIcon
              :icon="['fas', 'magnifying-glass']"
              class="field-label__icon"
              aria-hidden="true"
            />
            검색어
          </span>
          <div class="search-input-wrap">
            <input
              v-model="searchQuery"
              type="search"
              placeholder="영화 제목, 키워드..."
              @keyup.enter="handleSearch"
            />
            <button type="button" class="search-btn" @click="handleSearch">
              <FontAwesomeIcon :icon="['fas', 'magnifying-glass']" aria-hidden="true" />
              <span>검색</span>
            </button>
          </div>
        </label>

        <label class="field">
          <span class="field-label">
            <FontAwesomeIcon
              :icon="['fas', 'film']"
              class="field-label__icon"
              aria-hidden="true"
            />
            장르
          </span>
          <select v-model.number="selectedGenreId">
            <option :value="0">전체</option>
            <option
              v-for="genre in genres"
              :key="genre.id"
              :value="genre.id"
            >
              {{ genre.name }}
            </option>
          </select>
        </label>

        <label class="field">
          <span class="field-label">
            <FontAwesomeIcon
              :icon="['fas', 'star']"
              class="field-label__icon"
              aria-hidden="true"
            />
            최소 평점
          </span>
          <select v-model.number="minRating">
            <option :value="0">전체</option>
            <option :value="5">5.0 이상</option>
            <option :value="7">7.0 이상</option>
            <option :value="8">8.0 이상</option>
          </select>
        </label>

        <label class="field">
          <span class="field-label">
            <FontAwesomeIcon
              :icon="['fas', 'arrow-down-wide-short']"
              class="field-label__icon"
              aria-hidden="true"
            />
            정렬 방식
          </span>
          <select v-model="sortOption">
            <option value="popularityDesc">인기 순</option>
            <option value="ratingDesc">평점 높은 순</option>
            <option value="ratingAsc">평점 낮은 순</option>
            <option value="dateDesc">최신 개봉 순</option>
            <option value="dateAsc">오래된 순</option>
          </select>
        </label>
      </div>

      <div class="filter-footer">
        <button type="button" class="reset-btn" @click="resetFilters">
          <FontAwesomeIcon :icon="['fas', 'filter-circle-xmark']" aria-hidden="true" />
          <span>필터 초기화</span>
        </button>
        <span class="result-info" v-if="!loading && filteredMovies.length">
          총 {{ filteredMovies.length }}편 (검색 결과 {{ rawMovies.length }}편)
        </span>
      </div>

      <div v-if="history.length" class="history-row">
        <span class="history-label">
          <FontAwesomeIcon :icon="['fas', 'clock-rotate-left']" aria-hidden="true" />
          <span>최근 검색</span>
        </span>
        <div class="history-list">
          <button
            v-for="item in history"
            :key="item"
            class="history-chip"
            type="button"
            @click="selectHistory(item)"
          >
            {{ item }}
          </button>
        </div>
        <button type="button" class="clear-history" @click="clearHistory">
          <FontAwesomeIcon :icon="['fas', 'trash-can']" aria-hidden="true" />
          <span>전체 삭제</span>
        </button>
      </div>
    </section>

    <section class="panel results-section">
      <LoaderSpinner v-if="loading" />

      <p v-else-if="error" class="error-text">
        {{ error }}
      </p>

      <p
        v-else-if="!filteredMovies.length && searchPerformed"
        class="empty-text"
      >
        조건에 맞는 결과가 없습니다. 검색어나 필터를 조정해 보세요.
      </p>

      <p
        v-else-if="!filteredMovies.length && !searchPerformed"
        class="hint-text"
      >
        TMDB에서 제공하는 수만 편의 영화를 검색해 보세요.
      </p>

      <div v-else class="movie-grid">
        <MovieCard
          v-for="movie in filteredMovies"
          :key="movie.id"
          :movie="movie"
          :is-wishlisted="isInWishlist(movie.id)"
          @toggle-wishlist="toggleWishlist"
        />
      </div>
    </section>
  </main>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import LoaderSpinner from '@/components/common/LoaderSpinner.vue'
import MovieCard from '@/components/movie/MovieCard.vue'
import {
  fetchGenres,
  searchMovies,
  type TmdbGenre,
  type TmdbMovie,
} from '@/services/tmdb'
import { useWishlist } from '@/composables/useWishlist'
import { useSearchHistory } from '@/composables/useSearchHistory'

const searchQuery = ref('')
const rawMovies = ref<TmdbMovie[]>([])
const loading = ref(false)
const error = ref<string | null>(null)
const searchPerformed = ref(false)

const genres = ref<TmdbGenre[]>([])
const selectedGenreId = ref<number>(0)
const minRating = ref<number>(0)
const sortOption = ref<'popularityDesc' | 'ratingDesc' | 'ratingAsc' | 'dateDesc' | 'dateAsc'>(
  'popularityDesc',
)

const { toggleWishlist, isInWishlist } = useWishlist()
const { history, addSearch, clearHistory } = useSearchHistory()

async function handleSearch() {
  if (!searchQuery.value.trim()) {
    error.value = '검색어를 입력해 주세요.'
    searchPerformed.value = false
    rawMovies.value = []
    return
  }

  loading.value = true
  error.value = null
  searchPerformed.value = true

  try {
    const res = await searchMovies(searchQuery.value.trim(), 1)
    rawMovies.value = res.results
    addSearch(searchQuery.value)
  } catch (err) {
    console.error(err)
    error.value = '검색에 실패했습니다. 잠시 후 다시 시도해 주세요.'
    rawMovies.value = []
  } finally {
    loading.value = false
  }
}

function resetFilters() {
  selectedGenreId.value = 0
  minRating.value = 0
  sortOption.value = 'popularityDesc'
}

const filteredMovies = computed<TmdbMovie[]>(() => {
  let list = [...rawMovies.value]

  if (selectedGenreId.value !== 0) {
    list = list.filter((movie) => movie.genre_ids?.includes(selectedGenreId.value))
  }

  if (minRating.value > 0) {
    list = list.filter((movie) => (movie.vote_average ?? 0) >= minRating.value)
  }

  list.sort((a, b) => {
    const ratingA = a.vote_average ?? 0
    const ratingB = b.vote_average ?? 0
    const dateA = a.release_date ? new Date(a.release_date).getTime() : 0
    const dateB = b.release_date ? new Date(b.release_date).getTime() : 0

    switch (sortOption.value) {
      case 'ratingDesc':
        return ratingB - ratingA
      case 'ratingAsc':
        return ratingA - ratingB
      case 'dateDesc':
        return dateB - dateA
      case 'dateAsc':
        return dateA - dateB
      case 'popularityDesc':
      default:
        return 0
    }
  })

  return list
})

onMounted(async () => {
  try {
    genres.value = await fetchGenres()
  } catch (err) {
    console.error(err)
  }
})

function selectHistory(term: string) {
  searchQuery.value = term
  void handleSearch()
}
</script>

<style scoped>
.search-page {
  display: flex;
  flex-direction: column;
  gap: var(--space-lg);
}

.page-header h1 {
  margin: 0;
}

.page-eyebrow {
  text-transform: uppercase;
  letter-spacing: 0.2em;
  color: var(--color-muted);
  margin: 0 0 0.3rem;
  font-size: 0.8rem;
}

.page-subtitle {
  color: var(--color-muted);
  margin: 0.3rem 0 0;
  font-size: 0.9rem;
}

.filter-grid {
  display: grid;
  grid-template-columns: 2fr 1fr 1fr 1fr;
  gap: var(--space-md);
}

.field {
  display: flex;
  flex-direction: column;
  gap: 0.35rem;
  font-size: 0.85rem;
  color: #e5e7eb;
}

.field-label {
  display: inline-flex;
  align-items: center;
  gap: 0.35rem;
  font-weight: 600;
}

.field-label__icon {
  color: var(--color-accent);
  font-size: 0.9rem;
}

.field input,
.field select {
  background: #020617;
  border-radius: 12px;
  border: 1px solid #1f2937;
  padding: 0.6rem 0.75rem;
  font-size: 0.95rem;
  color: #e5e5e5;
}

[data-theme='light'] .field input,
[data-theme='light'] .field select {
  background: #fff;
  border-color: rgba(15, 23, 42, 0.2);
  color: #111827;
}

[data-theme='light'] .field select option {
  color: #111827;
}

.search-input-wrap {
  display: flex;
  gap: 0.5rem;
}

.search-input-wrap input {
  flex: 1;
}

[data-theme='light'] .search-input-wrap input::placeholder {
  color: rgba(15, 23, 42, 0.6);
}

.search-btn {
  border-radius: 999px;
  border: none;
  background: var(--color-accent);
  color: #fff;
  font-size: 0.85rem;
  padding: 0 1.4rem;
  cursor: pointer;
  transition: transform 0.15s ease, box-shadow 0.15s ease;
  will-change: transform, box-shadow;
  display: inline-flex;
  align-items: center;
  gap: 0.35rem;
}

.search-btn:hover {
  transform: translateY(-1px);
  box-shadow: 0 4px 16px rgba(229, 9, 20, 0.5);
}

.filter-footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-top: var(--space-md);
  gap: var(--space-sm);
}

[data-theme='light'] .result-info {
  color: #0f172a;
}

.reset-btn {
  border-radius: 999px;
  border: 1px solid #4b5563;
  background: transparent;
  color: #e5e5e5;
  font-size: 0.85rem;
  padding: 0.35rem 1rem;
  cursor: pointer;
  transition: background-color 0.15s ease;
  will-change: background-color;
  display: inline-flex;
  align-items: center;
  gap: 0.35rem;
}

.reset-btn:hover {
  background: #111827;
}

.result-info {
  font-size: 0.85rem;
  color: var(--color-muted);
  text-align: right;
  flex: 1;
}

.history-row {
  margin-top: var(--space-md);
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
  align-items: center;
}

.history-label {
  font-size: 0.85rem;
  color: var(--color-muted);
  display: inline-flex;
  align-items: center;
  gap: 0.3rem;
}

.history-list {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
  flex: 1;
}

.history-chip {
  border-radius: 999px;
  border: 1px solid rgba(255, 255, 255, 0.25);
  background: transparent;
  color: #e5e5e5;
  padding: 0.2rem 0.9rem;
  font-size: 0.8rem;
  cursor: pointer;
  transition: background-color 0.2s ease, color 0.2s ease;
  will-change: background-color, color;
}

.clear-history {
  border: none;
  background: transparent;
  color: var(--color-muted);
  font-size: 0.8rem;
  cursor: pointer;
  transition: color 0.2s ease;
  display: inline-flex;
  align-items: center;
  gap: 0.3rem;
}

.results-section {
  min-height: 200px;
}

.movie-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(140px, 1fr));
  gap: 1rem;
}

.error-text {
  color: #f97373;
  font-size: 0.9rem;
}

.empty-text,
.hint-text {
  font-size: 0.9rem;
  color: var(--color-muted);
}

[data-theme='light'] .field {
  color: #0f172a;
}

[data-theme='light'] .reset-btn {
  border-color: rgba(15, 23, 42, 0.45);
  color: #0f172a;
}

[data-theme='light'] .history-label,
[data-theme='light'] .clear-history {
  color: #0f172a;
}

[data-theme='light'] .history-chip {
  border-color: rgba(15, 23, 42, 0.35);
  color: #0f172a;
}

@media (max-width: 900px) {
  .filter-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}

@media (max-width: 600px) {
  .filter-grid {
    grid-template-columns: 1fr;
  }

  .filter-footer {
    flex-direction: column;
    align-items: flex-start;
  }

  .result-info {
    text-align: left;
  }
}
</style>
