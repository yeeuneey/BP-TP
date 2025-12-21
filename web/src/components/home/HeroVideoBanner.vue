<template>
  <section
    class="hero-banner panel"
    :style="heroStyle"
  >
    <div class="hero-banner__media">
      <div
        v-if="currentItem"
        ref="playerContainer"
        class="hero-banner__player"
      ></div>
      <div v-else class="hero-banner__fallback-media">
        <p class="hero-banner__fallback-eyebrow">YEEMIN originals</p>
        <h2>최신 인기 예고편을 한눈에</h2>
        <p>로그인만 하면 YEEMIN 배너에서 분위기 충만한 트레일러를 바로 재생할 수 있어요.</p>
      </div>
    </div>

    <div class="hero-banner__overlay">
      <LoaderSpinner v-if="loading" class="hero-banner__status" />
      <p v-else-if="error" class="hero-banner__status hero-banner__status--error">
        {{ error }}
      </p>
      <template v-else-if="currentItem">
        <p class="hero-banner__eyebrow">Exclusive Trailer</p>
        <div class="hero-banner__actions">
          <RouterLink
            class="hero-btn hero-btn--primary"
            :to="`/movies/${currentItem.movie.id}`"
          >
            상세 보기
          </RouterLink>
          <button type="button" class="hero-btn" @click="$emit('toggle-mute')">
            {{ muted ? '음소거 해제' : '음소거' }}
          </button>
          <button
            type="button"
            class="hero-btn hero-btn--ghost"
            @click="$emit('next')"
          >
            다음 예고편
          </button>
        </div>
      </template>
    </div>

    <div v-if="playlist.length > 1" class="hero-banner__playlist">
      <button
        v-for="(item, idx) in playlist"
        :key="item.movie.id"
        class="hero-dot"
        :class="{ active: idx === currentIndex }"
        type="button"
        @click="$emit('set-index', idx)"
      >
        <span class="sr-only">{{ item.movie.title }}</span>
      </button>
    </div>
  </section>
</template>

<script setup lang="ts">
import { computed, onBeforeUnmount, ref, watch } from 'vue'
import { RouterLink } from 'vue-router'
import LoaderSpinner from '@/components/common/LoaderSpinner.vue'
import type { TmdbMovie } from '@/services/tmdb'
import { buildImageUrl, TMDB_IMAGE_SIZES } from '@/services/URL'

interface HeroPlaylistEntry {
  movie: TmdbMovie
  videoKey: string
}

const props = defineProps<{
  playlist: HeroPlaylistEntry[]
  currentIndex: number
  muted: boolean
  loading: boolean
  error: string | null
}>()

const emit = defineEmits<{
  (e: 'next'): void
  (e: 'set-index', index: number): void
  (e: 'toggle-mute'): void
  (e: 'ended'): void
}>()

declare global {
  interface Window {
    YT?: {
      Player: new (element: HTMLElement, options: Record<string, unknown>) => {
        loadVideoById: (videoId: string) => void
        destroy: () => void
        mute: () => void
        unMute: () => void
        playVideo: () => void
        stopVideo: () => void
      }
      PlayerState: {
        ENDED: number
      }
    }
    onYouTubeIframeAPIReady?: () => void
  }
}

const playerContainer = ref<HTMLDivElement | null>(null)
let player: {
  loadVideoById: (videoId: string) => void
  destroy: () => void
  mute: () => void
  unMute: () => void
  playVideo: () => void
  stopVideo: () => void
} | null = null

let apiReadyPromise: Promise<void> | null = null

function loadYouTubeIframeAPI() {
  if (window.YT?.Player) {
    return Promise.resolve()
  }
  if (apiReadyPromise) return apiReadyPromise

  apiReadyPromise = new Promise<void>((resolve) => {
    const existing = document.getElementById('youtube-iframe-api')
    if (existing) {
      if (window.YT?.Player) {
        resolve()
        return
      }
      window.onYouTubeIframeAPIReady = () => resolve()
      return
    }

    const tag = document.createElement('script')
    tag.src = 'https://www.youtube.com/iframe_api'
    tag.id = 'youtube-iframe-api'
    window.onYouTubeIframeAPIReady = () => resolve()
    document.body.appendChild(tag)
  })

  return apiReadyPromise
}

const currentItem = computed(() => props.playlist[props.currentIndex] ?? null)

const heroStyle = computed(() => {
  const background = currentItem.value?.movie.backdrop_path
    ? `url(${buildImageUrl(currentItem.value.movie.backdrop_path, TMDB_IMAGE_SIZES.backdrop)})`
    : 'linear-gradient(135deg, #0f172a, #020617)'
  return {
    '--hero-video-background': background,
  }
})

