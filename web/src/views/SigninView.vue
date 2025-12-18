<template>
  <div class="auth-page">
    <div class="starfield">
      <span
        v-for="star in stars"
        :key="star.id"
        class="star"
        :class="`star--${star.variant}`"
        :style="star.style"
      ></span>
    </div>

    <div class="auth-stage">
      <div class="auth-stage__controls">
        <button
          type="button"
          class="mode-chip mode-chip--login"
          :class="{ active: mode === 'login' }"
          @click="changeMode('login')"
        >
          LOGIN
        </button>

        <div class="auth-title">
          {{ mode === 'login' ? 'Sign In' : 'Create Account' }}
        </div>

        <button
          type="button"
          class="mode-chip mode-chip--signup"
          :class="{ active: mode === 'register' }"
          @click="changeMode('register')"
        >
          SIGN UP
        </button>
      </div>

      <div class="auth-rotator">
        <div class="curtain" :class="{ 'curtain--open': curtainOpen }" aria-hidden="true">
          <span class="curtain__panel curtain__panel--left"></span>
          <span class="curtain__panel curtain__panel--right"></span>
          <span class="curtain__glow"></span>
        </div>
        <div
          class="auth-peek auth-peek--register"
          :class="{ 'auth-peek--visible': mode === 'login' }"
          aria-hidden="true"
        ></div>
        <div
          class="auth-peek auth-peek--login"
          :class="{ 'auth-peek--visible': mode === 'register' }"
          aria-hidden="true"
        ></div>

        <div class="auth-carousel" :class="[`auth-carousel--${mode}`]">
          <section class="auth-panel auth-panel--login">
            <div class="panel-content" :class="{ 'panel-content--visible': mode === 'login' }">
              <div class="panel-eyebrow">LOGIN PANEL</div>
              <h2 class="panel-title">Sign In</h2>
              <p class="panel-subtitle">
                TMDB API Key를 비밀번호 자리로 입력하면 됩니다.
              </p>

              <form class="auth-form" @submit.prevent="handleLogin">
                <div class="field">
                  <label for="login-email">이메일</label>
                  <input
                    id="login-email"
                    v-model="loginEmail"
                    type="email"
                    placeholder="you@example.com"
                    required
                  />
                </div>
                <div class="field">
                  <label for="login-password">비밀번호 (TMDB API Key)</label>
                  <input
                    id="login-password"
                    v-model="loginPassword"
                    type="password"
                    placeholder="TMDB API Key"
                    required
                  />
                </div>

                <div class="form-row">
                  <label class="remember-toggle">
                    <input v-model="rememberMe" type="checkbox" />
                    <span>로그인 상태 유지</span>
                  </label>
                </div>

              <button type="submit" class="cta-button" :disabled="isSubmitting">
                로그인
              </button>
            </form>

            <button
              type="button"
              class="cta-button cta-button--google"
              :disabled="isSubmitting"
              @click="handleGoogleLogin"
            >
              Google 로그인
            </button>

            <p v-if="message && mode === 'login'" class="auth-message auth-message--inline">
              {{ message }}
            </p>
          </div>
        </section>

          <section class="auth-panel auth-panel--register">
            <div
              class="panel-content"
              :class="{ 'panel-content--visible': mode === 'register' }"
            >
              <div class="panel-eyebrow">SIGN UP PANEL</div>
              <h2 class="panel-title">Create account</h2>
              <p class="panel-subtitle">
                이메일과 TMDB API Key로 계정을 생성합니다.
              </p>

              <form class="auth-form" @submit.prevent="handleRegister">
                <div class="field">
                  <label for="register-email">이메일</label>
                  <input
                    id="register-email"
                    v-model="registerEmail"
                    type="email"
                    placeholder="you@example.com"
                    required
                  />
                </div>
                <div class="field">
                  <label for="register-password">비밀번호 (TMDB API Key)</label>
                  <input
                    id="register-password"
                    v-model="registerPassword"
                    type="password"
                    placeholder="TMDB API Key"
                    required
                  />
                </div>
                <div class="field">
                  <label for="register-password-confirm">비밀번호 확인</label>
                  <input
                    id="register-password-confirm"
                    v-model="registerPasswordConfirm"
                    type="password"
                    placeholder="비밀번호를 다시 입력하세요"
                    required
                  />
                </div>

                <label class="terms">
                  <input v-model="agreeTerms" type="checkbox" />
                  <span>약관에 동의합니다.</span>
                </label>

                <button type="submit" class="cta-button cta-button--signup" :disabled="isSubmitting">
                  회원가입
                </button>
              </form>

              <p
                v-if="message && mode === 'register'"
                class="auth-message auth-message--inline"
              >
                {{ message }}
              </p>
            </div>
          </section>
        </div>
      </div>
    </div>

    <div class="curtain-toggle-row">
      <button type="button" class="curtain-toggle" @click="openCurtain">
        시작하기
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import {
  getRememberedEmail,
  isKeepLoginEnabled,
  tryLogin,
  tryRegister,
  loginWithGoogle,
} from '@/services/auth'

