import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

/// 카카오 로그인 서비스
class KakaoAuthService {
  /// 카카오 로그인 실행
  /// 
  /// 카카오톡이 설치되어 있으면 카카오톡으로 로그인,
  /// 없으면 카카오계정 웹 로그인을 진행합니다.
  /// 
  /// Returns: 로그인 성공 시 User 객체, 실패 시 null
  static Future<User?> login() async {
    try {
      // 휴대폰에 카카오톡이 깔려있는지 확인
      bool installed = await isKakaoTalkInstalled();

      // 카카오톡이 설치되어 있으면 카카오톡으로 로그인
      // 없으면 카카오계정 웹 로그인
      OAuthToken token = installed
          ? await UserApi.instance.loginWithKakaoTalk()
          : await UserApi.instance.loginWithKakaoAccount();

      // 로그인 성공 후 유저 정보 가져오기
      User user = await UserApi.instance.me();

      return user;
    } catch (e) {
      print(' 실패: $e');
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

