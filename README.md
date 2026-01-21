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
- ✅ 카카오 간편 로그인 (카카오톡/카카오계정)
- ✅ 웹뷰와 네이티브 앱 간 JavaScript 브리지 통신

## 🛠️ 개발 환경

- Flutter SDK
- Android Studio (Android 개발용)
- Xcode (iOS 개발용)

---

## 🔐 카카오 로그인 기능

이 앱은 카카오 간편 로그인 기능을 지원합니다. 웹뷰 내에서도 카카오 로그인을 사용할 수 있으며, 네이티브 앱과 웹 간의 JavaScript 브리지를 통해 통신합니다.

### 주요 기능

1. **카카오톡 간편 로그인**

   - 카카오톡 앱이 설치되어 있으면 카카오톡으로 로그인
   - 설치되어 있지 않으면 카카오계정 웹 로그인

2. **로그인 상태 관리**

   - 앱 상단에 로그인 상태 표시
   - 로그인/로그아웃 버튼 제공

3. **웹뷰 연동**
   - 웹 페이지에서 JavaScript로 카카오 로그인 요청 가능
   - 로그인 성공 후 사용자 정보를 웹으로 전달

### 카카오 로그인 사용 방법

#### 1. 앱 내에서 직접 로그인

앱 상단의 **"카카오 로그인"** 버튼을 클릭하면 카카오 로그인 화면이 표시됩니다.

- **에뮬레이터/시뮬레이터**: 카카오계정 웹 로그인 화면이 표시됩니다
- **실제 기기 (카카오톡 설치됨)**: 카카오톡 앱이 열려 로그인을 진행합니다
- **실제 기기 (카카오톡 미설치)**: 카카오계정 웹 로그인 화면이 표시됩니다

#### 2. 웹 페이지에서 JavaScript로 로그인 요청

웹 페이지에서 다음과 같이 카카오 로그인을 요청할 수 있습니다:

```javascript
// 웹 페이지에서 카카오 로그인 요청
window.requestKakaoLogin();

// 로그인 성공 콜백 함수 정의
window.onKakaoLoginSuccess = function (data) {
  console.log("로그인 성공:", data);
  // data 구조:
  // {
  //   id: "사용자 ID",
  //   nickname: "닉네임",
  //   email: "이메일",
  //   profileImage: "프로필 이미지 URL",
  //   cid: "사용자 ID"
  // }

  // 서버로 사용자 정보 전송 예시
  fetch("/api/auth/kakao", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(data),
  });
};

// 로그인 실패 콜백 함수 정의
window.onKakaoLoginError = function (error) {
  console.error("로그인 실패:", error);
  alert("카카오 로그인에 실패했습니다.");
};
```

### 카카오 로그인 플로우 상세 설명

React 앱이 Flutter WebView에서 실행될 때 카카오 로그인이 진행되는 전체 플로우를 단계별로 설명합니다.

#### 전체 플로우 다이어그램

```
1. Flutter: WebView 생성
   ↓
2. Flutter: window.requestKakaoLogin 주입
   ↓
3. Flutter: React 앱 로드
   ↓
4. React: window.onKakaoLoginSuccess/Error 등록
   ↓
5. 사용자: 웹에서 로그인 버튼 클릭
   ↓
6. React → Flutter: window.requestKakaoLogin() 호출
   ↓
7. Flutter → Kakao SDK: 로그인 요청
   ↓
8. Kakao SDK → Flutter: 로그인 결과 반환
   ↓
9. Flutter → React: window.onKakaoLoginSuccess/Error() 호출
   ↓
10. React: 훅에서 처리
```

#### 단계별 코드 설명

##### 1단계: 웹 페이지에서 로그인 요청

**웹 페이지 코드:**

```javascript
// 사용자가 버튼을 클릭하거나 로그인이 필요할 때 호출
function handleKakaoLoginClick() {
  // 앱에 주입된 함수를 호출하여 로그인 요청
  window.requestKakaoLogin();
}
```

**앱에서 주입된 JavaScript 함수 (`lib/main.dart`):**

