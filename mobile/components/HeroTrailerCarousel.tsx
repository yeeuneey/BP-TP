import { useEffect, useMemo, useRef, useState } from 'react'
import { ActivityIndicator, ImageBackground, Pressable, Text, View } from 'react-native'
import WebView, { WebViewMessageEvent } from 'react-native-webview'

import { fetchTrailerVideos, YoutubeVideo } from '../services/youtube'
import type { ThemeColors } from '../theme'
import { styles } from '../styles'

interface Props {
  colors: ThemeColors
  fontScale: (size: number) => number
}

export function HeroTrailerCarousel({ colors, fontScale }: Props) {
  const fs = fontScale
  const [trailers, setTrailers] = useState<YoutubeVideo[]>([])
  const [activeIndex, setActiveIndex] = useState(0)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const mountedRef = useRef(true)

  useEffect(() => {
    mountedRef.current = true
    ;(async () => {
      try {
        const data = await fetchTrailerVideos()
        if (mountedRef.current) {
          setTrailers(data)
          setActiveIndex(0)
        }
      } catch (err) {
        console.error(err)
        if (mountedRef.current) setError('트레일러를 불러오지 못했어요.')
      } finally {
        if (mountedRef.current) setLoading(false)
      }
    })()

    return () => {
      mountedRef.current = false
    }
  }, [])

  const current = trailers[activeIndex]

  const playerHtml = useMemo(() => {
    if (!current?.id) return ''
    return `
      <!DOCTYPE html>
      <html>
        <head>
          <style>
            html, body {
              margin: 0;
              padding: 0;
              background: black;
              overflow: hidden;
              width: 100%;
              height: 100%;
            }
            #player {
              position: absolute;
              top: 0;
              left: 0;
              width: 100%;
              height: 100%;
            }
          </style>
          <script src="https://www.youtube.com/iframe_api"></script>
          <script>
            let player;
            function onYouTubeIframeAPIReady() {
              player = new YT.Player('player', {
                videoId: '${current.id}',
                playerVars: {
                  autoplay: 1,
                  controls: 0,
                  modestbranding: 1,
                  rel: 0,
                  playsinline: 1,
                  mute: 1
                },
                events: {
                  onReady: () => player.playVideo(),
                  onStateChange: (event) => {
                    if (event.data === YT.PlayerState.ENDED) {
                      window.ReactNativeWebView && window.ReactNativeWebView.postMessage('ENDED');
                    }
                  }
                }
              });
            }
          </script>
        </head>
        <body>
          <div id="player"></div>
        </body>
      </html>
    `
  }, [current?.id])

  const handleMessage = (event: WebViewMessageEvent) => {
    if (event.nativeEvent.data === 'ENDED' && trailers.length > 0) {
      setActiveIndex((prev) => (prev + 1) % trailers.length)
    }
  }

  const handlePrev = () => {
    if (!trailers.length) return
    setActiveIndex((prev) => (prev - 1 + trailers.length) % trailers.length)
  }

  const handleNext = () => {
    if (!trailers.length) return
    setActiveIndex((prev) => (prev + 1) % trailers.length)
  }

  return (
    <View style={[styles.heroBanner, { borderColor: colors.border }]}>
      <View style={styles.heroVideoWrapper}>
        {current?.id ? (
          <WebView
            key={current.id}
            originWhitelist={['*']}
            allowsInlineMediaPlayback
            mediaPlaybackRequiresUserAction={false}
            scrollEnabled={false}
            source={{ html: playerHtml }}
            style={styles.heroVideo}
            onMessage={handleMessage}
          />
        ) : (
          <ImageBackground
            source={{ uri: current?.thumbnail ?? 'https://dummyimage.com/800x450/111827/ffffff&text=Trailers' }}
            style={styles.heroVideo}
            resizeMode="cover"
          >
            <View style={[styles.heroFallback, { backgroundColor: 'rgba(0,0,0,0.45)' }]}>
              {loading ? (
                <ActivityIndicator color={colors.accent} />
              ) : (
                <Text style={{ color: colors.text, fontWeight: '700' }}>{error ?? '트레일러가 없습니다.'}</Text>
              )}
            </View>
          </ImageBackground>
        )}
        <View style={[styles.heroOverlay, { backgroundColor: 'rgba(0,0,0,0.35)' }]}>
          <View style={{ flex: 1, justifyContent: 'flex-end', gap: 8 }}>
            <Text style={[styles.heroEyebrow, { color: '#e5e7eb' }]}>예고편 자동재생</Text>
            <Text style={[styles.heroTitle, { color: '#fff', fontSize: fs(22) }]} numberOfLines={1}>
              {current?.title ?? 'YouTube 트레일러'}
            </Text>
            <Text style={[styles.heroSubtitle, { color: '#e5e7eb', fontSize: fs(12) }]} numberOfLines={2}>
              {current?.channelTitle ? `${current.channelTitle} · Next up` : '홈 상단에서 바로 예고편을 확인하세요.'}
            </Text>
            <View style={styles.heroControls}>
              <Pressable
                style={({ pressed }) => [
                  styles.heroControlButton,
                  { backgroundColor: pressed ? colors.accent : colors.card, borderColor: colors.border },
                ]}
                onPress={handlePrev}
              >
                {({ pressed }) => (
                  <Text style={{ color: pressed ? '#fff' : colors.text, fontWeight: '800', fontSize: fs(16) }}>
                    {'\u2039'}
                  </Text>
                )}
              </Pressable>
              <Text style={[styles.heroCounter, { color: colors.text, fontSize: fs(12) }]}>
                {trailers.length ? `${activeIndex + 1} / ${trailers.length}` : '0 / 0'}
              </Text>
              <Pressable
                style={({ pressed }) => [
                  styles.heroControlButton,
                  { backgroundColor: pressed ? colors.accent : colors.card, borderColor: colors.border },
                ]}
                onPress={handleNext}
              >
                {({ pressed }) => (
                  <Text style={{ color: pressed ? '#fff' : colors.text, fontWeight: '800', fontSize: fs(16) }}>
                    {'\u203a'}
                  </Text>
                )}
              </Pressable>
            </View>
          </View>
        </View>
      </View>
    </View>
  )
}
