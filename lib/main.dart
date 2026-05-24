import 'dart:async';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/app_orientation.dart';
import 'bootstrap.dart';
import 'gate/config/endpoint_vault.dart';
import 'gate/config/signal_keys.dart';
import 'gate/infra/brick_beacon.dart';
import 'gate/infra/brick_dispatch.dart';
import 'gate/infra/network_probe.dart';
import 'gate/infra/brick_agent.dart';
import 'gate/infra/brick_vault.dart';
import 'gate/infra/brick_signal.dart';
import 'services/audio_service.dart';
import 'services/storage_service.dart';
import 'state/game_progress.dart';

// ════════════════════════════════════════════════════════════
// main() — entry point
// ════════════════════════════════════════════════════════════
//
// ORDER MATTERS — do not rearrange:
//   1. WidgetsFlutterBinding.ensureInitialized()
//   2. White-part game init (StorageService, GameProgress, AudioService)
//   3. Firebase.initializeApp() + FirebaseAppCheck.activate()
//   4. brickAgent.warmup() + BrickVault.init() in parallel
//   5. Flame asset preload (gray flow skips LoadingScreen)
//   6. runApp(TowerDashGateApp(...))
//
// Firebase must be initialized ONCE here and NEVER again.
// ════════════════════════════════════════════════════════════

late final GameProgress progress;

Future<void> _bootFirebase() async {
  try {
    await Firebase.initializeApp();
  } catch (err) {
    debugPrint('[BOOT] Firebase init skipped: $err');
    return;
  }
  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider:
          kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
      appleProvider: kDebugMode
          ? AppleProvider.debug
          : AppleProvider.appAttestWithDeviceCheckFallback,
    );
  } catch (err) {
    debugPrint('[BOOT] AppCheck skipped: $err');
  }
}

Future<void> main() async {
  final sw = Stopwatch()..start();
  WidgetsFlutterBinding.ensureInitialized();

  // ── White-part game init ────────────────────────────────────────────
  await setOrientationsForLoadingScreens();
  final storage = await StorageService.create();
  progress = GameProgress(storage);
  await AudioService.init(progress);
  debugPrint('[BOOT] white-part ready ${sw.elapsedMilliseconds}ms');

  // ── Gray gate init ──────────────────────────────────────────────────
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // Firebase + UA warmup + vault — run in parallel for speed
  final firebaseFuture = _bootFirebase();
  final agentFuture    = brickAgent.warmup();
  final vault          = BrickVault();
  final vaultFuture    = vault.init().catchError((err) {
    debugPrint('[BOOT] vault init failed: $err');
  });

  await firebaseFuture;
  debugPrint('[BOOT] firebase ready ${sw.elapsedMilliseconds}ms');
  await Future.wait([agentFuture, vaultFuture]);
  debugPrint('[BOOT] agent+vault ready ${sw.elapsedMilliseconds}ms');

  final probe    = NetworkProbe();
  final signal   = BrickSignal();
  final dispatch = BrickDispatch(vault);
  final beacon   = BrickBeacon(vault);

  // Pre-fire push bootstrap in parallel with first frame render
  unawaited(beacon.bootstrap().catchError((err) {
    debugPrint('[BOOT] beacon pre-fire: $err');
  }));

  // Gate is enabled when at least one credential is provisioned.
  final gateEnabled =
      gateEndpointUrl().isNotEmpty || appsflyerDevKey().isNotEmpty;

  debugPrint('[BOOT] gateEnabled=$gateEnabled  ${sw.elapsedMilliseconds}ms');

  runApp(TowerDashGateApp(
    vault: vault,
    probe: probe,
    signal: signal,
    dispatch: dispatch,
    beacon: beacon,
    gateEnabled: gateEnabled,
  ));
}
