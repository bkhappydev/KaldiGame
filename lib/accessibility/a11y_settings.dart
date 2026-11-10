import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:kaldi_app/utils/preference.dart';

/// How fast the narrator talks. Rates are flutter_tts values, where 0.5 is
/// the platform's normal speed on both Android and iOS; young listeners get
/// a slightly slower "normal".
enum SpeechSpeed {
  slow(0.32),
  normal(0.42),
  fast(0.55);

  final double rate;
  const SpeechSpeed(this.rate);
}

/// Narration volume steps (flutter_tts volume, 0-1).
enum SpeechVolume {
  low(0.45),
  medium(0.75),
  high(1.0);

  final double value;
  const SpeechVolume(this.value);
}

/// Accessibility choices, saved on the device.
///
/// * [audioMode]: the audio quiz for blind and low-vision children. Questions
///   are spoken riddles instead of pictures, and answers are big numbered
///   buttons that are read aloud.
/// * [readAloud]: the normal picture quiz also reads questions, answers and
///   feedback aloud (handy for children who can't read yet). The audio quiz
///   always narrates.
class A11ySettings extends ChangeNotifier {
  A11ySettings._();

  static final A11ySettings instance = A11ySettings._();

  static const String _kAudioMode = 'A11Y_AUDIO_MODE';
  static const String _kReadAloud = 'A11Y_READ_ALOUD';
  static const String _kSpeed = 'A11Y_SPEED';
  static const String _kVolume = 'A11Y_VOLUME';
  static const String _kAppVoice = 'A11Y_APP_VOICE';

  /// Set once the app has reacted to a screen reader, so a parent who turns
  /// the audio quiz off again is not overruled next time.
  static const String _kScreenReaderSeen = 'A11Y_SCREEN_READER_SEEN';

  Preference get _pref => Preference.shared;

  bool get audioMode => _pref.getBool(_kAudioMode) ?? false;
  bool get readAloud => _pref.getBool(_kReadAloud) ?? false;

  /// Kaldi's own text-to-speech voice. Screen-reader users can switch it
  /// off so only their screen reader talks (it reads the same words from the
  /// labels and live announcements instead).
  bool get appVoice => _pref.getBool(_kAppVoice) ?? true;

  /// True when the app should speak at all.
  bool get narrationOn => audioMode || readAloud;

  SpeechSpeed get speed =>
      SpeechSpeed.values.asNameMap()[_pref.getString(_kSpeed)] ??
      SpeechSpeed.normal;

  SpeechVolume get volume =>
      SpeechVolume.values.asNameMap()[_pref.getString(_kVolume)] ??
      SpeechVolume.high;

  Future<void> setAudioMode(bool on) async {
    await _pref.setBool(_kAudioMode, on);
    notifyListeners();
  }

  Future<void> setReadAloud(bool on) async {
    await _pref.setBool(_kReadAloud, on);
    notifyListeners();
  }

  Future<void> setAppVoice(bool on) async {
    await _pref.setBool(_kAppVoice, on);
    notifyListeners();
  }

  Future<void> setSpeed(SpeechSpeed s) async {
    await _pref.setString(_kSpeed, s.name);
    notifyListeners();
  }

  Future<void> setVolume(SpeechVolume v) async {
    await _pref.setString(_kVolume, v.name);
    notifyListeners();
  }

  /// The first time a screen reader (TalkBack / VoiceOver) is found, switch
  /// the audio quiz on so a blind child doesn't need sighted help to find
  /// the setting. Returns true if it was switched on now.
  Future<bool> adoptScreenReader(bool screenReaderOn) async {
    if (!screenReaderOn || (_pref.getBool(_kScreenReaderSeen) ?? false)) {
      return false;
    }
    await _pref.setBool(_kScreenReaderSeen, true);
    if (audioMode) return false;
    await setAudioMode(true);
    return true;
  }

  /// Whether a screen reader is running: TalkBack or VoiceOver on phones, and
  /// JAWS, NVDA, Narrator or VoiceOver on desktops. Phones report it directly;
  /// on desktops Flutter only switches its accessibility tree on once a
  /// screen reader connects, so that is the signal there.
  static bool screenReaderOn(BuildContext context) {
    if (MediaQuery.accessibleNavigationOf(context)) return true;
    if (kIsWeb) return false;
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      return SemanticsBinding.instance.semanticsEnabled;
    }
    return false;
  }
}
