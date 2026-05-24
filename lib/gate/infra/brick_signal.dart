import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../config/endpoint_vault.dart';
import '../config/brick_config.dart';
import 'brick_agent.dart';

/// AppsFlyer SDK wrapper for TowerDash Bricks attribution.
class BrickSignal {
  AppsflyerSdk? _sdk;
  Map<String, dynamic>? _conversionData;
  Map<String, dynamic>? _linkData;
  Map<String, dynamic>? _reopenData;

  final Completer<Map<String, dynamic>> _attributionReady = Completer();
  final Completer<void> _linkReady = Completer();

  bool _initialized = false;
  Future<void>? _initFuture;

  bool get started => _initialized;

  Future<void> warmup() => _initFuture ??= _initSdk();

  Future<void> _initSdk() async {
    if (_initialized) return;
    final devKey = BrickConfig.installKey;
    debugPrint('[TDB.BS] warmup devKeyLen=${devKey.length}');
    if (devKey.isEmpty) {
      _initialized = true;
      if (!_attributionReady.isCompleted) _attributionReady.complete({});
      if (!_linkReady.isCompleted) _linkReady.complete();
      return;
    }
    _initialized = true;
    try {
      if (Platform.isIOS) await _askTracking();
      final opts = AppsFlyerOptions(
        afDevKey: devKey,
        appId: BrickConfig.analyticsAppId,
        showDebug: kDebugMode,
        timeToWaitForATTUserAuthorization: 4,
      );
      _sdk = AppsflyerSdk(opts);
      _sdk!.onInstallConversionData(_handleConversion);
      _sdk!.onAppOpenAttribution(_handleReopen);
      _sdk!.onDeepLinking(_handleDeepLink);
      await _sdk!.initSdk(
        registerConversionDataCallback: true,
        registerOnAppOpenAttributionCallback: true,
        registerOnDeepLinkingCallback: true,
      );
      debugPrint('[TDB.BS] sdk init OK');
    } catch (err, st) {
      debugPrint('[TDB.BS] init error: $err\n$st');
      if (!_attributionReady.isCompleted) _attributionReady.complete({});
      if (!_linkReady.isCompleted) _linkReady.complete();
    }
  }

  Future<void> _askTracking() async {
    try {
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status != TrackingStatus.notDetermined) return;
      await WidgetsBinding.instance.endOfFrame;
      await Future.delayed(const Duration(milliseconds: 300));
      await AppTrackingTransparency.requestTrackingAuthorization();
    } catch (err) {
      debugPrint('[TDB.BS] ATT skipped: $err');
    }
  }

  Map<String, dynamic> _extractData(dynamic raw) {
    final m = Map<String, dynamic>.from(raw as Map);
    final inner = m['payload'];
    if (inner is Map) return Map<String, dynamic>.from(inner);
    return m;
  }

  void _handleConversion(dynamic raw) async {
    final data = _extractData(raw);
    debugPrint('[TDB.BS] conversion ${jsonEncode(data)}');
    if (data['af_status'] == 'Organic') {
      await Future.delayed(Duration(seconds: BrickConfig.organicRetrySeconds));
      final retry = await _fetchGcdData();
      _conversionData = retry ?? data;
    } else {
      _conversionData = data;
    }
    if (!_attributionReady.isCompleted) _attributionReady.complete(_conversionData);
  }

  void _handleReopen(dynamic raw) => _reopenData = _extractData(raw);

  void _handleDeepLink(DeepLinkResult r) {
    if (r.deepLink != null) _linkData = r.deepLink!.clickEvent;
    if (!_linkReady.isCompleted) _linkReady.complete();
  }

  Future<Map<String, dynamic>?> _fetchGcdData() async {
    try {
      final uid = await deviceId();
      if (uid == null) return null;
      final appId = Platform.isIOS ? BrickConfig.analyticsAppId : BrickConfig.bundleId;
      final url = gcdUrl(appId, uid);
      if (url.isEmpty) return null;
      final resp = await brickAgent.get(
        Uri.parse(url),
        headers: {'authorization': 'Bearer ${BrickConfig.installKey}'},
      ).timeout(const Duration(seconds: 12));
      if (resp.statusCode == 200) {
        final d = jsonDecode(resp.body);
        if (d is Map<String, dynamic>) return d;
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>> awaitConversion({
    Duration timeout = const Duration(seconds: 7),
  }) =>
      _attributionReady.future.timeout(timeout, onTimeout: () => {});

  Future<void> awaitDeepLink({
    Duration timeout = const Duration(seconds: 5),
  }) =>
      _linkReady.future.timeout(timeout, onTimeout: () {});

  Future<String?> deviceId() async {
    if (_sdk == null) return null;
    try { return await _sdk!.getAppsFlyerUID(); } catch (_) { return null; }
  }

  Future<Map<String, dynamic>> buildPayload({
    required String locale,
    String? pushToken,
  }) async {
    final body = <String, dynamic>{};
    if (_conversionData != null) body.addAll(_conversionData!);
    if (_linkData != null) {
      _linkData!.forEach((k, v) => body.putIfAbsent(k, () => v));
    }
    if (_reopenData != null) {
      _reopenData!.forEach((k, v) => body.putIfAbsent(k, () => v));
    }

    final uid = await deviceId();
    if (uid != null && uid.isNotEmpty) {
      body['af_id'] = uid;
    } else {
      body.putIfAbsent('af_id', () => '');
    }

    if (Platform.isIOS) {
      try {
        final status = await AppTrackingTransparency.trackingAuthorizationStatus;
        if (status == TrackingStatus.authorized) {
          final idfa = await AppTrackingTransparency.getAdvertisingIdentifier();
          if (idfa.isNotEmpty && !idfa.startsWith('00000000-')) {
            body.putIfAbsent('sub_id_10', () => idfa);
          }
        }
      } catch (_) {}
    }

    body['bundle_id'] = BrickConfig.bundleId;
    body['store_id']  = BrickConfig.platformStoreId;
    body['os']        = Platform.isAndroid ? 'Android' : 'iOS';
    body['locale']    = locale;
    if (pushToken != null && pushToken.isNotEmpty) {
      body['push_token'] = pushToken;
    }
    if (BrickConfig.firebaseNumber.isNotEmpty) {
      body['firebase_project_id'] = BrickConfig.firebaseNumber;
    }

    debugPrint('[TDB.BS] payload keys=${body.keys.toList()}');
    return body;
  }
}
