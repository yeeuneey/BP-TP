<template>
  <header class="head-bar" :class="{ 'head-bar--scrolled': isScrolled }">
    <div class="head-bar__inner page-shell">
      <button class="head-bar__brand" type="button" @click="goHome">
        <FontAwesomeIcon
          :icon="['fab', 'vuejs']"
          class="head-bar__brand-icon"
          aria-hidden="true"
        />
        PB<span>neteflix</span>
      </button>

      <button
        class="head-bar__menu"
        type="button"
        :aria-expanded="isMenuOpen"
        aria-label="Toggle navigation"
        @click="toggleMenu"
      >
        <span />
        <span />
        <span />
      </button>

      <nav
        class="head-bar__nav"
        :class="{ 'head-bar__nav--open': isMenuOpen }"
        aria-label="Primary navigation"
      >
        <RouterLink
          v-for="item in navItems"
          :key="item.to"
          class="head-bar__link"
          :to="item.to"
        >
          <FontAwesomeIcon :icon="item.icon" class="head-bar__link-icon" aria-hidden="true" />
          <span>{{ item.label }}</span>
        </RouterLink>
      </nav>

      <div class="head-bar__actions" :class="{ 'head-bar__actions--open': isMenuOpen }">
        <span v-if="isAuthenticated" class="head-bar__user">
          <FontAwesomeIcon
            :icon="['fas', 'user']"
            class="head-bar__user-icon"
            aria-hidden="true"
          />
          <span class="head-bar__user-text">{{ userId }}</span>
        </span>
        <button
          v-else
          type="button"
          class="head-bar__button"
          @click="handleSignIn"
        >
          Sign In
        </button>
        <div class="display-menu-wrapper" :class="{ 'display-menu-wrapper--open': isDisplayMenuOpen }">
          <button
            type="button"
            class="head-bar__button head-bar__button--muted display-trigger"
            :aria-expanded="isDisplayMenuOpen"
            aria-haspopup="true"
            @click="toggleDisplayMenu"
          >
            <FontAwesomeIcon :icon="['fas', 'sliders']" class="head-bar__button-icon" aria-hidden="true" />
            <span>Display</span>
            <FontAwesomeIcon :icon="['fas', 'chevron-down']" class="display-trigger__icon" aria-hidden="true" />
          </button>
          <div v-if="isDisplayMenuOpen" class="display-menu" role="menu">
            <button
              v-if="isAuthenticated"
              type="button"
              class="display-menu__item"
              role="menuitem"
              @click="handleLogout"
            >
              <FontAwesomeIcon :icon="['fas', 'right-from-bracket']" aria-hidden="true" />
              <span>Logout</span>
            </button>
            <button
              type="button"
              class="display-menu__item"
              role="menuitem"
              :aria-pressed="theme === 'light'"
              @click="toggleTheme"
            >
              <FontAwesomeIcon :icon="themeIcon" aria-hidden="true" />
              <span>{{ themeLabel }}</span>
            </button>
            <div class="display-menu__item font-item" role="group" aria-label="글자 크기 조절">
              <FontAwesomeIcon :icon="['fas', 'font']" aria-hidden="true" />
              <button type="button" class="font-btn" aria-label="글자 크기 축소" @click="decrease">
                <FontAwesomeIcon :icon="['fas', 'minus']" aria-hidden="true" />
              </button>
              <span class="font-label">{{ fontScaleLabel }}</span>
              <button type="button" class="font-btn" aria-label="글자 크기 확대" @click="increase">
                <FontAwesomeIcon :icon="['fas', 'plus']" aria-hidden="true" />
              </button>
            </div>
            <button
              type="button"
              class="display-menu__item"
              role="menuitem"
              :aria-pressed="isMotionReduced"
              @click="toggleMotion"
            >
              <FontAwesomeIcon :icon="motionIcon" aria-hidden="true" />
              <span>{{ motionLabel }}</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  </header>
</template>

<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { useRouter } from 'vue-router'

