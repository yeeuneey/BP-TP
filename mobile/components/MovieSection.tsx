import { FlatList, Image, Text, TouchableOpacity, View } from 'react-native'

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
              <TouchableOpacity
                style={[
                  styles.wishHeart,
                  picked && styles.wishHeartActive,
                  { borderColor: colors.border },
                ]}
                onPress={() => onToggleWishlist(item)}
                activeOpacity={0.8}
              >
                <Text style={{ color: '#fff', fontWeight: '800', fontSize: 18 }}>
                  {picked ? '❤' : '❤'}
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
                {item.overview || '줄거리가 없습니다.'}
              </Text>
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
