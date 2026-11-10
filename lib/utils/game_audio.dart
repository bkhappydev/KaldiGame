import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';
import 'package:kaldi_app/utils/debug.dart';
import 'package:kaldi_app/utils/preference.dart';

/// All app audio: the looping background music plus the quiz sound effects.
///
/// Music only plays while the app is in the foreground. It pauses as soon as
/// the app is backgrounded (home button, switching apps, screen off) and
/// picks up again on return if the player has music turned on.
class GameAudio {
  GameAudio._();

  /// Background track, relative to `assets/`. Drop a new file into
  /// `assets/sounds/` and point this at it to change the music.
  static const String musicAsset = 'sounds/background_music.ogg';
  static const String correctAsset = 'sounds/correct.wav';
  static const String wrongAsset = 'sounds/wrong.wav';

  /// Music sits under the sound effects so the answer feedback stands out.
  static const double _musicVolume = 0.45;
  static const double _sfxVolume = 1.0;

  static final AudioPlayer _music = AudioPlayer(playerId: 'background_music');
  static final AudioPlayer _correct = AudioPlayer(playerId: 'sfx_correct');
  static final AudioPlayer _wrong = AudioPlayer(playerId: 'sfx_wrong');

  static Future<void>? _initFuture;
  static bool _inForeground = true;

  static bool get musicEnabled =>
      Preference.shared.getBool(Preference.isMusic) ?? true;

  // iOS: the ambient category mixes with other apps, respects the silent
  // switch and is silenced automatically when the app goes to background.
  static AudioContextIOS get _iosContext =>
      AudioContextIOS(category: AVAudioSessionCategory.ambient);

  static Future<void> init() => _initFuture ??= _init();

  static Future<void> _init() async {
    try {
      // Music takes audio focus, so if another app starts playing audio
      // (video, call, music app) Android pauses ours instead of mixing.
      await _music.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.game,
            audioFocus: AndroidAudioFocus.gain,
          ),
          iOS: _iosContext,
        ),
      );
      await _music.setReleaseMode(ReleaseMode.loop);
      await _music.setVolume(_musicVolume);
      await _music.setSource(AssetSource(musicAsset));

      // Effects must not request focus: that would make Android pause the
      // music every time a chime plays.
      for (final (AudioPlayer player, String asset) in [
        (_correct, correctAsset),
        (_wrong, wrongAsset),
      ]) {
        await player.setAudioContext(
          AudioContext(
            android: const AudioContextAndroid(
              contentType: AndroidContentType.sonification,
              usageType: AndroidUsageType.game,
              audioFocus: AndroidAudioFocus.none,
            ),
            iOS: _iosContext,
          ),
        );
        // Keep the clip loaded after it finishes so replays are instant.
        await player.setReleaseMode(ReleaseMode.stop);
        await player.setVolume(_sfxVolume);
        await player.setSource(AssetSource(asset));
      }
    } catch (e) {
      Debug.printLog('GameAudio init failed: $e');
    }
  }

  /// Starts (or resumes) the music if it is enabled and the app is visible.
  static Future<void> startMusic() async {
    await init();
    if (!musicEnabled || !_inForeground) return;
    try {
      if (_music.state != PlayerState.playing) {
        await _music.resume();
      }
      // The app may have been backgrounded while resume() was in flight.
      if (!_inForeground || !musicEnabled) await _music.pause();
    } catch (e) {
      Debug.printLog('GameAudio startMusic failed: $e');
    }
  }

  /// Music volume while the narrator is talking, so spoken questions for
  /// blind and low-vision children stay easy to hear.
  static const double _duckedVolume = 0.08;

  /// Turns the music down (true) or back up (false) around narration.
  static Future<void> duckMusic(bool duck) async {
    await init();
    try {
      await _music.setVolume(duck ? _duckedVolume : _musicVolume);
    } catch (e) {
      Debug.printLog('GameAudio duckMusic failed: $e');
    }
  }

  static Future<void> pauseMusic() async {
    await init();
    try {
      await _music.pause();
    } catch (e) {
      Debug.printLog('GameAudio pauseMusic failed: $e');
    }
  }

  /// Saves the music on/off choice and applies it straight away.
  static Future<void> setMusicEnabled(bool enabled) async {
    await Preference.shared.setBool(Preference.isMusic, enabled);
    if (enabled) {
      await startMusic();
    } else {
      await pauseMusic();
    }
  }

  /// Call from [WidgetsBindingObserver.didChangeAppLifecycleState].
  static void onAppLifecycleChanged(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _inForeground = true;
        startMusic();
      case AppLifecycleState.inactive:
        // Brief interruptions (notification shade, system dialogs) while the
        // app is still on screen: keep playing.
        break;
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _inForeground = false;
        pauseMusic();
        _correct.stop();
        _wrong.stop();
    }
  }

  static Future<void> playCorrect() => _playEffect(_correct);

  static Future<void> playWrong() => _playEffect(_wrong);

  static Future<void> _playEffect(AudioPlayer player) async {
    await init();
    if (!_inForeground) return;
    try {
      // stop() rewinds, so a quick second answer restarts the clip.
      await player.stop();
      await player.resume();
    } catch (e) {
      Debug.printLog('GameAudio effect failed: $e');
    }
  }
}
