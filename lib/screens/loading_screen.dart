import 'dart:async';
import '../core/tdb_log.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';

import '../app/app_orientation.dart';
import '../app/tdb_assets.dart';
import 'main_menu_screen.dart';

/// Splash screen that plays a looping promo video and shows a 4-state
/// loading bar while game assets warm up. Supports both portrait and
/// landscape orientations — picks the matching video automatically.
class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _portraitVideo;
  VideoPlayerController? _landscapeVideo;
  bool _videosReady = false;
  bool _showBar = false;
  bool _hasNavigated = false;

  VoidCallback? _portraitListener;
  VoidCallback? _landscapeListener;

  late final AnimationController _progressController;

  static const _minDuration = Duration(milliseconds: 6000);
  static const _barDelay = Duration(milliseconds: 120);
  static const _barDuration = Duration(milliseconds: 4500);

  @override
  void initState() {
    super.initState();
    setOrientationsForLoadingScreens();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _progressController = AnimationController(
      vsync: this,
      duration: _barDuration,
    );

    _initialise();
  }

  Future<void> _initialise() async {
    final start = DateTime.now();

    await _initVideos();
    if (!mounted) return;
    setState(() => _videosReady = true);

    await Future<void>.delayed(_barDelay);
    if (!mounted) return;
    setState(() => _showBar = true);

    final barFuture = _progressController.forward();
    final assetsFuture = _preloadGameAssets();

    await Future.wait([barFuture, assetsFuture]);

    final elapsed = DateTime.now().difference(start);
    if (elapsed < _minDuration) {
      await Future<void>.delayed(_minDuration - elapsed);
    }

    await Future<void>.delayed(const Duration(milliseconds: 300));
    _goToMenu();
  }

  Future<void> _initVideos() async {
    try {
      final portrait =
          VideoPlayerController.asset(TdbAssets.splashPortrait);
      final landscape =
          VideoPlayerController.asset(TdbAssets.splashLandscape);

      await Future.wait([portrait.initialize(), landscape.initialize()]);

      portrait.setLooping(true);
      landscape.setLooping(true);
      portrait.setVolume(0);
      landscape.setVolume(0);

      try {
        await portrait.play();
      } catch (e) {
        tdbLog('LoadingScreen: portrait play() failed: $e');
      }
      try {
        await landscape.play();
      } catch (e) {
        tdbLog('LoadingScreen: landscape play() failed: $e');
      }

      _portraitListener = () => _restartIfFinished(portrait);
      _landscapeListener = () => _restartIfFinished(landscape);
      portrait.addListener(_portraitListener!);
      landscape.addListener(_landscapeListener!);

      _portraitVideo = portrait;
      _landscapeVideo = landscape;
    } catch (e, st) {
      tdbLog('LoadingScreen: video init failed: $e\n$st');
    }
  }

  void _restartIfFinished(VideoPlayerController c) {
    final value = c.value;
    if (!value.isInitialized) return;
    if (value.isPlaying) return;
    if (value.position < value.duration) return;
    c.seekTo(Duration.zero);
    c.play();
  }

  void _kickIfNotPlaying(VideoPlayerController? c) {
    if (c == null) return;
    if (!c.value.isInitialized) return;
    if (c.value.isPlaying) return;
    c.play();
  }

  Future<void> _preloadGameAssets() async {
    final paths = <String>[
      TdbAssets.sky,
      TdbAssets.ground,
      TdbAssets.cloud,
      TdbAssets.crane,
      TdbAssets.cityBg,
      TdbAssets.base,
      TdbAssets.icon,
      TdbAssets.gameName,
      ...TdbAssets.allBricks,
      for (var i = 1; i <= 4; i++) TdbAssets.loadingBar(i),
    ];
    for (final p in paths) {
      if (!mounted) break;
      try {
        await precacheImage(AssetImage(p), context);
      } catch (e) {
        tdbLog('LoadingScreen: failed to preload $p: $e');
      }
    }
    try {
      GoogleFonts.robotoSlab();
      await GoogleFonts.pendingFonts(<TextStyle>[
        GoogleFonts.robotoSlab(),
      ]);
    } catch (e) {
      tdbLog('LoadingScreen: Google Fonts preload failed: $e');
    }
  }

  void _goToMenu() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondary) =>
            const MainMenuScreen(),
        transitionDuration: const Duration(milliseconds: 600),
        transitionsBuilder: (context, animation, secondary, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    if (_portraitListener != null) {
      _portraitVideo?.removeListener(_portraitListener!);
    }
    if (_landscapeListener != null) {
      _landscapeVideo?.removeListener(_landscapeListener!);
    }
    _portraitVideo?.dispose();
    _landscapeVideo?.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: OrientationBuilder(
        builder: (context, orientation) {
          final isPortrait = orientation == Orientation.portrait;
          final controller =
              isPortrait ? _portraitVideo : _landscapeVideo;
          if (controller != null && controller.value.isInitialized) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _kickIfNotPlaying(controller);
            });
          }
          return Stack(
            fit: StackFit.expand,
            children: [
              if (_videosReady &&
                  controller != null &&
                  controller.value.isInitialized)
                _FullCoverVideo(controller: controller)
              else
                Container(color: Colors.black),
              if (_showBar)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _progressController,
                      builder: (context, _) {
                        final p = _progressController.value;
                        final state =
                            (p * 4).clamp(0.0, 4.0).floor().clamp(1, 4);
                        return _LoadingBar(
                          state: state,
                          isPortrait: isPortrait,
                        );
                      },
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _FullCoverVideo extends StatelessWidget {
  const _FullCoverVideo({required this.controller});
  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: controller.value.size.width,
            height: controller.value.size.height,
            child: VideoPlayer(controller),
          ),
        ),
      ),
    );
  }
}

class _LoadingBar extends StatelessWidget {
  const _LoadingBar({required this.state, required this.isPortrait});
  final int state;
  final bool isPortrait;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = isPortrait ? size.width * 0.7 : size.height * 0.4;
    return Image.asset(
      TdbAssets.loadingBar(state),
      width: width,
      fit: BoxFit.contain,
      gaplessPlayback: true,
    );
  }
}
