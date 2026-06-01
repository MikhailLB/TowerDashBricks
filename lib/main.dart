import 'dart:async';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'core/tdb_log.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/app_orientation.dart';
import 'tdb_root.dart';
import 'hub/cfg/tdb_endpoint.dart';
import 'hub/infra/tdb_push.dart';
import 'hub/infra/tdb_request.dart';
import 'hub/infra/tdb_net.dart';
import 'hub/infra/tdb_http.dart';
import 'hub/infra/tdb_store.dart';
import 'hub/infra/tdb_attr.dart';
import 'services/audio_service.dart';
import 'services/storage_service.dart';
import 'state/game_progress.dart';

// ════════════════════════════════════════════════════════════
// main() — entry point
// ════════════════════════════════════════════════════════════
//
// ORDER MATTERS — do not rearrange:
//   1. WidgetsFlutterBinding.ensureInitialized()
//   3. Firebase.initializeApp() + FirebaseAppCheck.activate()
//   4. tdbHttp.warmup() + TdbStore.init() in parallel
//   5. runApp(TdbApp(...))
//
// Firebase must be initialized ONCE here and NEVER again.
// ════════════════════════════════════════════════════════════

late final GameProgress progress;

Future<void> _bootFirebase() async {
  try {
    await Firebase.initializeApp();
  } catch (err) {
    tdbLog('[boot] Firebase init skipped: $err');
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
    tdbLog('[boot] AppCheck skipped: $err');
  }
}

Future<void> main() async {
  final sw = Stopwatch()..start();
  WidgetsFlutterBinding.ensureInitialized();

    await setOrientationsForLoadingScreens();
  final storage = await StorageService.create();
  progress = GameProgress(storage);
  await AudioService.init(progress);
  tdbLog('[boot] game module ready ${sw.elapsedMilliseconds}ms');

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // Firebase + UA warmup + vault — run in parallel for speed
  final firebaseFuture = _bootFirebase();
  final agentFuture    = tdbHttp.warmup();
  final vault          = TdbStore();
  final vaultFuture    = vault.init().catchError((err) {
    tdbLog('[boot] vault init failed: $err');
  });

  await firebaseFuture;
  tdbLog('[boot] firebase ready ${sw.elapsedMilliseconds}ms');
  await Future.wait([agentFuture, vaultFuture]);
  tdbLog('[boot] agent+vault ready ${sw.elapsedMilliseconds}ms');

  final probe    = TdbNet();
  final signal   = TdbAttr();
  final dispatch = TdbRequest(vault);
  final beacon   = TdbPush(vault);

  // Pre-fire push bootstrap in parallel with first frame render
  unawaited(beacon.bootstrap().catchError((err) {
    tdbLog('[boot] beacon pre-fire: $err');
  }));

  // Gate is enabled when at least one credential is provisioned.
  final tdbHubActive =
      tdbEndpoint().isNotEmpty || tdbAttrKey().isNotEmpty;

  tdbLog('[boot] tdbHubActive=$tdbHubActive  ${sw.elapsedMilliseconds}ms');

  runApp(TdbApp(
    vault: vault,
    probe: probe,
    signal: signal,
    dispatch: dispatch,
    beacon: beacon,
    tdbHubActive: tdbHubActive,
  ));
}
