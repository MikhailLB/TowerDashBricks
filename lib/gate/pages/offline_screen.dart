import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../infra/network_probe.dart';

class OfflineScreen extends StatefulWidget {
  final WidgetBuilder retryBuilder;
  final NetworkProbe probe;

  const OfflineScreen({
    super.key,
    required this.retryBuilder,
    required this.probe,
  });

  @override
  State<OfflineScreen> createState() => _OfflineScreenState();
}

class _OfflineScreenState extends State<OfflineScreen>
    with SingleTickerProviderStateMixin {
  bool _checking = false;
  bool _showHint = false;
  Timer? _hintTimeout;
  late final AnimationController _pressAnim;

  @override
  void initState() {
    super.initState();
    _pressAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 130),
    );
  }

  @override
  void dispose() {
    _hintTimeout?.cancel();
    _pressAnim.dispose();
    super.dispose();
  }

  Future<void> _attemptReconnect() async {
    if (_checking) return;
    HapticFeedback.lightImpact();
    await _pressAnim.forward();
    await _pressAnim.reverse();
    if (!mounted) return;
    setState(() => _checking = true);
    final online = await widget.probe.isOnline();
    if (!mounted) return;
    if (!online) {
      _hintTimeout?.cancel();
      setState(() { _checking = false; _showHint = true; });
      _hintTimeout = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => _showHint = false);
      });
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: widget.retryBuilder),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final landscape = mq.size.width > mq.size.height;
    final bgAsset = landscape
        ? 'assets/additional_assets/no_wifi/16x9_no_wifi_screen.webp'
        : 'assets/additional_assets/no_wifi/9x16_no_wifi_screen.webp';
    final btnW = landscape
        ? (mq.size.width * 0.24).clamp(200.0, 340.0)
        : (mq.size.width * 0.52).clamp(180.0, 300.0);
    final btnBottom = landscape ? mq.size.height * 0.05 : mq.size.height * 0.18;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(bgAsset, fit: BoxFit.cover,
              errorBuilder: (ctx, err, st) => const ColoredBox(color: Colors.black)),
          Positioned(
            left: 0, right: 0, bottom: btnBottom,
            child: Center(
              child: AnimatedBuilder(
                animation: _pressAnim,
                builder: (_, child) => Transform.scale(
                  scale: 1.0 - 0.05 * _pressAnim.value, child: child,
                ),
                child: GestureDetector(
                  onTap: _checking ? null : _attemptReconnect,
                  child: SizedBox(
                    width: btnW,
                    child: AspectRatio(
                      aspectRatio: 3.6,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          gradient: _checking
                              ? null
                              : const LinearGradient(
                                  colors: [Color(0xFF1E6FBF), Color(0xFF103D6E)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                          color: _checking ? const Color(0xFF1E6FBF).withValues(alpha: 0.3) : null,
                          border: Border.all(color: const Color(0xFF082E55), width: 3),
                        ),
                        child: Center(
                          child: _checking
                              ? const SizedBox(
                                  width: 24, height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.refresh_rounded,
                                        color: Colors.white, size: 26),
                                    SizedBox(width: 8),
                                    Text('Try Again',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.0,
                                        )),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: landscape ? Alignment.topCenter : Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: landscape ? 12 : 16,
                ),
                child: AnimatedOpacity(
                  opacity: _showHint ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 250),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Text(
                        'No connection — please check your network.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