```dart
// JavaScript 브리지 함수 주입
Future<void> _injectJavaScriptBridge() async {
  const bridgeScript = '''
    (function() {
      // 웹에서 카카오 로그인을 요청하는 함수
      window.requestKakaoLogin = function() {
        // FlutterKakaoBridge 채널로 메시지 전송
        FlutterKakaoBridge.postMessage(JSON.stringify({
          action: 'kakaoLogin'
        }));
      };
    })();
  ''';

  await controller.runJavaScript(bridgeScript);
}
```

##### 2단계: 앱에서 웹 메시지 수신 및 처리

**앱 코드 (`lib/main.dart`):**

```dart
// WebViewController에 JavaScript 채널 등록
controller.addJavaScriptChannel(
  'FlutterKakaoBridge',
  onMessageReceived: (JavaScriptMessage message) {
    _handleWebMessage(message.message);
  },
);

// 웹에서 보낸 메시지 처리
Future<void> _handleWebMessage(String message) async {
  try {
    final data = jsonDecode(message) as Map<String, dynamic>;
    final action = data['action'] as String?;

    debugPrint('웹에서 메시지 수신: $action');

    if (action == 'kakaoLogin') {
      // 카카오 로그인 처리 함수 호출
      await _handleKakaoLoginFromWeb();
    }
  } catch (e) {
    debugPrint('웹 메시지 처리 실패: $e');
    _sendMessageToWeb('onKakaoLoginError', {'error': e.toString()});
  }
}
```

##### 3단계: 앱에서 카카오 SDK로 로그인 요청

**앱 코드 (`lib/main.dart`):**

```dart
// 웹에서 요청한 카카오 로그인 처리
Future<void> _handleKakaoLoginFromWeb() async {
  try {
    debugPrint('웹에서 카카오 로그인 요청 받음');

    // KakaoAuthService를 통해 카카오 로그인 실행
    final user = await KakaoAuthService.login();

    // 로그인 성공 처리...
  } catch (e) {
    // 에러 처리...
  }
}
```

**카카오 로그인 서비스 코드 (`lib/services/kakao_auth_service.dart`):**

```dart
static Future<User?> login() async {
  try {
    // 1. 카카오톡 설치 여부 확인
    bool installed = await isKakaoTalkInstalled();

    // 2. 카카오톡이 설치되어 있으면 카카오톡으로 로그인
    //    없으면 카카오계정 웹 로그인
    OAuthToken token = installed
        ? await UserApi.instance.loginWithKakaoTalk()
        : await UserApi.instance.loginWithKakaoAccount();

    // 3. 로그인 성공 후 유저 정보 가져오기
    User user = await UserApi.instance.me();

    return user;
  } catch (e) {
    print('카카오 로그인 실패: $e');
    rethrow;
  }
}
```

##### 4단계: 카카오 서버에서 사용자 데이터 받기

카카오 SDK가 자동으로 처리합니다:

- **카카오톡 로그인**: 카카오톡 앱이 열리고 사용자가 동의하면 토큰 발급
- **카카오계정 로그인**: 웹뷰가 열리고 사용자가 로그인하면 토큰 발급
- **사용자 정보 조회**: 발급받은 토큰으로 `UserApi.instance.me()` 호출하여 사용자 정보 획득

**받아오는 데이터 구조:**

```dart
User {
  id: 123456789,                    // 카카오 사용자 ID
  kakaoAccount: {
    profile: {
      nickname: "홍길동",
      profileImageUrl: "https://...",
    },
    email: "user@example.com",
  }
}
```

##### 5단계: 앱에서 웹으로 사용자 데이터 전송

**앱 코드 (`lib/main.dart`):**

