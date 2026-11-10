import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:kaldi_app/database/tables/item_table.dart';
import 'package:kaldi_app/utils/debug.dart';

/// Spoken riddles that replace the quiz pictures in the audio quiz, one per
/// answer item, in English and Amharic (`assets/data/audio_clues.json`, keyed
/// by item_id). A riddle describes its item without naming it, and is
/// written to tell it apart from the other items in the same quiz.
class AudioClues {
  AudioClues._();

  static const String asset = 'assets/data/audio_clues.json';

  static Map<int, Map<String, String>> _clues = {};
  static Future<void>? _loading;

  static Future<void> load() => _loading ??= _load();

  static Future<void> _load() async {
    try {
      final Map<String, dynamic> raw =
          jsonDecode(await rootBundle.loadString(asset)) as Map<String, dynamic>;
      _clues = {
        for (final MapEntry<String, dynamic> e in raw.entries)
          int.parse(e.key): {
            for (final MapEntry<String, dynamic> t
                in (e.value as Map<String, dynamic>).entries)
              t.key: t.value as String,
          },
      };
    } catch (e) {
      Debug.printLog('AudioClues load failed: $e');
    }
  }

  /// The riddle for [item] in [language], or null if none was written.
  static String? clueFor(ItemTable item, String language) {
    final Map<String, String>? c = _clues[item.itemId];
    if (c == null) return null;
    return c[language] ?? c['en'];
  }

  /// First letter (English) or first fidel (Amharic, which is a whole
  /// syllable) of the answer's name: the "starts with ..." hint.
  static String firstSound(ItemTable item, String language) {
    final String name = item.nameFor(language).trim();
    if (name.isEmpty) return '';
    final String first = String.fromCharCode(name.runes.first);
    return language == 'en' ? first.toUpperCase() : first;
  }
}
