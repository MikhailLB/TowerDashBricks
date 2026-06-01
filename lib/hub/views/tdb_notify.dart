import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../cfg/tdb_config.dart';
import '../infra/tdb_push.dart';
import '../infra/tdb_net.dart';
import '../infra/tdb_store.dart';
import 'tdb_browser.dart';

/// Push permission offer screen. Shows a branded background image
/// (portrait or landscape) with Allow / Dismiss buttons styled in
/// blue/steel to match the TowerDash Bricks crane construction theme.
class TdbNotify extends StatefulWidget {
  final TdbStore vault;
  final TdbPush beacon;
  final TdbNet probe;
  final String destination;
  final bool coldStartPush;
  final Future<void> Function(String token)? onTokenReady;

  const TdbNotify({
    super.key,
    required this.vault,
    required this.beacon,
    required this.probe,
    required this.destination,
    this.coldStartPush = false,
    this.onTokenReady,
  });

  @override
  State<TdbNotify> createState() => _TdbNotifyState();
}

class _TdbNotifyState extends State<TdbNotify>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  bool _loading = false;
  late final AnimationController _pulse;
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
    _pulse = AnimationController(
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
    _pulse.dispose();
    _glow.dispose();
    super.dispose();
  }

  Future<void> _onAllow() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final granted = await widget.beacon.askConsent();
      if (granted) {
        final token = await widget.beacon.refreshTokenAfterConsent();
        if (token != null && token.isNotEmpty) {
          await widget.onTokenReady?.call(token);
        }
      } else {
        await _scheduleReminder();
      }
      _proceedToBrowser();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onDismiss() async {
    if (_loading) return;
    await _scheduleReminder();
    _proceedToBrowser();
  }

  Future<void> _scheduleReminder() async {
    final until = DateTime.now().millisecondsSinceEpoch ~/ 1000 +
        TdbConfig.pushCooldownSeconds;
    await widget.vault.writePushCooldown(until);
  }

  void _proceedToBrowser() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => TdbBrowser(
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
        ? 'assets/notice/notice_landscape.png'
        : 'assets/notice/notice_portrait.png';
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
                        _AllowButton(
                          width: btnW,
                          loading: _loading,
                          pulse: _pulse,
                          glow: _glow,
                          onTap: _onAllow,
                          compact: landscape,
                        ),
                        SizedBox(height: mq.size.height * 0.022),
                        _DismissButton(onTap: _onDismiss, compact: landscape),
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

// ── Blue/Steel Allow button — TowerDash Bricks crane construction theme ──
class _AllowButton extends StatefulWidget {
  final double width;
  final bool loading;
  final bool compact;
  final AnimationController pulse;
  final AnimationController glow;
  final VoidCallback onTap;
  const _AllowButton({
    required this.width, required this.loading, required this.pulse,
    required this.glow, required this.onTap, this.compact = false,
  });
  @override
  State<_AllowButton> createState() => _AllowButtonState();
}

class _AllowButtonState extends State<_AllowButton>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late final AnimationController _pressAnim = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 100),
  );
  @override
  void dispose() { _pressAnim.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final fontSize = widget.compact ? 16.0 : 20.0;
    return GestureDetector(
      onTapDown: (_) { setState(() => _pressed = true); _pressAnim.forward(); },
      onTapUp: (_) { setState(() => _pressed = false); _pressAnim.reverse(); widget.onTap(); },
      onTapCancel: () { setState(() => _pressed = false); _pressAnim.reverse(); },
      child: AnimatedBuilder(
        animation: Listenable.merge([_pressAnim, widget.glow]),
        builder: (_, child) => Transform.scale(
          scale: 1.0 - 0.04 * _pressAnim.value,
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
              child: widget.loading
                  ? SizedBox(
                      width: fontSize + 4, height: fontSize + 4,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text('Allow',
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

class _DismissButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool compact;
  const _DismissButton({required this.onTap, this.compact = false});
  @override
  State<_DismissButton> createState() => _DismissButtonState();
}

class _DismissButtonState extends State<_DismissButton> {
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
          child: Text('Not Now',
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
