import { useRef, useState } from 'react'
import { FlatList, Image, Pressable, Text, TouchableOpacity, View } from 'react-native'
import type { ThemeColors } from '../theme'
import { styles } from '../styles'
import { Movie, WishlistItem } from '../types'

interface Props {
  title: string
  data: Movie[]
  colors: ThemeColors
  fontScale: (size: number) => number
  wishlist: WishlistItem[]
  onToggleWishlist: (movie: Movie) => void
}

export function MovieSection({ title, data, colors, fontScale, wishlist, onToggleWishlist }: Props) {
  const fs = fontScale
  const listRef = useRef<FlatList<Movie>>(null)
  const [scrollX, setScrollX] = useState(0)
  const STEP = 160

  return (
    <View style={styles.section}>
      <Text style={[styles.sectionTitle, { color: colors.text, fontSize: fs(16) }]}>{title}</Text>
      <View style={{ position: 'relative' }}>
        <FlatList
          ref={listRef}
          data={data}
          keyExtractor={(item) => String(item.id)}
          horizontal
          showsHorizontalScrollIndicator={false}
          nestedScrollEnabled
          directionalLockEnabled
          onScroll={(e) => setScrollX(e.nativeEvent.contentOffset.x)}
          scrollEventThrottle={16}
          renderItem={({ item }) => {
            const picked = wishlist.some((w) => w.id === item.id)
            const heartTextColor = picked ? '#fff' : colors.text
            return (
              <View style={[styles.card, { backgroundColor: colors.card, borderColor: colors.border }]}>
                <TouchableOpacity
                  style={[
                    styles.wishHeart,
                    picked && styles.wishHeartActive,
                    { borderColor: colors.border, backgroundColor: picked ? colors.accent : colors.card },
                  ]}
                  onPress={() => onToggleWishlist(item)}
                  activeOpacity={0.8}
                >
                  <Text style={{ color: heartTextColor, fontWeight: '800', fontSize: 18 }}>
                    {picked ? '\u2665' : '\u2661'}
                  </Text>
                </TouchableOpacity>
                <Image
                  source={
                    item.poster
                      ? { uri: item.poster }
                      : { uri: 'https://dummyimage.com/500x750/111827/ffffff&text=No+Image' }
                  }
                  style={styles.poster}
                  resizeMode="cover"
                />
                <Text style={[styles.cardTitle, { color: colors.text, fontSize: fs(14) }]} numberOfLines={1}>
                  {item.title}
                </Text>
                <Text style={[styles.cardTag, { color: colors.muted, fontSize: fs(12) }]} numberOfLines={2}>
                  {item.overview || '정보가 없습니다.'}
                </Text>
              </View>
            )
          }}
        />
        <View style={styles.sliderArrows} pointerEvents="box-none">
          <Pressable
            style={({ pressed }) => [
              styles.sliderArrow,
              { backgroundColor: pressed ? colors.accent : colors.card, borderColor: colors.border },
            ]}
            onPress={() => {
              const next = Math.max(0, scrollX - STEP)
              listRef.current?.scrollToOffset({ offset: next, animated: true })
            }}
          >
            {({ pressed }) => (
              <Text style={{ color: pressed ? '#fff' : colors.text, fontWeight: '800', fontSize: 25 }}>
                {'\u2039'}
              </Text>
            )}
          </Pressable>
          <Pressable
            style={({ pressed }) => [
              styles.sliderArrow,
              { backgroundColor: pressed ? colors.accent : colors.card, borderColor: colors.border },
            ]}
            onPress={() => {
              const next = scrollX + STEP
              listRef.current?.scrollToOffset({ offset: next, animated: true })
            }}
          >
            {({ pressed }) => (
              <Text style={{ color: pressed ? '#fff' : colors.text, fontWeight: '800', fontSize: 25 }}>
                {'\u203a'}
              </Text>
            )}
          </Pressable>
        </View>
      </View>
    </View>
  )
}
