import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../../core/white_part.dart';
import '../infra/brick_dispatch.dart';
import '../infra/tap_bridge.dart';
import '../infra/brick_beacon.dart';
import '../infra/network_probe.dart';
import '../infra/brick_vault.dart';
import '../infra/brick_signal.dart';
import '../models/app_mode.dart';
import 'brick_browser.dart';
import 'offline_screen.dart';
import 'notify_screen.dart';

enum _LoadStep { empty, midway, done }

/// ★ Core gray gate screen for TowerDash Bricks. Shows loading splash video
/// while running the attribution + config pipeline, then routes to WebView
/// (gray) or the game (white).
class BrickGateLoader extends StatefulWidget {
  final BrickVault vault;
  final NetworkProbe probe;
  final BrickSignal signal;
  final BrickDispatch dispatch;
  final BrickBeacon beacon;

  const BrickGateLoader({
    super.key,
    required this.vault,
    required this.probe,
    required this.signal,
    required this.dispatch,
    required this.beacon,
  });

  @override
  State<BrickGateLoader> createState() => _BrickGateLoaderState();
}

class _BrickGateLoaderState extends State<BrickGateLoader> {
  VideoPlayerController? _vid;
  bool _vidReady = false;
  _LoadStep _step = _LoadStep.empty;
  bool _navigated = false;
  Orientation? _lastOrientation;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp, DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight,
    ]);
    _boot();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final o = MediaQuery.of(context).orientation;
    if (o != _lastOrientation) { _lastOrientation = o; _switchVideo(o); }
  }

  Future<void> _switchVideo(Orientation o) async {
    final asset = o == Orientation.landscape
        ? 'assets/splash/16x9_loading_screen.mp4'
        : 'assets/splash/9x16_loading_screen.mp4';
    final old = _vid;
    final ctrl = VideoPlayerController.asset(asset);
    try {
      await ctrl.initialize();
      ctrl.setLooping(true);
      ctrl.setVolume(0);
      ctrl.play();
      if (!mounted) { ctrl.dispose(); return; }
      setState(() { _vid = ctrl; _vidReady = true; });
      old?.dispose();
    } catch (_) {
      ctrl.dispose();
    }
  }

  void _setStep(_LoadStep s) { if (mounted) setState(() => _step = s); }

  Future<void> _boot() async {
    widget.beacon.onTokenRefresh = _onTokenRefresh;

    // ── HIGHEST PRIORITY: SceneDelegate cold-start URL ─────────────────
    // When the app is KILLED and the user taps a push notification, iOS
    // delivers the tap through SceneDelegate.scene(_:willConnectTo:options:)
    // BEFORE any Dart code runs. Firebase's getInitialMessage() does NOT
    // receive this tap on scene-based apps (flutterfire#8896). SceneDelegate
    // writes the URL to UserDefaults under flutter.tdb_gate_tap_url.
    // We read and clear it HERE — before push bootstrap, before network check,
    // before attribution — so the URL is NEVER lost to a timeout race.
    final nativeColdUrl = await TapBridge.consumeTapUrl();
    if (nativeColdUrl != null && nativeColdUrl.isNotEmpty) {
      debugPrint('[TDB.GL] native cold-start url → $nativeColdUrl');
      await widget.vault.writeMode(AppMode.web);
      await widget.vault.consumeOneShotUrl();
      unawaited(_dispatchBackground());
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _goContent(nativeColdUrl);
      });
      return;
    }

    _setStep(_LoadStep.empty);
    final mode = widget.vault.readMode();

    switch (mode) {
      case AppMode.web:
        _setStep(_LoadStep.midway);
        final pushFuture = widget.beacon.bootstrap().catchError((_) {});
        await _handleWebMode(pushFuture: pushFuture);
        break;
      case AppMode.game:
        _setStep(_LoadStep.midway);
        unawaited(widget.beacon.bootstrap().catchError((_) {}));
        final recovered = await _tryRecoverWebMode();
        if (recovered) return;
        _setStep(_LoadStep.done);
        await Future.delayed(const Duration(milliseconds: 600));
        _goGame();
        break;
      case AppMode.fresh:
        await widget.beacon.bootstrap().catchError((_) {});
        await _handleFreshMode();
        break;
    }
  }

  @override
  void dispose() {
    widget.beacon.onTokenRefresh = null;
    _vid?.dispose();
    super.dispose();
  }

  Future<void> _dispatchBackground() async {
    try {
      await Future.wait([
        widget.beacon.bootstrap().catchError((_) {}),
        widget.signal.warmup().catchError((_) {}),
      ]);
      await Future.wait([
        widget.signal.awaitConversion(timeout: const Duration(seconds: 6)),
        widget.signal.awaitDeepLink(),
      ]);
      final body = await widget.signal.buildPayload(
        locale: Platform.localeName.replaceAll('-', '_'),
        pushToken: widget.beacon.token,
      );
      await widget.dispatch.send(body);
    } catch (e) {
      debugPrint('[TDB.GL] background dispatch error: $e');
    }
  }

  void _onTokenRefresh(String token) async {
    final locale = Platform.localeName.replaceAll('-', '_');
    final body = await widget.signal.buildPayload(
      locale: locale, pushToken: token,
    );
    widget.dispatch.send(body);
  }

  Future<void> _handleFreshMode() async {
    _setStep(_LoadStep.empty);
    final online = await widget.probe.isOnline();
    if (!online) { if (mounted) _goOffline(fresh: true); return; }

    _setStep(_LoadStep.midway);
    await widget.signal.warmup();
    await Future.wait([
      widget.signal.awaitConversion(),
      widget.signal.awaitDeepLink(),
    ]);
    final locale = Platform.localeName.replaceAll('-', '_');
    final body = await widget.signal.buildPayload(
      locale: locale, pushToken: widget.beacon.token,
    );
    final reply = await widget.dispatch.send(body);

    if (reply.granted && reply.destination != null) {
      await widget.vault.writeMode(AppMode.web);
      _setStep(_LoadStep.done);
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      _goContent(reply.destination!);
    } else {
      await widget.vault.writeMode(AppMode.game);
      _setStep(_LoadStep.done);
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      _goGame();
    }
  }

  Future<void> _handleWebMode({Future<void>? pushFuture}) async {
    final netFuture = widget.probe.isOnline();
    if (pushFuture != null) await Future.wait([netFuture, pushFuture]);
    final online = await netFuture;

    if (!online) {
      _setStep(_LoadStep.done);
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) _goOffline(fresh: false);
      return;
    }

    final oneShotUrl = await widget.vault.consumeOneShotUrl();
    if (oneShotUrl != null) {
      _setStep(_LoadStep.done);
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) _goContent(oneShotUrl);
      return;
    }

    final signalFuture = widget.signal.warmup();
    final savedUrl = await widget.vault.readSavedUrl();
    await signalFuture;
    await Future.wait([
      widget.signal.awaitConversion(timeout: const Duration(seconds: 5)),
      widget.signal.awaitDeepLink(),
    ]);
    final locale = Platform.localeName.replaceAll('-', '_');
    final body = await widget.signal.buildPayload(
      locale: locale, pushToken: widget.beacon.token,
    );
    final reply = await widget.dispatch.send(body);

    _setStep(_LoadStep.done);
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    if (reply.granted && reply.destination != null) {
      _goContent(reply.destination!);
      return;
    }
    if (savedUrl != null) {
      _goContent(savedUrl);
    } else {
      _goOffline(fresh: false);
    }
  }

  Future<bool> _tryRecoverWebMode() async {
    final online = await widget.probe.isOnline();
    if (!online) return false;
    await widget.signal.warmup();
    await Future.wait([
      widget.signal.awaitConversion(timeout: const Duration(seconds: 8)),
      widget.signal.awaitDeepLink(),
    ]);
    final locale = Platform.localeName.replaceAll('-', '_');
    final body = await widget.signal.buildPayload(
      locale: locale, pushToken: widget.beacon.token,
    );
    final reply = await widget.dispatch.send(body);
    if (!(reply.granted && reply.destination != null)) return false;
    await widget.vault.writeMode(AppMode.web);
    _setStep(_LoadStep.done);
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return true;
    _goContent(reply.destination!);
    return true;
  }

  void _goContent(String url, {bool coldStartPush = false}) {
    if (_navigated) return;
    _navigated = true;
    if (widget.vault.needsPushPrompt()) {
      widget.beacon.shouldOfferConsent().then((canAsk) {
        if (!mounted) return;
        if (canAsk) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (_) => NotifyScreen(
              vault: widget.vault,
              beacon: widget.beacon,
              probe: widget.probe,
              destination: url,
              coldStartPush: coldStartPush,
              onTokenReady: (token) async {
                final locale = Platform.localeName.replaceAll('-', '_');
                final body = await widget.signal.buildPayload(
                  locale: locale, pushToken: token,
                );
                widget.dispatch.send(body);
              },
            ),
          ));
        } else {
          _directBrowser(url, coldStartPush: coldStartPush);
        }
      });
    } else {
      _directBrowser(url, coldStartPush: coldStartPush);
    }
  }

  void _directBrowser(String url, {bool coldStartPush = false}) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => BrickBrowser(
        destination: url,
        vault: widget.vault,
        beacon: widget.beacon,
        probe: widget.probe,
        coldStartPush: coldStartPush,
      ),
    ));
  }

  void _goGame() {
    if (_navigated) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const WhiteGameEntry()),
    );
  }

  void _goOffline({required bool fresh}) {
    if (_navigated) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => OfflineScreen(
        probe: widget.probe,
        retryBuilder: (_) => BrickGateLoader(
          vault: widget.vault,
          probe: widget.probe,
          signal: widget.signal,
          dispatch: widget.dispatch,
          beacon: widget.beacon,
        ),
      ),
    ));
  }

  String _barAsset() {
    switch (_step) {
      case _LoadStep.empty:  return 'assets/splash/tdb_bar_1.webp';
      case _LoadStep.midway: return 'assets/splash/tdb_bar_2.webp';
      case _LoadStep.done:   return 'assets/splash/tdb_bar_4.webp';
    }
  }

  @override
  Widget build(BuildContext context) {
    final barAsset = _barAsset();
    final mq = MediaQuery.of(context);
    final landscape = mq.orientation == Orientation.landscape;
    final barW = landscape
        ? (mq.size.height * 0.35).clamp(0.0, 160.0)
        : (mq.size.width * 0.70).clamp(0.0, 340.0);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Colors.black),
          AnimatedOpacity(
            opacity: _vidReady ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 400),
            child: _vid != null && _vidReady
                ? SizedBox.expand(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _vid!.value.size.width,
                        height: _vid!.value.size.height,
                        child: VideoPlayer(_vid!),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          if (_vidReady)
            Positioned(
              left: 0, right: 0,
              bottom: landscape ? 0 : mq.padding.bottom,
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Image.asset(
                    barAsset,
                    key: ValueKey(barAsset),
                    width: barW,
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                    errorBuilder: (ctx, e, st) => const SizedBox(height: 32),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
