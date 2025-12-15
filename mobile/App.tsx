import { StatusBar } from 'expo-status-bar'
import { useEffect, useMemo, useState } from 'react'
import {
  Alert,
  FlatList,
  SafeAreaView,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
  ActivityIndicator,
} from 'react-native'
import {
  createUserWithEmailAndPassword,
  onAuthStateChanged,
  signInWithEmailAndPassword,
  signOut,
  type User,
} from 'firebase/auth'
import { addDoc, collection, getDocs, orderBy, query, serverTimestamp } from 'firebase/firestore'
import { auth, db } from './firebaseConfig'

type Mode = 'login' | 'signup'

interface Movie {
  id: string
  title: string
  tag: string
  category: 'popular' | 'now' | 'recommend'
}

const MOCK_MOVIES: Movie[] = [
  { id: '1', title: 'Hunting Season', tag: '액션 • 서스펜스', category: 'popular' },
  { id: '2', title: '웨이큰 업 데드맨', tag: '드라마', category: 'popular' },
  { id: '3', title: '극장판 쥬라기', tag: '어드벤처', category: 'now' },
  { id: '4', title: '신작 큐레이션', tag: '추천', category: 'recommend' },
  { id: '5', title: '미드나이트 체이스', tag: '스릴러', category: 'recommend' },
]

