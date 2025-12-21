import * as WebBrowser from 'expo-web-browser'
import * as AuthSession from 'expo-auth-session'
import Constants from 'expo-constants'
import { GithubAuthProvider, signInWithCredential } from 'firebase/auth'

import { auth } from '../firebaseConfig'

WebBrowser.maybeCompleteAuthSession()

type ExtraConfig = {
  githubClientId?: string
  githubTokenEndpoint?: string
} | undefined

const extra = Constants.expoConfig?.extra as ExtraConfig
const owner = Constants.expoConfig?.owner ?? 'anonymous'
const slug = Constants.expoConfig?.slug ?? 'mobile'
const projectNameForProxy = `@${owner}/${slug}`
const scheme = Constants.expoConfig?.scheme

const getClientId = () =>
  process.env.EXPO_PUBLIC_GITHUB_CLIENT_ID ??
  extra?.githubClientId ??
  (AuthSession as { expoClientId?: string }).expoClientId ??
  ''

const getTokenEndpoint = () =>
  process.env.EXPO_PUBLIC_GITHUB_TOKEN_ENDPOINT ?? extra?.githubTokenEndpoint ?? ''

export async function signInWithGithub() {
  const clientId = getClientId()
  if (!clientId) {
    throw new Error('Missing GitHub OAuth Client ID. Set EXPO_PUBLIC_GITHUB_CLIENT_ID or extra.githubClientId.')
  }

  // Proxy is only available in Expo Go / dev client. Standalone builds must use the native scheme.
  const useProxy = Constants.appOwnership === 'expo' || Constants.appOwnership === 'guest'
  const redirectUri = AuthSession.makeRedirectUri({
    useProxy,
    scheme,
    projectNameForProxy,
  })
  console.log('GitHub redirectUri:', redirectUri, 'useProxy:', useProxy)
  const request = new AuthSession.AuthRequest({
    clientId,
    redirectUri,
    scopes: ['read:user', 'user:email'],
    responseType: AuthSession.ResponseType.Code,
    usePKCE: true,
  })

  const result = await request.promptAsync(
    { authorizationEndpoint: 'https://github.com/login/oauth/authorize', redirectUri },
    { useProxy } as AuthSession.AuthRequestPromptOptions & { useProxy?: boolean },
  )

  if (result.type !== 'success') {
    throw new Error('GitHub login cancelled')
  }

  const code = result.params?.code
  if (!code) {
    throw new Error('GitHub authorization code not returned')
  }

  const tokenEndpoint = getTokenEndpoint()
  if (!tokenEndpoint) {
    throw new Error('Missing token exchange endpoint. Set EXPO_PUBLIC_GITHUB_TOKEN_ENDPOINT or extra.githubTokenEndpoint.')
  }

  const response = await fetch(tokenEndpoint, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ code, redirectUri, clientId }),
  })

  if (!response.ok) {
    const message = await response.text()
    throw new Error(`Failed to exchange GitHub code: ${message || response.status}`)
  }

  const { accessToken } = (await response.json()) as { accessToken?: string }

  if (!accessToken) {
    throw new Error('GitHub access token missing in exchange response')
  }

  const credential = GithubAuthProvider.credential(accessToken)
  await signInWithCredential(auth, credential)
}