const router = useRouter()

const mode = ref<'login' | 'register'>('login')
const curtainOpen = ref(false)
let curtainTimer: number | null = null

type StarVariant = 'near' | 'mid' | 'far'

interface StarConfig {
  id: number
  variant: StarVariant
  style: Record<string, string>
}

const STAR_COUNT = 260

const variantBaseDuration: Record<StarVariant, number> = {
  near: 35,
  mid: 55,
  far: 90,
}

const stars: StarConfig[] = Array.from({ length: STAR_COUNT }, (_, idx) => {
  const variant: StarVariant = idx % 3 === 0 ? 'near' : idx % 2 === 0 ? 'mid' : 'far'
  const jitter = Math.random() * 12 - 6
  const duration = Math.max(15, variantBaseDuration[variant] + jitter)
  const delay = (Math.random() * duration * -1).toFixed(2)

  return {
    id: idx,
    variant,
    style: {
      top: `${Math.random() * 100}vh`,
      left: `${Math.random() * 100}vw`,
      animationDelay: `${delay}s`,
      animationDuration: `${duration}s`,
    },
  }
})

const loginEmail = ref(getRememberedEmail() ?? '')
const loginPassword = ref('')
const rememberMe = ref(isKeepLoginEnabled())

const registerEmail = ref('')
const registerPassword = ref('')
const registerPasswordConfirm = ref('')
const agreeTerms = ref(false)

const message = ref('')
const isSubmitting = ref(false)

function isValidEmail(email: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)
}

async function handleLogin() {
  if (!isValidEmail(loginEmail.value)) {
    message.value = '유효한 이메일을 입력해주세요.'
    return
  }
  message.value = ''
  isSubmitting.value = true
  await tryLogin(
    loginEmail.value,
    loginPassword.value,
    () => {
      message.value = '로그인 성공! 홈으로 이동합니다.'
      router.push('/')
    },
    (err: string) => {
      message.value = err
    },
    rememberMe.value,
  )
  isSubmitting.value = false
}

async function handleRegister() {
  if (!isValidEmail(registerEmail.value)) {
    message.value = '유효한 이메일을 입력해주세요.'
    return
  }
  if (registerPassword.value !== registerPasswordConfirm.value) {
    message.value = '비밀번호가 일치하지 않습니다.'
    return
  }
  if (!agreeTerms.value) {
    message.value = '약관에 동의해주세요.'
    return
  }

  message.value = ''
  isSubmitting.value = true
  await tryRegister(
    registerEmail.value,
    registerPassword.value,
    () => {
      message.value = '회원가입이 완료되었습니다. 로그인해 주세요.'
      mode.value = 'login'
      loginEmail.value = registerEmail.value
    },
    (err: string) => {
      message.value = err
    },
  )
  isSubmitting.value = false
}

async function handleGoogleLogin() {
  message.value = ''
  isSubmitting.value = true
  await loginWithGoogle(
    rememberMe.value,
    (user) => {
      message.value = `${user.id}로 로그인했어요.`
      router.push('/')
    },
    (err: string) => {
      message.value = err
    },
  )
  isSubmitting.value = false
}

