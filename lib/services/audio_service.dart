import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../state/game_progress.dart';

enum Sfx {
  buttonClick,
  blockLand,
  blockFall,
  levelComplete,
}

enum Bgm { menu, gameplay }

/// Global audio system — one looping BGM player and fire-and-forget SFX.
/// Initialise once in `main()` after [GameProgress] exists.
class AudioService with WidgetsBindingObserver {
  AudioService._(this._progress);

  static AudioService? _instance;
  static AudioService get instance {
    final i = _instance;
    if (i == null) {
      throw StateError('AudioService.init() must be called first');
    }
    return i;
  }

  static const _kMenuBgm = 'music/mainmenumusic.mp3';
  static const _kGameplayBgm = 'music/gameplaymusic.mp3';
  static const _kBlockFall = 'music/block_fall_sound.mp3';
  static const _kButtonClick = 'music/button-click-error.mp3';

  final GameProgress _progress;
  final AudioPlayer _bgm = AudioPlayer(playerId: 'tdb_bgm');
  Bgm? _currentBgm;
  bool _appInForeground = true;

  static Future<void> init(GameProgress progress) async {
    if (_instance != null) return;
    final svc = AudioService._(progress);
    _instance = svc;

    try {
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: false,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.none,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.ambient,
            options: const {AVAudioSessionOptions.mixWithOthers},
          ),
        ),
      );
    } catch (e) {
      debugPrint('AudioService: setAudioContext failed: $e');
    }

    await svc._bgm.setReleaseMode(ReleaseMode.loop);
    await svc._bgm.setVolume(progress.musicVolume);
    try {
      await svc._bgm.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: false,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.none,
          ),
        ),
      );
    } catch (e) {
      debugPrint('AudioService: bgm setAudioContext failed: $e');
    }
    progress.addListener(svc._onProgressChanged);
    WidgetsBinding.instance.addObserver(svc);
  }

  void _onProgressChanged() {
    if (_progress.musicEnabled && _appInForeground) {
      _bgm.setVolume(_progress.musicVolume);
      if (_currentBgm != null && _bgm.state != PlayerState.playing) {
        _bgm.resume();
      }
    } else {
      _bgm.pause();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final foreground = state == AppLifecycleState.resumed;
    if (foreground == _appInForeground) return;
    _appInForeground = foreground;
    if (!foreground) {
      _bgm.pause();
    } else if (_progress.musicEnabled && _currentBgm != null) {
      _bgm.resume();
    }
  }

  String _bgmPath(Bgm bgm) =>
      bgm == Bgm.menu ? _kMenuBgm : _kGameplayBgm;

  String _sfxPath(Sfx sfx) {
    switch (sfx) {
      case Sfx.buttonClick:
        return _kButtonClick;
      case Sfx.blockLand:
      case Sfx.blockFall:
        return _kBlockFall;
      case Sfx.levelComplete:
        return _kButtonClick;
    }
  }

  Future<void> playBgm(Bgm bgm) async {
    if (_currentBgm == bgm && _bgm.state == PlayerState.playing) return;
    _currentBgm = bgm;
    if (!_progress.musicEnabled || !_appInForeground) return;
    try {
      await _bgm.stop();
      await _bgm.setVolume(_progress.musicVolume);
      await _bgm.play(AssetSource(_bgmPath(bgm)));
    } catch (e) {
      debugPrint('AudioService: bgm play failed: $e');
    }
  }

  Future<void> stopBgm() async {
    _currentBgm = null;
    try {
      await _bgm.stop();
    } catch (_) {}
  }

  Future<void> playSfx(Sfx sfx) async {
    if (!_progress.soundEnabled) return;
    final player = AudioPlayer();
    try {
      await player.setReleaseMode(ReleaseMode.release);
      await player.setVolume(_progress.sfxVolume);
      await player.play(AssetSource(_sfxPath(sfx)));
      player.onPlayerComplete.first.then((_) => player.dispose());
    } catch (e) {
      debugPrint('AudioService: sfx play failed: $e');
      player.dispose();
    }
  }

  Future<void> vibrate({bool heavy = false}) async {
    if (!_progress.vibrationEnabled) return;
    if (heavy) {
      await HapticFeedback.heavyImpact();
    } else {
      await HapticFeedback.mediumImpact();
    }
  }
}
