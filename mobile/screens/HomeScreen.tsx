import { ActivityIndicator, Text, TextInput, TouchableOpacity, View } from 'react-native'

import { HeroTrailerCarousel } from '../components/HeroTrailerCarousel'
import { MovieSection } from '../components/MovieSection'
import type { ThemeColors } from '../theme'
import { styles } from '../styles'
import { Movie, TabKey, WishlistItem } from '../types'

interface Props {
  colors: ThemeColors
  fontScale: (size: number) => number
  searchQuery: string
  setSearchQuery: (value: string) => void
  onSearch: () => void
  loadingMovies: boolean
  popular: Movie[]
  nowPlaying: Movie[]
  topRated: Movie[]
  wishlist: WishlistItem[]
  onToggleWishlist: (movie: Movie) => void
  setCurrentTab: (tab: TabKey) => void
}

export function HomeScreen({
  colors,
  fontScale,
  searchQuery,
  setSearchQuery,
  onSearch,
  loadingMovies,
  popular,
  nowPlaying,
  topRated,
  wishlist,
  onToggleWishlist,
  setCurrentTab,
}: Props) {
  const fs = fontScale

  return (
    <>
      <HeroTrailerCarousel colors={colors} fontScale={fontScale} />
      <View style={styles.hero}>
        <Text style={[styles.heroEyebrow, { color: colors.muted }]}>FOR YOU</Text>
        <Text style={[styles.heroTitle, { color: colors.text }]}>TMDB API로 랜덤 추천</Text>
        <Text style={[styles.heroSubtitle, { color: colors.muted }]}>
          트렌딩, 극장 상영, 평점 높은 작품을 여기에서 만나보세요.
        </Text>
        <View style={styles.searchRow}>
          <TextInput
            placeholder="검색어를 입력하세요"
            placeholderTextColor="#9ca3af"
            style={[styles.searchInput, { backgroundColor: colors.card, borderColor: colors.border, color: colors.text }]}
            value={searchQuery}
            onChangeText={setSearchQuery}
            onSubmitEditing={() => {
              onSearch()
              setCurrentTab('search')
            }}
            returnKeyType="search"
          />
          <TouchableOpacity
            style={[styles.secondaryButton, { borderColor: colors.border, backgroundColor: colors.card }]}
            onPress={() => {
              onSearch()
              setCurrentTab('search')
            }}
            activeOpacity={0.85}
        >
          <Text style={[styles.secondaryText, { color: colors.text }]}>검색</Text>
        </TouchableOpacity>
        </View>
      </View>
      {loadingMovies && <ActivityIndicator color="#e50914" style={{ marginVertical: 10 }} />}
      <MovieSection
        title="지금 가장 인기 있는 영화"
        data={popular}
        colors={colors}
        fontScale={fs}
        wishlist={wishlist}
        onToggleWishlist={onToggleWishlist}
      />
      <View style={{ height: 14 }} />
      <MovieSection
        title="극장에서 만나는 신작"
        data={nowPlaying}
        colors={colors}
        fontScale={fs}
        wishlist={wishlist}
        onToggleWishlist={onToggleWishlist}
      />
      <View style={{ height: 14 }} />
      <MovieSection
        title="평점 높은 영화"
        data={topRated}
        colors={colors}
        fontScale={fs}
        wishlist={wishlist}
        onToggleWishlist={onToggleWishlist}
      />
    </>
  )
}
