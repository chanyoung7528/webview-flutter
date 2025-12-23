# 삼성아파트 웹뷰 앱

로컬 3000번 포트의 웹사이트를 웹뷰로 표시하는 Flutter 앱입니다.

## 🚀 빠른 실행

### 방법 1: 실행 스크립트 사용 (권장)

```bash
# 실행 권한 부여 (최초 1회)
chmod +x run.sh run_android.sh run_ios.sh

# 통합 실행 스크립트 (플랫폼 선택)
./run.sh

# 또는 직접 실행
./run_android.sh  # Android 에뮬레이터만
./run_ios.sh      # iOS 시뮬레이터만
```

### 방법 2: 직접 명령어 실행

#### Android 에뮬레이터
```bash
# 1. 에뮬레이터 실행 (별도 터미널)
emulator -avd <에뮬레이터_이름>

# 2. Flutter 앱 실행
flutter run
```

#### iOS 시뮬레이터
```bash
# 1. 시뮬레이터 실행 (별도 터미널)
open -a Simulator

# 2. Flutter 앱 실행
flutter run -d ios
```

## 📋 사전 요구사항

1. **로컬 서버 실행** (포트 3000)
   ```bash
   # 예: Next.js 앱
   npm run dev
   # 또는 다른 서버를 포트 3000에서 실행
   ```

2. **에뮬레이터/시뮬레이터 준비**
   - Android: Android Studio에서 AVD 생성
   - iOS: Xcode에서 시뮬레이터 설정

## 🔧 설정 정보

- **Android 에뮬레이터**: `http://10.0.2.2:3000` (호스트 머신의 localhost)
- **iOS 시뮬레이터**: `http://localhost:3000`
- **실제 기기**: 컴퓨터의 로컬 IP 주소 사용 (예: `http://192.168.0.xxx:3000`)

## 📝 주요 기능

- ✅ 플랫폼별 자동 URL 감지
- ✅ JavaScript 활성화
- ✅ 로딩 인디케이터
- ✅ 에러 핸들링

## 🛠️ 개발 환경

- Flutter SDK
- Android Studio (Android 개발용)
- Xcode (iOS 개발용)
