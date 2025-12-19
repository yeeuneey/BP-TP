import * as WebBrowser from 'expo-web-browser'
import {
  AuthRequest,
  type AuthRequestPromptOptions,
  makeRedirectUri,
} from 'expo-auth-session'
import Constants from 'expo-constants'
import { GithubAuthProvider, signInWithCredential } from 'firebase/auth'

import { auth } from '../firebaseConfig'

WebBrowser.maybeCompleteAuthSession()

type ExtraConfig =
  | {
      githubClientId?: string
      githubClientSecret?: string
    }
  | undefined

const extra = Constants.expoConfig?.extra as ExtraConfig

const getClientId = () =>
  process.env.EXPO_PUBLIC_GITHUB_CLIENT_ID ?? extra?.githubClientId ?? ''
const getClientSecret = () =>
  process.env.EXPO_PUBLIC_GITHUB_CLIENT_SECRET ?? extra?.githubClientSecret ?? ''

// Expo proxy를 강제 사용해 항상 HTTPS callback을 쓰도록 고정
const owner = Constants.expoConfig?.owner ?? 'anonymous'
const slug = Constants.expoConfig?.slug ?? 'mobile'
const redirectUri = `https://auth.expo.io/@${owner}/${slug}`
// 디버그용: 실제 redirect_uri 확인 -> 터미널에서 npx expo start -c 실행 후 이 로그를 복사해 GitHub/Firebase 콜백 URL로 사용
console.log('redirectUri (GitHub OAuth)', redirectUri)
const discovery = {
  authorizationEndpoint: 'https://github.com/login/oauth/authorize',
  tokenEndpoint: 'https://github.com/login/oauth/access_token',
}

async function exchangeCodeForToken(code: string, clientId: string, clientSecret: string) {
  const body = new URLSearchParams({
    client_id: clientId,
    client_secret: clientSecret,
    code,
  }).toString()

  const response = await fetch(discovery.tokenEndpoint, {
    method: 'POST',
    headers: {
      Accept: 'application/json',
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body,
  })

  const json = (await response.json()) as { access_token?: string; error?: string; error_description?: string }
  if (!response.ok || json.error || !json.access_token) {
    const detail = json.error_description ?? json.error ?? 'Unknown error'
    throw new Error(`GitHub 토큰 교환 실패: ${detail}`)
  }

  return json.access_token
}

export async function signInWithGithub() {
  const clientId = getClientId()
  const clientSecret = getClientSecret()

  if (!clientId || !clientSecret) {
    throw new Error('GitHub OAuth 설정이 없습니다. app.json 또는 환경변수를 확인하세요.')
  }

  const request = new AuthRequest({
    clientId,
    redirectUri,
    scopes: ['read:user', 'user:email'],
    usePKCE: false, // GitHub는 기본적으로 client_secret 기반
    extraParams: { allow_signup: 'false' },
  })

  await request.makeAuthUrlAsync(discovery)

  const promptOptions: AuthRequestPromptOptions = { useProxy: true }
  const result = await request.promptAsync(discovery, promptOptions)

  if (result.type !== 'success' || !result.params?.code) {
    throw new Error('GitHub 로그인 취소 또는 실패')
  }

  const token = await exchangeCodeForToken(result.params.code as string, clientId, clientSecret)
  const credential = GithubAuthProvider.credential(token)
  await signInWithCredential(auth, credential)
}
