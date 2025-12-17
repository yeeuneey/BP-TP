import { StatusBar } from 'expo-status-bar'
import { useEffect, useState } from 'react'
import { Alert, Modal, ScrollView, Text, TouchableOpacity, TouchableWithoutFeedback, View } from 'react-native'
import { SafeAreaView } from 'react-native-safe-area-context'
import {
  GoogleAuthProvider,
  createUserWithEmailAndPassword,
  onAuthStateChanged,
  signInWithCredential,
  signInWithEmailAndPassword,
  signOut,
  type User,
} from 'firebase/auth'
import { collection, doc, getDoc, setDoc } from 'firebase/firestore'
import * as AuthSession from 'expo-auth-session'
import { makeRedirectUri, ResponseType, useAuthRequest } from 'expo-auth-session'
import * as WebBrowser from 'expo-web-browser'

import { auth, db } from './firebaseConfig'
import { AuthScreen } from './screens/AuthScreen'
import { HomeScreen } from './screens/HomeScreen'
import { PopularScreen } from './screens/PopularScreen'
import { SearchScreen } from './screens/SearchScreen'
import { WishlistScreen } from './screens/WishlistScreen'
import { palette, type ThemeColors } from './theme'
import { styles } from './styles'
import {
  fetchNowPlaying,
  fetchPopular,
  searchMovies,
  posterUrl,
  type TmdbMovie,
} from './services/tmdb'
import type { Mode, Movie, TabKey, WishlistItem } from './types'

WebBrowser.maybeCompleteAuthSession()

const googleClientId =
  process.env.EXPO_PUBLIC_GOOGLE_CLIENT_ID ??
  '309869010872-mngfli8na798j5e7hgnu7qp4sn928fq1.apps.googleusercontent.com'
