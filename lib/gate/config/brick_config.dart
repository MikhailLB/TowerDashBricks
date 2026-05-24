import 'dart:io';
import 'endpoint_vault.dart';
import 'signal_keys.dart';
import 'brand_links.dart';

/// App-level constants for the TowerDash Bricks gray gate.
abstract final class BrickConfig {
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

  /// Hard boot timeout: gray flow falls back to game after this.
  static const int bootBudgetSeconds = 20;

  // ── Derived ──────────────────────────────────────────────
  static String get configEndpoint    => gateEndpointUrl();
  static String get installKey        => appsflyerDevKey();
  static String get firebaseNumber    => firebaseProjectNumber();
  static String get privacyUrl        => brandPrivacyPageUrl;
  static String get supportUrl        => brandSupportPageUrl;
  static String get platformStoreId   =>
      Platform.isIOS ? 'id$iosStoreId' : bundleId;
  static String get analyticsAppId    =>
      Platform.isIOS ? iosStoreId : bundleId;
}