watch(
  () => currentItem.value?.videoKey,
  async (key) => {
    if (!key) {
      if (player) {
        player.stopVideo()
        player.destroy()
        player = null
      }
      return
    }
    await loadYouTubeIframeAPI()
    if (!player && playerContainer.value && window.YT) {
      player = new window.YT.Player(playerContainer.value, {
        height: '100%',
        width: '100%',
        videoId: key,
        playerVars: {
          autoplay: 1,
          controls: 0,
          modestbranding: 1,
          playsinline: 1,
          fs: 0,
          rel: 0,
          mute: props.muted ? 1 : 0,
        },
        events: {
          onStateChange: (event: { data: number }) => {
            if (window.YT && event.data === window.YT.PlayerState.ENDED) {
              emit('ended')
            }
          },
        },
      })
    } else if (player) {
      player.loadVideoById(key)
      if (props.muted) {
        player.mute()
      } else {
        player.unMute()
      }
    }
  },
)

watch(
  () => props.muted,
  (muted) => {
    if (!player) return
    if (muted) player.mute()
    else player.unMute()
  },
)

onBeforeUnmount(() => {
  if (player) {
    player.destroy()
    player = null
  }
})
</script>

<style scoped>
.hero-banner {
  position: relative;
  overflow: hidden;
  min-height: clamp(320px, 50vh, 480px);
  background-image: var(--hero-video-background);
  background-size: cover;
  background-position: center;
  border: none;
  padding: 0;
}

.hero-banner__media {
  position: absolute;
  inset: 0;
  background: rgba(0, 0, 0, 0.6);
}

.hero-banner__player {
  width: 100%;
  height: 100%;
  pointer-events: none;
}

.hero-banner__fallback-media {
  width: 100%;
  height: 100%;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  text-align: center;
  gap: 0.6rem;
  color: #f8fafc;
  padding: 2rem;
  background: rgba(2, 6, 23, 0.8);
}

.hero-banner__fallback-eyebrow {
  letter-spacing: 0.4em;
  text-transform: uppercase;
  font-size: 0.75rem;
  color: #fbbf24;
}

.hero-banner__overlay {
  position: absolute;
  inset: 0;
  z-index: 2;
  padding: var(--space-lg) var(--space-lg) calc(var(--space-lg) * 0.4);
  display: flex;
  flex-direction: column;
  gap: var(--space-md);
  justify-content: flex-end;
  align-items: flex-start;
  width: 100%;
  height: 100%;
  color: #fff;
}

.hero-banner__eyebrow {
  text-transform: uppercase;
  letter-spacing: 0.35em;
  font-size: 0.75rem;
  color: #fbbf24;
  margin: 0;
}

.hero-banner__actions {
  align-self: flex-start;
  display: flex;
  flex-wrap: wrap;
  gap: 0.75rem;
  align-items: center;
  margin-top: auto;
}

.hero-btn {
  border-radius: 999px;
  border: 1px solid rgba(255, 255, 255, 0.5);
  padding: 0.45rem 1rem;
  font-weight: 600;
  font-size: 0.85rem;
  background: transparent;
  color: #fff;
  cursor: pointer;
  transition: transform 0.2s ease, box-shadow 0.2s ease, background 0.2s ease;
}

.hero-btn--primary {
  background: var(--color-accent);
  border-color: var(--color-accent);
  color: #0f172a;
}

.hero-btn--ghost {
  border-color: rgba(255, 255, 255, 0.3);
}

.hero-btn:hover {
  transform: translateY(-1px);
  box-shadow: 0 8px 20px rgba(0, 0, 0, 0.25);
}

.hero-banner__playlist {
  position: absolute;
  right: var(--space-md);
  bottom: var(--space-md);
  display: flex;
  gap: 0.4rem;
  z-index: 2;
}

.hero-dot {
  width: 10px;
  height: 10px;
  border-radius: 50%;
  border: none;
  background: rgba(255, 255, 255, 0.4);
  cursor: pointer;
  padding: 0;
}

.hero-dot.active {
  background: #fff;
  transform: scale(1.2);
}

.hero-banner__status {
  position: absolute;
  top: var(--space-md);
  right: var(--space-md);
  z-index: 3;
}

.hero-banner__status--error {
  color: #fecaca;
  font-weight: 500;
}

@media (max-width: 960px) {
  .hero-banner__overlay {
    max-width: 100%;
    padding: var(--space-md);
  }
}
</style>
