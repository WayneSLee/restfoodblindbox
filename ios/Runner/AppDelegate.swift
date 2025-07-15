import Flutter
import UIKit
import GoogleMaps // 1. 引入 GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // 2. 提供您的 iOS Google Maps API Key
    GMSServices.provideAPIKey("AIzaSyB4g9CA7Pc5ceKdxtsSkHOp_LzHMkd8o_4")

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}