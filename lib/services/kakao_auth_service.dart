import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

/// 카카오 로그인 서비스
class KakaoAuthService {
  /// 카카오 로그인 실행
  /// 
  /// 카카오톡이 설치되어 있으면 카카오톡으로 로그인,
  /// 없으면 카카오계정 웹 로그인을 진행합니다.
  /// 항상 새로운 인증을 요구합니다.
  /// 
  /// Returns: 로그인 성공 시 User와 토큰 정보를 포함한 Map, 실패 시 null
  static Future<Map<String, dynamic>?> login() async {
    // loginWithToken()을 호출하여 중복 코드 제거
    return await loginWithToken();
  }

  /// 카카오 로그인 실행 (토큰 포함)
  /// 
  /// 카카오톡이 설치되어 있으면 카카오톡으로 로그인,
  /// 없으면 카카오계정 웹 로그인을 진행합니다.
  /// 항상 새로운 인증을 요구합니다.
  /// 
  /// Returns: 로그인 성공 시 User와 OAuthToken을 포함한 Map, 실패 시 null
  static Future<Map<String, dynamic>?> loginWithToken() async {
    try {
      // 기존 액세스 토큰이 있다면 로그아웃하여 강제로 새 로그인 화면 표시
      try {
        await UserApi.instance.logout();
      } catch (e) {
        // 토큰이 없는 경우 무시
        print('기존 토큰 없음 또는 로그아웃 실패 (정상): $e');
      }

      // 휴대폰에 카카오톡이 깔려있는지 확인
      bool installed = await isKakaoTalkInstalled();

      OAuthToken token;
      if (installed) {
        // 카카오톡이 설치되어 있으면 카카오톡으로 로그인
        token = await UserApi.instance.loginWithKakaoTalk();
      } else {
        // 카카오계정 웹 로그인 (강제 로그인 화면 표시)
        token = await UserApi.instance.loginWithKakaoAccount(
          prompts: [Prompt.login], // 기존 세션이 있어도 항상 로그인 화면 표시
        );
      }

      // 토큰 정보 로그
      print('🔑 카카오 토큰 정보:');
      print('  - Access Token: ${token.accessToken}');
      print('  - Refresh Token: ${token.refreshToken}');
      print('  - token: ${token}');
    

      // 로그인 성공 후 유저 정보 가져오기
      User user = await UserApi.instance.me();

      return {
        'user': user,
        'accessToken': token.accessToken,
        'refreshToken': token.refreshToken,
        'idToken': token.idToken,
        'expiresAt': token.expiresAt,
      };
    } catch (e) {
      print('카카오 로그인 실패: $e');
      rethrow;
    }
  }

  /// 카카오 로그아웃
  static Future<void> logout() async {
    try {
      await UserApi.instance.logout();
    } catch (e) {
      print('카카오 로그아웃 실패: $e');
      rethrow;
    }
  }

  /// 현재 로그인 상태 확인
  static Future<bool> isLoggedIn() async {
    try {
      await UserApi.instance.me();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 현재 로그인된 사용자 정보 가져오기
  static Future<User?> getCurrentUser() async {
    try {
      return await UserApi.instance.me();
    } catch (e) {
      return null;
    }
  }
}