```dart
// 카카오 로그인 성공 후 웹으로 데이터 전송
if (mounted) {
  setState(() {
    isLoggedIn = true;
    currentUser = user;
  });

  // 로그인 성공 정보를 웹으로 전달
  final userData = {
    'id': user?.id.toString(),
    'nickname': user?.kakaoAccount?.profile?.nickname,
    'email': user?.kakaoAccount?.email,
    'profileImage': user?.kakaoAccount?.profile?.profileImageUrl,
    'cid': user?.id.toString(), // CID는 사용자 ID로 사용
  };

  // 웹의 onKakaoLoginSuccess 콜백 함수 호출
  _sendMessageToWeb('onKakaoLoginSuccess', userData);

  debugPrint('카카오 로그인 성공, 웹으로 데이터 전송: $userData');
}
```

**웹으로 메시지 전송 함수:**

```dart
// 웹으로 메시지 전송
Future<void> _sendMessageToWeb(String callbackName, Map<String, dynamic> data) async {
  try {
    final jsonData = jsonEncode(data);
    final script = '''
      if (typeof $callbackName === 'function') {
        $callbackName($jsonData);
      } else {
        console.warn('콜백 함수 $callbackName이 정의되지 않았습니다.');
      }
    ''';

    await controller.runJavaScript(script);
    debugPrint('웹으로 메시지 전송 완료: $callbackName');
  } catch (e) {
    debugPrint('웹으로 메시지 전송 실패: $e');
  }
}
```

##### 6단계: 웹 페이지에서 사용자 데이터 수신

**웹 페이지 코드:**

```javascript
// 앱에서 호출하는 콜백 함수 정의
window.onKakaoLoginSuccess = function (data) {
  console.log("로그인 성공:", data);

  // 받은 데이터 구조:
  // {
  //   id: "123456789",
  //   nickname: "홍길동",
  //   email: "user@example.com",
  //   profileImage: "https://...",
  //   cid: "123456789"
  // }

  // 사용자 정보를 화면에 표시
  document.getElementById("user-name").textContent = data.nickname;
  document.getElementById("user-email").textContent = data.email;

  // 서버로 사용자 정보 전송
  fetch("/api/auth/kakao", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      kakaoId: data.id,
      nickname: data.nickname,
      email: data.email,
      profileImage: data.profileImage,
      cid: data.cid,
    }),
  })
    .then((response) => response.json())
    .then((result) => {
      console.log("서버 저장 완료:", result);
      // 로그인 완료 후 페이지 이동 등 처리
      window.location.href = "/home";
    })
    .catch((error) => {
      console.error("서버 저장 실패:", error);
    });
};

// 에러 처리 콜백 함수
window.onKakaoLoginError = function (error) {
  console.error("로그인 실패:", error);
  alert("카카오 로그인에 실패했습니다: " + error.message);
};
```

#### 전체 플로우 요약

1. **웹 페이지 요청** → `window.requestKakaoLogin()` 호출
2. **앱 송신** → `FlutterKakaoBridge.postMessage()`로 앱에 메시지 전송
3. **앱에서 카카오 요청** → `KakaoAuthService.login()` 호출하여 카카오 SDK로 로그인
4. **카카오 데이터 앱에서 받음** → `UserApi.instance.me()`로 사용자 정보 획득
5. **앱에서 웹으로 보냄** → `_sendMessageToWeb('onKakaoLoginSuccess', userData)` 호출
6. **웹 받음** → `window.onKakaoLoginSuccess(data)` 콜백 함수 실행

#### 에러 처리 플로우

에러가 발생하면 다음과 같이 처리됩니다:

```dart
// 앱에서 에러 발생 시
catch (e) {
  debugPrint('카카오 로그인 실패: $e');
  _sendMessageToWeb('onKakaoLoginError', {
    'error': e.toString(),
    'message': '카카오 로그인에 실패했습니다.',
  });
}
```

```javascript
// 웹에서 에러 수신
window.onKakaoLoginError = function (error) {
  console.error("로그인 실패:", error);
  // error 구조: { error: "에러 메시지", message: "사용자 친화적 메시지" }
  alert(error.message || "카카오 로그인에 실패했습니다.");
};
```

### 카카오 로그인 서비스 구조

#### 파일 구조

```
lib/
├── main.dart                    # 메인 앱 및 WebView 페이지
└── services/
    └── kakao_auth_service.dart  # 카카오 로그인 서비스
```

