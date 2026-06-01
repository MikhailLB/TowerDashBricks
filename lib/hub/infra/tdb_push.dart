import 'dart:async';
import '../../core/tdb_log.dart';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'tdb_http.dart';
import 'tdb_store.dart';

const _channelId    = 'tdb_push_channel';
const _channelLabel = 'TowerDash Bricks Updates';
const _iconRes      = '@drawable/ic_tdb_notification';

@pragma('vm:entry-point')
Future<void> _silentBgHandler(RemoteMessage _) async {}

/// Top-level handler for taps on locally-displayed notifications when the
/// Dart isolate isn't alive.
@pragma('vm:entry-point')
Future<void> beaconLocalTapHandler(NotificationResponse resp) async {
  final payload = resp.payload;
  if (payload == null || payload.isEmpty) return;
  try {
    final d = jsonDecode(payload);
    if (d is Map && d['url'] is String && (d['url'] as String).isNotEmpty) {
      await TdbStore().stashOneShotUrl(d['url'] as String);
    }
  } catch (_) {}
}

/// FCM + flutter_local_notifications wrapper for TowerDash Bricks.
class TdbPush {
  final FlutterLocalNotificationsPlugin _notifPlugin =
      FlutterLocalNotificationsPlugin();
  final TdbStore _vault;
  final Completer<void> _initReady = Completer<void>();

  FirebaseMessaging? _fcm;
  String? _token;
  bool _active = false;
  Future<void>? _startupFuture;
  Future<bool>? _consentInflight;

  void Function(String url)? onPushUrl;
  void Function(String token)? onTokenRefresh;

  TdbPush(this._vault);

  String? get token => _token;
  bool get ready => _active;

  Future<void> get initComplete => _initReady.future;

  Future<void> bootstrap() => _startupFuture ??= _initServices();

