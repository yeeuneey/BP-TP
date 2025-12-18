import { StatusBar } from 'expo-status-bar'
import { useEffect, useMemo, useRef, useState } from 'react'
import { Alert, Modal, Pressable, ScrollView, Text, TouchableOpacity, TouchableWithoutFeedback, View } from 'react-native'
import { SafeAreaView } from 'react-native-safe-area-context'
import {
  createUserWithEmailAndPassword,
  onAuthStateChanged,
  signInWithEmailAndPassword,
  signOut,
  type User,
} from 'firebase/auth'
import { collection, doc, getDoc, setDoc } from 'firebase/firestore'

import { auth, db } from './firebaseConfig'
import { AuthScreen, type AuthScreenHandle } from './screens/AuthScreen'
import { HomeScreen } from './screens/HomeScreen'
import { PopularScreen } from './screens/PopularScreen'
import { SearchScreen } from './screens/SearchScreen'
import { WishlistScreen } from './screens/WishlistScreen'
import { palette, type ThemeColors } from './theme'
import { styles } from './styles'
import {
  fetchNowPlaying,
  fetchPopular,
  fetchTopRated,
  searchMovies,
  fetchMovieDetails,
  posterUrl,
  type TmdbMovie,
} from './services/tmdb'
import type {
  Mode,
  Movie,
  SearchGenre,
  SearchLanguage,
  SearchSort,
  SearchYearRange,
  TabKey,
  WishlistItem,
} from './types'

