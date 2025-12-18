import { forwardRef, useImperativeHandle, useMemo, useRef, useState } from 'react'
import { ActivityIndicator, Animated, Easing, Text, TextInput, TouchableOpacity, View } from 'react-native'
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
}

export interface AuthScreenHandle {
  openCurtain: () => Promise<void>
  closeCurtain: () => Promise<void>
  switchModeAnimated: (next: Mode) => Promise<void>
}

export const AuthScreen = forwardRef<AuthScreenHandle, Props>(function AuthScreen(
  {
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
  },
  ref,
) {
  const fs = fontScale
  const curtainProgress = useRef(new Animated.Value(0)).current
  const [stageWidth, setStageWidth] = useState(0)
  const [curtainOpen, setCurtainOpen] = useState(false)
  const stripes = useMemo(() => Array.from({ length: 14 }, (_, idx) => idx), [])

  const halfWidth = stageWidth / 2
  const leftTranslate = curtainProgress.interpolate({
    inputRange: [0, 1],
    outputRange: [0, -halfWidth],
  })
  const rightTranslate = curtainProgress.interpolate({
    inputRange: [0, 1],
    outputRange: [0, halfWidth],
  })
  const formOpacity = curtainProgress.interpolate({
    inputRange: [0.45, 1],
    outputRange: [0, 1],
    extrapolate: 'clamp',
  })
  const formTranslate = curtainProgress.interpolate({
    inputRange: [0, 1],
    outputRange: [16, 0],
  })

  const animateCurtain = (open: boolean, onComplete?: () => void) => {
    if (open) setCurtainOpen(true)
    Animated.timing(curtainProgress, {
      toValue: open ? 1 : 0,
      duration: 750,
      easing: Easing.out(Easing.cubic),
      useNativeDriver: true,
    }).start(({ finished }) => {
      if (!finished) return
      if (!open) setCurtainOpen(false)
      if (onComplete) onComplete()
    })
  }

  const switchMode = (next: Mode) => {
    if (mode === next) return
    animateCurtain(false, () => {
      setMode(next)
      animateCurtain(true)
    })
  }

  const runCurtain = (open: boolean) => new Promise<void>((resolve) => animateCurtain(open, resolve))

  useImperativeHandle(ref, () => ({
    openCurtain: () => runCurtain(true),
    closeCurtain: () => runCurtain(false),
    switchModeAnimated: async (next: Mode) => {
      if (mode === next) return runCurtain(true)
      await runCurtain(false)
      setMode(next)
      await runCurtain(true)
    },
  }))

  return (
    <>
      <StatusBar style="light" />
      <Text style={[styles.logo, { color: colors.accent }]}></Text>
      <View style={styles.curtainSection}>
        <View
          style={[styles.curtainStage, mode === 'signup' && styles.curtainStageTall]}
          onLayout={({ nativeEvent }) => setStageWidth(nativeEvent.layout.width)}
        >
          <Animated.View
            style={[
              styles.curtainPanel,
              styles.curtainPanelLeft,
              { transform: [{ translateX: leftTranslate }] },
            ]}
          >
            <View style={[styles.curtainFill, { backgroundColor: '#e02020' }]}>
              <View style={styles.curtainStripes}>
                {stripes.map((idx) => (
                  <View
                    key={`left-${idx}`}
                    style={[
                      styles.curtainStripe,
                      { opacity: idx % 2 === 0 ? 0.08 : 0.16, backgroundColor: 'rgba(0,0,0,0.18)' },
                    ]}
                  />
                ))}
              </View>
              <View style={styles.curtainSheen} />
            </View>
          </Animated.View>
          <Animated.View
            style={[
              styles.curtainPanel,
              styles.curtainPanelRight,
              { transform: [{ translateX: rightTranslate }] },
            ]}
          >
            <View style={[styles.curtainFill, { backgroundColor: '#e02020' }]}>
              <View style={styles.curtainStripes}>
                {stripes.map((idx) => (
                  <View
                    key={`right-${idx}`}
                    style={[
                      styles.curtainStripe,
                      { opacity: idx % 2 === 0 ? 0.08 : 0.16, backgroundColor: 'rgba(0,0,0,0.18)' },
                    ]}
                  />
                ))}
              </View>
              <View style={styles.curtainSheen} />
            </View>
          </Animated.View>
          <Animated.View
            style={[
              styles.curtainContent,
              {
                backgroundColor: colors.card,
                borderColor: colors.border,
                opacity: formOpacity,
                transform: [{ translateY: formTranslate }],
              },
            ]}
            pointerEvents={curtainOpen ? 'auto' : 'none'}
          >
            <View style={styles.authTabs}>
              <TouchableOpacity
                style={[
                  styles.authTab,
                  { borderColor: colors.border },
                  mode === 'login' && { backgroundColor: colors.accent, borderColor: colors.accent },
                ]}
                onPress={() => switchMode('login')}
                activeOpacity={0.85}
              >
                <Text style={[styles.authTabText, { fontSize: fs(14) }]}>LOGIN</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[
                  styles.authTab,
                  { borderColor: colors.border },
                  mode === 'signup' && { backgroundColor: colors.accent, borderColor: colors.accent },
                ]}
                onPress={() => switchMode('signup')}
                activeOpacity={0.85}
              >
                <Text style={[styles.authTabText, { fontSize: fs(14) }]}>SIGN UP</Text>
              </TouchableOpacity>
            </View>

            <Text style={[styles.authTitle, { fontSize: fs(20), color: colors.text }]}>
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
                <Text style={[styles.primaryText, { fontSize: fs(16) }]}>
                  {mode === 'login' ? '로그인하기' : '회원가입하기'}
                </Text>
              )}
            </TouchableOpacity>
          </Animated.View>
        </View>
        <View style={styles.curtainButtons}>
          <TouchableOpacity
            style={[
              styles.curtainButton,
              styles.curtainButtonPrimary,
              { backgroundColor: colors.accent, borderColor: colors.accent },
            ]}
            onPress={() => animateCurtain(true)}
            activeOpacity={0.85}
          >
            <Text style={styles.curtainButtonPrimaryText}>입장하기</Text>
          </TouchableOpacity>
        </View>
      </View>
    </>
  )
})
