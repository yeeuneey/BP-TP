// Firebase initialization for Expo (mobile)
// Reads config from env (app.json / app.config.ts) via process.env.*
import { initializeApp, getApps, getApp, type FirebaseApp } from 'firebase/app'
import { getAuth } from 'firebase/auth'
import { getFirestore } from 'firebase/firestore'

const config = {
  apiKey: process.env.EXPO_PUBLIC_FIREBASE_API_KEY,
  authDomain: process.env.EXPO_PUBLIC_FIREBASE_AUTH_DOMAIN,
  projectId: process.env.EXPO_PUBLIC_FIREBASE_PROJECT_ID,
  storageBucket: process.env.EXPO_PUBLIC_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: process.env.EXPO_PUBLIC_FIREBASE_MESSAGING_SENDER_ID,
  appId: process.env.EXPO_PUBLIC_FIREBASE_APP_ID,
}

const missing = Object.entries(config)
  .filter(([, v]) => !v)
  .map(([k]) => k)

if (missing.length) {
  throw new Error(`Missing Firebase env vars: ${missing.join(', ')}`)
}

let app: FirebaseApp
if (getApps().length) {
  app = getApp()
} else {
  app = initializeApp(config)
}

export const auth = getAuth(app)
export const db = getFirestore(app)
