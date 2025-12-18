<!-- src/views/HomeView.vue -->
<template>
  <main class="home-page page-shell">
    <section class="hero panel">
      <div class="hero__content">
        <p class="hero__eyebrow">Just for you</p>
        <p class="hero__copy">
          TMDB API와 연동된 실시간 인기, 상영 중 영화를 한 곳에서 만나볼 수 있습니다.
        </p>
        <div class="hero__actions">
          <RouterLink to="/popular" class="hero__cta hero__cta--primary">인기작 보기</RouterLink>
          <RouterLink to="/search" class="hero__cta">검색하러 가기</RouterLink>
        </div>
      </div>
      <div class="hero__stats">
        <div class="stat">
          <strong>24K+</strong>
          <span>TMDB Movies</span>
        </div>
        <div class="stat">
          <strong>120+</strong>
          <span>장르 조합</span>
        </div>
        <div class="stat">
          <strong>∞</strong>
          <span>나만의 위시리스트</span>
        </div>
      </div>
    </section>

    <section
      v-for="section in sections"
      :key="section.key"
      class="section-block"
    >
      <div class="section-header">
        <div>
          <p class="section-eyebrow">Curated · {{ section.key }}</p>
          <h2>{{ section.title }}</h2>
        </div>
      </div>

      <LoaderSpinner v-if="section.loading" />
      <p v-else-if="section.error" class="error-text">
        {{ section.error }}
      </p>

      <div v-else class="movie-row">
        <MovieCard
          v-for="movie in section.movies"
          :key="movie.id"
          :movie="movie"
          :is-wishlisted="isInWishlist(movie.id)"
          :is-recommended="false"
          @toggle-wishlist="toggleWishlist"
        />
      </div>
    </section>
  </main>
</template>

<script setup lang="ts">
import { onMounted, reactive } from 'vue'
import { RouterLink } from 'vue-router'
import LoaderSpinner from '@/components/common/LoaderSpinner.vue'
import MovieCard from '@/components/movie/MovieCard.vue'
import {
  fetchPopularMovies,
  fetchNowPlayingMovies,
  fetchDiscoverMovies,
  type TmdbMovie,
} from '@/services/tmdb'
import { useWishlist } from '@/composables/useWishlist'

interface HomeSectionState {
  key: string
  title: string
  loading: boolean
  error: string | null
  movies: TmdbMovie[]
}

const { toggleWishlist, isInWishlist } = useWishlist()

const sections = reactive<HomeSectionState[]>([
  {
    key: 'popular',
    title: '지금 가장 뜨는 영화',
    loading: true,
    error: null,
    movies: [],
  },
  {
    key: 'nowPlaying',
    title: '극장에서 막 나온 작품',
    loading: true,
    error: null,
    movies: [],
  },
  {
    key: 'topRated',
    title: '팬들이 뽑은 명작 컬렉션',
    loading: true,
    error: null,
    movies: [],
  },
  {
    key: 'genreAction',
    title: '숨 쉴 틈 없는 액션',
    loading: true,
    error: null,
    movies: [],
  },
])

async function loadSection(
  key: HomeSectionState['key'],
  loader: () => Promise<TmdbMovie[]>,
) {
  const section = sections.find((s) => s.key === key)
  if (!section) return

  section.loading = true
  section.error = null
  try {
    const movies = await loader()
    section.movies = movies
  } catch (err) {
    console.error(err)
    section.error = '영화를 불러오지 못했습니다.'
  } finally {
    section.loading = false
  }
}

onMounted(async () => {
  await Promise.all([
    loadSection('popular', async () => {
      const res = await fetchPopularMovies(1)
      return res.results
    }),
    loadSection('nowPlaying', async () => {
      const res = await fetchNowPlayingMovies(1)
      return res.results
    }),
    loadSection('topRated', async () => {
      const res = await fetchDiscoverMovies(
        '&sort_by=vote_average.desc&vote_count.gte=500',
        1,
      )
      return res.results
    }),
    loadSection('genreAction', async () => {
      const res = await fetchDiscoverMovies('&with_genres=28', 1)
      return res.results
    }),
  ])
})
</script>

<style scoped>
.home-page {
  display: flex;
  flex-direction: column;
  gap: var(--space-xl);
}

.hero {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: var(--space-lg);
  background-image: linear-gradient(120deg, rgba(3, 7, 18, 0.75), rgba(3, 7, 18, 0.35)),
    var(--hero-background, url('https://image.tmdb.org/t/p/original/8sMmAmN2x7mBiNKEX2o0aOTozEB.jpg'));
  background-size: cover;
  background-position: center;
}

.hero__content {
  display: flex;
  flex-direction: column;
  gap: var(--space-sm);
  color: #fff;
}

.hero__eyebrow {
  text-transform: uppercase;
  letter-spacing: 0.3em;
  font-size: 0.8rem;
  color: #fbbf24;
  margin: 0;
}

.hero__copy {
  max-width: 520px;
  color: #f8fafc;
  margin: 0 0 var(--space-md);
}

.hero__actions {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-sm);
}

.hero__cta {
  border-radius: 999px;
  border: 1px solid rgba(255, 255, 255, 0.4);
  padding: 0.65rem 1.5rem;
  font-weight: 600;
  letter-spacing: 0.03em;
}

.hero__cta--primary {
  background: var(--color-accent);
  border-color: var(--color-accent);
}

.hero__stats {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(120px, 1fr));
  gap: var(--space-sm);
}

.stat {
  background: rgba(3, 7, 18, 0.65);
  border-radius: var(--radius-md);
  border: 1px solid rgba(255, 255, 255, 0.2);
  padding: var(--space-md);
  display: flex;
  flex-direction: column;
  gap: 0.1rem;
  color: #fff;
}

.stat strong {
  font-size: 1.8rem;
}

.stat span {
  color: rgba(255, 255, 255, 0.8);
  font-size: 0.85rem;
}

.section-block {
  display: flex;
  flex-direction: column;
  gap: var(--space-sm);
}

.section-header {
  display: flex;
  align-items: baseline;
  justify-content: space-between;
  gap: var(--space-sm);
}

.section-eyebrow {
  text-transform: uppercase;
  color: var(--color-muted);
  font-size: 0.75rem;
  margin: 0;
}

.section-header h2 {
  margin: 0.2rem 0 0;
}

.movie-row {
  display: grid;
  grid-auto-flow: column;
  grid-auto-columns: minmax(160px, 1fr);
  gap: var(--space-sm);
  overflow-x: auto;
  padding-bottom: 0.5rem;
  scroll-snap-type: x mandatory;
}

.movie-row > * {
  scroll-snap-align: start;
}

.movie-row::-webkit-scrollbar {
  height: 6px;
}

.movie-row::-webkit-scrollbar-thumb {
  background: rgba(148, 163, 184, 0.5);
  border-radius: 999px;
}

.error-text {
  color: #f97373;
  font-size: 0.9rem;
}

@media (max-width: 960px) {
  .hero {
    grid-template-columns: 1fr;
  }
}

@media (max-width: 700px) {
  .movie-row {
    grid-auto-flow: row;
    grid-template-columns: repeat(auto-fill, minmax(150px, 1fr));
    overflow-x: visible;
  }
}
</style>
