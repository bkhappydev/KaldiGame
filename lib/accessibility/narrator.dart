import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:kaldi_app/accessibility/a11y_settings.dart';
import 'package:kaldi_app/localization/language/language_am.dart';
import 'package:kaldi_app/localization/language/language_en.dart';
import 'package:kaldi_app/localization/language/languages.dart';
import 'package:kaldi_app/utils/debug.dart';
import 'package:kaldi_app/utils/game_audio.dart';

/// Text-to-speech for the whole app, in Amharic and English.
///
/// Only one sentence is spoken at a time: every [say] cuts off whatever was
/// playing, so narration never overlaps or talks over itself. While a screen
/// reader (TalkBack / VoiceOver) is running the app stays quiet and lets the
/// screen reader speak the labels instead, because two voices at once are
/// impossible to follow.
class Narrator {
  Narrator._();

  static final Narrator instance = Narrator._();

  final FlutterTts _tts = FlutterTts();
  Future<void>? _initFuture;

  /// Whether the phone has an Amharic voice installed. Many Android phones
  /// don't ship one; then Amharic users hear English narration instead of
  /// silence (and Settings explains how to add the voice).
  bool amharicVoice = false;

  /// Bumped by every [say] / [stop]; a sentence only "finishes" if no newer
  /// one started meanwhile.
  int _token = 0;
  Completer<void>? _interrupt;
  String? _currentLanguage;

  Future<void> init() => _initFuture ??= _init();

  Future<void> _init() async {
    try {
      await _tts.awaitSpeakCompletion(true);
      if (Platform.isIOS) {
        // Play through the silent switch (a blind child can't see it) and
        // mix with the game music, which GameAudio turns down meanwhile.
        await _tts.setSharedInstance(true);
        await _tts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [
            IosTextToSpeechAudioCategoryOptions.mixWithOthers,
            IosTextToSpeechAudioCategoryOptions.duckOthers,
          ],
          IosTextToSpeechAudioMode.spokenAudio,
        );
      }
      amharicVoice = await _hasLanguage('am-ET') || await _hasLanguage('am');
      Debug.printLog('Narrator ready, Amharic voice: $amharicVoice');
      await _applySettings();
      A11ySettings.instance.addListener(_applySettings);
    } catch (e) {
      Debug.printLog('Narrator init failed: $e');
    }
  }

  Future<bool> _hasLanguage(String code) async {
    try {
      final dynamic ok = await _tts.isLanguageAvailable(code);
      return ok == true || ok == 1;
    } catch (_) {
      return false;
    }
  }

  Future<void> _applySettings() async {
    final A11ySettings s = A11ySettings.instance;
    await _tts.setSpeechRate(s.speed.rate);
    await _tts.setVolume(s.volume.value);
  }

  /// The language narration actually uses for an app in [appLanguage]:
  /// Amharic when a voice exists for it, otherwise English.
  String voiceLanguage(String appLanguage) =>
      appLanguage == 'am' && amharicVoice ? 'am' : 'en';

  /// UI strings in the narration language (see [voiceLanguage]).
  Languages strings(String appLanguage) =>
      voiceLanguage(appLanguage) == 'am' ? LanguageAm() : LanguageEn();

  /// Speaks [text] in [language] ('am' or 'en'), cutting off anything still
  /// playing. Completes when the sentence ends; returns false if it was
  /// interrupted by a newer [say] or by [stop].
  Future<bool> say(String text, {required String language}) async {
    final int token = ++_token;
    _interrupt?.complete();
    final Completer<void> interrupt = _interrupt = Completer<void>();
    await init();
    if (token != _token) return false;
    try {
      await _tts.stop();
      if (_currentLanguage != language) {
        await _tts.setLanguage(language == 'am' ? 'am-ET' : 'en-US');
        _currentLanguage = language;
      }
      if (token != _token) return false;
      if (kDebugMode) debugPrint('Narrator [$language]: $text');
      GameAudio.duckMusic(true);
      await Future.any([_tts.speak(text), interrupt.future]);
    } catch (e) {
      Debug.printLog('Narrator say failed: $e');
    } finally {
      if (token == _token) GameAudio.duckMusic(false);
    }
    return token == _token;
  }

  /// Silences the narrator straight away.
  Future<void> stop() async {
    _token++;
    _interrupt?.complete();
    _interrupt = null;
    GameAudio.duckMusic(false);
    try {
      await _tts.stop();
    } catch (_) {}
  }

  /// True when the app should speak for itself on this screen: narration and
  /// Kaldi's voice are switched on, and no screen reader (TalkBack,
  /// VoiceOver, JAWS, NVDA, Narrator) is talking already.
  static bool shouldSpeak(BuildContext context) =>
      A11ySettings.instance.narrationOn &&
      A11ySettings.instance.appVoice &&
      !A11ySettings.screenReaderOn(context);

  /// Speaks a sentence built in the narration language, if [shouldSpeak].
  /// `build` gets the strings and language code to use (Amharic falls back
  /// to English on phones without an Amharic voice).
  static Future<bool> narrate(
    BuildContext context,
    String Function(Languages strings, String language) build,
  ) async {
    if (!shouldSpeak(context)) return false;
    final String appLanguage = Localizations.localeOf(context).languageCode;
    await instance.init();
    final String language = instance.voiceLanguage(appLanguage);
    return instance.say(
      build(instance.strings(appLanguage), language),
      language: language,
    );
  }
}
