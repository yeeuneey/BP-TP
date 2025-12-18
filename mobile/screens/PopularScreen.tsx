import { ActivityIndicator, Text, View } from 'react-native'

import { PopularList } from '../components/PopularList'
import type { ThemeColors } from '../theme'
import { styles } from '../styles'
import { Movie, WishlistItem } from '../types'

interface Props {
  colors: ThemeColors
  fontScale: (size: number) => number
  loading: boolean
  popular: Movie[]
  wishlist: WishlistItem[]
  hasMore: boolean
  page: number
  onLoadMore: (page: number) => void
  onToggleWishlist: (movie: Movie) => void
}

export function PopularScreen({
  colors,
  fontScale,
  loading,
  popular,
  wishlist,
  hasMore,
  page,
  onLoadMore,
  onToggleWishlist,
}: Props) {
  const fs = fontScale
  const initialLoading = loading && popular.length === 0

  return (
    <View style={styles.section}>
      <Text style={[styles.sectionTitle, { color: colors.text, fontSize: fs(18) }]}>지금 가장 있기 있는 영화</Text>
      {initialLoading ? (
        <ActivityIndicator color="#e50914" />
      ) : (
        <PopularList
          data={popular}
          wishlist={wishlist}
          colors={colors}
          fontScale={fs}
          loading={loading}
          hasMore={hasMore}
          page={page}
          onLoadMore={onLoadMore}
          onToggleWishlist={onToggleWishlist}
        />
      )}
    </View>
  )
}


