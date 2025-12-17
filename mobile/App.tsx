import { StatusBar } from 'expo-status-bar'
import { useEffect, useMemo, useState } from 'react'
import { Alert, ScrollView, Text, TouchableOpacity, View } from 'react-native'
import { SafeAreaView } from 'react-native-safe-area-context'
import {
  createUserWithEmailAndPassword,
  onAuthStateChanged,
  signInWithEmailAndPassword,
  signOut,
  type User,
} from 'firebase/auth'
import {
  addDoc,
  collection,
  doc,
  getDoc,
  getDocs,
  orderBy,
  query,
  serverTimestamp,
  setDoc,
} from 'firebase/firestore'

import { auth, db } from './firebaseConfig'
import { AuthScreen } from './screens/AuthScreen'
import { HomeScreen } from './screens/HomeScreen'
import { PopularScreen } from './screens/PopularScreen'
import { RecommendedScreen } from './screens/RecommendedScreen'
import { SearchScreen } from './screens/SearchScreen'
import { WishlistScreen } from './screens/WishlistScreen'
import { palette, type ThemeColors } from './theme'
import { styles } from './styles'
import {
  fetchNowPlaying,
  fetchPopular,
  fetchTopRated,
  searchMovies,
  posterUrl,
  type TmdbMovie,
} from './services/tmdb'
import type { Mode, Movie, TabKey, WishlistItem } from './types'