#### 주요 클래스 및 메서드

**`KakaoAuthService`** (`lib/services/kakao_auth_service.dart`)

- `login()`: 카카오 로그인 실행

  - 카카오톡 설치 여부 확인
  - 카카오톡 또는 카카오계정으로 로그인
  - 사용자 정보 반환

- `logout()`: 카카오 로그아웃

- `isLoggedIn()`: 현재 로그인 상태 확인

- `getCurrentUser()`: 현재 로그인된 사용자 정보 가져오기

**`_WebViewPageState`** (`lib/main.dart`)

- `_handleKakaoLogin()`: 카카오 로그인 처리
- `_handleKakaoLogout()`: 카카오 로그아웃 처리
- `_handleWebMessage()`: 웹에서 보낸 메시지 처리
- `_sendMessageToWeb()`: 웹으로 메시지 전송
- `_injectJavaScriptBridge()`: JavaScript 브리지 함수 주입

### JavaScript 브리지 API

앱은 웹뷰에 다음 JavaScript 함수들을 주입합니다:

#### `window.requestKakaoLogin()`

카카오 로그인을 요청합니다.

```javascript
window.requestKakaoLogin();
```

#### `window.onKakaoLoginSuccess(data)`

로그인 성공 시 호출되는 콜백 함수입니다. 웹 페이지에서 이 함수를 정의하여 사용합니다.

```javascript
window.onKakaoLoginSuccess = function (data) {
  // data: { id, nickname, email, profileImage, cid }
};
```

#### `window.onKakaoLoginError(error)`

로그인 실패 시 호출되는 콜백 함수입니다.

```javascript
window.onKakaoLoginError = function (error) {
  // error: { error, message }
};
```

### 에뮬레이터/시뮬레이터에서 테스트하기

1. **앱 실행**

   ```bash
   flutter run
   ```

2. **카카오 로그인 버튼 클릭**

   - 앱 상단의 "카카오 로그인" 버튼을 클릭합니다

3. **카카오계정으로 로그인**

   - 에뮬레이터/시뮬레이터에는 카카오톡이 설치되어 있지 않으므로
   - 카카오계정 웹 로그인 화면이 표시됩니다
   - 카카오 계정 이메일/비밀번호로 로그인합니다

4. **로그인 확인**
   - 로그인 성공 시 상단에 닉네임이 표시됩니다
   - "카카오 로그인" 버튼이 "로그아웃" 버튼으로 변경됩니다

### 실제 기기에서 테스트하기

실제 Android/iOS 기기에서는 카카오톡이 설치되어 있으면 카카오톡 앱이 열려 로그인을 진행합니다.

### 카카오 개발자 설정

카카오 로그인을 사용하려면 [카카오 개발자 콘솔](https://developers.kakao.com/)에서 다음 설정이 필요합니다:

1. **앱 등록 및 키 발급**

   - Native App Key 발급
   - 현재 사용 중인 키: `2de5d11bdb7c339c7850fea252db68ec`

2. **플랫폼 설정**

   - **Android**: 패키지명과 키 해시 등록
   - **iOS**: Bundle ID와 URL Scheme 등록

3. **Redirect URI 설정**
   - Android: `kakao2de5d11bdb7c339c7850fea252db68ec://oauth`
   - iOS: `kakao2de5d11bdb7c339c7850fea252db68ec://oauth`

### 주의사항

- 에뮬레이터/시뮬레이터에서는 카카오톡이 설치되어 있지 않으므로 항상 웹 로그인으로 진행됩니다
- 실제 기기에서 테스트할 때는 카카오 개발자 콘솔에 기기의 패키지명/번들 ID가 등록되어 있어야 합니다
- 카카오 로그인은 인터넷 연결이 필요합니다

### 참고 자료

- [카카오 Flutter SDK 공식 문서](https://developers.kakao.com/docs/latest/ko/kakaologin/flutter)
- [카카오 개발자 콘솔](https://developers.kakao.com/)
