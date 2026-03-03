# 본인인증 웹 ↔ Flutter 브릿지 사용 가이드

## 개요
Flutter WebView와 웹 사이의 본인인증 통신을 위한 브릿지입니다.

## 웹에서 본인인증 요청하기

### TypeScript/JavaScript 코드 예제

```typescript
/**
 * Flutter WebView 브릿지로 본인인증 URL 전달
 * 앱이 In-App Browser로 해당 URL을 띄움
 */
function openAuthWindow(authUrl: string): boolean {
  try {
    // Flutter InAppWebView 사용
    if (window.flutter_inappwebview?.callHandler) {
      console.log('[IDV Bridge] Flutter에 인증 URL 전달 (callHandler)', { authUrl });
      
      window.flutter_inappwebview.callHandler('openAuth', {
        type: 'OPEN_AUTH',
        url: authUrl,
      });
      
      return true;
    }

    // Fallback: postMessage 방식 (Flutter가 message 리스너를 등록한 경우)
    if (typeof window.postMessage === 'function') {
      console.log('[IDV Bridge] Flutter에 인증 URL 전달 (postMessage)', { authUrl });
      
      window.postMessage(
        JSON.stringify({
          type: 'OPEN_AUTH',
          url: authUrl,
        }),
        '*',
      );
      
      return true;
    }

    // WebView가 아닌 경우 (웹 브라우저 직접 접속)
    console.warn('[IDV Bridge] Flutter WebView 없음, Full-Page 이동');
    window.location.href = authUrl;
    return false;
  } catch (error) {
    console.error('[IDV Bridge] 브릿지 호출 실패, Full-Page로 fallback', { error });
    window.location.href = authUrl;
    return false;
  }
}

/**
 * 본인인증 성공 콜백
 * Flutter에서 본인인증이 완료되면 이 함수가 호출됩니다.
 */
window.onAuthSuccess = function(data: {
  success: boolean;
  data?: Record<string, string>; // URL query parameters
  url: string;
}) {
  console.log('[IDV Bridge] 본인인증 성공:', data);
  
  // 여기에 본인인증 성공 후 처리 로직 작성
  // 예: 서버에 인증 정보 전송, UI 업데이트 등
  
  // 예시: 서버로 인증 결과 전송
  fetch('/api/auth/verify', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      authData: data.data,
      verificationUrl: data.url,
    }),
  }).then(response => {
    if (response.ok) {
      alert('본인인증이 완료되었습니다.');
      // 다음 단계로 이동
    }
  });
};

/**
 * 본인인증 실패 콜백
 */
window.onAuthError = function(error: {
  success: boolean;
  error: string;
  message: string;
  url?: string;
}) {
  console.error('[IDV Bridge] 본인인증 실패:', error);
  
  // 에러 처리 로직
  alert(`본인인증 실패: ${error.message}`);
};

/**
 * 본인인증 취소 콜백
 */
window.onAuthCancel = function() {
  console.log('[IDV Bridge] 본인인증 취소');
  
  // 취소 처리 로직
  alert('본인인증이 취소되었습니다.');
};
```

### React 예제

```tsx
import { useEffect } from 'react';

export function IdentityVerification() {
  useEffect(() => {
    // 본인인증 콜백 함수 등록
    window.onAuthSuccess = (data) => {
      console.log('본인인증 성공:', data);
      // 성공 처리 로직
      handleAuthSuccess(data);
    };
    
    window.onAuthError = (error) => {
      console.error('본인인증 실패:', error);
      // 에러 처리 로직
      alert(`본인인증 실패: ${error.message}`);
    };
    
    window.onAuthCancel = () => {
      console.log('본인인증 취소');
      // 취소 처리 로직
    };
    
    return () => {
      // 클린업
      delete window.onAuthSuccess;
      delete window.onAuthError;
      delete window.onAuthCancel;
    };
  }, []);
  
  const handleStartAuth = () => {
    // 서버에서 본인인증 URL 받아오기
    fetch('/api/auth/start')
      .then(res => res.json())
      .then(data => {
        const authUrl = data.authUrl;
        
        // Flutter 브릿지로 본인인증 시작
        openAuthWindow(authUrl);
      });
  };
  
  return (
    <div>
      <button onClick={handleStartAuth}>
        본인인증 시작
      </button>
    </div>
  );
}

function openAuthWindow(authUrl: string): boolean {
  try {
    if (window.flutter_inappwebview?.callHandler) {
      window.flutter_inappwebview.callHandler('openAuth', {
        type: 'OPEN_AUTH',
        url: authUrl,
      });
      return true;
    }
    
    window.location.href = authUrl;
    return false;
  } catch (error) {
    console.error('브릿지 호출 실패:', error);
    window.location.href = authUrl;
    return false;
  }
}
```

