import { ActivityIndicator, Pressable, Text, TextInput, View } from 'react-native'

import { MovieSection } from '../components/MovieSection'
import type { ThemeColors } from '../theme'
import { styles } from '../styles'
import { Movie, WishlistItem } from '../types'

interface Props {
  colors: ThemeColors
  fontScale: (size: number) => number
  loading: boolean
  searchQuery: string
  setSearchQuery: (value: string) => void
  onSearch: () => void
  results: Movie[]
  wishlist: WishlistItem[]
  onToggleWishlist: (movie: Movie) => void
}

export function SearchScreen({
  colors,
  fontScale,
  loading,
  searchQuery,
  setSearchQuery,
  onSearch,
  results,
  wishlist,
  onToggleWishlist,
}: Props) {
  const fs = fontScale

  return (
    <View style={styles.section}>
      <Text style={[styles.sectionTitle, { color: colors.text, fontSize: fs(18) }]}>검색</Text>
      <View style={styles.searchRow}>
        <TextInput
          placeholder="검색어를 입력하세요"
          placeholderTextColor="#9ca3af"
          style={[styles.searchInput, { backgroundColor: colors.card, borderColor: colors.border, color: colors.text }]}
          value={searchQuery}
          onChangeText={setSearchQuery}
          onSubmitEditing={onSearch}
          returnKeyType="search"
      />
      <Pressable
        style={({ pressed }) => [
          styles.secondaryButton,
          {
            borderColor: pressed ? colors.accent : colors.border,
            backgroundColor: pressed ? colors.accent : colors.card,
          },
        ]}
        onPress={onSearch}
      >
        {({ pressed }) => (
          <Text style={[styles.secondaryText, { color: pressed ? '#fff' : colors.text }]}>검색</Text>
        )}
      </Pressable>
      </View>
      {loading && <ActivityIndicator color="#e50914" style={{ marginVertical: 10 }} />}
      {!!results.length && (
        <MovieSection
          title="검색 결과"
          data={results}
          colors={colors}
          fontScale={fs}
          wishlist={wishlist}
          onToggleWishlist={onToggleWishlist}
        />
      )}
    </View>
  )
}