function openCurtain() {
  curtainOpen.value = true
}

function changeMode(next: 'login' | 'register') {
  if (mode.value === next) return
  if (curtainTimer) {
    window.clearTimeout(curtainTimer)
    curtainTimer = null
  }
  curtainOpen.value = false
  curtainTimer = window.setTimeout(() => {
    mode.value = next
    curtainOpen.value = true
  }, 1000)
}
</script>

<style scoped>
.auth-page {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 2rem 0;
  background: #000;
  color: #fff;
  overflow: hidden;
  position: relative;
}

.starfield {
  position: fixed;
  inset: 0;
  overflow: hidden;
  background: #000;
  z-index: 0;
  pointer-events: none;
}

.star {
  position: absolute;
  background: white;
  border-radius: 50%;
  opacity: 0.8;
  animation-name: drift;
  animation-timing-function: linear;
  animation-iteration-count: infinite;
  will-change: transform;
}

.star--far {
  width: 1px;
  height: 1px;
  opacity: 0.4;
  animation-duration: 90s;
}

.star--mid {
  width: 2px;
  height: 2px;
  opacity: 0.7;
  animation-duration: 50s;
}

.star--near {
  width: 3px;
  height: 3px;
  opacity: 0.9;
  animation-duration: 30s;
}

@keyframes drift {
  from {
    transform: translate3d(0, 0, 0);
  }
  to {
    transform: translate3d(-40vw, 0, 0);
  }
}

.auth-stage {
  position: relative;
  width: min(720px, 100%);
  padding: 1.8rem 0 1rem;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 1.5rem;
  perspective: 1600px;
  perspective-origin: 50% 40%;
  z-index: 1;
}

.auth-stage__controls {
  display: grid;
  grid-template-columns: auto 1fr auto;
  align-items: center;
  column-gap: 1rem;
  padding: 0.65rem 1rem;
  border-radius: 999px;
  background: rgba(7, 10, 24, 0.75);
  box-shadow:
    0 20px 40px rgba(0, 0, 0, 0.55),
    inset 0 0 0 1px rgba(255, 255, 255, 0.08);
  backdrop-filter: blur(12px);
  position: relative;
}

.auth-title {
  text-align: center;
  font-size: 1.1rem;
  font-weight: 700;
  letter-spacing: 0.08em;
}

.mode-chip {
  border-radius: 999px;
  padding: 0.35rem 1rem;
  border: none;
  font-size: 0.78rem;
  letter-spacing: 0.12em;
  font-weight: 700;
  cursor: pointer;
  background: transparent;
  color: rgba(255, 255, 255, 0.75);
  white-space: nowrap;
  box-shadow: inset 0 0 0 1px rgba(229, 9, 20, 0.35);
  transition: background 0.2s ease, box-shadow 0.2s ease, transform 0.15s ease,
    color 0.2s ease;
}

.mode-chip--login {
  padding-inline: 0.9rem;
}

.mode-chip--signup {
  padding-inline: 1.05rem;
}