const googleDiscovery = {
  authorizationEndpoint: 'https://accounts.google.com/o/oauth2/v2/auth',
  tokenEndpoint: 'https://oauth2.googleapis.com/token',
}

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
  const [wishlist, setWishlist] = useState<WishlistItem[]>([])
  const [searchQuery, setSearchQuery] = useState('')
  const [searchResults, setSearchResults] = useState<Movie[]>([])
  const [loadingMovies, setLoadingMovies] = useState(false)
  const [loadingPopular, setLoadingPopular] = useState(false)
  const [theme, setTheme] = useState<'dark' | 'light'>('dark')
  const [fontLevel, setFontLevel] = useState(4) // 1~7 -> 0.90~1.20
  const [reduceMotion, setReduceMotion] = useState(false)
  const [navOpen, setNavOpen] = useState(false)
  const [settingsOpen, setSettingsOpen] = useState(false)
  const [currentTab, setCurrentTab] = useState<TabKey>('home')
  const [confirmMovie, setConfirmMovie] = useState<Movie | null>(null)
  const [request, response, promptAsync] = useAuthRequest(
    {
      clientId: googleClientId,
      responseType: ResponseType.IdToken,
      scopes: ['openid', 'profile', 'email'],
      redirectUri: makeRedirectUri({ useProxy: true }),
      prompt: 'select_account',
      usePKCE: false,
      extraParams: {
        nonce: `${Date.now()}`,
      },
    },
    googleDiscovery
  )
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
      const now = await fetchNowPlaying()
      await loadPopular(1)
      setNowPlaying(mapMovies(now.slice(0, 10)))
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

  useEffect(() => {
    const handleGoogleResponse = async () => {
      if (response?.type === 'success' && response.params?.id_token) {
        try {
          setBusy(true)
          const credential = GoogleAuthProvider.credential(response.params.id_token as string)
          await signInWithCredential(auth, credential)
        } catch (err) {
          const message = err instanceof Error ? err.message : '구글 로그인 중 오류가 발생했습니다.'
          Alert.alert('구글 로그인 오류', message)
        } finally {
          setBusy(false)
        }
      }
    }
    handleGoogleResponse()
  }, [response])

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

  async function handleGoogleLogin() {
    if (!googleClientId) {
      Alert.alert('구글 로그인 오류', 'Google Client ID가 설정되지 않았습니다.')
      return
    }
    if (!request) {
      Alert.alert('구글 로그인 오류', '로그인 요청을 초기화하지 못했습니다.')
      return
    }
    try {
      setBusy(true)
      await promptAsync({ useProxy: true })
    } catch (err) {
      const message = err instanceof Error ? err.message : '구글 로그인 중 오류가 발생했습니다.'
      Alert.alert('구글 로그인 오류', message)
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

    if (exists) {
      setConfirmMovie(movie)
      return
    }

    const next = [...wishlist, { id: movie.id, title: movie.title, poster: movie.poster }]
    await setDoc(docRef, { items: next }, { merge: true })
    setWishlist(next)
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
  const fontSteps = [0.9, 0.95, 1, 1.05, 1.1, 1.15, 1.2] as const
  const currentFontScale = fontSteps[Math.min(Math.max(fontLevel, 1), 7) - 1]
  const fs = (size: number) => size * currentFontScale
  const tabLabel: Record<TabKey, string> = {
    home: 'HOME',
    popular: 'POPULAR',
    search: 'SEARCH',
    wishlist: 'WISHLIST',
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
          onGoogleLogin={handleGoogleLogin}
        />
      </SafeAreaView>
    )
  }

  return (
    <SafeAreaView style={[styles.homeContainer, { backgroundColor: c.bg }]}>
      <StatusBar style="light" />
      <TouchableWithoutFeedback
        onPress={() => {
          if (navOpen || settingsOpen) closePanels()
        }}
      >
        <View style={{ flex: 1 }}>
          <View style={[styles.navBar, { backgroundColor: c.bg }]}>
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
                    closePanels()
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
              <View style={[styles.navRow, { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' }]}>
                <Text style={[styles.navLink, { color: c.text }]}>글자 크기</Text>
                <View style={{ flexDirection: 'row', gap: 8, alignItems: 'center' }}>
                  <TouchableOpacity
                    style={[styles.menuButton, { paddingVertical: 6, paddingHorizontal: 10, marginLeft: 0, borderColor: c.border }]}
                    onPress={() => setFontLevel((lvl) => Math.max(1, lvl - 1))}
                    activeOpacity={0.8}
                  >
                    <Text style={{ color: c.text, fontWeight: '700' }}>-</Text>
                  </TouchableOpacity>
                  <Text style={{ color: c.text, fontWeight: '700', minWidth: 44, textAlign: 'center' }}>
                    {fontLevel}
                  </Text>
                  <TouchableOpacity
                    style={[styles.menuButton, { paddingVertical: 6, paddingHorizontal: 10, marginLeft: 0, borderColor: c.border }]}
                    onPress={() => setFontLevel((lvl) => Math.min(7, lvl + 1))}
                    activeOpacity={0.8}
                  >
                    <Text style={{ color: c.text, fontWeight: '700' }}>+</Text>
                  </TouchableOpacity>
                </View>
              </View>
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

          <ScrollView showsVerticalScrollIndicator={false}>
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
            results={searchResults}
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
          <Modal visible={!!confirmMovie} transparent animationType="fade" onRequestClose={() => setConfirmMovie(null)}>
            <TouchableWithoutFeedback onPress={() => setConfirmMovie(null)}>
              <View style={styles.modalOverlay}>
                <TouchableWithoutFeedback>
                  <View style={styles.modalCard}>
                    <Text style={styles.modalTitle}>삭제 확인</Text>
                    <Text style={styles.modalText}>위시리스트에서 삭제하시겠습니까?</Text>
                    <View style={styles.modalButtons}>
                      <TouchableOpacity style={styles.modalButton} onPress={() => setConfirmMovie(null)}>
                        <Text style={{ color: '#e5e7eb', fontWeight: '700' }}>취소</Text>
                      </TouchableOpacity>
                      <TouchableOpacity
                        style={[styles.modalButton, styles.modalButtonPrimary]}
                        onPress={async () => {
                          if (!confirmMovie || !user) return
                          const docRef = doc(db, 'wishlists', user.uid)
                          const next = wishlist.filter((w) => w.id !== confirmMovie.id)
                          await setDoc(docRef, { items: next }, { merge: true })
                          setWishlist(next)
                          setConfirmMovie(null)
                        }}
                      >
                        <Text style={{ color: '#fff', fontWeight: '700' }}>확인</Text>
                      </TouchableOpacity>
                    </View>
                  </View>
                </TouchableWithoutFeedback>
              </View>
            </TouchableWithoutFeedback>
          </Modal>
        </View>
      </TouchableWithoutFeedback>
    </SafeAreaView>
  )
}
