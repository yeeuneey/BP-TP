import { ref } from 'vue'

const STORAGE_KEY = 'recentSearches'
const MAX_ITEMS = 8

const history = ref<string[]>(load())

function load(): string[] {
  const raw = localStorage.getItem(STORAGE_KEY)
  if (!raw) return []
  try {
    const parsed = JSON.parse(raw) as string[]
    return Array.isArray(parsed) ? parsed : []
  } catch {
    return []
  }
}

function persist() {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(history.value))
}

function addSearch(term: string) {
  const normalized = term.trim()
  if (!normalized) return

  history.value = [normalized, ...history.value.filter((item) => item !== normalized)].slice(
    0,
    MAX_ITEMS,
  )
  persist()
}

function clearHistory() {
  history.value = []
  persist()
}

export function useSearchHistory() {
  return {
    history,
    addSearch,
    clearHistory,
  }
}
