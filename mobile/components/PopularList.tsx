import { Image } from 'expo-image'
import { ActivityIndicator, Text, TouchableOpacity, View } from 'react-native'

import type { ThemeColors } from '../theme'
import { styles } from '../styles'
import { Movie, WishlistItem } from '../types'

interface Props {
  data: Movie[]
  wishlist: WishlistItem[]
  colors: ThemeColors
  fontScale: (size: number) => number
  loading: boolean
  hasMore: boolean
  page: number
  onLoadMore: (page: number) => void
  onToggleWishlist: (movie: Movie) => void
}

export function PopularList({
  data,
  wishlist,
  colors,
  fontScale,
  loading,
  hasMore,
  page,
  onLoadMore,
  onToggleWishlist,
}: Props) {
  const fs = fontScale

  return (
    <View style={{ gap: 10 }}>
      {data.map((item) => {
        const picked = wishlist.some((w) => w.id === item.id)
        return (
          <View key={item.id} style={[styles.popularCard, { backgroundColor: colors.card, borderColor: colors.border }]}>
            <Image
              source={
                item.poster
                  ? { uri: item.poster, cachePolicy: 'memory-disk' }
                  : { uri: 'https://dummyimage.com/500x750/111827/ffffff&text=No+Image' }
              }
              placeholder={require('../assets/icon.png')}
              style={styles.popularPoster}
              contentFit="cover"
              transition={150}
            />
            <View style={styles.popularBody}>
              <Text style={[styles.cardTitle, { color: colors.text, fontSize: fs(14) }]} numberOfLines={1}>
                {item.title}
              </Text>
              <Text style={[styles.cardTag, { color: colors.muted, fontSize: fs(12) }]} numberOfLines={2}>
                {item.overview || '줄거리가 없습니다.'}
              </Text>
              <TouchableOpacity
                style={[styles.wishButton, picked && styles.wishButtonActive, { borderColor: colors.border }]}
                onPress={() => onToggleWishlist(item)}
              >
                <Text style={[styles.wishButtonText, { color: colors.text, fontSize: fs(12) }]}>
                  {picked ? '취소됨' : '위시리스트'}
                </Text>
              </TouchableOpacity>
            </View>
          </View>
        )
      })}
      {hasMore && (
        <TouchableOpacity
          style={[styles.secondaryButton, { borderColor: colors.border, backgroundColor: colors.card, marginTop: 6 }]}
          onPress={() => !loading && onLoadMore(page + 1)}
          activeOpacity={0.85}
        >
          {loading ? <ActivityIndicator color={colors.accent} /> : <Text style={[styles.secondaryText, { color: colors.text }]}>더보기</Text>}
        </TouchableOpacity>
      )}
    </View>
  )
}
