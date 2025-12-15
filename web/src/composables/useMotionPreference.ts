import { computed, onMounted, ref } from 'vue'

const STORAGE_KEY = 'motionReduced'

const isMotionReduced = ref(false)
const hasCustomPreference = ref(false)
let initialized = false

function applyMotionPreference(value: boolean) {
  if (typeof document === 'undefined') return
  document.documentElement.classList.toggle('motion-reduced', value)
}

function initPreference() {
  if (initialized || typeof window === 'undefined') return
  const stored = window.localStorage.getItem(STORAGE_KEY)
  if (stored !== null) {
    isMotionReduced.value = stored === 'true'
    hasCustomPreference.value = true
  } else {
    const mq = window.matchMedia('(prefers-reduced-motion: reduce)')
    isMotionReduced.value = mq.matches
    mq.addEventListener('change', (event) => {
      if (!hasCustomPreference.value) {
        isMotionReduced.value = event.matches
        applyMotionPreference(event.matches)
      }
    })
  }
  applyMotionPreference(isMotionReduced.value)
  initialized = true
}

if (typeof window !== 'undefined') {
  initPreference()
}

export function useMotionPreference() {
  onMounted(() => {
    initPreference()
  })

  function toggleMotion() {
    const next = !isMotionReduced.value
    isMotionReduced.value = next
    hasCustomPreference.value = true
    if (typeof window !== 'undefined') {
      window.localStorage.setItem(STORAGE_KEY, String(next))
    }
    applyMotionPreference(next)
  }

  function resetMotionToSystem() {
    hasCustomPreference.value = false
    if (typeof window !== 'undefined') {
      window.localStorage.removeItem(STORAGE_KEY)
    }
    const systemPrefersReduced =
      typeof window !== 'undefined' &&
      window.matchMedia &&
      window.matchMedia('(prefers-reduced-motion: reduce)').matches
    isMotionReduced.value = systemPrefersReduced
    applyMotionPreference(systemPrefersReduced)
  }

  const motionLabel = computed(() =>
    isMotionReduced.value ? '애니메이션 켜기' : '애니메이션 끄기',
  )

  return {
    isMotionReduced,
    toggleMotion,
    resetMotionToSystem,
    motionLabel,
  }
}
