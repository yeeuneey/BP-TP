import { ActivityIndicator, Text, TextInput, TouchableOpacity, View } from 'react-native'
import { StatusBar } from 'expo-status-bar'

import type { ThemeColors } from '../theme'
import { styles } from '../styles'
import { Mode } from '../types'

interface Props {
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
}

export function AuthScreen({
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
}: Props) {
  const fs = fontScale

  return (
    <>
      <StatusBar style="light" />
      <Text style={[styles.logo, { color: colors.accent }]}>PB neteflix</Text>
      <View style={[styles.authCard, { backgroundColor: colors.card, borderColor: colors.border }]}>
        <View style={styles.authTabs}>
          <TouchableOpacity
            style={[
              styles.authTab,
              { borderColor: colors.border },
              mode === 'login' && { backgroundColor: colors.accent, borderColor: colors.accent },
            ]}
            onPress={() => setMode('login')}
          >
            <Text style={[styles.authTabText, { fontSize: fs(14) }]}>LOGIN</Text>
          </TouchableOpacity>
          <TouchableOpacity
            style={[
              styles.authTab,
              { borderColor: colors.border },
              mode === 'signup' && { backgroundColor: colors.accent, borderColor: colors.accent },
            ]}
            onPress={() => setMode('signup')}
          >
            <Text style={[styles.authTabText, { fontSize: fs(14) }]}>SIGN UP</Text>
          </TouchableOpacity>
        </View>

        <Text style={[styles.authTitle, { fontSize: fs(20), color: colors.text }]}>
          {mode === 'login' ? '로그인' : 'Create account'}
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
          {busy ? <ActivityIndicator color="#fff" /> : <Text style={[styles.primaryText, { fontSize: fs(16) }]}>시작하기</Text>}
        </TouchableOpacity>

        <TouchableOpacity
          style={[styles.googleButton, { borderColor: colors.border }]}
          onPress={onGoogleLogin}
          disabled={busy}
          activeOpacity={0.85}
        >
          <Text style={[styles.googleButtonText, { color: colors.text, fontSize: fs(14) }]}>Google로 로그인</Text>
        </TouchableOpacity>
      </View>
    </>
  )
}
