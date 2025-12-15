import { computed, onMounted, ref } from 'vue'

const STORAGE_KEY = 'theme'
type Theme = 'dark' | 'light'

const theme = ref<Theme>('dark')
let initialized = false

function applyTheme(value: Theme) {
  if (typeof document === 'undefined') return
  document.documentElement.setAttribute('data-theme', value)
}

function initTheme() {
  if (initialized || typeof window === 'undefined') return
  const stored = window.localStorage.getItem(STORAGE_KEY) as Theme | null
  if (stored === 'dark' || stored === 'light') {
    theme.value = stored
  } else {
    const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches
    theme.value = prefersDark ? 'dark' : 'light'
  }
  applyTheme(theme.value)
  initialized = true
}

if (typeof window !== 'undefined') {
  initTheme()
}

export function useTheme() {
  onMounted(() => initTheme())

  function toggleTheme() {
    const next: Theme = theme.value === 'dark' ? 'light' : 'dark'
    theme.value = next
    if (typeof window !== 'undefined') {
      window.localStorage.setItem(STORAGE_KEY, next)
    }
    applyTheme(next)
  }

  const themeLabel = computed(() => (theme.value === 'dark' ? '라이트 모드' : '다크 모드'))

  return {
    theme,
    toggleTheme,
    themeLabel,
  }
}
