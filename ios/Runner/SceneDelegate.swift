import Flutter
import UIKit
import UserNotifications

/// Scene-based apps deliver cold-start push taps through
/// `scene(_:willConnectTo:options:)` — NOT through the traditional
/// AppDelegate launchOptions path that Firebase swizzle reads.
/// `getInitialMessage()` therefore returns nil for these taps.
///
/// We capture the URL here and store it in UserDefaults under
/// `flutter.tdb_gate_tap_url`. The `flutter.` prefix is mandatory
/// because `shared_preferences` on iOS reads UserDefaults values using
/// that prefix, letting `TapBridge.consumeTapUrl()` pick it up
/// through SharedPreferences with no MethodChannel dance.
class SceneDelegate: FlutterSceneDelegate {
  static let tapUrlKey = "flutter.tdb_gate_tap_url"

  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)

    if let response = connectionOptions.notificationResponse,
       let url = SceneDelegate.extractUrl(
         from: response.notification.request.content.userInfo
       )
    {
      SceneDelegate.persist(url: url)
    }
  }

  override func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
    super.scene(scene, continue: userActivity)
  }

  /// Checks every key the gray backend may use for the destination URL.
  /// Priority order matches BrickBeacon._extractUrl() on the Dart side so
  /// killed-app and live-app paths resolve identically.
  static func extractUrl(from userInfo: [AnyHashable: Any]) -> String? {
    let keys = ["url", "link", "target", "deeplink", "deep_link"]

    func scan(_ map: [AnyHashable: Any]) -> String? {
      for key in keys {
        if let raw = map[key] as? String,
           !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
          return raw.trimmingCharacters(in: .whitespacesAndNewlines)
        }
      }
      return nil
    }

    // 1. Direct top-level keys (FCM flattens data payload into userInfo)
    if let direct = scan(userInfo) { return direct }

    // 2. Nested "data" dict (some backends wrap payload in data:{})
    if let nested = userInfo["data"] as? [AnyHashable: Any] {
      if let url = scan(nested) { return url }
    }

    // 3. Nested "payload" dict
    if let nested = userInfo["payload"] as? [AnyHashable: Any] {
      if let url = scan(nested) { return url }
    }

    return nil
  }

  static func persist(url: String) {
    let d = UserDefaults.standard
    d.set(url, forKey: tapUrlKey)
    d.synchronize()
  }
}