export default function App() {
  const [mode, setMode] = useState<Mode>('login')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [passwordConfirm, setPasswordConfirm] = useState('')
  const [user, setUser] = useState<User | null>(null)
  const [busy, setBusy] = useState(false)

  const [popular, setPopular] = useState<Movie[]>([])
  const [popularPage, setPopularPage] = useState(1)
  const [hasMorePopular, setHasMorePopular] = useState(true)
  const [nowPlaying, setNowPlaying] = useState<Movie[]>([])
  const [recommend, setRecommend] = useState<Movie[]>([])
  const [wishlist, setWishlist] = useState<WishlistItem[]>([])
  const [recommendedList, setRecommendedList] = useState<WishlistItem[]>([])
  const [notes, setNotes] = useState<string[]>([])
  const [searchQuery, setSearchQuery] = useState('')
  const [searchResults, setSearchResults] = useState<Movie[]>([])
  const [loadingMovies, setLoadingMovies] = useState(false)
  const [loadingPopular, setLoadingPopular] = useState(false)
  const [theme, setTheme] = useState<'dark' | 'light'>('dark')
  const [fontScale, setFontScale] = useState(1)
  const [reduceMotion, setReduceMotion] = useState(false)
  const [navOpen, setNavOpen] = useState(false)
  const [settingsOpen, setSettingsOpen] = useState(false)
  const [currentTab, setCurrentTab] = useState<TabKey>('home')

  const notesRef = useMemo(() => collection(db, 'mobile-notes'), [])

  useEffect(() => {
    const unsub = onAuthStateChanged(auth, (next) => {
      setUser(next)
      if (next) {
        loadMovies()
        fetchWishlist(next.uid)
        fetchRecommended(next.uid)
      } else {
        setWishlist([])
        setRecommendedList([])
      }
    })
    return unsub
  }, [])

  function mapMovies(items: TmdbMovie[]): Movie[] {
    return items.map((m) => ({
      id: m.id,
      title: m.title,
      overview: m.overview,
      poster: posterUrl(m.poster_path),
    }))
  }

  function mergeUniqueMovies(base: Movie[], incoming: Movie[]) {
    const map = new Map<number, Movie>()
    base.forEach((m) => map.set(m.id, m))
    incoming.forEach((m) => map.set(m.id, m))
    return Array.from(map.values())
  }

  async function loadPopular(page = 1) {
    setLoadingPopular(true)
    try {
      const pop = await fetchPopular(page)
      const mapped = mapMovies(pop)
      if (page === 1) {
        setPopular(mapped)
      } else {
        setPopular((prev) => mergeUniqueMovies(prev, mapped))
      }
      setPopularPage(page)
      setHasMorePopular(mapped.length > 0)
    } catch (err) {
      console.error(err)
      Alert.alert('TMDB 오류', '인기 영화를 불러오지 못했어요.')
    } finally {
      setLoadingPopular(false)
    }
  }

  async function loadMovies() {
    setLoadingMovies(true)
    try {
      const [now, top] = await Promise.all([fetchNowPlaying(), fetchTopRated()])
      await loadPopular(1)
      setNowPlaying(mapMovies(now.slice(0, 10)))
      setRecommend(mapMovies(top.slice(0, 10)))
    } catch (err) {
      console.error(err)
      Alert.alert('TMDB 오류', '영화 정보를 불러오지 못했어요.')
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

  async function fetchRecommended(uid: string) {
    try {
      const snap = await getDoc(doc(db, 'recommended', uid))
      const items = (snap.exists() ? (snap.data().items as WishlistItem[]) : []) ?? []
      setRecommendedList(items)
    } catch (err) {
      console.error('recommended load error', err)
    }
  }

  async function handleAuth() {
    if (!email.trim() || !password) {
      Alert.alert('입력 필요', '이메일과 비밀번호를 입력해주세요.')
      return
    }
    if (mode === 'signup' && password !== passwordConfirm) {
      Alert.alert('비밀번호 확인', '비밀번호가 서로 일치하지 않습니다.')
      return
    }
    setBusy(true)
    try {
      if (mode === 'login') {
        await signInWithEmailAndPassword(auth, email.trim(), password)
      } else {
        await createUserWithEmailAndPassword(auth, email.trim(), password)
        Alert.alert('회원가입 완료', '로그인되었습니다.')
      }
    } catch (err: unknown) {
      const message =
        err instanceof Error ? err.message : '로그인/회원가입 과정에서 오류가 발생했어요.'
      Alert.alert('오류', message)
    } finally {
      setBusy(false)
    }
  }

  async function handleLogout() {
    setBusy(true)
    try {
      await signOut(auth)
    } finally {
      setBusy(false)
    }
  }

  async function toggleWishlistItem(movie: Movie) {
    if (!user) {
      Alert.alert('로그인 필요', '먼저 로그인해주세요.')
      return
    }
    const docRef = doc(db, 'wishlists', user.uid)
    const exists = wishlist.find((w) => w.id === movie.id)
    const next = exists
      ? wishlist.filter((w) => w.id !== movie.id)
      : [...wishlist, { id: movie.id, title: movie.title, poster: movie.poster }]
    await setDoc(docRef, { items: next }, { merge: true })
    setWishlist(next)
  }

  async function toggleRecommendedItem(movie: Movie) {
    if (!user) {
      Alert.alert('로그인 필요', '먼저 로그인해주세요.')
      return
    }
    const docRef = doc(db, 'recommended', user.uid)
    const exists = recommendedList.find((w) => w.id === movie.id)
    const next = exists
      ? recommendedList.filter((w) => w.id !== movie.id)
      : [...recommendedList, { id: movie.id, title: movie.title, poster: movie.poster }]
    await setDoc(docRef, { items: next }, { merge: true })
    setRecommendedList(next)
  }

  async function handleAddNote() {
    if (!user) return
    const text = `Hello from ${user.email ?? 'user'} @ ${new Date().toLocaleTimeString()}`
    try {
      await addDoc(notesRef, { text, createdAt: serverTimestamp(), uid: user.uid })
      const snapshot = await getDocs(query(notesRef, orderBy('createdAt', 'desc')))
      setNotes(snapshot.docs.map((d) => (d.data().text as string) ?? ''))
    } catch (err) {
      const message = err instanceof Error ? err.message : '메모 저장에 실패했어요.'
      Alert.alert('오류', message)
    }
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
      setCurrentTab('search')
    } catch (err) {
      console.error(err)
      Alert.alert('검색 오류', '검색 결과를 불러오지 못했어요.')
    } finally {
      setLoadingMovies(false)
    }
  }

  const c: ThemeColors = theme === 'dark' ? palette.dark : palette.light
  const fs = (size: number) => size * fontScale
  const tabLabel: Record<TabKey, string> = {
    home: 'HOME',
    popular: 'POPULAR',
    search: 'SEARCH',
    wishlist: 'WISHLIST',
    recommended: 'RECOMMENDED',
  }

  if (!user) {
    return (
      <SafeAreaView style={[styles.authContainer, { backgroundColor: c.bg }]}>
        <AuthScreen
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
      <ScrollView showsVerticalScrollIndicator={false}>
        <View style={styles.navBar}>
          <Text style={[styles.logo, { color: c.accent }]}>PB neteflix</Text>
          <TouchableOpacity
            style={[styles.menuButton, { borderColor: c.border }]}
            onPress={() => {
              setNavOpen((v) => !v)
              setSettingsOpen(false)
            }}
            activeOpacity={0.8}
          >
            <Text style={{ color: c.text, fontWeight: '700' }}>MENU</Text>
          </TouchableOpacity>
          <View style={styles.navActions}>
            <TouchableOpacity
              style={styles.menuButton}
              onPress={() => {
                setSettingsOpen((v) => !v)
                setNavOpen(false)
              }}
              activeOpacity={0.8}
            >
              <Text style={{ color: c.text, fontWeight: '700' }}>SETTINGS</Text>
            </TouchableOpacity>
          </View>
        </View>
        {navOpen && (
          <View style={[styles.navDropdown, { backgroundColor: c.card, borderColor: c.border }]}>
            {(Object.keys(tabLabel) as Array<keyof typeof tabLabel>).map((key) => (
              <TouchableOpacity
                key={key}
                onPress={() => {
                  setCurrentTab(key)
                  setNavOpen(false)
                }}
                style={[styles.navRow, currentTab === key && { borderLeftWidth: 2, borderLeftColor: c.accent }]}
              >
                <Text style={[styles.navLink, { color: c.text }]}>{tabLabel[key]}</Text>
              </TouchableOpacity>
            ))}
          </View>
        )}

        {settingsOpen && (
          <View style={[styles.navDropdown, { backgroundColor: c.card, borderColor: c.border }]}>
            <TouchableOpacity
              style={styles.navRow}
              onPress={() => setTheme(theme === 'dark' ? 'light' : 'dark')}
            >
              <Text style={[styles.navLink, { color: c.text }]}>
                테마: {theme === 'dark' ? '다크' : '라이트'}
              </Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={styles.navRow}
              onPress={() => setFontScale((s) => Math.min(1.2, s + 0.05))}
            >
              <Text style={[styles.navLink, { color: c.text }]}>글자 크게</Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={styles.navRow}
              onPress={() => setFontScale((s) => Math.max(0.9, s - 0.05))}
            >
              <Text style={[styles.navLink, { color: c.text }]}>글자 작게</Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={styles.navRow}
              onPress={() => setReduceMotion((v) => !v)}
            >
              <Text style={[styles.navLink, { color: c.text }]}>
                애니메이션 {reduceMotion ? '끄기' : '켜기'}
              </Text>
            </TouchableOpacity>
            <TouchableOpacity style={styles.navRow} onPress={handleLogout} disabled={busy}>
              <Text style={[styles.navLink, { color: c.text }]}>로그아웃</Text>
            </TouchableOpacity>
          </View>
        )}

        {currentTab === 'home' && (
          <HomeScreen
            colors={c}
            fontScale={fs}
            searchQuery={searchQuery}
            setSearchQuery={setSearchQuery}
            onSearch={handleSearch}
            notes={notes}
            onAddNote={handleAddNote}
            loadingMovies={loadingMovies}
            popular={popular}
            nowPlaying={nowPlaying}
            recommend={recommend}
            wishlist={wishlist}
            recommended={recommendedList}
            onToggleWishlist={toggleWishlistItem}
            onToggleRecommended={toggleRecommendedItem}
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
            results={searchResults}
            wishlist={wishlist}
            recommended={recommendedList}
            onToggleWishlist={toggleWishlistItem}
            onToggleRecommended={toggleRecommendedItem}
          />
        )}

        {currentTab === 'wishlist' && (
          <WishlistScreen
            colors={c}
            fontScale={fs}
            wishlist={wishlist}
            recommended={recommendedList}
            onToggleWishlist={toggleWishlistItem}
            onToggleRecommended={toggleRecommendedItem}
          />
        )}

        {currentTab === 'recommended' && (
          <RecommendedScreen
            colors={c}
            fontScale={fs}
            recommendedList={recommendedList}
            recommendMovies={recommend}
            wishlist={wishlist}
            onToggleWishlist={toggleWishlistItem}
            onToggleRecommended={toggleRecommendedItem}
          />
        )}
      </ScrollView>
    </SafeAreaView>
  )
}
