import 'package:flutter/foundation.dart';
import 'package:kaldi_app/database/database_helper.dart';
import 'package:kaldi_app/rewards/treats.dart';
import 'package:kaldi_app/utils/preference.dart';

/// Tracks the child's stars, player level and won treats.
///
/// Stars are the child's best result per quiz, so replaying a quiz badly never
/// takes rewards away. Every [starsPerGift] stars levels the child up and
/// earns one gift box to open.
class RewardStore extends ChangeNotifier {
  RewardStore._();

  static final RewardStore instance = RewardStore._();

  static const int starsPerGift = 5;

  static const String _bestStarsKey = 'REWARD_BEST_STARS';
  static const String _giftsOpenedKey = 'REWARD_GIFTS_OPENED';

  /// Best stars (0-3) per quiz level, keyed by level number.
  final Map<int, int> _bestStars = {};
  int _giftsOpened = 0;
  bool _loaded = false;

  /// Stars for a 0-1 quiz score. Same thresholds as the result screen.
  static int starsForScore(double score) {
    if (score >= 0.9) return 3;
    if (score >= 0.6) return 2;
    if (score >= 0.2) return 1;
    return 0;
  }

  int starsFor(int level) => _bestStars[level] ?? 0;

  int get totalStars => _bestStars.values.fold(0, (a, b) => a + b);

  int get maxStars => _bestStars.length * 3;

  /// Quizzes passed with at least one star.
  int get quizzesDone => _bestStars.values.where((s) => s > 0).length;

  int get quizCount => _bestStars.length;

  /// Player level, starting at 1. Goes up every [starsPerGift] stars.
  int get playerLevel => 1 + totalStars ~/ starsPerGift;

  /// Stars collected toward the next level / gift (0 .. starsPerGift-1).
  int get starsTowardNext => totalStars % starsPerGift;

  int get giftsEarned => totalStars ~/ starsPerGift;

  int get giftsOpened => _giftsOpened;

  int get pendingGifts => (giftsEarned - _giftsOpened).clamp(0, 1 << 20);

  /// How many of [treat] the child has won so far.
  int countOf(Treat treat) {
    int count = 0;
    for (int i = 0; i < _giftsOpened; i++) {
      if (Treats.forGift(i).id == treat.id) count++;
    }
    return count;
  }

  int get distinctTreats => Treats.all.where((t) => countOf(t) > 0).length;

  /// Loads saved progress. The first time, it starts from the scores already
  /// in the database, so children who played before get their gifts too.
  Future<void> load() async {
    if (_loaded) return;
    final levels = await DataBaseHelper().getLevelData();
    final String? saved = Preference.shared.getString(_bestStarsKey);
    final Map<int, int> savedStars = _decode(saved);

    _bestStars.clear();
    for (final level in levels) {
      final int number = level.level ?? 0;
      if (number <= 0) continue;
      final int fromDb = starsForScore(level.score ?? 0);
      final int fromSave = savedStars[number] ?? 0;
      _bestStars[number] = fromDb > fromSave ? fromDb : fromSave;
    }
    _giftsOpened = Preference.shared.getInt(_giftsOpenedKey) ?? 0;
    _loaded = true;
    await _save();
    notifyListeners();
  }

  /// Records a finished quiz. Returns how many new gifts it earned (0 if the
  /// child did not beat their best on that quiz).
  Future<int> recordResult(int level, double score) async {
    await load();
    final int before = giftsEarned;
    final int stars = starsForScore(score);
    if (stars > starsFor(level)) {
      _bestStars[level] = stars;
      await _save();
      notifyListeners();
    }
    return giftsEarned - before;
  }

  /// Opens the next waiting gift and returns the treat inside, or null if
  /// there is nothing to open.
  Future<Treat?> openGift() async {
    await load();
    if (pendingGifts <= 0) return null;
    final Treat treat = Treats.forGift(_giftsOpened);
    _giftsOpened++;
    await Preference.shared.setInt(_giftsOpenedKey, _giftsOpened);
    notifyListeners();
    return treat;
  }

  Future<void> _save() => Preference.shared.setString(
        _bestStarsKey,
        _bestStars.entries.map((e) => '${e.key}:${e.value}').join(','),
      );

  static Map<int, int> _decode(String? raw) {
    final Map<int, int> out = {};
    if (raw == null || raw.isEmpty) return out;
    for (final part in raw.split(',')) {
      final List<String> kv = part.split(':');
      if (kv.length != 2) continue;
      final int? k = int.tryParse(kv[0]);
      final int? v = int.tryParse(kv[1]);
      if (k != null && v != null) out[k] = v.clamp(0, 3);
    }
    return out;
  }
}
