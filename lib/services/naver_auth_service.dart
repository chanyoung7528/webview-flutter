import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'package:flutter_naver_login/interface/types/naver_login_result.dart';
import 'package:flutter_naver_login/interface/types/naver_login_status.dart';
import 'package:flutter_naver_login/interface/types/naver_account_result.dart';
import 'package:flutter_naver_login/interface/types/naver_token.dart';

/// 네이버 로그인 서비스
class NaverAuthService {
  /// 네이버 로그인 실행
  /// 
  /// 네이버 앱이 설치되어 있으면 네이버 앱으로 로그인,
  /// 없으면 네이버 계정 웹 로그인을 진행합니다.
  /// 
  /// Returns: 로그인 성공 시 사용자 정보 및 토큰을 포함한 Map, 실패 시 null
  static Future<Map<String, dynamic>?> login() async {
    try {
      final NaverLoginResult result = await FlutterNaverLogin.logIn();
      
      if (result.status == NaverLoginStatus.loggedIn && result.account != null) {
        final account = result.account!;
        
        // 로그인 성공 후 토큰 가져오기
        Map<String, dynamic> userData = {
          'id': account.id,
          'nickname': account.nickname,
          'name': account.name,
          'email': account.email,
          'profileImage': account.profileImage,
        };
        
        // 토큰 정보 추가
        try {
          final NaverToken token = await FlutterNaverLogin.getCurrentAccessToken();
          if (token.isValid()) {
            // 토큰 정보 로그
            print('🔑 네이버 토큰 정보:');
            print('  - Access Token: ${token.accessToken}');
            print('  - Refresh Token: ${token.refreshToken}...');
            print('  - token: ${token}');
            
            userData['accessToken'] = token.accessToken;
            userData['refreshToken'] = token.refreshToken;
            userData['tokenType'] = token.tokenType;
            userData['expiresAt'] = token.expiresAt;
          } else {
            print('⚠️ 네이버 토큰이 유효하지 않음');
          }
        } catch (e) {
          print('❌ 네이버 토큰 가져오기 실패: $e');
        }
        
        return userData;
      }
      
      return null;
    } catch (e) {
      print('네이버 로그인 실패: $e');
      rethrow;
    }
  }

  /// 네이버 로그아웃
  static Future<void> logout() async {
    try {
      await FlutterNaverLogin.logOut();
    } catch (e) {
      print('네이버 로그아웃 실패: $e');
      rethrow;
    }
  }

  /// 네이버 로그아웃 및 토큰 삭제
  static Future<void> logoutAndDeleteToken() async {
    try {
      await FlutterNaverLogin.logOutAndDeleteToken();
    } catch (e) {
      print('네이버 로그아웃 및 토큰 삭제 실패: $e');
      rethrow;
    }
  }

  /// 현재 로그인 상태 확인
  static Future<bool> isLoggedIn() async {
    try {
      return await FlutterNaverLogin.isLoggedIn();
    } catch (e) {
      return false;
    }
  }

  /// 현재 액세스 토큰 가져오기
  static Future<Map<String, dynamic>?> getCurrentAccessToken() async {
    try {
      final NaverToken token = await FlutterNaverLogin.getCurrentAccessToken();
      if (token.isValid()) {
        return {
          'accessToken': token.accessToken,
          'refreshToken': token.refreshToken,
          'tokenType': token.tokenType,
          'expiresAt': token.expiresAt,
        };
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 현재 로그인된 사용자 정보 가져오기
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final NaverAccountResult account = await FlutterNaverLogin.getCurrentAccount();
      return {
        'id': account.id,
        'nickname': account.nickname,
        'name': account.name,
        'email': account.email,
        'profileImage': account.profileImage,
      };
    } catch (e) {
      return null;
    }
  }
}