import { getCurrentUserId, logout } from '@/services/auth'
import { useMotionPreference } from '@/composables/useMotionPreference'
import { useTheme } from '@/composables/useTheme'
import { useFontScale } from '@/composables/useFontScale'

const router = useRouter()
const userId = ref<string | null>(getCurrentUserId())
const isMenuOpen = ref(false)
const isDisplayMenuOpen = ref(false)
const isScrolled = ref(false)

const navItems = [
  { to: '/', label: 'Home', icon: ['fas', 'house'] as const },
  { to: '/popular', label: 'Popular', icon: ['fas', 'fire'] as const },
  { to: '/search', label: 'Search', icon: ['fas', 'magnifying-glass'] as const },
  { to: '/wishlist', label: 'Wishlist', icon: ['fas', 'heart'] as const },
  { to: '/recommended', label: 'Recommended', icon: ['fas', 'thumbs-up'] as const },
]

const isAuthenticated = computed(() => userId.value !== null)
const { isMotionReduced, toggleMotion, motionLabel } = useMotionPreference()
const { theme, toggleTheme, themeLabel } = useTheme()
const { increase, decrease, fontScaleLabel } = useFontScale()
const themeIcon = computed(() =>
  theme.value === 'light' ? (['fas', 'sun'] as const) : (['fas', 'moon'] as const),
)
const motionIcon = computed(() =>
  isMotionReduced.value
    ? (['fas', 'circle-half-stroke'] as const)
    : (['fas', 'wand-magic-sparkles'] as const),
)

watch(
  () => router.currentRoute.value.fullPath,
  () => {
    userId.value = getCurrentUserId()
    isMenuOpen.value = false
    isDisplayMenuOpen.value = false
  },
  { immediate: true },
)

function updateScrollState() {
  const scrollTop = window.pageYOffset || document.documentElement.scrollTop || 0
  isScrolled.value = scrollTop > 30
}

onMounted(() => {
  updateScrollState()
  window.addEventListener('scroll', updateScrollState, { passive: true })
})

onBeforeUnmount(() => {
  window.removeEventListener('scroll', updateScrollState)
})

function goHome() {
  router.push('/')
}

function toggleMenu() {
  isMenuOpen.value = !isMenuOpen.value
  if (!isMenuOpen.value) {
    isDisplayMenuOpen.value = false
  }
}

function toggleDisplayMenu() {
  isDisplayMenuOpen.value = !isDisplayMenuOpen.value
}

function handleSignIn() {
  router.push('/signin')
}

function handleLogout() {
  logout()
  userId.value = null
  router.push('/signin')
}

</script>

<style scoped>
.head-bar {
  position: sticky;
  top: 0;
  z-index: 30;
  background: linear-gradient(180deg, rgba(3, 7, 18, 0.85), rgba(3, 7, 18, 0.2));
  backdrop-filter: blur(14px);
  border-bottom: 1px solid rgba(148, 163, 184, 0.12);
  transition: background-color 0.3s ease, border-color 0.3s ease, box-shadow 0.3s ease,
    transform 0.3s ease;
  will-change: background-color, border-color, box-shadow, transform;
}

.head-bar--scrolled {
  background: rgba(3, 7, 18, 0.92);
  border-color: rgba(148, 163, 184, 0.3);
  box-shadow: 0 12px 40px rgba(2, 6, 23, 0.4);
  transform: translateZ(0);
}

[data-theme='light'] .head-bar {
  background: linear-gradient(180deg, rgba(248, 250, 252, 0.95), rgba(248, 250, 252, 0.65));
  border-color: rgba(15, 23, 42, 0.08);
  color: #0f172a;
}

[data-theme='light'] .head-bar--scrolled {
  background: rgba(248, 250, 252, 0.95);
  border-color: rgba(15, 23, 42, 0.2);
  box-shadow: 0 12px 35px rgba(15, 23, 42, 0.15);
}

.head-bar__inner {
  display: grid;
  grid-template-columns: auto 1fr auto;
  align-items: center;
  gap: 1rem;
}

