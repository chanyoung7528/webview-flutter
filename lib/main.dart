import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'services/kakao_auth_service.dart';
import 'services/naver_auth_service.dart';

void main() {
  const meSdk = '482c0c7428f3f38d6812fab4f87eb571';
  const teamSdk = '660a067b3484e8f4455886e633f79436';
  WidgetsFlutterBinding.ensureInitialized();
  KakaoSdk.init(nativeAppKey: teamSdk);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '웰피',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const WebViewPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class WebViewPage extends StatefulWidget {
  const WebViewPage({super.key});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> with WidgetsBindingObserver {
  late final WebViewController controller;
  bool isLoading = true;
  String? errorMessage;
  User? currentUser;
  bool isLoggedIn = false;

  String _getLocalhostUrl() {
    // ⚠️ 실제 기기에서 테스트할 때는 PC의 IP 주소로 변경하세요
    // 예: 'http://192.168.1.100:3000' 또는 'http://10.0.0.5:3000'
    // 
    // PC IP 확인 방법:
    // macOS: 터미널에서 `ifconfig | grep "inet " | grep -v 127.0.0.1`
    // Windows: 명령 프롬프트에서 `ipconfig`
    
    const bool isRealDevice = true; // 실제 기기면 true, 에뮬레이터면 false
    const String pcIpAddress = '192.168.1.100'; // ⚠️ 여기에 PC의 실제 IP 입력!
    
    if (Platform.isAndroid) {
      if (isRealDevice) {
        // 실제 기기: PC의 실제 IP 주소 사용
        // return 'https://poc-template-gamma.vercel.app/';
        return 'https://app-dev.wellfy.co.kr';
      } else {
        // 에뮬레이터: 10.0.2.2 사용
        return 'http://10.0.2.2:3000';
      }
    } else if (Platform.isIOS) {
      return 'http://localhost:3000';
    }
    return 'http://localhost:3000';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // 상태바를 투명하게 설정 (풀스크린)
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
      ),
    );

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..addJavaScriptChannel(
        'FlutterAuthBridge',
        onMessageReceived: (JavaScriptMessage message) {
          _handleWebMessage(message.message);
        },
      )
      ..addJavaScriptChannel(
        'NativeApp',
        onMessageReceived: (JavaScriptMessage message) {
          _handleNativeAppMessage(message.message);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            debugPrint('🌐 페이지 로드 시작: $url');
            if (mounted) {
              setState(() {
                isLoading = true;
                errorMessage = null; // 에러 메시지 초기화
              });
            }
          },
          onPageFinished: (String url) {
            debugPrint('✅ 페이지 로드 완료: $url');
            if (mounted) {
              setState(() {
                isLoading = false;
              });
              // 페이지 로드 완료 후 JavaScript 브리지 + safe-area 주입
              _injectJavaScriptBridge();
              _injectSafeAreaInsets();
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('❌ WebView 에러 발생!');
            debugPrint('  - Description: ${error.description}');
            debugPrint('  - Error Code: ${error.errorCode}');
            debugPrint('  - Error Type: ${error.errorType}');
            debugPrint('  - Failed URL: ${error.url}');
            debugPrint('  - Error Code 상세:');
            debugPrint('    6 = ERR_CONNECTION_REFUSED (서버 연결 거부)');
            debugPrint('    2 = ERR_INTERNET_DISCONNECTED (인터넷 연결 없음)');
            debugPrint('    3 = ERR_NAME_NOT_RESOLVED (DNS 해석 실패)');
            
            // 에러 발생 시 로딩 상태 해제 및 에러 메시지 표시
            if (mounted) {
              setState(() {
                isLoading = false;
                errorMessage = '연결 오류: ${error.description}\n'
                    'URL: ${error.url}\n'
                    '에러 코드: ${error.errorCode}\n'
                    '에러 타입: ${error.errorType}';
              });
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            debugPrint('🔗 네비게이션 요청: ${request.url}');
            return NavigationDecision.navigate;
          },
        ),
      );
    
    // Android WebView 특정 설정: Mixed Content 허용
    if (Platform.isAndroid) {
      final androidController = controller.platform as AndroidWebViewController;
      androidController.setMediaPlaybackRequiresUserGesture(false);
    }
    
    // 초기 로그인 상태 확인
    _checkLoginStatus();
    
    // URL 로드
    try {
      final url = _getLocalhostUrl();
      debugPrint('Loading URL: $url');
      controller.loadRequest(Uri.parse(url));
    } catch (e) {
      debugPrint('Error loading URL: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // 키보드 올라오거나 내려갈 때 safe-area 값 재주입
  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    if (!isLoading) {
      _injectSafeAreaInsets();
    }
  }

  // 로그인 상태 확인
  Future<void> _checkLoginStatus() async {
    try {
      final loggedIn = await KakaoAuthService.isLoggedIn();
      if (loggedIn) {
        final user = await KakaoAuthService.getCurrentUser();
        if (mounted) {
          setState(() {
            isLoggedIn = true;
            currentUser = user;
          });
        }
      }
    } catch (e) {
      debugPrint('로그인 상태 확인 실패: $e');
    }
  }

  // 카카오 로그인 실행
  Future<void> _handleKakaoLogin() async {
    try {
      final result = await KakaoAuthService.login();
      if (result != null && mounted) {
        final user = result['user'] as User?;
        final accessToken = result['accessToken'] as String?;
        
        setState(() {
          isLoggedIn = true;
          currentUser = user;  // User 객체를 저장
        });
        
        debugPrint('🔑 카카오 로그인 Access Token (전체): $accessToken');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('로그인 성공! ${user?.kakaoAccount?.profile?.nickname ?? "사용자"}님 환영합니다.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('카카오 로그인 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('로그인 실패: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 카카오 로그아웃 실행
  Future<void> _handleKakaoLogout() async {
    try {
      await KakaoAuthService.logout();
      if (mounted) {
        setState(() {
          isLoggedIn = false;
          currentUser = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('로그아웃되었습니다.'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      debugPrint('카카오 로그아웃 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('로그아웃 실패: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 네이티브 앱 메시지 처리
  Future<void> _handleNativeAppMessage(String message) async {
    try {
      final data = jsonDecode(message) as Map<String, dynamic>;
      final type = data['type'] as String?;
      
      debugPrint('📱 네이티브 앱 메시지 수신: $type');
      
      if (type == 'onPopupClose') {
        debugPrint('🔴 팝업 닫기 요청');
        // 알럿 표시 후 확인 시 닫기
        if (mounted) {
          final shouldClose = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('알림'),
              content: const Text('정말 닫으시겠습니까?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('취소'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('확인'),
                ),
              ],
            ),
          );
          
          // 확인 버튼을 누르면 닫기
          if (shouldClose == true && mounted) {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              // 더 이상 뒤로 갈 페이지가 없으면 앱 종료
              SystemNavigator.pop();
            }
          }
        }
      } else if (type == 'onPopupOpen') {
        debugPrint('🟢 팝업 열기 요청');
        // 팝업 열기 처리 (필요시 구현)
      } else {
        debugPrint('알 수 없는 네이티브 앱 메시지 타입: $type');
      }
    } catch (e) {
      debugPrint('네이티브 앱 메시지 처리 실패: $e');
    }
  }

  // JavaScript 브리지 함수 주입 (웹에서 사용할 수 있도록)
  Future<void> _injectJavaScriptBridge() async {
    const bridgeScript = '''
      (function() {
        // NativeApp 인터페이스 설정
        window.NativeApp = {
          onPopupClose: function() {
            NativeApp.postMessage(JSON.stringify({
              type: 'onPopupClose'
            }));
          },
          onPopupOpen: function() {
            NativeApp.postMessage(JSON.stringify({
              type: 'onPopupOpen'
            }));
          }
        };
        
        // iOS WebKit 메시지 핸들러 호환성 (Flutter WebView는 자동 처리)
        if (!window.webkit) {
          window.webkit = {};
        }
        if (!window.webkit.messageHandlers) {
          window.webkit.messageHandlers = {};
        }
        if (!window.webkit.messageHandlers.NativeApp) {
          window.webkit.messageHandlers.NativeApp = {
            postMessage: function(message) {
              NativeApp.postMessage(JSON.stringify(message));
            }
          };
        }
        
        // 웹에서 카카오 로그인을 요청하는 함수
        window.requestKakaoLogin = function() {
          FlutterAuthBridge.postMessage(JSON.stringify({
            action: 'kakaoLogin'
          }));
        };
        
        // 웹에서 네이버 로그인을 요청하는 함수
        window.requestNaverLogin = function() {
          FlutterAuthBridge.postMessage(JSON.stringify({
            action: 'naverLogin'
          }));
        };
        
        // 앱에서 카카오 로그인 결과를 받는 콜백 함수 (웹에서 정의)
        window.onKakaoLoginSuccess = function(data) {
          console.log('카카오 로그인 성공:', data);
          // 웹에서 이 함수를 오버라이드하여 사용
        };
        
        window.onKakaoLoginError = function(error) {
          console.error('카카오 로그인 실패:', error);
          // 웹에서 이 함수를 오버라이드하여 사용
        };
        
        // 앱에서 네이버 로그인 결과를 받는 콜백 함수 (웹에서 정의)
        window.onNaverLoginSuccess = function(data) {
          console.log('네이버 로그인 성공:', data);
          // 웹에서 이 함수를 오버라이드하여 사용
        };
        
        window.onNaverLoginError = function(error) {
          console.error('네이버 로그인 실패:', error);
          // 웹에서 이 함수를 오버라이드하여 사용
        };
        
        // ===== 본인인증 브릿지 =====
        
        // flutter_inappwebview 호환 인터페이스 설정
        window.flutter_inappwebview = {
          callHandler: function(handlerName, data) {
            console.log('[IDV Bridge] callHandler 호출:', handlerName, data);
            FlutterAuthBridge.postMessage(JSON.stringify({
              action: handlerName,
              data: data
            }));
          }
        };
        
        // 테스트용: URL 없이 호출하면 앱이 example.com으로 In-App Browser 띄움
        window.openTestAuthWindow = function() {
          console.log('[IDV Bridge] 테스트 In-App Browser 열기 (example.com)');
          FlutterAuthBridge.postMessage(JSON.stringify({
            action: 'openAuth',
            data: { type: 'OPEN_AUTH' }
          }));
        };
        
        // 본인인증 콜백 함수들 (웹에서 정의/오버라이드 가능)
        window.onAuthSuccess = function(data) {
          console.log('[IDV Bridge] 본인인증 성공:', data);
          // 웹에서 이 함수를 오버라이드하여 사용
        };
        
        window.onAuthError = function(error) {
          console.error('[IDV Bridge] 본인인증 실패:', error);
          // 웹에서 이 함수를 오버라이드하여 사용
        };
        
        window.onAuthCancel = function() {
          console.log('[IDV Bridge] 본인인증 취소');
          // 웹에서 이 함수를 오버라이드하여 사용
        };
        
        console.log('✅ NativeApp 및 본인인증 브릿지 초기화 완료');
      })();
    ''';
    
    try {
      await controller.runJavaScript(bridgeScript);
      debugPrint('JavaScript 브리지 함수 주입 완료 (카카오/네이버 로그인 + NativeApp + 본인인증)');
    } catch (e) {
      debugPrint('JavaScript 브리지 주입 실패: $e');
    }
  }

  // 웹에서 보낸 메시지 처리
  Future<void> _handleWebMessage(String message) async {
    try {
      final data = jsonDecode(message) as Map<String, dynamic>;
      final action = data['action'] as String?;
      
      debugPrint('웹에서 메시지 수신: $action');
      
      if (action == 'kakaoLogin') {
        await _handleKakaoLoginFromWeb();
      } else if (action == 'naverLogin') {
        await _handleNaverLoginFromWeb();
      } else if (action == 'openAuth') {
        // 본인인증 요청 처리
        final authData = data['data'] as Map<String, dynamic>?;
        if (authData != null) {
          await _handleOpenAuth(authData);
        } else {
          debugPrint('❌ 본인인증 데이터가 없습니다.');
        }
      } else {
        debugPrint('알 수 없는 액션: $action');
      }
    } catch (e) {
      debugPrint('웹 메시지 처리 실패: $e');
      _sendMessageToWeb('onKakaoLoginError', {'error': e.toString()});
    }
  }

  /// 테스트용 URL (본인인증 URL 없이 In-App Browser만 확인할 때 사용)
  /// - 폼 페이지라 본인인증 입력 단계 느낌으로 테스트하기 좋음
  static const String _testAuthUrl = 'https://httpbin.org/forms/post';

  // 본인인증 열기 처리
  Future<void> _handleOpenAuth(Map<String, dynamic> authData) async {
    try {
      final rawUrl = authData['url'] as String?;
      final type = authData['type'] as String?;
      
      // URL 없으면 테스트용 URL로 In-App Browser만 띄워서 동작 확인
      final String authUrl;
      if (rawUrl == null || rawUrl.isEmpty) {
        debugPrint('⚠️ [IDV Bridge] 본인인증 URL 없음 → 테스트 URL로 In-App Browser 띄움');
        authUrl = _testAuthUrl;
      } else {
        authUrl = rawUrl;
      }
      
      debugPrint('🔐 [IDV Bridge] 본인인증 요청 수신');
      debugPrint('  - Type: $type');
      debugPrint('  - URL: $authUrl');
      
      if (!mounted) return;
      
      // In-App Browser로 본인인증 페이지 열기
      final result = await Navigator.of(context).push<Map<String, dynamic>>(
        MaterialPageRoute(
          builder: (context) => AuthWebViewPage(
            authUrl: authUrl,
            onResult: (result) {
              Navigator.of(context).pop(result);
            },
          ),
          fullscreenDialog: true,
        ),
      );
      
      // 결과 처리
      if (result != null) {
        final success = result['success'] as bool? ?? false;
        
        if (success) {
          debugPrint('✅ [IDV Bridge] 본인인증 성공');
          _sendMessageToWeb('onAuthSuccess', result);
        } else {
          debugPrint('❌ [IDV Bridge] 본인인증 실패');
          _sendMessageToWeb('onAuthError', result);
        }
      } else {
        debugPrint('⚠️ [IDV Bridge] 본인인증 취소');
        _sendMessageToWeb('onAuthCancel', {
          'message': '사용자가 본인인증을 취소했습니다.',
        });
      }
    } catch (e) {
      debugPrint('❌ [IDV Bridge] 본인인증 처리 중 오류 발생: $e');
      _sendMessageToWeb('onAuthError', {
        'error': e.toString(),
        'message': '본인인증 처리 중 오류가 발생했습니다.',
      });
    }
  }

  // 웹에서 요청한 카카오 로그인 처리
  Future<void> _handleKakaoLoginFromWeb() async {
    try {
      debugPrint('웹에서 카카오 로그인 요청 받음');
      
      // 카카오 SDK로 로그인 실행 (토큰 포함)
      final result = await KakaoAuthService.login();
      
      if (result != null && mounted) {
        final user = result['user'] as User?;
        final accessToken = result['accessToken'] as String?;
        final refreshToken = result['refreshToken'] as String?;
        
        setState(() {
          isLoggedIn = true;
          currentUser = user;
        });
        
        // 로그인 성공 정보를 웹으로 전달 (토큰 포함)
        final userData = {
          'id': user?.id.toString(),
          'nickname': user?.kakaoAccount?.profile?.nickname,
          'email': user?.kakaoAccount?.email,
          'profileImage': user?.kakaoAccount?.profile?.profileImageUrl,
          'cid': user?.id.toString(), // CID는 사용자 ID로 사용
          'accessToken': accessToken, // 카카오 액세스 토큰
          'refreshToken': refreshToken, // 카카오 리프레시 토큰
        };
        
        _sendMessageToWeb('onKakaoLoginSuccess', userData);
        
        debugPrint('✅ 카카오 로그인 성공!');
        debugPrint('📤 웹으로 전송할 데이터:');
        debugPrint('  - ID: ${userData['id']}');
        debugPrint('  - Nickname: ${userData['nickname']}');
        debugPrint('  - Email: ${userData['email']}');
        debugPrint('  - Access Token (전체): $accessToken');
        debugPrint('  - Refresh Token (전체): $refreshToken');
      }
    } catch (e) {
      debugPrint('❌ 카카오 로그인 실패: $e');
      _sendMessageToWeb('onKakaoLoginError', {
        'error': e.toString(),
        'message': '카카오 로그인에 실패했습니다.',
      });
    }
  }

  // 웹에서 요청한 네이버 로그인 처리
  Future<void> _handleNaverLoginFromWeb() async {
    try {
      debugPrint('웹에서 네이버 로그인 요청 받음');
      
      // 네이버 SDK로 로그인 실행
      final userData = await NaverAuthService.login();
      
      if (userData != null && mounted) {
        setState(() {
          isLoggedIn = true;
        });
        
        // 로그인 성공 정보를 웹으로 전달
        _sendMessageToWeb('onNaverLoginSuccess', userData);
        
        debugPrint('네이버 로그인 성공, 웹으로 데이터 전송: $userData');
      } else {
        throw Exception('네이버 로그인이 취소되었거나 실패했습니다.');
      }
    } catch (e) {
      debugPrint('네이버 로그인 실패: $e');
      _sendMessageToWeb('onNaverLoginError', {
        'error': e.toString(),
        'message': '네이버 로그인에 실패했습니다.',
      });
    }
  }

  // Flutter에서 읽은 safe-area / 키보드 inset 값을 웹 CSS 변수로 주입
  Future<void> _injectSafeAreaInsets() async {
    if (!mounted) return;

    final padding = MediaQuery.of(context).padding;
    final viewInsets = MediaQuery.of(context).viewInsets;
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;

    // dp → px 변환 없이 CSS px 단위 그대로 사용 (WebView의 1px = 1dp)
    final top = padding.top;
    final bottom = padding.bottom;
    final left = padding.left;
    final right = padding.right;
    final keyboardHeight = viewInsets.bottom;

    final script = '''
      (function() {
        var root = document.documentElement;

        // 네비게이션 바 / 노치 등 시스템 영역 inset
        root.style.setProperty('--sat', '${top}px');
        root.style.setProperty('--sar', '${right}px');
        root.style.setProperty('--sab', '${bottom}px');
        root.style.setProperty('--sal', '${left}px');

        // 키보드 높이 (올라와 있을 때만 양수)
        root.style.setProperty('--keyboard-height', '${keyboardHeight}px');

        console.log('[SafeArea] top=${top} right=${right} bottom=${bottom} left=${left} keyboard=${keyboardHeight}');
      })();
    ''';

    try {
      await controller.runJavaScript(script);
      debugPrint('SafeArea 주입 완료: top=$top, bottom=$bottom, keyboard=$keyboardHeight');
    } catch (e) {
      debugPrint('SafeArea 주입 실패: $e');
    }
  }

  // 웹으로 메시지 전송
  Future<void> _sendMessageToWeb(String callbackName, Map<String, dynamic> data) async {
    try {
      final jsonData = jsonEncode(data);
      // JSON 문자열을 base64로 인코딩하여 안전하게 전달
      final base64Data = base64Encode(utf8.encode(jsonData));
      final script = '''
        (function() {
          try {
            var jsonString = atob('$base64Data');
            var data = JSON.parse(jsonString);
            
            if (typeof $callbackName === 'function') {
              $callbackName(data);
            } else {
              console.warn('콜백 함수 $callbackName이 정의되지 않았습니다.');
              console.log('받은 데이터:', data);
            }
          } catch (e) {
            console.error('콜백 함수 실행 중 오류:', e);
            console.error('에러 상세:', e.message, e.stack);
            try {
              var jsonString = atob('$base64Data');
              console.log('원본 JSON 문자열:', jsonString);
            } catch (parseError) {
              console.error('JSON 파싱 실패:', parseError);
            }
          }
        })();
      ''';
      
      await controller.runJavaScript(script);
      debugPrint('웹으로 메시지 전송 완료: $callbackName, 데이터: $jsonData');
    } catch (e) {
      debugPrint('웹으로 메시지 전송 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = _getLocalhostUrl();

    // Flutter에서 실제 safe-area inset 값을 읽어 웹으로 주입
    final mediaPadding = MediaQuery.of(context).padding;
    final viewInsets = MediaQuery.of(context).viewInsets;

    return PopScope(
      canPop: false, // 기본 뒤로가기 동작 방지
      onPopInvoked: (bool didPop) async {
        if (didPop) return;
        
        // 웹뷰에서 뒤로 갈 수 있는지 확인
        if (await controller.canGoBack()) {
          // 이전 페이지로 이동
          await controller.goBack();
        } else {
          // 더 이상 뒤로 갈 페이지가 없으면 앱 종료 여부 확인
          if (context.mounted) {
            final shouldPop = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('앱 종료'),
                content: const Text('앱을 종료하시겠습니까?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('취소'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('종료'),
                  ),
                ],
              ),
            );
            
            if (shouldPop == true && context.mounted) {
              SystemNavigator.pop(); // 앱 종료
            }
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        // 키보드가 올라와도 WebView 높이를 줄이지 않음
        // 웹 내부에서 CSS env(keyboard-inset-height) 또는 JS로 직접 처리
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
          WebViewWidget(controller: controller),
          // 카카오 로그인 상태 표시 및 버튼
          // Positioned(
          //   top: 0,
          //   left: 0,
          //   right: 0,
          //   child: SafeArea(
          //     child: Container(
          //       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          //       decoration: BoxDecoration(
          //         color: Colors.white.withOpacity(0.9),
          //         boxShadow: [
          //           BoxShadow(
          //             color: Colors.black.withOpacity(0.1),
          //             blurRadius: 4,
          //             offset: const Offset(0, 2),
          //           ),
          //         ],
          //       ),
          //       child: Row(
          //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //         children: [
          //           // 로그인 상태 표시
          //           Expanded(
          //             child: isLoggedIn
          //                 ? Row(
          //                     children: [
          //                       const Icon(Icons.check_circle, color: Colors.green, size: 20),
          //                       const SizedBox(width: 8),
          //                       Expanded(
          //                         child: Text(
          //                           '${currentUser?.kakaoAccount?.profile?.nickname ?? "사용자"}님',
          //                           style: const TextStyle(
          //                             fontSize: 14,
          //                             fontWeight: FontWeight.w500,
          //                           ),
          //                           overflow: TextOverflow.ellipsis,
          //                         ),
          //                       ),
          //                     ],
          //                   )
          //                 : const Text(
          //                     '로그인이 필요합니다',
          //                     style: TextStyle(
          //                       fontSize: 14,
          //                       color: Colors.grey,
          //                     ),
          //                   ),
          //           ),
          //           const SizedBox(width: 8),
          //           // 로그인/로그아웃 버튼
          //           ElevatedButton.icon(
          //             onPressed: isLoggedIn ? _handleKakaoLogout : _handleKakaoLogin,
          //             icon: Icon(isLoggedIn ? Icons.logout : Icons.login),
          //             label: Text(isLoggedIn ? '로그아웃' : '카카오 로그인'),
          //             style: ElevatedButton.styleFrom(
          //               backgroundColor: isLoggedIn ? Colors.grey : const Color(0xFFFEE500),
          //               foregroundColor: isLoggedIn ? Colors.white : Colors.black87,
          //               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          //               minimumSize: const Size(0, 36),
          //             ),
          //           ),
          //         ],
          //       ),
          //     ),
          //   ),
          // ),
          if (isLoading)
            Container(
              color: Colors.white,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      '페이지를 불러오는 중...',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          if (errorMessage != null && !isLoading)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '연결 오류',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '시도 중인 URL: $url',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            errorMessage = null;
                            isLoading = true;
                          });
                          controller.reload();
                        },
                        child: const Text('다시 시도'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 본인인증용 In-App Browser 페이지
class AuthWebViewPage extends StatefulWidget {
  final String authUrl;
  final Function(Map<String, dynamic>) onResult;

  const AuthWebViewPage({
    super.key,
    required this.authUrl,
    required this.onResult,
  });

  @override
  State<AuthWebViewPage> createState() => _AuthWebViewPageState();
}

class _AuthWebViewPageState extends State<AuthWebViewPage> {
  late final WebViewController authController;
  bool isLoading = true;
  String currentUrl = '';

  @override
  void initState() {
    super.initState();
    
    authController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..addJavaScriptChannel(
        'AuthResult',
        onMessageReceived: (JavaScriptMessage message) {
          _handleAuthResult(message.message);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            debugPrint('🔐 [IDV Browser] 페이지 로드 시작: $url');
            if (mounted) {
              setState(() {
                isLoading = true;
                currentUrl = url;
              });
            }
          },
          onPageFinished: (String url) {
            debugPrint('✅ [IDV Browser] 페이지 로드 완료: $url');
            if (mounted) {
              setState(() {
                isLoading = false;
                currentUrl = url;
              });
            }
            
            // 본인인증 완료 체크 (URL 패턴으로 감지)
            _checkAuthCompletion(url);
          },
          onNavigationRequest: (NavigationRequest request) {
            debugPrint('🔗 [IDV Browser] 네비게이션 요청: ${request.url}');
            
            // 특정 URL 패턴에 따라 완료/취소 판단
            if (request.url.contains('/auth/success') || 
                request.url.contains('/auth/complete')) {
              // 성공 페이지로 이동하는 경우
              _handleAuthSuccess(request.url);
              return NavigationDecision.prevent;
            } else if (request.url.contains('/auth/cancel') || 
                       request.url.contains('/auth/fail')) {
              // 취소/실패 페이지로 이동하는 경우
              _handleAuthCancel(request.url);
              return NavigationDecision.prevent;
            }
            
            return NavigationDecision.navigate;
          },
        ),
      );
    
    // Android WebView 특정 설정
    if (Platform.isAndroid) {
      final androidController = authController.platform as AndroidWebViewController;
      androidController.setMediaPlaybackRequiresUserGesture(false);
    }
    
    // 본인인증 URL 로드
    authController.loadRequest(Uri.parse(widget.authUrl));
  }

  // 본인인증 완료 체크 (URL 기반)
  void _checkAuthCompletion(String url) {
    // URL 파라미터에서 인증 결과 추출
    try {
      final uri = Uri.parse(url);
      
      // 성공 케이스
      if (uri.path.contains('/success') || uri.path.contains('/complete')) {
        final resultData = {
          'success': true,
          'data': uri.queryParameters,
          'url': url,
        };
        widget.onResult(resultData);
      }
      // 실패 케이스
      else if (uri.path.contains('/fail') || uri.path.contains('/error')) {
        final resultData = {
          'success': false,
          'error': uri.queryParameters['error'] ?? 'UNKNOWN_ERROR',
          'message': uri.queryParameters['message'] ?? '본인인증에 실패했습니다.',
          'url': url,
        };
        widget.onResult(resultData);
      }
    } catch (e) {
      debugPrint('❌ [IDV Browser] URL 파싱 실패: $e');
    }
  }

  // 본인인증 결과 처리 (JavaScript 메시지)
  void _handleAuthResult(String message) {
    try {
      final data = jsonDecode(message) as Map<String, dynamic>;
      debugPrint('✅ [IDV Browser] JavaScript에서 인증 결과 수신: $data');
      widget.onResult(data);
    } catch (e) {
      debugPrint('❌ [IDV Browser] 인증 결과 파싱 실패: $e');
    }
  }

  // 본인인증 성공 처리
  void _handleAuthSuccess(String url) {
    debugPrint('✅ [IDV Browser] 본인인증 성공 URL 감지: $url');
    
    try {
      final uri = Uri.parse(url);
      final resultData = {
        'success': true,
        'data': uri.queryParameters,
        'url': url,
      };
      widget.onResult(resultData);
    } catch (e) {
      debugPrint('❌ [IDV Browser] 성공 URL 파싱 실패: $e');
      widget.onResult({
        'success': true,
        'url': url,
      });
    }
  }

  // 본인인증 취소 처리
  void _handleAuthCancel(String url) {
    debugPrint('⚠️ [IDV Browser] 본인인증 취소 URL 감지: $url');
    
    widget.onResult({
      'success': false,
      'error': 'USER_CANCEL',
      'message': '사용자가 본인인증을 취소했습니다.',
      'url': url,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('본인인증'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            // 뒤로가기 시 취소로 처리
            widget.onResult({
              'success': false,
              'error': 'USER_CANCEL',
              'message': '사용자가 본인인증을 취소했습니다.',
            });
          },
        ),
        actions: [
          if (!isLoading)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                authController.reload();
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: authController),
          if (isLoading)
            Container(
              color: Colors.white,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      '본인인증 페이지를 불러오는 중...',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
