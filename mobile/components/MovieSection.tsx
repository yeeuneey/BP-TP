import { Image } from 'expo-image'
import { FlatList, Text, TouchableOpacity, View } from 'react-native'

import type { ThemeColors } from '../theme'
import { styles } from '../styles'
import { Movie, WishlistItem } from '../types'

interface Props {
  title: string
  data: Movie[]
  colors: ThemeColors
  fontScale: (size: number) => number
  wishlist: WishlistItem[]
  recommended: WishlistItem[]
  onToggleWishlist: (movie: Movie) => void
  onToggleRecommended: (movie: Movie) => void
}

export function MovieSection({
  title,
  data,
  colors,
  fontScale,
  wishlist,
  recommended,
  onToggleWishlist,
  onToggleRecommended,
}: Props) {
  const fs = fontScale

  return (
    <View style={styles.section}>
      <Text style={[styles.sectionTitle, { color: colors.text, fontSize: fs(16) }]}>{title}</Text>
      <FlatList
        data={data}
        keyExtractor={(item) => String(item.id)}
        horizontal
        showsHorizontalScrollIndicator={false}
        renderItem={({ item }) => {
          const picked = wishlist.some((w) => w.id === item.id)
          const rec = recommended.some((w) => w.id === item.id)
          return (
            <View style={[styles.card, { backgroundColor: colors.card, borderColor: colors.border }]}>
              <Image
                source={
                  item.poster
                    ? { uri: item.poster, cachePolicy: 'memory-disk' }
                    : { uri: 'https://dummyimage.com/500x750/111827/ffffff&text=No+Image' }
                }
                placeholder={require('../assets/icon.png')}
                style={styles.poster}
                contentFit="cover"
                transition={150}
              />
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
              <TouchableOpacity
                style={[
                  styles.wishButton,
                  rec && styles.wishButtonActive,
                  { borderColor: colors.border, marginTop: 6 },
                ]}
                onPress={() => onToggleRecommended(item)}
              >
                <Text style={[styles.wishButtonText, { color: colors.text, fontSize: fs(12) }]}>
                  {rec ? '추천 취소' : '추천'}
                </Text>
              </TouchableOpacity>
            </View>
          )
        }}
      />
    </View>
  )
}
