// Firebase initialization
// Reads config from Vite env (VITE_FIREBASE_*)
import { initializeApp, getApp, getApps, type FirebaseApp } from 'firebase/app'
import { getAuth } from 'firebase/auth'
import { getFirestore } from 'firebase/firestore'

const rawConfig = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY,
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN,
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID,
  storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID,
  appId: import.meta.env.VITE_FIREBASE_APP_ID,
}

if (import.meta.env.DEV) {
  // Helps diagnose missing envs in local dev
  // eslint-disable-next-line no-console
  console.log('Firebase env (dev):', rawConfig)
}

const missing = Object.entries(rawConfig)
  .filter(([, v]) => !v)
  .map(([k]) => k)

if (missing.length) {
  throw new Error(`Missing Firebase env vars: ${missing.join(', ')}`)
}

const firebaseConfig = rawConfig as {
  apiKey: string
  authDomain: string
  projectId: string
  storageBucket: string
  messagingSenderId: string
  appId: string
}

// Prevent re-initialization in HMR, and ensure type is FirebaseApp (not undefined)
let app: FirebaseApp
if (getApps().length) {
  app = getApp()
} else {
  app = initializeApp(firebaseConfig)
}

export const auth = getAuth(app)
export const db = getFirestore(app)
