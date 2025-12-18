import { StatusBar } from 'expo-status-bar'
import * as Google from 'expo-auth-session/providers/google'
import Constants from 'expo-constants'
import * as WebBrowser from 'expo-web-browser'
import { useEffect, useMemo, useRef, useState } from 'react'
import {
  ActivityIndicator,
  Alert,
  Animated,
  Easing,
  FlatList,
  Image,
  ScrollView,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from 'react-native'
import { SafeAreaView } from 'react-native-safe-area-context'
import {
  createUserWithEmailAndPassword,
  GoogleAuthProvider,
  onAuthStateChanged,
  signInWithEmailAndPassword,
  signInWithCredential,
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
import {
  fetchNowPlaying,
  fetchPopular,
  searchMovies,
  posterUrl,
  type TmdbMovie,
} from './services/tmdb'
import { styles } from './styles'
import { palette, type ThemeColors } from './theme'

WebBrowser.maybeCompleteAuthSession()

type AppExtra = {
  googleAuth?: {
    iosClientId?: string
    androidClientId?: string
    webClientId?: string
    expoClientId?: string
  }
}

const appExtra = Constants.expoConfig?.extra as AppExtra | undefined
const expoUsername = process.env.EXPO_PUBLIC_EXPO_USERNAME ?? 'mxxng'
const projectSlug = Constants.expoConfig?.slug ?? 'mobile'
const proxyRedirectUri = `https://auth.expo.io/@${expoUsername}/${projectSlug}`

type Mode = 'login' | 'signup'
type TabKey = 'home' | 'popular' | 'search' | 'wishlist'

interface Movie {
  id: number
  title: string
  overview: string
  poster: string | undefined
}

interface WishlistItem {
  id: number
  title: string
  poster: string | undefined
}

export default function App() {
  const [mode, setMode] = useState<Mode>('login')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [passwordConfirm, setPasswordConfirm] = useState('')
  const [user, setUser] = useState<User | null>(null)
  const [busy, setBusy] = useState(false)

  const googleClientIds = useMemo(
    () => ({
      ios: process.env.EXPO_PUBLIC_GOOGLE_IOS_CLIENT_ID ?? appExtra?.googleAuth?.iosClientId,
      android: process.env.EXPO_PUBLIC_GOOGLE_ANDROID_CLIENT_ID ?? appExtra?.googleAuth?.androidClientId,
      web: process.env.EXPO_PUBLIC_GOOGLE_WEB_CLIENT_ID ?? appExtra?.googleAuth?.webClientId,
      expo: process.env.EXPO_PUBLIC_GOOGLE_EXPO_CLIENT_ID ?? appExtra?.googleAuth?.expoClientId,
    }),
    [],
  )

  const primaryGoogleClientId =
    googleClientIds.web ?? googleClientIds.expo ?? googleClientIds.android ?? googleClientIds.ios

  const googleAuthConfig = useMemo(
    () =>
      primaryGoogleClientId
        ? {
            clientId: primaryGoogleClientId,
            iosClientId: googleClientIds.ios,
            androidClientId: googleClientIds.android,
            expoClientId: googleClientIds.expo ?? googleClientIds.web ?? primaryGoogleClientId,
            redirectUri: proxyRedirectUri,
          }
        : undefined,
    [googleClientIds.android, googleClientIds.expo, googleClientIds.ios, googleClientIds.web, primaryGoogleClientId],
  )

  const [googleRequest, , promptGoogleAuth] = Google.useIdTokenAuthRequest(googleAuthConfig ?? {})

  const [popular, setPopular] = useState<Movie[]>([])
  const [popularPage, setPopularPage] = useState(1)
  const [hasMorePopular, setHasMorePopular] = useState(true)
  const [nowPlaying, setNowPlaying] = useState<Movie[]>([])
  const [wishlist, setWishlist] = useState<WishlistItem[]>([])
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
  const [curtainOpen, setCurtainOpen] = useState(false)
  const [cardLayout, setCardLayout] = useState({ width: 0, height: 0, y: 0 })
  const curtainProgress = useRef(new Animated.Value(0)).current
  const notesRef = useMemo(() => collection(db, 'mobile-notes'), [])

  useEffect(() => {
    Animated.timing(curtainProgress, {
      toValue: curtainOpen ? 1 : 0,
      duration: 800,
      easing: Easing.out(Easing.cubic),
      useNativeDriver: true,
    }).start()
  }, [curtainOpen, curtainProgress])

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
      Alert.alert('TMDB 오류', '영화를 불러오는 중 오류가 발생했습니다.')
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
      Alert.alert('입력 확인', '이메일과 비밀번호를 입력하세요.')
      return
    }
    if (mode === 'signup' && password !== passwordConfirm) {
      Alert.alert('비밀번호 확인', '비밀번호가 일치하지 않습니다.')
      return
    }
    setBusy(true)
    try {
      if (mode === 'login') {
        await signInWithEmailAndPassword(auth, email.trim(), password)
      } else {
        await createUserWithEmailAndPassword(auth, email.trim(), password)
        Alert.alert('회원가입 완료', '로그인해서 계속 이용해주세요.')
      }
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : '인증 중 오류가 발생했습니다.'
      Alert.alert('로그인 오류', message)
    } finally {
      setBusy(false)
    }
  }

  async function handleGoogleLogin() {
    if (!primaryGoogleClientId || !googleRequest) {
      Alert.alert('Google login not configured', 'Add the Google client ID to app.json or env.')
      return
    }
    setBusy(true)
    try {
      const result = await promptGoogleAuth()
      if (!result || result.type !== 'success') {
        const errorMessage =
          (result as typeof result & { error?: string; params?: Record<string, string> })?.error ??
          (result as typeof result & { params?: Record<string, string> })?.params?.error ??
          result?.type ??
          'unknown_error'
        if (errorMessage !== 'success') {
          Alert.alert('Google login failed', `Error: ${errorMessage}`)
        }
        return
      }
      const params = (result as typeof result & { params?: Record<string, string> }).params
      const idToken = params?.id_token ?? result.authentication?.idToken
      if (!idToken) {
        Alert.alert('Google login failed', 'Could not retrieve ID token from Google response.')
        return
      }
      const credential = GoogleAuthProvider.credential(idToken)
      await signInWithCredential(auth, credential)
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : 'Google login failed. Please try again.'
      Alert.alert('Google login failed', message)
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
      Alert.alert('로그인이 필요합니다', '로그인 후 이용해주세요.')
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

  async function handleAddNote() {
    if (!user) return
    const text = `Hello from ${user.email ?? 'user'} @ ${new Date().toLocaleTimeString()}`
    try {
      await addDoc(notesRef, { text, createdAt: serverTimestamp(), uid: user.uid })
      const snapshot = await getDocs(query(notesRef, orderBy('createdAt', 'desc')))
      setNotes(snapshot.docs.map((d) => (d.data().text as string) ?? ''))
    } catch (err) {
      const message = err instanceof Error ? err.message : '메모 저장 중 오류가 발생했습니다.'
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
      Alert.alert('검색 오류', '검색 결과를 불러오지 못했습니다.')
    } finally {
      setLoadingMovies(false)
    }
  }

  const c = theme === 'dark' ? palette.dark : palette.light
  const fs = (size: number) => size * fontScale
  const handleStartCurtain = () => {
    if (!curtainOpen) {
      setCurtainOpen(true)
    } else {
      curtainProgress.stopAnimation()
      curtainProgress.setValue(1)
    }
  }
  const tabLabel = {
    home: 'HOME',
    popular: 'POPULAR',
    search: 'SEARCH',
    wishlist: 'WISHLIST',
  } as const

  const AuthScreen = ({
    mode,
    setMode,
    email,
    password,
    passwordConfirm,
    setEmail,
    setPassword,
    setPasswordConfirm,
    busy,
    colors,
    fontScale,
    onSubmit,
    onGoogleLogin,
    curtainOpen,
    setCurtainOpen,
    curtainProgress,
    cardLayout,
    setCardLayout,
  }: {
    mode: Mode
    setMode: (next: Mode) => void
    email: string
    password: string
    passwordConfirm: string
    setEmail: (value: string) => void
    setPassword: (value: string) => void
    setPasswordConfirm: (value: string) => void
    busy: boolean
    colors: ThemeColors
    fontScale: (size: number) => number
    onSubmit: () => void
    onGoogleLogin: () => void
    curtainOpen: boolean
    setCurtainOpen: (value: boolean) => void
    curtainProgress: Animated.Value
    cardLayout: { width: number; height: number; y: number }
    setCardLayout: (next: { width: number; height: number; y: number }) => void
  }) => {
    const localFs = fontScale
    const slideDistance = cardLayout.width > 0 ? cardLayout.width * 0.55 : 180
    const leftTranslate = curtainProgress.interpolate({
      inputRange: [0, 1],
      outputRange: [0, -slideDistance],
    })
    const rightTranslate = curtainProgress.interpolate({
      inputRange: [0, 1],
      outputRange: [0, slideDistance],
    })

    const switchMode = (next: Mode) => {
      if (next === mode) return
      setMode(next)
    }

    return (
      <>
        <StatusBar style="light" />
        <Text style={[styles.logo, { color: colors.accent }]}>PB neteflix</Text>

        <View style={styles.curtainWrapper}>
          <View
            style={[styles.authCard, { backgroundColor: colors.card, borderColor: colors.border }]}
            onLayout={({ nativeEvent }) =>
              setCardLayout({
                width: nativeEvent.layout.width,
                height: nativeEvent.layout.height,
                y: nativeEvent.layout.y,
              })
            }
          >
            <View style={styles.authTabs}>
              <TouchableOpacity
                style={[
                  styles.authTab,
                  { borderColor: colors.border },
                  mode === 'login' && { backgroundColor: colors.accent, borderColor: colors.accent },
                ]}
                onPress={() => switchMode('login')}
                activeOpacity={0.9}
              >
                <Text style={[styles.authTabText, { fontSize: localFs(14) }]}>LOGIN</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[
                  styles.authTab,
                  { borderColor: colors.border },
                  mode === 'signup' && { backgroundColor: colors.accent, borderColor: colors.accent },
                ]}
                onPress={() => switchMode('signup')}
                activeOpacity={0.9}
              >
                <Text style={[styles.authTabText, { fontSize: localFs(14) }]}>SIGN UP</Text>
              </TouchableOpacity>
            </View>

            <Text style={[styles.authTitle, { fontSize: localFs(20), color: colors.text }]}>
              {mode === 'login' ? '로그인' : '회원가입'}
            </Text>

            <TextInput
              placeholder="이메일"
              placeholderTextColor="#9ca3af"
              autoCapitalize="none"
              keyboardType="email-address"
              style={[styles.input, { backgroundColor: colors.card, borderColor: colors.border, color: colors.text }]}
              value={email}
              onChangeText={setEmail}
            />
            <TextInput
              placeholder="비밀번호"
              placeholderTextColor="#9ca3af"
              secureTextEntry
              style={[styles.input, { backgroundColor: colors.card, borderColor: colors.border, color: colors.text }]}
              value={password}
              onChangeText={setPassword}
            />
            {mode === 'signup' && (
              <TextInput
                placeholder="비밀번호 확인"
                placeholderTextColor="#9ca3af"
                secureTextEntry
                style={[styles.input, { backgroundColor: colors.card, borderColor: colors.border, color: colors.text }]}
                value={passwordConfirm}
                onChangeText={setPasswordConfirm}
              />
            )}

            <TouchableOpacity
              style={[styles.primaryButton, { backgroundColor: colors.accent }]}
              onPress={onSubmit}
              disabled={busy}
              activeOpacity={0.85}
            >
              {busy ? (
                <ActivityIndicator color="#fff" />
              ) : (
                <Text style={[styles.primaryText, { fontSize: localFs(16) }]}>
                  {mode === 'login' ? '로그인하기' : '회원가입하기'}
                </Text>
              )}
            </TouchableOpacity>

            <TouchableOpacity
              style={[styles.googleButton, { borderColor: colors.border }]}
              onPress={onGoogleLogin}
              disabled={busy}
              activeOpacity={0.85}
            >
            <View style={styles.googleButtonContent}>
              <Text style={[styles.googleWord, { fontSize: localFs(16) }]}>
                <Text style={styles.googleBlue}>G</Text>
                <Text style={styles.googleRed}>o</Text>
                <Text style={styles.googleYellow}>o</Text>
                <Text style={styles.googleBlue}>g</Text>
                <Text style={styles.googleGreen}>l</Text>
                <Text style={styles.googleRed}>e</Text>
              </Text>
              <Text style={[styles.googleButtonText, { fontSize: localFs(14) }]}>로 로그인</Text>
            </View>
          </TouchableOpacity>
        </View>

          <View
            style={[
              styles.curtainOverlay,
              { top: cardLayout.y, height: cardLayout.height },
            ]}
          >
            <View style={[styles.curtainTop, { height: 0 }]} />
            <View style={[styles.curtainBody, { height: cardLayout.height }]}>
              <Animated.View
                style={[
                  styles.curtainPanel,
                  styles.curtainLeft,
                  { transform: [{ translateX: leftTranslate }] },
                ]}
              >
                <View style={styles.curtainStripes}>
                  {[0, 1, 2, 3, 4].map((stripe) => (
                    <View key={`stripe-left-${stripe}`} style={styles.curtainStripe} />
                  ))}
                </View>
              </Animated.View>
              <Animated.View
                style={[
                  styles.curtainPanel,
                  styles.curtainRight,
                  { transform: [{ translateX: rightTranslate }] },
                ]}
              >
                <View style={styles.curtainStripes}>
                  {[0, 1, 2, 3, 4].map((stripe) => (
                    <View key={`stripe-right-${stripe}`} style={styles.curtainStripe} />
                  ))}
                </View>
              </Animated.View>
            </View>
          </View>
        </View>

        <TouchableOpacity
          style={styles.curtainStartButton}
          onPress={handleStartCurtain}
          activeOpacity={0.9}
        >
          <Text style={styles.curtainButtonText}>시작하기</Text>
        </TouchableOpacity>
      </>
    )
  }

  const MovieSection = ({
    title,
    data,
    colors,
    fontScale,
    wishlist,
    onToggleWishlist,
  }: {
    title: string
    data: Movie[]
    colors: ThemeColors
    fontScale: (size: number) => number
    wishlist: WishlistItem[]
    onToggleWishlist: (movie: Movie) => void
  }) => {
    const localFs = fontScale
    return (
      <View style={styles.section}>
        <Text style={[styles.sectionTitle, { color: colors.text, fontSize: localFs(16) }]}>{title}</Text>
        <FlatList
          data={data}
          keyExtractor={(item) => String(item.id)}
          horizontal
          showsHorizontalScrollIndicator={false}
          renderItem={({ item }: { item: Movie }) => {
            const picked = wishlist.some((w) => w.id === item.id)
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
                <Text style={[styles.cardTitle, { color: colors.text, fontSize: localFs(14) }]} numberOfLines={1}>
                  {item.title}
                </Text>
                <Text style={[styles.cardTag, { color: colors.muted, fontSize: localFs(12) }]} numberOfLines={2}>
                  {item.overview || '줄거리가 없습니다.'}
                </Text>
              </View>
            )
          }}
        />
      </View>
    )
  }

  const PopularList = ({
    data,
    wishlist,
    colors,
    fontScale,
    loading,
    hasMore,
    page,
    onLoadMore,
    onToggleWishlist,
  }: {
    data: Movie[]
    wishlist: WishlistItem[]
    colors: ThemeColors
    fontScale: (size: number) => number
    loading: boolean
    hasMore: boolean
    page: number
    onLoadMore: (page: number) => void
    onToggleWishlist: (movie: Movie) => void
  }) => {
    const localFs = fontScale
    return (
      <View style={{ gap: 10 }}>
        {data.map((item) => {
          const picked = wishlist.some((w) => w.id === item.id)
          return (
            <View
              key={item.id}
              style={[styles.popularCard, { backgroundColor: colors.card, borderColor: colors.border, position: 'relative' }]}
            >
              <TouchableOpacity
                style={[
                  styles.wishHeart,
                  picked && styles.wishHeartActive,
                  { borderColor: colors.border, top: 10, right: 10 },
                ]}
                onPress={() => onToggleWishlist(item)}
                activeOpacity={0.8}
              >
                <Text style={{ color: '#fff', fontWeight: '800', fontSize: 18 }}>
                  {picked ? '❤' : '❤'}
                  {picked ? '❤' : '❤'}
                  </Text>
              </TouchableOpacity>
              <Image
                source={
                  item.poster
                    ? { uri: item.poster }
                    : { uri: 'https://dummyimage.com/500x750/111827/ffffff&text=No+Image' }
                }
                style={styles.popularPoster}
                resizeMode="cover"
              />
              <View style={styles.popularBody}>
                <Text style={[styles.cardTitle, { color: colors.text, fontSize: localFs(14) }]} numberOfLines={1}>
                  {item.title}
                </Text>
                <Text style={[styles.cardTag, { color: colors.muted, fontSize: localFs(12) }]} numberOfLines={2}>
                  {item.overview || '줄거리가 없습니다.'}
                </Text>
              </View>
            </View>
          )
        })}
        {hasMore && (
          <TouchableOpacity
            style={[styles.secondaryButton, { borderColor: colors.border, backgroundColor: colors.card, marginTop: 6 }]}
            onPress={() => !loading && onLoadMore(page + 1)}
            activeOpacity={0.85}
          >
            {loading ? (
              <ActivityIndicator color={colors.accent} />
            ) : (
              <Text style={[styles.secondaryText, { color: colors.text }]}>더보기</Text>
            )}
          </TouchableOpacity>
        )}
      </View>
    )
  }

  const PopularScreen = ({
    colors,
    fontScale,
    loading,
    popular,
    wishlist,
    hasMore,
    page,
    onLoadMore,
    onToggleWishlist,
  }: {
    colors: ThemeColors
    fontScale: (size: number) => number
    loading: boolean
    popular: Movie[]
    wishlist: WishlistItem[]
    hasMore: boolean
    page: number
    onLoadMore: (page: number) => void
    onToggleWishlist: (movie: Movie) => void
  }) => {
    const localFs = fontScale
    return (
      <View style={styles.section}>
        <Text style={[styles.sectionTitle, { color: colors.text, fontSize: localFs(18) }]}>지금 가장 인기 있는 영화</Text>
        {loading ? (
          <ActivityIndicator color="#e50914" />
        ) : (
          <PopularList
            data={popular}
            wishlist={wishlist}
            colors={colors}
            fontScale={localFs}
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

  const HomeScreen = ({
    colors,
    fontScale,
    searchQuery,
    setSearchQuery,
    onSearch,
    loadingMovies,
    popular,
    nowPlaying,
    wishlist,
    onToggleWishlist,
    setCurrentTab,
  }: {
    colors: ThemeColors
    fontScale: (size: number) => number
    searchQuery: string
    setSearchQuery: (value: string) => void
    onSearch: () => void
    loadingMovies: boolean
    popular: Movie[]
    nowPlaying: Movie[]
    wishlist: WishlistItem[]
    onToggleWishlist: (movie: Movie) => void
    setCurrentTab: (tab: TabKey) => void
  }) => {
    const localFs = fontScale
    return (
      <>
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
              style={[
                styles.searchInput,
                { backgroundColor: colors.card, borderColor: colors.border, color: colors.text },
              ]}
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
          fontScale={localFs}
          wishlist={wishlist}
          onToggleWishlist={onToggleWishlist}
        />
        <MovieSection
          title="극장에서 만나는 신작"
          data={nowPlaying}
          colors={colors}
          fontScale={localFs}
          wishlist={wishlist}
          onToggleWishlist={onToggleWishlist}
        />
      </>
    )
  }

  const SearchScreen = ({
    colors,
    fontScale,
    loading,
    searchQuery,
    setSearchQuery,
    onSearch,
    results,
    wishlist,
    onToggleWishlist,
  }: {
    colors: ThemeColors
    fontScale: (size: number) => number
    loading: boolean
    searchQuery: string
    setSearchQuery: (value: string) => void
    onSearch: () => void
    results: Movie[]
    wishlist: WishlistItem[]
    onToggleWishlist: (movie: Movie) => void
  }) => {
    const localFs = fontScale
    return (
      <View style={styles.section}>
        <Text style={[styles.sectionTitle, { color: colors.text, fontSize: localFs(18) }]}>검색</Text>
        <View style={styles.searchRow}>
          <TextInput
            placeholder="검색어를 입력하세요"
            placeholderTextColor="#9ca3af"
            style={[
              styles.searchInput,
              { backgroundColor: colors.card, borderColor: colors.border, color: colors.text },
            ]}
            value={searchQuery}
            onChangeText={setSearchQuery}
            onSubmitEditing={onSearch}
            returnKeyType="search"
          />
          <TouchableOpacity
            style={[styles.secondaryButton, { borderColor: colors.border, backgroundColor: colors.card }]}
            onPress={onSearch}
            activeOpacity={0.85}
          >
            <Text style={[styles.secondaryText, { color: colors.text }]}>검색</Text>
          </TouchableOpacity>
        </View>
        {loading && <ActivityIndicator color="#e50914" style={{ marginVertical: 10 }} />}
        {!!results.length && (
          <MovieSection
            title="검색 결과"
            data={results}
            colors={colors}
            fontScale={localFs}
            wishlist={wishlist}
            onToggleWishlist={onToggleWishlist}
          />
        )}
      </View>
    )
  }

  const WishlistScreen = ({
    colors,
    fontScale,
    wishlist,
    onToggleWishlist,
  }: {
    colors: ThemeColors
    fontScale: (size: number) => number
    wishlist: WishlistItem[]
    onToggleWishlist: (movie: Movie) => void
  }) => {
    const localFs = fontScale
    return (
      <View style={styles.section}>
        <Text style={[styles.sectionTitle, { color: colors.text, fontSize: localFs(18) }]}>위시리스트</Text>
        {wishlist.length ? (
          <MovieSection
            title=""
            data={wishlist.map((w) => ({ id: w.id, title: w.title, overview: '', poster: w.poster }))}
            colors={colors}
            fontScale={localFs}
            wishlist={wishlist}
            onToggleWishlist={onToggleWishlist}
          />
        ) : (
          <Text style={{ color: colors.muted }}>위시리스트가 비어 있습니다.</Text>
        )}
      </View>
    )
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
          curtainOpen={curtainOpen}
          setCurtainOpen={setCurtainOpen}
          curtainProgress={curtainProgress}
          cardLayout={cardLayout}
          setCardLayout={setCardLayout}
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
            onPress={() => setNavOpen((v) => !v)}
            activeOpacity={0.8}
          >
            <Text style={{ color: c.text, fontWeight: '700' }}>MENU</Text>
          </TouchableOpacity>
          <View style={styles.navActions}>
            <TouchableOpacity
              style={[styles.menuButton, { borderColor: c.border }]}
              onPress={() => setSettingsOpen((v) => !v)}
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
              <Text style={[styles.navLink, { color: c.text }]}>Theme: {theme === 'dark' ? 'Dark' : 'Light'}</Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={styles.navRow}
              onPress={() => setFontScale((s) => Math.min(1.2, s + 0.05))}
            >
              <Text style={[styles.navLink, { color: c.text }]}>Font bigger</Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={styles.navRow}
              onPress={() => setFontScale((s) => Math.max(0.9, s - 0.05))}
            >
              <Text style={[styles.navLink, { color: c.text }]}>Font smaller</Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={styles.navRow}
              onPress={() => setReduceMotion((v) => !v)}
            >
              <Text style={[styles.navLink, { color: c.text }]}>Animations: {reduceMotion ? 'Off' : 'On'}</Text>
            </TouchableOpacity>
            <TouchableOpacity style={styles.navRow} onPress={handleLogout} disabled={busy}>
              <Text style={[styles.navLink, { color: c.text }]}>Logout</Text>
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
            onLoadMore={loadPopular}
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
    </SafeAreaView>
  )
}



