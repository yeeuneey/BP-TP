import { useMemo } from 'react'
import { Image, Text, TouchableOpacity, View, useWindowDimensions } from 'react-native'

import type { ThemeColors } from '../theme'
import { styles } from '../styles'
import { Movie, WishlistItem } from '../types'

interface Props {
  colors: ThemeColors
  fontScale: (size: number) => number
  wishlist: WishlistItem[]
  onToggleWishlist: (movie: Movie) => void
}

export function WishlistScreen({ colors, fontScale, wishlist, onToggleWishlist }: Props) {
  const fs = fontScale
  const { width: windowWidth } = useWindowDimensions()
  const data: Movie[] = useMemo(
    () => wishlist.map((w) => ({ id: w.id, title: w.title, overview: '', poster: w.poster })),
    [wishlist],
  )
  const cardWidth = Math.max(100, (windowWidth - 40 - 16 - 16) / 3) // match search grid sizing

  return (
    <View style={[styles.section, { flex: 1 }]}>
      <Text style={[styles.sectionTitle, { color: colors.text, fontSize: fs(18) }]}>위시리스트</Text>
      {data.length === 0 ? (
        <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center', paddingVertical: 20 }}>
          <Text style={{ color: colors.muted, fontSize: fs(14) }}>위시리스트가 비어 있습니다.</Text>
        </View>
      ) : (
        <View
          style={{
            flexDirection: 'row',
            flexWrap: 'wrap',
            columnGap: 8,
            rowGap: 12,
            paddingHorizontal: 8,
            paddingBottom: 16,
            flexGrow: 1,
          }}
        >
          {data.map((item) => {
            const picked = wishlist.some((w) => w.id === item.id)
            const heartTextColor = picked ? '#fff' : colors.text
            return (
              <View
                key={item.id}
                style={[
                  styles.card,
                  {
                    width: cardWidth,
                    marginRight: 0,
                    backgroundColor: colors.card,
                    borderColor: colors.border,
                  },
                ]}
              >
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
                  style={[styles.poster, { width: cardWidth - 20 }]}
                  resizeMode="cover"
                />
                <Text style={[styles.cardTitle, { color: colors.text, fontSize: fs(14) }]} numberOfLines={1}>
                  {item.title}
                </Text>
                <Text style={[styles.cardTag, { color: colors.muted, fontSize: fs(12) }]} numberOfLines={2}>
                  정보가 없습니다.
                </Text>
              </View>
            )
          })}
        </View>
      )}
    </View>
  )
}
