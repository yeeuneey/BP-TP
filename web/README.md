# WSD Assignment 02 - WSDflix

TMDB 공개 데이터를 활용해 영화/TV/인물 정보를 제공하는 Vue 3 SPA 사이드 프로젝트입니다. Composition API + TypeScript로 작성되며 Git Flow, PR 규칙, Local Storage 활용을 모두 과제 조건에 맞춰 구현했습니다.

## 프로젝트 개요

| 항목 | 내용 |
| --- | --- |
| 프로젝트명 | WSDflix |
| 주요 기능 | 영화/TV/인물 검색, 인기·상영작·추천 리스트, 위시리스트 |
| 핵심 기술 | Vue 3, TypeScript, Vite, Vue Router, Pinia, Axios, TMDB API |

## 기술 스택

- **Framework**: Vue 3 (Composition API, `<script setup>`), Vite
- **Language**: TypeScript
- **State**: Pinia
- **Routing**: Vue Router
- **HTTP**: Axios + TMDB REST API
- **UI**: Font Awesome, Custom CSS
- **Infra**: GitHub Actions(CI), GitHub Pages(정적 배포)

## 설치 & 실행

```bash
npm install
npm run dev        # 로컬 개발 서버 (http://localhost:5173)
npm run build      # 프로덕션 번들
npm run preview    # 빌드 결과 로컬 확인
```

`.env.example`을 복사해 `.env` 파일을 만들고 `VITE_TMDB_API_KEY` 값을 반드시 채워야 합니다.

## 디렉터리 구조

```
src/
  assets/        # 정적 리소스
  components/    # 공통/페이지 단위 컴포넌트
  composables/   # Composition API 훅
  router/        # Vue Router 설정
  services/      # TMDB/인증 등 서비스 계층
  store/         # Pinia 스토어
  views/         # 페이지 컴포넌트
```

## TMDB API & Local Storage 활용

- **API 인증/헤더**: `src/services/tmdb.ts`에서 `.env` 혹은 Local Storage에 저장된 TMDB Key를 읽어 v4(`Authorization: Bearer`) 또는 v3(`api_key` 파라미터) 방식으로 자동 설정합니다.
- **API 캐싱**: `src/services/cache.ts`가 Local Storage + TTL(5분~24시간)을 이용해 인기/상영작/검색/장르/상세 응답을 캐싱하여 호출 수를 줄입니다.
- **이미지 URL 관리**: `src/services/URL.ts`가 TMDB REST 엔드포인트 및 이미지 사이즈(`thumbnail`, `card`, `poster`, `backdrop`) 빌더를 제공합니다.
- **계정 정보 저장**: `src/services/auth.ts`가 회원가입 시 `users`, `TMDb-Key`, `currentUser`, `keepLogin`, `rememberEmail`을 Local/Session Storage에 저장하고, 로그인 유지 여부를 관리합니다.
- **사용자 선호 데이터**:
  - `src/composables/useWishlist.ts`: 즐겨찾기 영화 목록을 JSON으로 보관.
  - `src/composables/useRecommendations.ts`: 추천 영화 리스트 및 로컬 저장.
  - `src/composables/useSearchHistory.ts`: 최근 검색어 기록을 중복 없이 저장.
  - `src/composables/useTheme.ts`, `useFontScale.ts`, `useMotionPreference.ts`: 테마/폰트/모션 설정을 Local Storage로 유지.
- **스토리지 네이밍/정리**: 모든 키는 의미있는 접두사(`tmdb-cache:*`, `users`, `TMDb-Key`, `wishlist`)를 사용하며, 캐시 만료 시 자동 삭제합니다.

## Git Flow 전략

- **main**: 실제 배포 브랜치. 태그(`v<major>.<minor>.<patch>`)가 붙은 결과만 머지.
- **develop**: 통합 개발 브랜치.
- **feature/***: 기능 개발 브랜치 (`develop`에서 파생 → 완료 시 PR → `develop` 머지).
- **release/*** (선택): QA/사전 검증.
- **hotfix/***: 배포 후 긴급 수정 브랜치 (`main`에서 파생 후 `main`+`develop` 반영).

### 태깅 규칙

- `main` HEAD에 `v1.2.0` 형태로 태그를 남깁니다.
- release 브랜치는 QA 완료 후 태그/릴리스 노트/위키 업데이트를 진행합니다.

## 커밋 & 브랜치 네이밍

- **커밋 메시지**: `type: summary` (예: `feat: add infinite scroll`), 허용 타입: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`.
- **커밋 본문**: 변경 이유/영향/테스트 범위를 서술.
- **브랜치 이름**:
  - 기능: `feature/<short-desc>`
  - 버그: `fix/<issue-id>`
  - 핫픽스: `hotfix/<issue>`

## PR 가이드

- 제목은 `[type] summary (#issue)` 형식.
- `.github/pull_request_template.md`에 변경 요약, 타입 체크, 테스트 결과, 문서 여부를 채웁니다.
- 최소 1인 이상 리뷰 + CI 통과 후 `squash & merge`.
- `main`/`develop` 직접 push 금지, 반드시 PR + CI.

## 이슈 & 작업 관리

- 라벨: `feat`, `bug`, `docs`, `chore` 사용.
- 이슈 템플릿: **배경 → 작업 목록(To-do) → 기대 결과 → 테스트 계획** 순서로 작성하고 Assignee/Project/Milestone을 지정.
- GitHub Projects(보드)에서 Todo → In Progress → Done 이동.
- 상세 문서는 `/docs` 또는 Wiki에 정리.

## 코드 스타일 & 품질

- ESLint/Prettier 규칙 준수, 컴포넌트 PascalCase, Composition API 우선.
- CSS는 Scoped/Utility 균형, 접근성 고려.
- 서비스/스토어 단위 테스트 결과는 PR에 명시.
- 비밀 값은 `.env`와 GitHub Secrets에만 저장.

## 저장소 보안 & 브랜치 보호

- `main`/`develop`에 브랜치 보호 규칙(승인 1명 + CI 통과) 적용.
- 충돌 발생 시 rebase/merge 전략을 PR 본문에 명확히 기록.
- 서명 커밋을 권장하며, 필요 시 `git config commit.gpgsign true`.
- GitHub Actions 실패 시 머지 불가, `.env` 등 비밀 키는 공개 금지.

## 참고 자료

- TMDB API: https://developer.themoviedb.org/reference/intro/getting-started
- WSDflix Wiki & Release note
- UX 레퍼런스: Recommendations 관련 이슈/문서