export default function App() {
  const [mode, setMode] = useState<Mode>('login')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [passwordConfirm, setPasswordConfirm] = useState('')
  const [user, setUser] = useState<User | null>(null)
  const [busy, setBusy] = useState(false)
  const [wishlist, setWishlist] = useState<Set<string>>(new Set())
  const [notes, setNotes] = useState<string[]>([])
  const notesRef = useMemo(() => collection(db, 'mobile-notes'), [])

  useEffect(() => {
    const unsub = onAuthStateChanged(auth, (next) => {
      setUser(next)
      if (!next) {
        setWishlist(new Set())
      }
    })
    return unsub
  }, [])

  async function handleAuth() {
    if (!email.trim() || !password) {
      Alert.alert('입력 필요', '이메일과 비밀번호를 입력하세요.')
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
        Alert.alert('회원가입 완료', '로그인되었습니다.')
      }
    } catch (err: unknown) {
      const message =
        err instanceof Error ? err.message : '로그인/회원가입 중 오류가 발생했습니다.'
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

  function toggleWishlist(id: string) {
    setWishlist((prev) => {
      const next = new Set(prev)
      if (next.has(id)) next.delete(id)
      else next.add(id)
      return next
    })
  }

  async function handleAddNote() {
    if (!user) return
    const text = `Hello from ${user.email ?? 'user'} @ ${new Date().toLocaleTimeString()}`
    try {
      await addDoc(notesRef, { text, createdAt: serverTimestamp(), uid: user.uid })
      const snapshot = await getDocs(query(notesRef, orderBy('createdAt', 'desc')))
      setNotes(snapshot.docs.map((d) => (d.data().text as string) ?? ''))
    } catch (err) {
      const message = err instanceof Error ? err.message : '저장에 실패했습니다.'
      Alert.alert('오류', message)
    }
  }

  if (!user) {
    return (
      <SafeAreaView style={styles.authContainer}>
        <StatusBar style="light" />
        <Text style={styles.logo}>PB neteflix</Text>
        <View style={styles.authCard}>
          <View style={styles.authTabs}>
            <TouchableOpacity
              style={[styles.authTab, mode === 'login' && styles.authTabActive]}
              onPress={() => setMode('login')}
            >
              <Text style={styles.authTabText}>LOGIN</Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={[styles.authTab, mode === 'signup' && styles.authTabActive]}
              onPress={() => setMode('signup')}
            >
              <Text style={styles.authTabText}>SIGN UP</Text>
            </TouchableOpacity>
          </View>

          <Text style={styles.authTitle}>{mode === 'login' ? '로그인' : 'Create account'}</Text>
          <TextInput
            placeholder="이메일"
            placeholderTextColor="#9ca3af"
            autoCapitalize="none"
            keyboardType="email-address"
            style={styles.input}
            value={email}
            onChangeText={setEmail}
          />
          <TextInput
            placeholder="비밀번호"
            placeholderTextColor="#9ca3af"
            secureTextEntry
            style={styles.input}
            value={password}
            onChangeText={setPassword}
          />
          {mode === 'signup' && (
            <TextInput
              placeholder="비밀번호 확인"
              placeholderTextColor="#9ca3af"
              secureTextEntry
              style={styles.input}
              value={passwordConfirm}
              onChangeText={setPasswordConfirm}
            />
          )}

          <TouchableOpacity
            style={styles.primaryButton}
            onPress={handleAuth}
            disabled={busy}
            activeOpacity={0.85}
          >
            {busy ? <ActivityIndicator color="#fff" /> : <Text style={styles.primaryText}>시작하기</Text>}
          </TouchableOpacity>
        </View>
      </SafeAreaView>
    )
  }

  const popular = MOCK_MOVIES.filter((m) => m.category === 'popular')
  const nowPlaying = MOCK_MOVIES.filter((m) => m.category === 'now')
  const recommend = MOCK_MOVIES.filter((m) => m.category === 'recommend')

  return (
    <SafeAreaView style={styles.homeContainer}>
      <StatusBar style="light" />
      <ScrollView showsVerticalScrollIndicator={false}>
        <View style={styles.navBar}>
          <Text style={styles.logo}>PB neteflix</Text>
          <View style={styles.navLinks}>
            <Text style={styles.navLink}>HOME</Text>
            <Text style={styles.navLink}>POPULAR</Text>
            <Text style={styles.navLink}>SEARCH</Text>
            <Text style={styles.navLink}>WISHLIST</Text>
            <Text style={styles.navLink}>RECOMMENDED</Text>
          </View>
          <TouchableOpacity style={styles.logoutPill} onPress={handleLogout} disabled={busy}>
            <Text style={styles.logoutPillText}>로그아웃</Text>
          </TouchableOpacity>
        </View>

        <View style={styles.hero}>
          <Text style={styles.heroEyebrow}>FOR YOU</Text>
          <Text style={styles.heroTitle}>TMDB API로 큐레이션된 추천</Text>
          <Text style={styles.heroSubtitle}>인기, 상영 중, 추천 작품을 한 곳에서 만나보세요.</Text>
          <View style={styles.heroButtons}>
            <TouchableOpacity style={styles.primaryButton} onPress={handleAddNote} activeOpacity={0.85}>
              <Text style={styles.primaryText}>Firestore에 메모 저장</Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={styles.secondaryButton}
              onPress={() => Alert.alert('추천', '추천 리스트를 확인하세요!')}
              activeOpacity={0.85}
            >
              <Text style={styles.secondaryText}>추천 보기</Text>
            </TouchableOpacity>
          </View>
          {!!notes.length && (
            <View style={styles.noteBubble}>
              <Text style={styles.noteBubbleText}>{notes[0]}</Text>
            </View>
          )}
        </View>

        <Section title="지금 가장 뜨는 영화" data={popular} wishlist={wishlist} onToggle={toggleWishlist} />
        <Section title="극장에서 막 나온 작품" data={nowPlaying} wishlist={wishlist} onToggle={toggleWishlist} />
        <Section title="추천 큐레이션" data={recommend} wishlist={wishlist} onToggle={toggleWishlist} />
      </ScrollView>
    </SafeAreaView>
  )
}

function Section({
  title,
  data,
  wishlist,
  onToggle,
}: {
  title: string
  data: Movie[]
  wishlist: Set<string>
  onToggle: (id: string) => void
}) {
  return (
    <View style={styles.section}>
      <Text style={styles.sectionTitle}>{title}</Text>
      <FlatList
        data={data}
        keyExtractor={(item) => item.id}
        horizontal
        showsHorizontalScrollIndicator={false}
        renderItem={({ item }) => {
          const picked = wishlist.has(item.id)
          return (
            <View style={styles.card}>
              <View style={styles.poster} />
              <Text style={styles.cardTitle} numberOfLines={1}>
                {item.title}
              </Text>
              <Text style={styles.cardTag}>{item.tag}</Text>
              <TouchableOpacity
                style={[styles.wishButton, picked && styles.wishButtonActive]}
                onPress={() => onToggle(item.id)}
              >
                <Text style={styles.wishButtonText}>{picked ? '♥ 찜됨' : '♡ 찜하기'}</Text>
              </TouchableOpacity>
            </View>
          )
        }}
      />
    </View>
  )
}

const styles = StyleSheet.create({
  authContainer: {
    flex: 1,
    backgroundColor: '#05070f',
    paddingHorizontal: 20,
    justifyContent: 'center',
  },
  logo: {
    color: '#e50914',
    fontWeight: '800',
    fontSize: 22,
  },
  authCard: {
    marginTop: 12,
    backgroundColor: '#0b1021',
    borderRadius: 16,
    padding: 18,
    borderWidth: 1,
    borderColor: '#111827',
  },
  authTabs: {
    flexDirection: 'row',
    marginBottom: 14,
  },
  authTab: {
    flex: 1,
    paddingVertical: 10,
    alignItems: 'center',
    borderWidth: 1,
    borderColor: '#1f2937',
  },
  authTabActive: {
    backgroundColor: '#e50914',
    borderColor: '#e50914',
  },
  authTabText: {
    color: '#fff',
    fontWeight: '700',
    letterSpacing: 1,
  },
  authTitle: {
    color: '#fff',
    fontSize: 20,
    fontWeight: '700',
    marginBottom: 12,
  },
  input: {
    backgroundColor: '#0f172a',
    color: '#fff',
    borderRadius: 12,
    paddingHorizontal: 14,
    paddingVertical: 12,
    marginBottom: 10,
    borderWidth: 1,
    borderColor: '#1f2937',
  },
  primaryButton: {
    backgroundColor: '#e50914',
    borderRadius: 12,
    paddingVertical: 14,
    alignItems: 'center',
    marginTop: 6,
  },
  primaryText: {
    color: '#fff',
    fontWeight: '700',
  },
  homeContainer: {
    flex: 1,
    backgroundColor: '#05070f',
  },
  navBar: {
    paddingHorizontal: 20,
    paddingVertical: 14,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  navLinks: {
    flexDirection: 'row',
    gap: 12,
    alignItems: 'center',
  },
  navLink: {
    color: '#e5e7eb',
    fontSize: 12,
    letterSpacing: 1,
  },
  logoutPill: {
    borderRadius: 999,
    borderWidth: 1,
    borderColor: '#1f2937',
    paddingHorizontal: 12,
    paddingVertical: 8,
    backgroundColor: '#0b1021',
  },
  logoutPillText: {
    color: '#cbd5e1',
    fontWeight: '600',
  },
  hero: {
    paddingHorizontal: 20,
    paddingVertical: 18,
    gap: 6,
  },
  heroEyebrow: {
    color: '#9ca3af',
    letterSpacing: 2,
    fontSize: 11,
  },
  heroTitle: {
    color: '#fff',
    fontSize: 22,
    fontWeight: '800',
  },
  heroSubtitle: {
    color: '#cbd5e1',
    fontSize: 13,
  },
  heroButtons: {
    flexDirection: 'row',
    gap: 10,
    marginTop: 10,
    flexWrap: 'wrap',
  },
  secondaryButton: {
    borderRadius: 12,
    borderWidth: 1,
    borderColor: '#1f2937',
    paddingVertical: 12,
    paddingHorizontal: 14,
    backgroundColor: '#0b1021',
  },
  secondaryText: {
    color: '#e5e7eb',
    fontWeight: '700',
  },
  noteBubble: {
    marginTop: 10,
    backgroundColor: '#0f172a',
    padding: 10,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: '#1f2937',
  },
  noteBubbleText: {
    color: '#e5e7eb',
  },
  section: {
    paddingHorizontal: 20,
    marginTop: 10,
    marginBottom: 4,
  },
  sectionTitle: {
    color: '#e5e7eb',
    fontSize: 16,
    fontWeight: '700',
    marginBottom: 8,
  },
  card: {
    backgroundColor: '#0b1021',
    borderRadius: 12,
    padding: 10,
    marginRight: 12,
    width: 160,
    borderWidth: 1,
    borderColor: '#1f2937',
  },
  poster: {
    height: 190,
    borderRadius: 8,
    backgroundColor: '#111827',
    marginBottom: 10,
  },
  cardTitle: {
    color: '#fff',
    fontWeight: '700',
    marginBottom: 4,
  },
  cardTag: {
    color: '#9ca3af',
    fontSize: 12,
    marginBottom: 10,
  },
  wishButton: {
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#1f2937',
    paddingVertical: 8,
    alignItems: 'center',
    backgroundColor: '#0f172a',
  },
  wishButtonActive: {
    borderColor: '#e50914',
    backgroundColor: 'rgba(229,9,20,0.12)',
  },
  wishButtonText: {
    color: '#e5e7eb',
    fontWeight: '700',
    fontSize: 12,
  },
})
