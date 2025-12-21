# YEEMIN Mobile & Web 가이드

Flutter 모바일 앱과 Vue 3 + Vite 웹 클라이언트가 함께 들어있는 모노레포입니다. TMDB 데이터를 활용해 인기/최신 영화, 자동 재생 트레일러, 검색·필터·정렬, 위시리스트, 상세 정보 등을 제공하며 Firebase 인증/Firestore로 사용자 상태를 관리합니다.

## 주요 기능 (모바일)
- **홈 히어로 배너**: 트레일러 포스터/배경을 크게 표시, 10초마다 부드럽게 자동 전환, YouTube 열기/다음 트레일러 이동 버튼 제공.
- **카탈로그**: 인기/현재상영 작품 리스트, 무한 스크롤(Load more), 다크 테마(배경/네비게이션 바 검정).
- **검색**: 검색어 없이도 필터·정렬만으로 결과 조회 가능. 장르, 연도, 최소 평점 필터 + 인기/평점/최신 정렬.
- **위시리스트**: Firebase Firestore에 저장/동기화, 하트 토글로 추가·제거.
- **상세 보기**: 러닝타임, 개봉년도, 감독/출연, 평점, 유사 작품, TMDB 원문 링크, 포스터/백드롭 이미지 표시.
- **브랜딩**: YEEMIN 로고/로고텍스트 적용.

## 주요 기능 (웹)
- **히어로 배너**: 자동 재생/배경 영상 블록, 외부 YouTube 이동.
- **검색**: 자동완성, 최근 검색어, 장르/연도/평점 필터 및 정렬.
- **위시리스트/추천**: 로컬 스토리지 기반, 로그인 없이 저장 및 추천 토글.
- **상세 페이지**: 포스터, 정보, 런닝타임/평점/개봉일, 장르, 공식 사이트 링크.
- **브랜딩**: YEEMIN 로고/폰트 적용, 다크 UI.

## 요구사항
- Flutter SDK ≥ 3.3, Dart SDK 포함
- Android Studio or Android SDK/AVD (Android 13+ 권장)
- iOS 빌드 시 Xcode 15+ (macOS)
- Node.js 18+ (웹 클라이언트 개발 시)

## 설치 및 설정
1) 의존성 설치
- Flutter: `flutter doctor`로 환경 확인 후 `flutter pub get`
- 웹(선택): `cd web && npm install`

2) 환경 변수
### 모바일(`mobile/.env`)
```
TMDB_API_KEY=<TMDB_v3_API_KEY>
FIREBASE_API_KEY=<firebase api key>
FIREBASE_AUTH_DOMAIN=<your-app>.firebaseapp.com
FIREBASE_PROJECT_ID=<project id>
FIREBASE_STORAGE_BUCKET=<bucket>.appspot.com
FIREBASE_MESSAGING_SENDER_ID=<sender id>
FIREBASE_APP_ID=<app id>
```
- 실제 키를 채워 넣고, `pubspec.yaml`의 `assets`에 `.env`가 포함되어 있으므로 변경 없이 번들링됩니다.

### 웹(`web/.env` 또는 `web/.env.local`)
```
VITE_TMDB_API_KEY=<TMDB_v3_API_KEY>
VITE_FIREBASE_API_KEY=<firebase api key>
VITE_FIREBASE_AUTH_DOMAIN=<your-app>.firebaseapp.com
VITE_FIREBASE_PROJECT_ID=<project id>
VITE_FIREBASE_STORAGE_BUCKET=<bucket>.appspot.com
VITE_FIREBASE_MESSAGING_SENDER_ID=<sender id>
VITE_FIREBASE_APP_ID=<app id>
```
- `.env.example`을 복사해 사용하세요. TMDB 키는 필수, Firebase 키는 인증/저장 기능을 사용할 때 필요합니다.

3) Firebase 설정
- Android: `mobile/android/app/google-services.json` 위치에 Firebase 콘솔에서 받은 파일을 둡니다.
- iOS: `mobile/ios/Runner/GoogleService-Info.plist` 추가 후 Xcode에서 Runner 타겟에 포함.
- 인증: Firebase Authentication에서 Google Sign-In 활성화, OAuth 클라이언트 SHA-1/256 키를 콘솔에 등록.

## 실행 방법
### Android 에뮬레이터/디바이스
```
cd mobile
flutter pub get
flutter run -d <device_id>   # 예: emulator-5554
```
- 디바이스 목록: `flutter devices`
- 핫리로드: 실행 중 `r` (터미널) 또는 IDE 기능 사용.

### iOS 시뮬레이터/디바이스 (macOS)
```
cd mobile
flutter pub get
flutter run -d <ios-device-id>
```
사전에 `pod install` 실행 필요할 수 있음 (`cd ios && pod install`).

### 웹 클라이언트(참고용)
```
cd web
npm install
npm run dev   # http://localhost:5173
```

## 빌드
- Android APK: `flutter build apk --release`
- Android App Bundle: `flutter build appbundle --release`
- iOS: `flutter build ipa --release` (Xcode 계정/프로비저닝 필요)
- 웹: `cd web && npm run build`

## 트러블슈팅
- **디바이스 없음**: AVD 실행 후 `flutter devices`로 확인, 필요 시 ANDROID_HOME/SDK 경로 설정.
- **Firebase DEVELOPER_ERROR**: OAuth 클라이언트 SHA-1/256 등록 여부 확인, 앱 번들 ID/패키지명이 Firebase 설정과 일치하는지 확인.
- **TMDB 요청 실패**: `.env`의 `TMDB_API_KEY` 확인, v3 Key 사용 또는 v4 Token이면 Authorization 헤더 형식에 맞게 추가.
- **레이아웃 오버플로**: 상세 보기 버튼 영역은 `Wrap`으로 구성되어 있음. 새 버튼 추가 시 `spacing/runSpacing`을 조정.

## 테스트 범위
- 현재 로컬 환경에서는 **Android 에뮬레이터**로만 동작 확인했습니다. macOS/iOS 시뮬레이터는 장비 부재로 미검증입니다.

## 폴더 구조(요약)
```
mobile/
  lib/main.dart          # 앱 엔트리/화면/상태 관리
  assets/logo-yeemin.png # 로고
  .env                   # TMDB/Firebase 키 (번들 포함)
  android/ ios/          # 플랫폼별 구성
web/                     # Vue 3 + Vite 웹 클라이언트
  src/                   # 뷰/서비스/스타일
  .env(.local)           # Vite 환경 변수
```

## 라이선스/크레딧
- 영화 데이터: TMDB API
- 인증/스토리지: Firebase
- UI/로고: YEEMIN 브랜딩