  Future<void> _initServices() async {
    try {
      _fcm = FirebaseMessaging.instance;
      await _readInitialMessage();
      FirebaseMessaging.onBackgroundMessage(_silentBgHandler);
      await _initNotifications();
      try {
        await _fcm!.setForegroundNotificationPresentationOptions(
          alert: true, badge: true, sound: true,
        );
      } catch (_) {}
      _fcm!.onTokenRefresh.listen((t) {
        _token = t;
        onTokenRefresh?.call(t);
      });
      FirebaseMessaging.onMessage.listen(_handleIncoming);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleBgTap);
      if (Platform.isIOS) {
        try {
          final s = await _fcm!.getNotificationSettings();
          if (s.authorizationStatus == AuthorizationStatus.notDetermined) {
            await _fcm!.requestPermission(
              alert: false, badge: false, sound: false, provisional: true,
            );
          }
        } catch (_) {}
        await _waitForApnsToken();
      }
      _token = await _fcm!.getToken();
      _active = true;
      tdbLog('[psh] init OK token=${_token == null ? 'null' : 'present'}');
    } catch (err, st) {
      tdbLog('[psh] init error: $err\n$st');
    } finally {
      if (!_initReady.isCompleted) _initReady.complete();
    }
  }

  Future<void> _readInitialMessage() async {
    try {
      final msg = await _fcm!.getInitialMessage().timeout(
        const Duration(seconds: 4),
        onTimeout: () => null,
      );
      if (msg != null) {
        final url = _findUrl(msg);
        if (url != null) {
          await _vault.stashOneShotUrl(url);
          tdbLog('[psh] cold-start url stashed');
        }
      }
    } catch (_) {} finally {
      if (!_initReady.isCompleted) _initReady.complete();
    }
  }

  String? _findUrl(RemoteMessage msg) {
    for (final k in const ['url', 'link', 'target', 'deeplink', 'deep_link']) {
      final v = msg.data[k];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    final nested = msg.data['payload'];
    if (nested is Map) {
      for (final k in const ['url', 'link', 'target', 'deeplink', 'deep_link']) {
        final v = nested[k];
        if (v is String && v.trim().isNotEmpty) return v.trim();
      }
    }
    return null;
  }

  Future<void> _waitForApnsToken({int retries = 5}) async {
    for (var i = 0; i < retries; i++) {
      try {
        final t = await _fcm!.getAPNSToken();
        if (t != null && t.isNotEmpty) return;
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  Future<void> _initNotifications() async {
    await _notifPlugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings(_iconRes),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (resp) {
        final payload = resp.payload;
        if (payload == null) return;
        try {
          final d = jsonDecode(payload);
          if (d is Map && d['url'] is String) {
            _routeUrl(d['url'] as String, from: 'tray');
          }
        } catch (_) {}
      },
      onDidReceiveBackgroundNotificationResponse: beaconLocalTapHandler,
    );
    if (Platform.isAndroid) {
      final impl = _notifPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await impl?.createNotificationChannel(const AndroidNotificationChannel(
        _channelId, _channelLabel,
        description: 'TowerDash Bricks real-time updates',
        importance: Importance.high,
      ));
    }
  }

  Future<bool> shouldOfferConsent() async {
    final m = _fcm;
    if (m == null) return false;
    try {
      if (Platform.isAndroid) {
        final impl = _notifPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        if (impl == null) return true;
        final enabled = await impl.areNotificationsEnabled();
        return enabled != true;
      }
      final s = await m.getNotificationSettings();
      final st = s.authorizationStatus;
      if (st == AuthorizationStatus.denied) {
        await _vault.writePushCooldown(
          DateTime.now().millisecondsSinceEpoch ~/ 1000 + 365 * 24 * 3600,
        );
        await _vault.writePushConsent(false);
      }
      return st == AuthorizationStatus.notDetermined ||
          st == AuthorizationStatus.provisional;
    } catch (_) {
      return false;
    }
  }

  Future<bool> askConsent() async {
    if (_fcm == null) return false;
    final pending = _consentInflight;
    if (pending != null) return pending;
    final flow = _requestConsent();
    _consentInflight = flow;
    try {
      return await flow;
    } finally {
      _consentInflight = null;
    }
  }

  Future<bool> _requestConsent() async {
    try {
      if (Platform.isAndroid) {
        final impl = _notifPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        if (impl != null) {
          final already = await impl.areNotificationsEnabled();
          if (already == true) { await _vault.writePushConsent(true); return true; }
          final ok = (await impl.requestNotificationsPermission()) ?? false;
          await _vault.writePushConsent(ok);
          return ok;
        }
      }
      final settings = await _fcm!.getNotificationSettings();
      final st = settings.authorizationStatus;
      if (st == AuthorizationStatus.denied) {
        await _vault.writePushCooldown(
          DateTime.now().millisecondsSinceEpoch ~/ 1000 + 365 * 24 * 3600,
        );
        await _vault.writePushConsent(false);
        return false;
      }
      if (st == AuthorizationStatus.authorized) {
        await _vault.writePushConsent(true);
        return true;
      }
      final result = await _fcm!.requestPermission(
        alert: true, badge: true, sound: true, provisional: false,
      );
      final ok = result.authorizationStatus == AuthorizationStatus.authorized ||
          result.authorizationStatus == AuthorizationStatus.provisional;
      if (!ok && result.authorizationStatus == AuthorizationStatus.denied) {
        await _vault.writePushCooldown(
          DateTime.now().millisecondsSinceEpoch ~/ 1000 + 365 * 24 * 3600,
        );
      }
      await _vault.writePushConsent(ok);
      return ok;
    } catch (err) {
      tdbLog('[psh] askConsent error: $err');
      return false;
    }
  }

  Future<String?> refreshTokenAfterConsent() async {
    final m = _fcm;
    if (m == null) return null;
    try {
      if (Platform.isIOS) await _waitForApnsToken(retries: 14);
      _token = await m.getToken().timeout(const Duration(seconds: 10));
      final t = _token;
      if (t != null && t.isNotEmpty) onTokenRefresh?.call(t);
      return t;
    } catch (_) {
      return null;
    }
  }

  void _handleIncoming(RemoteMessage msg) async {
    if (Platform.isIOS) return;
    final notif = msg.notification;
    if (notif == null) {
      final url = _findUrl(msg);
      if (url != null) _routeUrl(url, from: 'fg-data');
      return;
    }
    final imageUrl = msg.notification?.android?.imageUrl;
    AndroidNotificationDetails? androidDetails;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      final bytes = await _downloadImage(imageUrl);
      if (bytes != null) {
        androidDetails = AndroidNotificationDetails(
          _channelId, _channelLabel,
          importance: Importance.high, priority: Priority.high,
          icon: _iconRes,
          styleInformation: BigPictureStyleInformation(
            ByteArrayAndroidBitmap(bytes),
            largeIcon:
                const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          ),
        );
      }
    }
    androidDetails ??= const AndroidNotificationDetails(
      _channelId, _channelLabel,
      importance: Importance.high, priority: Priority.high,
      icon: _iconRes,
    );
    await _notifPlugin.show(
      notif.hashCode, notif.title, notif.body,
      NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(
          presentAlert: true, presentBadge: true,
          presentSound: true, presentBanner: true, presentList: true,
        ),
      ),
      payload: msg.data.isNotEmpty ? jsonEncode(msg.data) : null,
    );
  }

  void _handleBgTap(RemoteMessage msg) {
    final url = _findUrl(msg);
    if (url != null) _routeUrl(url, from: 'bg-tap');
  }

  void _routeUrl(String url, {required String from}) {
    final cb = onPushUrl;
    if (cb != null) {
      tdbLog('[psh] route ($from) → live browser');
      cb(url);
    } else {
      tdbLog('[psh] route ($from) → stash');
      _vault.stashOneShotUrl(url);
    }
  }

  Future<Uint8List?> _downloadImage(String url) async {
    try {
      final r = await tdbHttp
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      if (r.statusCode == 200) return r.bodyBytes;
    } catch (_) {}
    return null;
  }
}