.head-bar__brand {
  display: inline-flex;
  align-items: center;
  gap: 0.4rem;
  font-size: 1.45rem;
  font-weight: 700;
  color: var(--color-accent);
  background: transparent;
  border: none;
  cursor: pointer;
  letter-spacing: 0.06em;
}

.head-bar__brand span {
  color: #fff;
  font-size: 0.9rem;
  letter-spacing: 0.1em;
}

[data-theme='light'] .head-bar__brand span {
  color: #0f172a;
}

.head-bar__brand-icon {
  font-size: 1.2rem;
}

.head-bar__menu {
  display: none;
  flex-direction: column;
  justify-content: center;
  gap: 0.3rem;
  width: 2.75rem;
  height: 2.75rem;
  border-radius: 999px;
  border: 1px solid rgba(255, 255, 255, 0.2);
  background: transparent;
  cursor: pointer;
  padding: 0;
  will-change: transform;
  transform: translateZ(0);
}

.head-bar__menu span {
  display: block;
  width: 1.35rem;
  height: 2px;
  background: #fff;
  margin: 0 auto;
  transition: transform 0.2s ease, opacity 0.2s ease;
}

[data-theme='light'] .head-bar__menu {
  border-color: rgba(15, 23, 42, 0.18);
}

[data-theme='light'] .head-bar__menu span {
  background: #0f172a;
}

.head-bar__nav {
  display: flex;
  gap: 1.25rem;
  justify-content: flex-end;
}

.head-bar__link {
  display: inline-flex;
  align-items: center;
  gap: 0.4rem;
  color: #d1d5db;
  font-size: 0.85rem;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  position: relative;
  will-change: color;
}

[data-theme='light'] .head-bar__link {
  color: #1f2937;
}

.head-bar__link-icon {
  font-size: 0.85rem;
}

.head-bar__link.router-link-active::after,
.head-bar__link:hover::after {
  width: 100%;
}

.head-bar__link::after {
  content: '';
  position: absolute;
  left: 0;
  bottom: -0.35rem;
  width: 0;
  height: 2px;
  background: var(--color-accent);
  transition: width 0.2s ease;
}

.head-bar__actions {
  display: flex;
  align-items: center;
  gap: 0.6rem;
  flex-wrap: wrap;
  position: relative;
}

.head-bar__user {
  font-size: 0.85rem;
  color: var(--color-muted);
  display: inline-flex;
  align-items: center;
  gap: 0.35rem;
}

