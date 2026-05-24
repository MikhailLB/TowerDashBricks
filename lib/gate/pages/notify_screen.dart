import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/brick_config.dart';
import '../infra/brick_beacon.dart';
import '../infra/network_probe.dart';
import '../infra/brick_vault.dart';
import 'brick_browser.dart';

/// Push permission offer screen. Shows a branded background image
/// (portrait or landscape) with Accept / Skip buttons styled in
/// blue/steel to match the TowerDash Bricks crane construction theme.
class NotifyScreen extends StatefulWidget {
  final BrickVault vault;
  final BrickBeacon beacon;
  final NetworkProbe probe;
  final String destination;
  final bool coldStartPush;
  final Future<void> Function(String token)? onTokenReady;

  const NotifyScreen({
    super.key,
    required this.vault,
    required this.beacon,
    required this.probe,
    required this.destination,
    this.coldStartPush = false,
    this.onTokenReady,
  });

  @override
  State<NotifyScreen> createState() => _NotifyScreenState();
}

class _NotifyScreenState extends State<NotifyScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  bool _busy = false;
  late final AnimationController _shimmer;
  late final AnimationController _glow;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _shimmer = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2200),
    )..repeat();
    _glow = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void didChangeMetrics() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _shimmer.dispose();
    _glow.dispose();
    super.dispose();
  }

  Future<void> _accept() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final granted = await widget.beacon.askConsent();
      if (granted) {
        final token = await widget.beacon.refreshTokenAfterConsent();
        if (token != null && token.isNotEmpty) {
          await widget.onTokenReady?.call(token);
        }
      } else {
        await _setCooldown();
      }
      _openBrowser();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _skip() async {
    if (_busy) return;
    await _setCooldown();
    _openBrowser();
  }

  Future<void> _setCooldown() async {
    final until = DateTime.now().millisecondsSinceEpoch ~/ 1000 +
        BrickConfig.pushCooldownSeconds;
    await widget.vault.writePushCooldown(until);
  }

  void _openBrowser() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => BrickBrowser(
        destination: widget.destination,
        vault: widget.vault,
        beacon: widget.beacon,
        probe: widget.probe,
        coldStartPush: widget.coldStartPush,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final landscape = mq.size.width > mq.size.height;
    final bgAsset = landscape
        ? 'assets/additional_assets/notifications/16x9_notification.webp'
        : 'assets/additional_assets/notifications/9x16_notification.webp';
    final btnW = landscape
        ? (mq.size.width * 0.30).clamp(220.0, 360.0)
        : mq.size.width * 0.76;
    final bottomGap = mq.size.height * (landscape ? 0.05 : 0.07);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(bgAsset, fit: BoxFit.cover,
                errorBuilder: (ctx, err, st) => const ColoredBox(color: Colors.black)),
            SafeArea(
              child: Stack(
                children: [
                  Positioned(
                    left: 0, right: 0, bottom: bottomGap,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _AcceptButton(
                          width: btnW,
                          busy: _busy,
                          shimmer: _shimmer,
                          glow: _glow,
                          onTap: _accept,
                          compact: landscape,
                        ),
                        SizedBox(height: mq.size.height * 0.022),
                        _SkipButton(onTap: _skip, compact: landscape),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Blue/Steel Accept button — matches TowerDash Bricks crane theme ───────
class _AcceptButton extends StatefulWidget {
  final double width;
  final bool busy;
  final bool compact;
  final AnimationController shimmer;
  final AnimationController glow;
  final VoidCallback onTap;
  const _AcceptButton({
    required this.width, required this.busy, required this.shimmer,
    required this.glow, required this.onTap, this.compact = false,
  });
  @override
  State<_AcceptButton> createState() => _AcceptButtonState();
}

class _AcceptButtonState extends State<_AcceptButton>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late final AnimationController _press = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 100),
  );
  @override
  void dispose() { _press.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final fontSize = widget.compact ? 16.0 : 20.0;
    return GestureDetector(
      onTapDown: (_) { setState(() => _pressed = true); _press.forward(); },
      onTapUp: (_) { setState(() => _pressed = false); _press.reverse(); widget.onTap(); },
      onTapCancel: () { setState(() => _pressed = false); _press.reverse(); },
      child: AnimatedBuilder(
        animation: Listenable.merge([_press, widget.glow]),
        builder: (_, child) => Transform.scale(
          scale: 1.0 - 0.04 * _press.value,
          child: Container(
            width: widget.width,
            padding: EdgeInsets.symmetric(vertical: widget.compact ? 12 : 17),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _pressed
                    ? [const Color(0xFF0D4E8A), const Color(0xFF082E55)]
                    : [const Color(0xFF1E6FBF), const Color(0xFF103D6E)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E6FBF)
                      .withValues(alpha: _pressed ? 0.2 : 0.3 + 0.2 * widget.glow.value),
                  blurRadius: _pressed ? 6 : 16 + widget.glow.value * 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: widget.busy
                  ? SizedBox(
                      width: fontSize + 4, height: fontSize + 4,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text('Accept',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: fontSize,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      )),
            ),
          ),
        ),
      ),
    );
  }
}

class _SkipButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool compact;
  const _SkipButton({required this.onTap, this.compact = false});
  @override
  State<_SkipButton> createState() => _SkipButtonState();
}

class _SkipButtonState extends State<_SkipButton> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedOpacity(
        opacity: _pressed ? 0.45 : 0.82,
        duration: const Duration(milliseconds: 80),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: widget.compact ? 4 : 8),
          child: Text('Skip',
              style: TextStyle(
                color: Colors.white,
                fontSize: widget.compact ? 16 : 22,
                fontWeight: FontWeight.w700,
                shadows: const [Shadow(color: Colors.black54, blurRadius: 6)],
              )),
        ),
      ),
    );
  }
}
