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
  WidgetsFlutterBinding.ensureInitialized();
  KakaoSdk.init(nativeAppKey: '482c0c7428f3f38d6812fab4f87eb571');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '삼성아파트',
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

class _WebViewPageState extends State<WebViewPage> {
  late final WebViewController controller;
  bool isLoading = true;
  String? errorMessage;
  User? currentUser;
  bool isLoggedIn = false;

  String _getLocalhostUrl() {
    // Android 에뮬레이터의 경우 10.0.2.2가 호스트 머신의 localhost를 가리킴
    // iOS 시뮬레이터의 경우 localhost를 직접 사용 가능
    if (Platform.isAndroid) {
      return 'https://poc-template-b69b.vercel.app/';
    } else if (Platform.isIOS) {
      return 'http://localhost:3000';
    }
    return 'http://localhost:3000';
  }

  @override
  void initState() {
    super.initState();
    
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
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                isLoading = true;
              });
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                isLoading = false;
              });
            }
            // 페이지 로드 완료 후 JavaScript 브리지 함수 주입
            _injectJavaScriptBridge();
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView error: ${error.description}');
            debugPrint('Error code: ${error.errorCode}');
            debugPrint('Error type: ${error.errorType}');
            debugPrint('Failed URL: ${error.url}');
            // 에러 발생 시 로딩 상태 해제 및 에러 메시지 표시
            if (mounted) {
              setState(() {
                isLoading = false;
                errorMessage = '연결 오류: ${error.description}\n'
                    'URL: ${error.url}\n'
                    '에러 코드: ${error.errorCode}';
              });
            }
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
      final user = await KakaoAuthService.login();
      if (mounted) {
        setState(() {
          isLoggedIn = true;
          currentUser = user;
        });
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

  // JavaScript 브리지 함수 주입 (웹에서 사용할 수 있도록)
  Future<void> _injectJavaScriptBridge() async {
    const bridgeScript = '''
      (function() {
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
      })();
    ''';
    
    try {
      await controller.runJavaScript(bridgeScript);
      debugPrint('JavaScript 브리지 함수 주입 완료 (카카오/네이버 로그인)');
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
      } else {
        debugPrint('알 수 없는 액션: $action');
      }
    } catch (e) {
      debugPrint('웹 메시지 처리 실패: $e');
      _sendMessageToWeb('onKakaoLoginError', {'error': e.toString()});
    }
  }

  // 웹에서 요청한 카카오 로그인 처리
  Future<void> _handleKakaoLoginFromWeb() async {
    try {
      debugPrint('웹에서 카카오 로그인 요청 받음');
      
      // 카카오 SDK로 로그인 실행
      final user = await KakaoAuthService.login();
      
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
        
        _sendMessageToWeb('onKakaoLoginSuccess', userData);
        
        debugPrint('카카오 로그인 성공, 웹으로 데이터 전송: $userData');
      }
    } catch (e) {
      debugPrint('카카오 로그인 실패: $e');
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