.head-bar__user-text {
  max-width: 140px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.head-bar__user-icon {
  color: var(--color-accent);
}

[data-theme='light'] .head-bar__user {
  color: #0f172a;
}

.head-bar__button {
  background: var(--color-accent);
  border: none;
  border-radius: 999px;
  color: #fff;
  font-weight: 600;
  padding: 0.45rem 1.2rem;
  cursor: pointer;
  transition: opacity 0.2s ease;
  will-change: opacity, transform;
  display: inline-flex;
  align-items: center;
  gap: 0.35rem;
}

.head-bar__button:hover {
  opacity: 0.85;
}

.head-bar__button--ghost {
  background: rgba(15, 23, 42, 0.35);
  border: 1px solid rgba(248, 250, 252, 0.4);
  color: #f8fafc;
  padding: 0.4rem 1.1rem;
}

.head-bar__button--muted {
  background: transparent;
  border: 1px solid rgba(148, 163, 184, 0.35);
  color: #f3f4f6;
  font-size: 0.75rem;
  padding: 0.25rem 0.75rem;
  border-radius: 0.6rem;
}

.display-menu-wrapper {
  position: relative;
}

.display-menu {
  position: absolute;
  right: 0;
  top: calc(100% + 0.35rem);
  min-width: 220px;
  padding: 0.9rem;
  border-radius: 0.75rem;
  background: rgba(3, 7, 18, 0.95);
  border: 1px solid rgba(255, 255, 255, 0.1);
  box-shadow: 0 15px 35px rgba(2, 6, 23, 0.55);
  display: flex;
  flex-direction: column;
  gap: 0.4rem;
  z-index: 15;
}

[data-theme='light'] .display-menu {
  background: rgba(248, 250, 252, 0.98);
  border-color: rgba(15, 23, 42, 0.12);
  box-shadow: 0 18px 35px rgba(15, 23, 42, 0.12);
}

.display-menu__item {
  width: 100%;
  display: inline-flex;
  align-items: center;
  gap: 0.6rem;
  padding: 0.4rem 0.5rem;
  border-radius: 0.6rem;
  border: none;
  background: transparent;
  color: #f4f4f5;
  font-size: 0.85rem;
  cursor: pointer;
  transition: background 0.2s ease;
}

.display-menu__item:hover {
  background: rgba(148, 163, 184, 0.15);
}

[data-theme='light'] .display-menu__item {
  color: #0f172a;
}

[data-theme='light'] .display-menu__item:hover {
  background: rgba(15, 23, 42, 0.08);
}

.display-trigger {
  font-size: 0.8rem;
  padding-inline: 0.9rem;
}

.display-trigger__icon {
  font-size: 0.7rem;
}

.font-item {
  display: flex;
  align-items: center;
  gap: 0.35rem;
}

.font-btn {
  border: none;
  background: rgba(148, 163, 184, 0.25);
  color: #fff;
  border-radius: 0.4rem;
  padding: 0.15rem 0.35rem;
  cursor: pointer;
}

[data-theme='light'] .font-btn {
  background: rgba(15, 23, 42, 0.08);
  color: #0f172a;
}

.display-menu-wrapper--open .display-trigger {
  box-shadow:
    inset 0 0 0 1px rgba(229, 9, 20, 0.45),
    0 6px 18px rgba(229, 9, 20, 0.3);
}

.font-controls {
  display: inline-flex;
  align-items: center;
  gap: 0.25rem;
}

.head-bar__button-icon {
  font-size: 0.85rem;
}

.font-label {
  font-size: 0.75rem;
  color: var(--color-muted);
}

.font-controls .head-bar__button--muted {
  font-size: 0.7rem;
  padding: 0.18rem 0.5rem;
  border-radius: 0.5rem;
}

[data-theme='light'] .head-bar__button--ghost {
  background: rgba(248, 250, 252, 0.9);
  color: #0f172a;
  border-color: rgba(15, 23, 42, 0.2);
}

[data-theme='light'] .head-bar__button--muted {
  border-color: rgba(15, 23, 42, 0.25);
  color: #0f172a;
}

[data-theme='light'] .font-label {
  color: rgba(15, 23, 42, 0.7);
}

@media (max-width: 720px) {
  [data-theme='light'] .head-bar__nav,
  [data-theme='light'] .head-bar__actions {
    background: rgba(248, 250, 252, 0.98);
    border-color: rgba(15, 23, 42, 0.12);
  }
}

@media (max-width: 900px) {
  .head-bar__inner {
    grid-template-columns: auto auto;
    grid-template-rows: auto auto;
  }

  .head-bar__nav,
  .head-bar__actions {
    grid-column: 1 / -1;
    width: 100%;
  }

  .head-bar__nav {
    justify-content: flex-start;
  }
}

@media (max-width: 720px) {
  .head-bar__inner {
    grid-template-columns: auto auto;
  }

  .head-bar__menu {
    display: inline-flex;
    justify-self: end;
  }

  .head-bar__nav,
  .head-bar__actions {
    display: none;
    flex-direction: column;
    align-items: flex-start;
    width: 100%;
    background: rgba(3, 7, 18, 0.95);
    padding: 0.75rem 0;
    border-radius: 0.75rem;
    margin-top: 0.5rem;
    border: 1px solid rgba(255, 255, 255, 0.07);
  }

  .head-bar__nav--open,
  .head-bar__actions--open {
    display: flex;
  }

  .head-bar__actions {
    gap: 0.4rem;
    align-items: stretch;
  }

  .head-bar__user {
    max-width: none;
  }

  .display-menu-wrapper {
    width: 100%;
  }

  .display-trigger {
    width: 100%;
    justify-content: space-between;
  }

  .display-menu {
    position: static;
    width: 100%;
    margin-top: 0.35rem;
  }
}
</style>