## 타입 정의

```typescript
// global.d.ts 또는 types/window.d.ts
interface Window {
  // Flutter InAppWebView 인터페이스
  flutter_inappwebview?: {
    callHandler: (handlerName: string, data: any) => void;
  };
  
  // 본인인증 콜백 함수들
  onAuthSuccess?: (data: {
    success: boolean;
    data?: Record<string, string>;
    url: string;
  }) => void;
  
  onAuthError?: (error: {
    success: boolean;
    error: string;
    message: string;
    url?: string;
  }) => void;
  
  onAuthCancel?: () => void;
}
```

## Flutter → 웹 통신 흐름

1. **웹에서 본인인증 요청**
   ```javascript
   window.flutter_inappwebview.callHandler('openAuth', {
     type: 'OPEN_AUTH',
     url: 'https://auth-provider.com/verify?...'
   });
   ```

2. **Flutter가 In-App Browser 띄움**
   - `AuthWebViewPage` 위젯이 새 화면으로 표시됨
   - 본인인증 URL이 In-App Browser에서 로드됨

3. **본인인증 완료 감지**
   - URL 패턴으로 감지:
     - 성공: `/auth/success`, `/auth/complete`
     - 실패: `/auth/fail`, `/auth/error`
     - 취소: 사용자가 닫기 버튼 클릭

4. **결과를 웹으로 전달**
   ```javascript
   // 성공 시
   window.onAuthSuccess({
     success: true,
     data: { /* URL query params */ },
     url: 'https://...'
   });
   
   // 실패 시
   window.onAuthError({
     success: false,
     error: 'ERROR_CODE',
     message: 'Error message',
     url: 'https://...'
   });
   
   // 취소 시
   window.onAuthCancel();
   ```

## 커스터마이징

### 성공/실패 URL 패턴 변경

`main.dart`의 `AuthWebViewPage`에서 다음 부분을 수정:

```dart
onNavigationRequest: (NavigationRequest request) {
  // 여기서 URL 패턴을 변경할 수 있습니다
  if (request.url.contains('/your-custom-success-pattern')) {
    _handleAuthSuccess(request.url);
    return NavigationDecision.prevent;
  } else if (request.url.contains('/your-custom-fail-pattern')) {
    _handleAuthCancel(request.url);
    return NavigationDecision.prevent;
  }
  
  return NavigationDecision.navigate;
},
```

### JavaScript 메시지로 결과 전달

본인인증 제공자가 JavaScript로 결과를 전달하는 경우:

```javascript
// 본인인증 페이지에서 (제공자 측)
if (window.AuthResult) {
  window.AuthResult.postMessage(JSON.stringify({
    success: true,
    data: { /* 인증 결과 */ }
  }));
}
```

Flutter가 이를 자동으로 수신하고 웹으로 전달합니다.

## 디버깅

### Flutter 로그 확인
```bash
# Android
adb logcat | grep "IDV Bridge"

# iOS
# Xcode Console에서 "[IDV Bridge]" 필터
```

### 웹 콘솔 로그
```javascript
// 브릿지가 제대로 초기화되었는지 확인
console.log('flutter_inappwebview:', window.flutter_inappwebview);
console.log('onAuthSuccess:', window.onAuthSuccess);
```

## 주의사항

1. **URL 패턴 확인**: 본인인증 제공자의 성공/실패 리다이렉트 URL 패턴을 확인하세요.
2. **HTTPS 사용**: 본인인증 URL은 반드시 HTTPS를 사용해야 합니다.
3. **타임아웃**: 본인인증은 시간 제한이 있을 수 있으니 적절히 처리하세요.
4. **에러 처리**: 네트워크 오류, 취소 등 다양한 케이스를 고려하세요.