.mode-chip.active {
  background: radial-gradient(circle at 20% 0%, #ff646c, #e50914 55%, #a0030b 95%);
  color: #fff;
  box-shadow:
    0 0 14px rgba(229, 9, 20, 0.65),
    0 12px 20px rgba(72, 5, 7, 0.85);
  transform: translateY(-1px);
}

.curtain-toggle-row {
  display: flex;
  justify-content: center;
  position: absolute;
  left: 50%;
  transform: translateX(-50%);
  bottom: 1.75rem;
  width: 100%;
  pointer-events: none;
}

.curtain-toggle {
  border: 1px solid rgba(229, 9, 20, 0.7);
  background: linear-gradient(135deg, #b4050c, #e50914, #8a040a);
  color: #fff;
  border-radius: 999px;
  padding: 0.55rem 1.4rem;
  font-weight: 800;
  letter-spacing: 0.08em;
  cursor: pointer;
  box-shadow:
    0 14px 28px rgba(229, 9, 20, 0.35),
    inset 0 0 0 1px rgba(255, 255, 255, 0.12);
  transition: background 0.2s ease, box-shadow 0.2s ease, transform 0.15s ease,
    filter 0.2s ease;
  pointer-events: auto;
}

.curtain-toggle:hover {
  background: linear-gradient(135deg, #c4060d, #e50914, #9b040c);
  box-shadow:
    0 18px 34px rgba(229, 9, 20, 0.4),
    inset 0 0 0 1px rgba(255, 255, 255, 0.15);
  transform: translateY(-1px);
  filter: brightness(1.05);
}

.auth-rotator {
  position: relative;
  width: clamp(260px, 64vw, 420px);
  height: clamp(320px, 50vh, 400px);
  perspective: inherit;
}

.curtain {
  position: absolute;
  inset: -28% -18%;
  display: grid;
  grid-template-columns: 1fr 1fr;
  pointer-events: none;
  z-index: 5;
}

.curtain::after {
  content: '';
  position: absolute;
  inset: 0;
  background: rgba(0, 0, 0, 0.16);
  pointer-events: none;
  z-index: 1;
}

.curtain__panel {
  position: relative;
  overflow: hidden;
  background:
    linear-gradient(120deg, rgba(255, 255, 255, 0.12), transparent 40%),
    linear-gradient(60deg, rgba(255, 255, 255, 0.07), transparent 55%),
    repeating-linear-gradient(
      to right,
      rgba(0, 0, 0, 0.16) 0%,
      rgba(0, 0, 0, 0.06) 4%,
      rgba(0, 0, 0, 0.16) 8%
    ),
    repeating-linear-gradient(
      to bottom,
      rgba(0, 0, 0, 0.18) 0%,
      rgba(0, 0, 0, 0.08) 18%,
      rgba(0, 0, 0, 0.18) 36%
    ),
    linear-gradient(135deg, rgba(229, 9, 20, 1), rgba(124, 6, 12, 1));
  border: 1px solid rgba(255, 255, 255, 0.08);
  transition: transform 0.6s cubic-bezier(0.19, 1, 0.22, 1);
  box-shadow:
    inset 0 0 50px rgba(0, 0, 0, 0.35),
    0 18px 45px rgba(0, 0, 0, 0.6);
  opacity: 1;
}

.curtain__panel::before {
  content: '';
  position: absolute;
  inset: -14% 12%;
  background: radial-gradient(circle at 40% 20%, rgba(255, 255, 255, 0.22), transparent 45%);
  opacity: 0.35;
  mix-blend-mode: screen;
  filter: blur(2px);
  pointer-events: none;
}

.curtain__panel::after {
  content: '';
  position: absolute;
  inset: 0;
  background: repeating-linear-gradient(
    to right,
    rgba(0, 0, 0, 0.24) 0%,
    rgba(0, 0, 0, 0.08) 6%,
    rgba(0, 0, 0, 0.24) 12%
  );
  opacity: 0.25;
  mix-blend-mode: multiply;
  pointer-events: none;
}

.curtain__panel--left {
  border-right: none;
}

.curtain__panel--right {
  border-left: none;
}

.curtain__glow {
  position: absolute;
  inset: 8% 4%;
  background: radial-gradient(circle, rgba(229, 9, 20, 0.5), transparent 70%);
  filter: blur(32px);
  opacity: 0;
  transition: opacity 0.6s ease;
}

.curtain--open .curtain__panel--left {
  transform: translateX(-105%);
}

.curtain--open .curtain__panel--right {
  transform: translateX(105%);
}

.curtain--open .curtain__glow {
  opacity: 0;
}

.curtain-launch {
  margin-top: 0.45rem;
  width: 100%;
  border: 1px solid rgba(229, 9, 20, 0.6);
  background: linear-gradient(135deg, #c4060d, #e50914);
  color: #fff;
  border-radius: 999px;
  padding: 0.75rem 1rem;
  font-weight: 800;
  letter-spacing: 0.08em;
  cursor: pointer;
  box-shadow:
    0 18px 32px rgba(229, 9, 20, 0.35),
    inset 0 0 0 1px rgba(255, 255, 255, 0.08);
  transition: transform 0.18s ease, box-shadow 0.18s ease, filter 0.18s ease;
}

.curtain-launch:hover {
  transform: translateY(-1px);
  filter: brightness(1.05);
  box-shadow:
    0 22px 36px rgba(229, 9, 20, 0.4),
    inset 0 0 0 1px rgba(255, 255, 255, 0.12);
}

.auth-peek {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  margin: 0 auto;
  width: 86%;
  height: 82%;
  border-radius: 1.5rem;
  background:
    radial-gradient(circle at 20% 30%, rgba(255, 255, 255, 0.15) 1px, transparent 1px),
    radial-gradient(circle at 70% 60%, rgba(255, 255, 255, 0.08) 1px, transparent 1px),
    radial-gradient(circle at top, rgba(41, 63, 109, 0.5), rgba(12, 13, 41, 0.9));
  opacity: 0;
  transform: translateY(-28px) scale(0.94);
  transition: opacity 0.35s ease;
  pointer-events: none;
  z-index: 0;
  filter: blur(0.5px);
}

.auth-peek--login {
  background: radial-gradient(circle at top, rgba(106, 48, 244, 0.5), rgba(9, 7, 45, 0.85));
}

.auth-peek--visible {
  opacity: 0.35;
}

.auth-carousel {
  --panel-depth: 150px;
  position: relative;
  width: 100%;
  height: 100%;
  transform-style: preserve-3d;
  transition: transform 0.9s cubic-bezier(0.19, 1, 0.22, 1);
  transform: rotateY(var(--carousel-rotation, 0deg));
  z-index: 1;
}

.auth-carousel--login {
  --carousel-rotation: 0deg;
}

.auth-carousel--register {
  --carousel-rotation: 180deg;
}

.auth-panel {
  position: absolute;
  top: 0;
  left: 50%;
  width: min(360px, 96%);
  min-height: 100%;
  padding: 1.35rem 1rem 1.8rem;
  border-radius: 1.65rem;
  background: radial-gradient(circle at top left, rgba(8, 12, 36, 0.95), rgba(4, 6, 19, 0.98));
  border: 1px solid rgba(255, 255, 255, 0.08);
  box-shadow:
    0 22px 50px rgba(0, 0, 0, 0.82),
    0 0 0 1px rgba(0, 0, 0, 0.45);
  transform-style: preserve-3d;
  backface-visibility: hidden;
  opacity: 0.9;
  pointer-events: none;
  will-change: transform;
  transition: opacity 0.35s ease, filter 0.35s ease, transform 0.35s ease;
}

.auth-panel--login {
  transform: translateX(-50%) rotateY(0deg) translateZ(var(--panel-depth));
}

.auth-panel--register {
  transform: translateX(-50%) rotateY(180deg) translateZ(var(--panel-depth));
}

.auth-carousel--login .auth-panel--login,
.auth-carousel--register .auth-panel--register {
  opacity: 1;
  pointer-events: auto;
  filter: drop-shadow(0 25px 40px rgba(0, 0, 0, 0.7));
}

.auth-carousel--login .auth-panel--register,
.auth-carousel--register .auth-panel--login {
  opacity: 0.1;
}

.panel-eyebrow {
  text-transform: uppercase;
  letter-spacing: 0.4em;
  font-size: 0.72rem;
  color: rgba(255, 255, 255, 0.6);
}

.panel-title {
  margin: 0.2rem 0 0.3rem;
  font-size: 1.5rem;
  letter-spacing: 0.08em;
}

.panel-subtitle {
  margin: 0 0 0.95rem;
  color: rgba(255, 255, 255, 0.65);
  font-size: 0.9rem;
}

.panel-content {
  opacity: 0;
  transform: translateY(12px);
  transition: opacity 0.4s ease, transform 0.4s ease;
  pointer-events: none;
}

.panel-content--visible {
  opacity: 1;
  transform: translateY(0);
  pointer-events: auto;
}

.auth-form {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.field {
  display: flex;
  flex-direction: column;
  gap: 0.35rem;
}

.field label {
  font-size: 0.86rem;
  color: rgba(255, 255, 255, 0.85);
  letter-spacing: 0.02em;
}

.field input {
  width: 100%;
  border-radius: 0.88rem;
  border: 1px solid rgba(110, 148, 210, 0.6);
  background: radial-gradient(circle at top left, #05091a, #030511);
  color: #fff;
  padding: 0.55rem 1.2rem;
  font-size: 0.84rem;
  outline: none;
  min-height: 2.2rem;
  transition: border-color 0.18s ease, box-shadow 0.18s ease, background 0.18s ease;
}

.field input::placeholder {
  color: rgba(255, 255, 255, 0.45);
}

.field input:focus {
  border-color: #e50914;
  box-shadow:
    0 0 0 1px rgba(229, 9, 20, 0.45),
    0 0 22px rgba(229, 9, 20, 0.35);
  background: radial-gradient(circle at top left, #060c24, #050817);
}

.form-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  font-size: 0.82rem;
  margin-top: 0.25rem;
}

.remember-toggle {
  display: inline-flex;
  align-items: center;
  gap: 0.4rem;
  cursor: pointer;
  color: rgba(255, 255, 255, 0.78);
}

.remember-toggle input,
.terms input {
  accent-color: #e50914;
}

.terms {
  display: flex;
  gap: 0.5rem;
  font-size: 0.8rem;
  align-items: center;
  color: rgba(255, 255, 255, 0.78);
}

.cta-button {
  margin-top: 0.75rem;
  width: 100%;
  border: none;
  border-radius: 999px;
  padding: 0.9rem 1.2rem;
  font-weight: 700;
  font-size: 0.98rem;
  letter-spacing: 0.16em;
  text-align: center;
  color: #fff;
  cursor: pointer;
  background: linear-gradient(135deg, #a0040c, #e50914, #7b0308);
  box-shadow:
    0 18px 38px rgba(78, 5, 8, 0.85),
    0 0 0 1px rgba(229, 9, 20, 0.4);
  transition: transform 0.18s ease, box-shadow 0.18s ease, filter 0.18s ease;
}

.cta-button:hover {
  transform: translateY(-1px);
  filter: brightness(1.05);
  box-shadow:
    0 22px 40px rgba(86, 6, 10, 0.9),
    0 0 0 1px rgba(229, 9, 20, 0.6);
}

.cta-button:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.cta-button--google {
  margin-top: 0.4rem;
  background: linear-gradient(135deg, #1a73e8, #0f5db6);
  box-shadow:
    0 18px 38px rgba(15, 93, 182, 0.6),
    0 0 0 1px rgba(26, 115, 232, 0.45);
}

.auth-message {
  margin-top: 1.2rem;
  text-align: center;
  font-size: 0.86rem;
  color: #f5c518;
  z-index: 1;
}

.auth-message--inline {
  margin-top: 0.75rem;
  text-align: left;
}

@media (prefers-reduced-motion: reduce) {
  .auth-carousel {
    transition: none;
  }
  .panel-content {
    transition: none;
  }
}

@media (max-width: 640px) {
  .auth-stage {
    padding-inline: 1rem;
  }

  .auth-carousel {
    --panel-depth: 150px;
    height: min(460px, 70vh);
  }

  .auth-panel {
    width: 96%;
    padding: 1.7rem 1.25rem 2rem;
  }

  .form-row {
    flex-direction: column;
    align-items: flex-start;
    gap: 0.35rem;
  }

  .field input {
    font-size: 1rem;
  }
}

.slide-fade-enter-active,
.slide-fade-leave-active {
  transition: all 0.35s ease;
}
.slide-fade-enter-from {
  opacity: 0;
  transform: translateY(18px);
}
.slide-fade-leave-to {
  opacity: 0;
  transform: translateY(-18px);
}

@media (max-width: 520px) {
  .auth-card {
    width: calc(100% - 1.5rem);
    padding: 1.9rem 1.4rem 2.1rem;
  }

  .auth-header-row {
    column-gap: 0.5rem;
  }

  .auth-title {
    font-size: 1.05rem;
  }

  .form-row {
    flex-direction: column;
    align-items: flex-start;
    gap: 0.35rem;
  }
}
</style>
