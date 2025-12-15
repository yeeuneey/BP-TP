import { createRouter, createWebHistory } from 'vue-router'
import type { RouteRecordRaw } from 'vue-router'
import { getCurrentUserId } from '@/services/auth'
import SigninView from '@/views/SigninView.vue'
import HomeView from '@/views/HomeView.vue'
import PopularView from '@/views/PopularView.vue'
import SearchView from '@/views/SearchView.vue'
import WishlistView from '@/views/WishlistView.vue'
import RecommendedView from '@/views/RecommendedView.vue'
import MovieDetailView from '@/views/MovieDetailView.vue'

const routes: RouteRecordRaw[] = [
  {
    path: '/signin',
    name: 'signin',
    component: SigninView,
    meta: { public: true },
  },
  {
    path: '/',
    name: 'home',
    component: HomeView,
    meta: { requiresAuth: true },
  },
  {
    path: '/popular',
    name: 'popular',
    component: PopularView,
    meta: { requiresAuth: true },
  },
  {
    path: '/search',
    name: 'search',
    component: SearchView,
    meta: { requiresAuth: true },
  },
  {
    path: '/wishlist',
    name: 'wishlist',
    component: WishlistView,
    meta: { requiresAuth: true },
  },
  {
    path: '/recommended',
    name: 'recommended',
    component: RecommendedView,
    meta: { requiresAuth: true },
  },
  {
    path: '/movies/:id',
    name: 'movie-detail',
    component: MovieDetailView,
    meta: { requiresAuth: true },
  },
  { path: '/:pathMatch(.*)*', redirect: '/' },
]

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes,
})

// 로그인 여부 체크 (LocalStorage or Pinia)
router.beforeEach((to, _from, next) => {
  const isLoggedIn = getCurrentUserId() !== null

  if (to.meta.requiresAuth && !isLoggedIn) {
    next({ name: 'signin' })
  } else if (to.name === 'signin' && isLoggedIn) {
    next({ name: 'home' })
  } else {
    next()
  }
})

export default router
