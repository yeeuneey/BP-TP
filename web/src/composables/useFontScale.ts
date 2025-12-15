import { computed, onMounted, ref } from 'vue'

const STORAGE_KEY = 'fontScale'
const MIN_SCALE = 0.9
const MAX_SCALE = 1.2
const STEP = 0.1

const scale = ref(1)
let initialized = false

function applyScale(value: number) {
  if (typeof document === 'undefined') return
  document.documentElement.style.setProperty('--font-scale', value.toString())
}

function initScale() {
  if (initialized || typeof window === 'undefined') return
  const stored = Number(window.localStorage.getItem(STORAGE_KEY))
  if (!Number.isNaN(stored) && stored >= MIN_SCALE && stored <= MAX_SCALE) {
    scale.value = stored
  }
  applyScale(scale.value)
  initialized = true
}

if (typeof window !== 'undefined') {
  initScale()
}

export function useFontScale() {
  onMounted(() => initScale())

  function setScale(value: number) {
    const clamped = Math.min(MAX_SCALE, Math.max(MIN_SCALE, value))
    scale.value = clamped
    if (typeof window !== 'undefined') {
      window.localStorage.setItem(STORAGE_KEY, clamped.toString())
    }
    applyScale(clamped)
  }

  function increase() {
    setScale(Number((scale.value + STEP).toFixed(2)))
  }

  function decrease() {
    setScale(Number((scale.value - STEP).toFixed(2)))
  }

  const fontScaleLabel = computed(() => `글자 크기 ${Math.round(scale.value * 100)}%`)

  return {
    scale,
    increase,
    decrease,
    fontScaleLabel,
  }
}
