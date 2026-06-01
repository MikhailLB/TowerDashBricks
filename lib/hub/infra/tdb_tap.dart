import 'dart:io';
import '../../core/tdb_log.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Reads the cold-start push URL that SceneDelegate captured before Dart
/// code was alive.
///
/// On iOS scene-based apps, tapping a push notification while the app is
/// killed routes the tap through SceneDelegate.scene(_:willConnectTo:options:)
/// — NOT through Firebase's swizzled AppDelegate path. SceneDelegate writes
/// the URL to UserDefaults under `flutter.tdb_gate_tap_url`. The `flutter.`
/// prefix is required: SharedPreferences on iOS namespaces every key with it,
/// so reading via SharedPreferences is equivalent to reading via UserDefaults.
class TdbTap {
  static const String _key = 'tdb_gate_tap_url';

  /// Returns and clears the URL left by SceneDelegate on cold-start tap.
  /// Returns null on non-iOS or when no URL is stored.
  static Future<String?> consumeTapUrl() async {
    if (!Platform.isIOS) return null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.trim().isEmpty) {
        tdbLog('[tap] consumeTapUrl -> null');
        return null;
      }
      await prefs.remove(_key);
      tdbLog('[tap] consumeTapUrl -> "$raw"');
      return raw.trim();
    } catch (err) {
      tdbLog('[tap] consumeTapUrl failed: $err');
      return null;
    }
  }
}
