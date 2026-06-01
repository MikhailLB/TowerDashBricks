import 'dart:io';
import 'tdb_endpoint.dart';

abstract final class TdbConfig {
  // ── iOS App Store numeric ID ──────────────────────────────
  static const String iosStoreId = '6771513809';

  // ── Android/iOS bundle / package ID ──────────────────────
  static const String bundleId = 'com.towerlab.tower.dash.bricks';

  // ── Display name used in debug logs ──────────────────────
  static const String appTitle = 'TowerDash Bricks';

  // ── Timing constants ─────────────────────────────────────
  /// Seconds before the push opt-in screen re-appears after Skip.
  static const int pushCooldownSeconds = 259200; // 3 days

  /// Seconds to retry GCD when AppsFlyer reports Organic.
  static const int organicRetrySeconds = 6;

    static const int bootBudgetSeconds = 20;

  // ── Derived ──────────────────────────────────────────────
  static String get configEndpoint    => tdbEndpoint();
  static String get installKey        => tdbAttrKey();
  static String get firebaseNumber    => tdbFbNum();
  static String get privacyUrl        => tdbPrivUrl;
  static String get supportUrl        => tdbSuppUrl;
  static String get platformStoreId   =>
      Platform.isIOS ? 'id$iosStoreId' : bundleId;
  static String get analyticsAppId    =>
      Platform.isIOS ? iosStoreId : bundleId;
}
