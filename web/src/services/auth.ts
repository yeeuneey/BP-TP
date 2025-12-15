// src/services/auth.ts
import type { User } from '@/types/user'

const USERS_KEY = 'users'
const CURRENT_USER_KEY = 'currentUser'
const KEEP_LOGIN_KEY = 'keepLogin'
const TMDB_KEY_STORAGE = 'TMDb-Key'
const REMEMBER_EMAIL_KEY = 'rememberEmail'

function setPersistedValue(key: string, value: string, persist: boolean) {
  const primary = persist ? localStorage : sessionStorage
  const secondary = persist ? sessionStorage : localStorage
  primary.setItem(key, value)
  secondary.removeItem(key)
}

function clearStoredValue(key: string) {
  localStorage.removeItem(key)
  sessionStorage.removeItem(key)
}

function getFromStorages(key: string): string | null {
  return localStorage.getItem(key) ?? sessionStorage.getItem(key)
}

function getUsers(): User[] {
  const raw = localStorage.getItem(USERS_KEY)
  return raw ? (JSON.parse(raw) as User[]) : []
}

function saveUsers(users: User[]) {
  localStorage.setItem(USERS_KEY, JSON.stringify(users))
}

export function tryRegister(
  email: string,
  password: string,
  success: (user: User) => void,
  fail: (msg: string) => void,
) {
  const users = getUsers()

  const userExists = users.some((u) => u.id === email)
  if (userExists) {
    fail('이미 가입된 계정입니다.')
    return
  }

  const newUser: User = { id: email, password }
  users.push(newUser)
  saveUsers(users)
  localStorage.setItem(TMDB_KEY_STORAGE, password)

  success(newUser)
}

export function tryLogin(
  email: string,
  password: string,
  success: (user: User) => void,
  fail: (msg: string) => void,
  saveToken: boolean,
) {
  const users = getUsers()
  const user = users.find((u) => u.id === email && u.password === password)

  if (!user) {
    fail('입력하신 아이디 또는 비밀번호가 올바르지 않습니다.')
    return
  }

  setPersistedValue(TMDB_KEY_STORAGE, user.password, saveToken)
  setPersistedValue(CURRENT_USER_KEY, user.id, saveToken)

  if (saveToken) {
    localStorage.setItem(KEEP_LOGIN_KEY, 'true')
    localStorage.setItem(REMEMBER_EMAIL_KEY, email)
  } else {
    localStorage.removeItem(KEEP_LOGIN_KEY)
    localStorage.removeItem(REMEMBER_EMAIL_KEY)
  }

  success(user)
}

export function logout() {
  clearStoredValue(CURRENT_USER_KEY)
  clearStoredValue(TMDB_KEY_STORAGE)
}

export function getCurrentUserId(): string | null {
  return getFromStorages(CURRENT_USER_KEY)
}

export function getStoredTmdbKey(): string | null {
  return getFromStorages(TMDB_KEY_STORAGE)
}

export function getRememberedEmail(): string | null {
  return localStorage.getItem(REMEMBER_EMAIL_KEY)
}

export function isKeepLoginEnabled(): boolean {
  return localStorage.getItem(KEEP_LOGIN_KEY) === 'true'
}
