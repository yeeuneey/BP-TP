import { useState } from 'react'
import {
  ActivityIndicator,
  FlatList,
  Image,
  Pressable,
  Text,
  TextInput,
  TouchableOpacity,
  View,
  useWindowDimensions,
} from 'react-native'

import { MovieSection } from '../components/MovieSection'
import type { ThemeColors } from '../theme'
import { styles } from '../styles'
import { Movie, SearchGenre, SearchLanguage, SearchSort, SearchYearRange, WishlistItem } from '../types'

interface Props {
  colors: ThemeColors
  fontScale: (size: number) => number
  loading: boolean
  searchQuery: string
  setSearchQuery: (value: string) => void
  onSearch: (sortOverride?: SearchSort) => void
  searchSort: SearchSort | null
  setSearchSort: (value: SearchSort | null) => void
  searchGenre: SearchGenre
  setSearchGenre: (value: SearchGenre) => void
  searchLanguage: SearchLanguage
  setSearchLanguage: (value: SearchLanguage) => void
  searchYear: SearchYearRange
  setSearchYear: (value: SearchYearRange) => void
  onResetFilters: () => void
  results: Movie[]
  page: number
  hasMore: boolean
  onLoadMore: (page: number) => void
  searchActive: boolean
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
  searchSort,
  setSearchSort,
  searchGenre,
  setSearchGenre,
  searchLanguage,
  setSearchLanguage,
  searchYear,
  setSearchYear,
  onResetFilters,
  results,
  page,
  hasMore,
  onLoadMore,
  searchActive,
  wishlist,
  onToggleWishlist,
}: Props) {
  const fs = fontScale
  const hasResults = results.length > 0
  const [openFilter, setOpenFilter] = useState<'genre' | 'language' | 'year' | null>(null)
  const { width: windowWidth } = useWindowDimensions()
  const cardWidth = Math.max(100, (windowWidth - 40 - 16 - 16) / 3) // section padding 40 + column padding 16 + gaps ~16
  const sortOptions: Array<{ key: SearchSort; label: string }> = [
    { key: 'popular', label: '인기순' },
    { key: 'latest', label: '최신순' },
    { key: 'rating', label: '평점순' },
    { key: 'title', label: '제목순' },
  ]
  const genreOptions: Array<{ value: SearchGenre; label: string }> = [
    { value: 'all', label: '전체' },
    { value: '액션', label: '액션' },
    { value: '어드벤처', label: '어드벤처' },
    { value: '애니메이션', label: '애니메이션' },
    { value: '코미디', label: '코미디' },
    { value: '범죄', label: '범죄' },
    { value: '드라마', label: '드라마' },
    { value: '판타지', label: '판타지' },
    { value: '공포', label: '공포' },
    { value: '로맨스', label: '로맨스' },
    { value: 'SF', label: 'SF' },
    { value: '스릴러', label: '스릴러' },
  ]
  const languageOptions: Array<{ value: SearchLanguage; label: string }> = [
    { value: 'all', label: '전체' },
    { value: 'ko', label: '한국어' },
    { value: 'en', label: '영어' },
    { value: 'ja', label: '일본어' },
  ]
  const yearOptions: Array<{ value: SearchYearRange; label: string }> = [
    { value: 'all', label: '전체' },
    { value: '2020+', label: '2020년 이후' },
    { value: '2010s', label: '2010-2019' },
    { value: '2000s', label: '2000-2009' },
    { value: '1990s', label: '1990-1999' },
    { value: 'pre1990', label: '1990년 이전' },
  ]

  const renderSelect = <T extends string>(
    label: string,
    value: T,
    options: Array<{ value: T; label: string }>,
    onChange: (value: T) => void,
    key: 'genre' | 'language' | 'year',
  ) => {
    const selected = options.find((o) => o.value === value)?.label ?? '전체'
    return (
      <View style={styles.filterGroup}>
        <Text style={[styles.filterLabel, { color: colors.text }]}>{label}</Text>
        <Pressable
          style={({ pressed }) => [
            styles.filterSelect,
            {
              borderColor: pressed || openFilter === key ? colors.accent : colors.border,
              backgroundColor: colors.card,
            },
          ]}
          onPress={() => setOpenFilter((prev) => (prev === key ? null : key))}
        >
          <Text style={[styles.filterSelectText, { color: colors.text }]}>{selected}</Text>
          <Text style={[styles.filterCaret, { color: colors.text }]}>▾</Text>
        </Pressable>
        {openFilter === key && (
          <View style={[styles.filterDropdown, { borderColor: colors.border, backgroundColor: colors.card }]}>
            {options.map((option) => {
              const active = option.value === value
              return (
                <Pressable
                  key={option.value}
                  style={({ pressed }) => [
                    styles.filterOption,
                    {
                      backgroundColor: active || pressed ? colors.accent : colors.card,
                    },
                  ]}
                  onPress={() => {
                    onChange(option.value)
                    setOpenFilter(null)
                    onSearch()
                  }}
                >
                  {({ pressed }) => (
                    <Text
                      style={[
                        styles.filterOptionText,
                        { color: active || pressed ? '#fff' : colors.text },
                      ]}
                    >
                      {option.label}
                    </Text>
                  )}
                </Pressable>
              )
            })}
          </View>
        )}
      </View>
    )
  }

  const handleReset = () => {
    setOpenFilter(null)
    onResetFilters()
  }

  return (
    <View style={[styles.section, { flex: 1 }]}>
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
          onPress={() => onSearch()}
        >
          {({ pressed }) => (
            <Text style={[styles.secondaryText, { color: pressed ? '#fff' : colors.text }]}>검색</Text>
          )}
        </Pressable>
      </View>
      <View style={styles.sortSection}>
        <Text style={[styles.sortLabel, { color: colors.text }]}>정렬</Text>
        <View style={styles.sortRow}>
          {sortOptions.map((option) => {
            const active = option.key === searchSort
            return (
              <Pressable
                key={option.key}
                style={({ pressed }) => [
                  styles.sortChip,
                  {
                    borderColor: active ? colors.accent : colors.border,
                    backgroundColor: active || pressed ? colors.accent : colors.card,
                  },
                ]}
                onPress={() => {
                  setSearchSort(option.key)
                  onSearch(option.key)
                }}
              >
                {({ pressed }) => (
                  <Text
                    style={[
                      styles.sortChipText,
                      { color: active || pressed ? '#fff' : colors.text },
                    ]}
                  >
                    {option.label}
                  </Text>
                )}
              </Pressable>
            )
          })}
        </View>
      </View>
      <View style={styles.filterSection}>
        <View style={styles.filterRow}>
          {renderSelect('장르', searchGenre, genreOptions, setSearchGenre, 'genre')}
          {renderSelect('언어', searchLanguage, languageOptions, setSearchLanguage, 'language')}
          {renderSelect('개봉 연도', searchYear, yearOptions, setSearchYear, 'year')}
        </View>
        <Pressable
          style={({ pressed }) => [
            styles.filterReset,
            {
              backgroundColor: pressed ? '#b20710' : colors.accent,
            },
          ]}
          onPress={handleReset}
        >
          <Text style={styles.filterResetText}>필터 초기화</Text>
        </Pressable>
      </View>
      {loading && <ActivityIndicator color="#e50914" style={{ marginVertical: 10 }} />}
      <View style={{ flex: 1, marginTop: 12 }}>
        <Text style={[styles.sectionTitle, { color: colors.text, fontSize: fs(16) }]}>검색 결과</Text>
        <FlatList
          data={searchActive ? results : []}
          style={{ flex: 1 }}
          keyExtractor={(item) => String(item.id)}
          numColumns={3}
          columnWrapperStyle={{ gap: 8, paddingHorizontal: 8, justifyContent: 'flex-start' }}
          contentContainerStyle={{ gap: 12, paddingBottom: 16, flexGrow: 1 }}
          renderItem={({ item }) => {
            const picked = wishlist.some((w) => w.id === item.id)
            const heartTextColor = picked ? '#fff' : colors.text
            return (
              <View
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
                  style={[styles.poster, { width: cardWidth - 20 }]} // account for card padding
                  resizeMode="cover"
                />
                <Text style={[styles.cardTitle, { color: colors.text, fontSize: fs(14) }]} numberOfLines={1}>
                  {item.title}
                </Text>
                <Text style={[styles.cardTag, { color: colors.muted, fontSize: fs(12) }]} numberOfLines={2}>
                  {item.overview || '정보가 부족합니다.'}
                </Text>
              </View>
            )
          }}
          onEndReachedThreshold={0.4}
          onEndReached={() => searchActive && hasMore && onLoadMore(page + 1)}
          ListFooterComponent={
            loading ? (
              <View style={{ paddingVertical: 12 }}>
                <ActivityIndicator color={colors.accent} />
              </View>
            ) : null
          }
          ListEmptyComponent={
            !loading ? (
              <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center', paddingVertical: 20 }}>
                <Text style={{ color: colors.muted, fontSize: fs(14), marginBottom: 10 }}>
                  결과가 없습니다. 검색어를 입력하거나 정렬/필터를 선택하세요.
                </Text>
              </View>
            ) : null
          }
        />
      </View>
    </View>
  )
}