export default function App() {
  const [mode, setMode] = useState<Mode>('login')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [passwordConfirm, setPasswordConfirm] = useState('')
  const [user, setUser] = useState<User | null>(null)
  const [busy, setBusy] = useState(false)
  const curtainRef = useRef<AuthScreenHandle>(null)

  const [popular, setPopular] = useState<Movie[]>([])
  const [popularPage, setPopularPage] = useState(1)
  const [hasMorePopular, setHasMorePopular] = useState(true)
  const [nowPlaying, setNowPlaying] = useState<Movie[]>([])
  const [topRated, setTopRated] = useState<Movie[]>([])
  const [wishlist, setWishlist] = useState<WishlistItem[]>([])
  const [searchQuery, setSearchQuery] = useState('')
  const [searchResults, setSearchResults] = useState<Movie[]>([])
  const [searchSort, setSearchSort] = useState<SearchSort>('popular')
  const [searchGenre, setSearchGenre] = useState<SearchGenre>('all')
  const [searchLanguage, setSearchLanguage] = useState<SearchLanguage>('all')
  const [searchYear, setSearchYear] = useState<SearchYearRange>('all')
  const [loadingMovies, setLoadingMovies] = useState(false)
  const [loadingPopular, setLoadingPopular] = useState(false)
  const [theme, setTheme] = useState<'dark' | 'light'>('dark')
  const [fontLevel, setFontLevel] = useState(4) // 1~7 -> 0.90~1.20
  const [reduceMotion, setReduceMotion] = useState(false)
  const [navOpen, setNavOpen] = useState(false)
  const [settingsOpen, setSettingsOpen] = useState(false)
  const [currentTab, setCurrentTab] = useState<TabKey>('home')
  const [confirmMovie, setConfirmMovie] = useState<Movie | null>(null)
  const [showPopularTop, setShowPopularTop] = useState(false)
  const scrollRef = useRef<ScrollView>(null)
  const [menuButtonLayout, setMenuButtonLayout] = useState({ x: 0, y: 0, width: 0, height: 0 })
  const [settingsButtonLayout, setSettingsButtonLayout] = useState({ x: 0, y: 0, width: 0, height: 0 })
  const popularLoadSeq = useRef(0)
  const closePanels = () => {
    setNavOpen(false)
    setSettingsOpen(false)
  }

  useEffect(() => {
    const unsub = onAuthStateChanged(auth, (next) => {
      setUser(next)
      if (next) {
        loadMovies()
        fetchWishlist(next.uid)
      } else {
        setWishlist([])
      }
    })
    return unsub
  }, [])

  function mapMovies(items: TmdbMovie[]): Movie[] {
    const countryName = (code?: string) => {
      const map: Record<string, string> = {
        KR: '대한민국',
        US: '미국',
        JP: '일본',
        CN: '중국',
        GB: '영국',
        FR: '프랑스',
        DE: '독일',
        FI: '핀란드',
        SE: '스웨덴',
        ES: '스페인',
        IT: '이탈리아',
        CA: '캐나다',
        AU: '호주',
        IN: '인도',
        BR: '브라질',
        MX: '멕시코',
        RU: '러시아',
      }
      return code ? map[code.toUpperCase()] ?? code.toUpperCase() : undefined
    }
    const genreNames: Record<number, string> = {
      28: '액션',
      12: '어드벤처',
      16: '애니메이션',
      35: '코미디',
      80: '범죄',
      99: '다큐멘터리',
      18: '드라마',
      10751: '가족',
      14: '판타지',
      36: '역사',
      27: '공포',
      10402: '음악',
      9648: '미스터리',
      10749: '로맨스',
      878: 'SF',
      10770: 'TV 영화',
      53: '스릴러',
      10752: '전쟁',
      37: '서부',
    }
    return items.map((m) => ({
      id: m.id,
      title: m.title,
      overview: m.overview,
      poster: posterUrl(m.poster_path),
      rating: m.vote_average,
      releaseDate: m.release_date,
      genres: m.genre_ids?.map((id) => genreNames[id]).filter(Boolean),
      country: countryName(m.origin_country?.[0]),
      language: m.original_language,
    }))
  }

  async function hydrateDetails(movies: Movie[]) {
    const countryName = (code?: string) => {
      const map: Record<string, string> = {
        KR: '대한민국',
        US: '미국',
        JP: '일본',
        CN: '중국',
        GB: '영국',
        FR: '프랑스',
        DE: '독일',
        FI: '핀란드',
        SE: '스웨덴',
        ES: '스페인',
        IT: '이탈리아',
        CA: '캐나다',
        AU: '호주',
        IN: '인도',
        BR: '브라질',
        MX: '멕시코',
        RU: '러시아',
      }
      return code ? map[code.toUpperCase()] ?? code.toUpperCase() : undefined
    }
    return Promise.all(
      movies.map(async (m) => {
        try {
          const detail = await fetchMovieDetails(m.id)
          return {
            ...m,
            rating: detail.vote_average ?? m.rating,
            releaseDate: detail.release_date ?? m.releaseDate,
            runtime: detail.runtime ?? m.runtime,
            country: countryName(detail.production_countries?.[0]?.iso_3166_1) ?? m.country,
            genres: detail.genres?.map((g) => g.name) ?? m.genres,
          }
        } catch (err) {
          console.error('detail fetch failed', err)
          return m
        }
      }),
    )
  }

  function mergeUniqueMovies(base: Movie[], incoming: Movie[]) {
    const map = new Map<number, Movie>()
    base.forEach((m) => map.set(m.id, m))
    incoming.forEach((m) => map.set(m.id, m))
    return Array.from(map.values())
  }

  async function loadPopular(page = 1) {
    const requestId = ++popularLoadSeq.current
    setLoadingPopular(true)
    try {
      const pop = await fetchPopular(page)
      const mapped = await hydrateDetails(mapMovies(pop))
      if (popularLoadSeq.current !== requestId) return
      if (page === 1) {
        setPopular(mapped)
      } else {
        setPopular((prev) => mergeUniqueMovies(prev, mapped))
      }
      setPopularPage(page)
      setHasMorePopular(mapped.length > 0)
    } catch (err) {
      console.error(err)
      Alert.alert('TMDB error', 'Failed to load popular movies.')
    } finally {
      if (popularLoadSeq.current === requestId) {
        setLoadingPopular(false)
      }
    }
  }

  async function loadMovies() {
    setLoadingMovies(true)
    try {
      const now = await fetchNowPlaying()
      const top = await fetchTopRated()
      await loadPopular(1)
      setNowPlaying(mapMovies(now.slice(0, 10)))
      setTopRated(mapMovies(top.slice(0, 10)))
    } catch (err) {
      console.error(err)
      Alert.alert('TMDB error', 'Failed to load movies.')
    } finally {
      setLoadingMovies(false)
    }
  }

async function fetchWishlist(uid: string) {
    try {
      const snap = await getDoc(doc(db, 'wishlists', uid))
      const items = (snap.exists() ? (snap.data().items as WishlistItem[]) : []) ?? []
      setWishlist(items)
    } catch (err) {
      console.error('wishlist load error', err)
    }
  }

  async function handleAuth() {
    if (!email.trim() || !password) {
      Alert.alert('Input required', 'Please enter email and password.')
      return
    }
    if (mode === 'signup' && password !== passwordConfirm) {
      Alert.alert('Password check', 'Passwords do not match.')
      return
    }
    setBusy(true)
    try {
      if (mode === 'login') {
        await curtainRef.current?.closeCurtain()
        await signInWithEmailAndPassword(auth, email.trim(), password)
        await curtainRef.current?.closeCurtain()
      } else {
        await curtainRef.current?.closeCurtain()
        await createUserWithEmailAndPassword(auth, email.trim(), password)
        try {
          await signOut(auth)
        } catch (err) {
          console.error('post-signup signout failed', err)
        }
        setMode('login')
        setPassword('')
        setPasswordConfirm('')
        await curtainRef.current?.openCurtain()
      }
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Unknown error occurred.'
      Alert.alert('Error', message)
      await curtainRef.current?.openCurtain()
    } finally {
      setBusy(false)
    }
  }

async function handleLogout() {
    setBusy(true)
    try {
      await signOut(auth)
      setUser(null)
      setWishlist([])
      setMode('login')
      setCurrentTab('home')
      setNavOpen(false)
      setSettingsOpen(false)
    } catch (err) {
      console.error('logout failed', err)
      Alert.alert('Logout failed', 'Please try again.')
    } finally {
      setBusy(false)
    }
  }

async function toggleWishlistItem(movie: Movie) {
    if (!user) {
      Alert.alert('Login required', 'Please log in first.')
      return
    }
    const docRef = doc(db, 'wishlists', user.uid)
    const exists = wishlist.find((w) => w.id === movie.id)

    if (exists) {
      setConfirmMovie(movie)
      return
    }

    const next = [...wishlist, { id: movie.id, title: movie.title, poster: movie.poster }]
    await setDoc(docRef, { items: next }, { merge: true })
    setWishlist(next)
  }

  function sortSearchResults(list: Movie[], sort: SearchSort) {
    const parsedDate = (value?: string) => {
      const ts = value ? Date.parse(value) : 0
      return Number.isFinite(ts) ? ts : 0
    }
    const items = [...list]
    switch (sort) {
      case 'latest':
        return items.sort((a, b) => parsedDate(b.releaseDate) - parsedDate(a.releaseDate))
      case 'rating':
        return items.sort((a, b) => (b.rating ?? 0) - (a.rating ?? 0))
      case 'title':
        return items.sort((a, b) => (a.title || '').localeCompare(b.title || ''))
      case 'popular':
      default:
        return items
    }
  }

  function filterSearchResults(list: Movie[]) {
    return list.filter((m) => {
      if (searchGenre !== 'all' && !(m.genres || []).includes(searchGenre)) return false
      if (searchLanguage !== 'all' && (m.language ?? '').toLowerCase() !== searchLanguage) return false
      if (searchYear !== 'all') {
        const year = m.releaseDate ? Number(m.releaseDate.slice(0, 4)) : NaN
        if (!Number.isFinite(year)) return false
        if (searchYear === '2020+' && year < 2020) return false
        if (searchYear === '2010s' && (year < 2010 || year > 2019)) return false
        if (searchYear === '2000s' && (year < 2000 || year > 2009)) return false
        if (searchYear === '1990s' && (year < 1990 || year > 1999)) return false
        if (searchYear === 'pre1990' && year >= 1990) return false
      }
      return true
    })
  }

  async function handleSearch() {
    if (!searchQuery.trim()) {
      setSearchResults([])
      return
    }
    try {
      setLoadingMovies(true)
      const results = await searchMovies(searchQuery.trim())
      setSearchResults(mapMovies(results.slice(0, 12)))
      setSearchSort('popular')
      setCurrentTab('search')
    } catch (err) {
      console.error(err)
      Alert.alert('Search error', 'Failed to load search results.')
    } finally {
      setLoadingMovies(false)
    }
  }

  function resetSearchFilters() {
    setSearchSort('popular')
    setSearchGenre('all')
    setSearchLanguage('all')
    setSearchYear('all')
    setSearchResults([])
  }

  const filteredSearchResults = useMemo(
    () => filterSearchResults(searchResults),
    [searchResults, searchGenre, searchLanguage, searchYear],
  )

  const sortedSearchResults = useMemo(
    () => sortSearchResults(filteredSearchResults, searchSort),
    [filteredSearchResults, searchSort],
  )

const c: ThemeColors = theme === 'dark' ? palette.dark : palette.light
  const fontSteps = [0.9, 0.95, 1, 1.05, 1.1, 1.15, 1.2] as const
  const currentFontScale = fontSteps[Math.min(Math.max(fontLevel, 1), 7) - 1]
  const fs = (size: number) => size * currentFontScale
  const tabLabel: Record<TabKey, string> = {
    home: 'HOME',
    popular: 'POPULAR',
    search: 'SEARCH',
    wishlist: 'WISHLIST',
  }
  const menuDropdownWidth = 150
  const menuDropdownLeft = Math.max(12, menuButtonLayout.x + menuButtonLayout.width / 2 - menuDropdownWidth / 2)
  const menuDropdownTop = menuButtonLayout.y + menuButtonLayout.height + 12
  const settingsDropdownTop = settingsButtonLayout.y + settingsButtonLayout.height + 20

  useEffect(() => {
    if (currentTab !== 'popular') {
      if (popular.length > 0 || loadingPopular) {
        popularLoadSeq.current += 1
        setPopular([])
        setPopularPage(1)
        setHasMorePopular(true)
        setLoadingPopular(false)
      }
      if (showPopularTop) setShowPopularTop(false)
      return
    }

    if (popular.length === 0 && !loadingPopular) {
      loadPopular(1)
    }
  }, [currentTab])

  if (!user) {
    return (
      <SafeAreaView style={[styles.authContainer, { backgroundColor: c.bg }]}>
        <AuthScreen
          ref={curtainRef}
          mode={mode}
          setMode={setMode}
          email={email}
          password={password}
          passwordConfirm={passwordConfirm}
          setEmail={setEmail}
          setPassword={setPassword}
          setPasswordConfirm={setPasswordConfirm}
          busy={busy}
          colors={c}
          fontScale={fs}
          onSubmit={handleAuth}
        />
      </SafeAreaView>
    )
  }

  return (
    <SafeAreaView style={[styles.homeContainer, { backgroundColor: c.bg }]}>
      <StatusBar style="light" />
      <Pressable
        style={{ flex: 1 }}
        disabled={!navOpen && !settingsOpen}
        onPress={() => {
          if (navOpen || settingsOpen) closePanels()
        }}
      >
        <View style={{ flex: 1 }} pointerEvents="box-none">
          <View style={[styles.navBar, { backgroundColor: c.bg, position: 'relative' }]}>
            <TouchableOpacity
              style={[styles.menuButton, { borderColor: c.border, position: 'absolute', left: 20 }]}
              onPress={() => {
                setNavOpen((v) => !v)
                setSettingsOpen(false)
              }}
              activeOpacity={0.8}
              onLayout={({ nativeEvent }) => setMenuButtonLayout(nativeEvent.layout)}
            >
              <Text style={{ color: c.text, fontWeight: '700' }}>메뉴</Text>
            </TouchableOpacity>
            <TouchableOpacity
              onPress={() => {
                setCurrentTab('home')
                closePanels()
              }}
              activeOpacity={0.85}
            >
              <Text style={[styles.logo, { color: c.accent }]}>BPTP</Text>
            </TouchableOpacity>
            <View style={[styles.navActions, { gap: 10, position: 'absolute', right: 20 }]}>
              <TouchableOpacity
                style={[styles.menuButton, { borderColor: c.border }]}
                onPress={() => {
                  setSettingsOpen((v) => !v)
                  setNavOpen(false)
                }}
                activeOpacity={0.8}
                onLayout={({ nativeEvent }) => setSettingsButtonLayout(nativeEvent.layout)}
              >
                <Text style={{ color: c.text, fontWeight: '700' }}>설정</Text>
              </TouchableOpacity>
            </View>
          </View>

          {navOpen && (
            <View
              style={[
                styles.navDropdown,
                {
                  backgroundColor: theme === 'dark' ? '#1e2740' : 'rgba(255,255,255,0.96)',
                  borderColor: theme === 'dark' ? '#394766' : '#d1d5db',
                  left: menuDropdownLeft,
                  top: menuDropdownTop,
                  width: menuDropdownWidth,
                },
              ]}
            >
              {(Object.keys(tabLabel) as Array<keyof typeof tabLabel>).map((key) => (
                <TouchableOpacity
                  key={key}
                  onPress={() => {
                    setCurrentTab(key)
                    closePanels()
                  }}
                  style={[
                    styles.navRow,
                    currentTab === key && {
                      backgroundColor: c.accent,
                      borderRadius: 8,
                      paddingHorizontal: 12,
                      alignItems: 'center',
                      justifyContent: 'center',
                    },
                  ]}
                >
                  <Text
                    style={[
                      styles.navLink,
                      { color: currentTab === key ? '#fff' : c.text, fontWeight: '700' },
                    ]}
                  >
                    {tabLabel[key]}
                  </Text>
                </TouchableOpacity>
              ))}
            </View>
          )}

          {settingsOpen && (
            <View
              style={[
                styles.navDropdown,
                {
                  backgroundColor: theme === 'dark' ? '#1e2740' : 'rgba(255,255,255,0.96)',
                  borderColor: theme === 'dark' ? '#394766' : '#d1d5db',
                  right: 16,
                  left: undefined,
                  width: '44%',
                  top: settingsDropdownTop,
                },
              ]}
            >
              <View style={[styles.navRow, { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' }]}>
                <Text style={[styles.navLink, { color: c.text }]}>테마</Text>
                <View style={{ flexDirection: 'row', alignItems: 'center', gap: 6 }}>
                  <TouchableOpacity
                    style={[
                      styles.menuButton,
                      {
                        paddingVertical: 6,
                        paddingHorizontal: 10,
                        marginLeft: 0,
                        borderColor: c.border,
                        backgroundColor: theme === 'light' ? c.accent : c.card,
                      },
                    ]}
                    onPress={() => setTheme('light')}
                    activeOpacity={0.85}
                  >
                    <Text style={{ color: theme === 'light' ? '#fff' : c.text, fontWeight: '700' }}>라이트</Text>
                  </TouchableOpacity>
                  <TouchableOpacity
                    style={[
                      styles.menuButton,
                      {
                        paddingVertical: 6,
                        paddingHorizontal: 10,
                        marginLeft: 0,
                        borderColor: c.border,
                        backgroundColor: theme === 'dark' ? c.accent : c.card,
                      },
                    ]}
                    onPress={() => setTheme('dark')}
                    activeOpacity={0.85}
                  >
                    <Text style={{ color: theme === 'dark' ? '#fff' : c.text, fontWeight: '700' }}>다크</Text>
                  </TouchableOpacity>
                </View>
              </View>
              <View style={[styles.navRow, { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' }]}>
                <Text style={[styles.navLink, { color: c.text }]}>폰트 크기</Text>
                <View style={{ flexDirection: 'row', gap: 1, alignItems: 'center' }}>
                  <Pressable
                    style={({ pressed }) => [
                      styles.menuButton,
                      {
                        paddingVertical: 6,
                        paddingHorizontal: 10,
                        marginLeft: 0,
                        borderColor: pressed ? c.accent : c.border,
                        backgroundColor: pressed ? c.accent : c.card,
                      },
                    ]}
                    onPress={() => setFontLevel((lvl) => Math.max(1, lvl - 1))}
                  >
                    {({ pressed }) => (
                      <Text style={{ color: pressed ? '#fff' : c.text, fontWeight: '700' }}>-</Text>
                    )}
                  </Pressable>
                  <Text style={{ color: c.text, fontWeight: '700', minWidth: 25, textAlign: 'center' }}>
                    {fontLevel}
                  </Text>
                  <Pressable
                    style={({ pressed }) => [
                      styles.menuButton,
                      {
                        paddingVertical: 6,
                        paddingHorizontal: 10,
                        marginLeft: 0,
                        borderColor: pressed ? c.accent : c.border,
                        backgroundColor: pressed ? c.accent : c.card,
                      },
                    ]}
                    onPress={() => setFontLevel((lvl) => Math.min(7, lvl + 1))}
                  >
                    {({ pressed }) => (
                      <Text style={{ color: pressed ? '#fff' : c.text, fontWeight: '700' }}>+</Text>
                    )}
                  </Pressable>
                </View>
              </View>
              <View style={[styles.navRow, { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' }]}>
                <Text style={[styles.navLink, { color: c.text }]}>애니메이션</Text>
                <View style={{ flexDirection: 'row', alignItems: 'center', gap: 6 }}>
                  <TouchableOpacity
                    style={[
                      styles.menuButton,
                      {
                        paddingVertical: 6,
                        paddingHorizontal: 10,
                        marginLeft: 0,
                        borderColor: c.border,
                        backgroundColor: reduceMotion ? c.accent : c.card,
                      },
                    ]}
                    onPress={() => setReduceMotion(true)}
                    activeOpacity={0.85}
                  >
                    <Text style={{ color: reduceMotion ? '#fff' : c.text, fontWeight: '700' }}>끄기</Text>
                  </TouchableOpacity>
                  <TouchableOpacity
                    style={[
                      styles.menuButton,
                      {
                        paddingVertical: 6,
                        paddingHorizontal: 10,
                        marginLeft: 0,
                        borderColor: c.border,
                        backgroundColor: !reduceMotion ? c.accent : c.card,
                      },
                    ]}
                    onPress={() => setReduceMotion(false)}
                    activeOpacity={0.85}
                  >
                    <Text style={{ color: !reduceMotion ? '#fff' : c.text, fontWeight: '700' }}>켜기</Text>
                  </TouchableOpacity>
                </View>
              </View>
              <TouchableOpacity style={styles.navRow} onPress={handleLogout} disabled={busy}>
                <Text style={[styles.navLink, { color: c.text }]}>로그아웃</Text>
              </TouchableOpacity>
            </View>
          )}

          <ScrollView
            ref={scrollRef}
            showsVerticalScrollIndicator={false}
            keyboardShouldPersistTaps="handled"
            contentContainerStyle={{ paddingBottom: 32, flexGrow: 1 }}
            nestedScrollEnabled
            overScrollMode="always"
            scrollEventThrottle={16}
            onScroll={({ nativeEvent }) => {
              if (currentTab === 'popular' && hasMorePopular && !loadingPopular) {
                const { contentOffset, contentSize, layoutMeasurement } = nativeEvent
                const distanceFromBottom = contentSize.height - (contentOffset.y + layoutMeasurement.height)
                if (distanceFromBottom < 200) {
                  loadPopular(popularPage + 1)
                }
              }
              if (currentTab === 'popular') {
                setShowPopularTop(nativeEvent.contentOffset.y > 400)
              } else if (showPopularTop) {
                setShowPopularTop(false)
              }
            }}
          >
            {currentTab === 'home' && (
              <HomeScreen
                colors={c}
                fontScale={fs}
                searchQuery={searchQuery}
                setSearchQuery={setSearchQuery}
                onSearch={handleSearch}
                loadingMovies={loadingMovies}
                popular={popular}
                nowPlaying={nowPlaying}
                topRated={topRated}
                wishlist={wishlist}
                onToggleWishlist={toggleWishlistItem}
                setCurrentTab={setCurrentTab}
              />
            )}

            {currentTab === 'popular' && (
              <PopularScreen
                colors={c}
                fontScale={fs}
                loading={loadingPopular}
                popular={popular}
                wishlist={wishlist}
                hasMore={hasMorePopular}
                page={popularPage}
                onLoadMore={(nextPage) => !loadingPopular && loadPopular(nextPage)}
                onToggleWishlist={toggleWishlistItem}
              />
            )}

            {currentTab === 'search' && (
              <SearchScreen
                colors={c}
                fontScale={fs}
                loading={loadingMovies}
                searchQuery={searchQuery}
                setSearchQuery={setSearchQuery}
                onSearch={handleSearch}
                searchSort={searchSort}
                setSearchSort={setSearchSort}
                searchGenre={searchGenre}
                setSearchGenre={setSearchGenre}
                searchLanguage={searchLanguage}
                setSearchLanguage={setSearchLanguage}
                searchYear={searchYear}
                setSearchYear={setSearchYear}
                onResetFilters={resetSearchFilters}
                results={sortedSearchResults}
                wishlist={wishlist}
                onToggleWishlist={toggleWishlistItem}
              />
            )}

            {currentTab === 'wishlist' && (
              <WishlistScreen
                colors={c}
                fontScale={fs}
                wishlist={wishlist}
                onToggleWishlist={toggleWishlistItem}
              />
            )}
          </ScrollView>

          {currentTab === 'popular' && showPopularTop && (
            <TouchableOpacity
              style={{
                position: 'absolute',
                right: 16,
                bottom: 20,
                width: 48,
                height: 48,
                borderRadius: 24,
                backgroundColor: c.accent,
                alignItems: 'center',
                justifyContent: 'center',
                shadowColor: '#000',
                shadowOpacity: 0.3,
                shadowRadius: 8,
                shadowOffset: { width: 0, height: 4 },
                elevation: 6,
              }}
              activeOpacity={0.85}
              onPress={() => scrollRef.current?.scrollTo({ y: 0, animated: true })}
            >
              <Text style={{ color: '#fff', fontWeight: '800', fontSize: 22 }}>{'\u2191'}</Text>
            </TouchableOpacity>
          )}

          <Modal
            visible={!!confirmMovie}
            transparent
            animationType="fade"
            onRequestClose={() => setConfirmMovie(null)}
          >
            <TouchableWithoutFeedback onPress={() => setConfirmMovie(null)}>
              <View style={styles.modalOverlay}>
                <TouchableWithoutFeedback>
                  <View style={[styles.modalCard, { backgroundColor: c.card, borderColor: c.border }]}>
                    <Text style={[styles.modalTitle, { color: c.text }]}>Remove from wishlist</Text>
                    <Text style={[styles.modalText, { color: c.muted }]}>Remove this movie from your wishlist?</Text>
                    <View style={styles.modalButtons}>
                      <TouchableOpacity
                        style={[styles.modalButton, { backgroundColor: c.card, borderColor: c.border }]}
                        onPress={() => setConfirmMovie(null)}
                      >
                        <Text style={{ color: c.text, fontWeight: '700' }}>Cancel</Text>
                      </TouchableOpacity>
                      <TouchableOpacity
                        style={[
                          styles.modalButton,
                          styles.modalButtonPrimary,
                          { backgroundColor: c.accent, borderColor: c.accent },
                        ]}
                        onPress={async () => {
                          if (!confirmMovie || !user) return
                          const docRef = doc(db, 'wishlists', user.uid)
                          const next = wishlist.filter((w) => w.id !== confirmMovie.id)
                          await setDoc(docRef, { items: next }, { merge: true })
                          setWishlist(next)
                          setConfirmMovie(null)
                        }}
                      >
                        <Text style={{ color: '#fff', fontWeight: '700' }}>Delete</Text>
                      </TouchableOpacity>
                    </View>
                  </View>
                </TouchableWithoutFeedback>
              </View>
            </TouchableWithoutFeedback>
          </Modal>
        </View>
      </Pressable>
    </SafeAreaView>
  )
}
