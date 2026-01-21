import Flutter
import UIKit
import NidThirdPartyLogin

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    // 네이버 앱에서 전달된 URL인 경우
    if (NidOAuth.shared.handleURL(url) == true) {
      return true
    }
    
    // 다른 앱에서 전달된 URL 처리
    return super.application(app, open: url, options: options)
  }
}
