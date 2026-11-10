import 'package:flutter/material.dart';
import 'package:kaldi_app/common/coffee3d/coffee_3d.dart';
import 'package:kaldi_app/common/commonTopBar/common_topbar.dart';
import 'package:kaldi_app/common/effects/motion.dart';
import 'package:kaldi_app/data/quiz_catalog.dart';
import 'package:kaldi_app/localization/language/languages.dart';
import 'package:kaldi_app/rewards/reward_store.dart';
import 'package:kaldi_app/rewards/treats.dart';
import 'package:kaldi_app/ui/category/category_screen.dart';
import 'package:kaldi_app/ui/treats/treats_screen.dart';

/// "My Level": the child's player level, stars toward the next gift and
/// how far they are in each topic.
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Languages lang = Languages.of(context)!;
    final String code = Localizations.localeOf(context).languageCode;
    final RewardStore store = RewardStore.instance;

    return CoffeeBackdrop(
      child: ListenableBuilder(
        listenable: store,
        builder:
            (context, _) => ListView(
              padding: EdgeInsets.fromLTRB(
                20,
                0,
                20,
                24 + MediaQuery.paddingOf(context).bottom,
              ),
              children: [
                // The title scrolls away with the content.
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CommonTopBar(lang.txtProgress, null),
                ),
                // The quiz list's coffee-bean artwork with the player's
                // level on it; its stars fill up on the way to the next
                // gift.
                Semantics(
                  label: '${lang.txtLevel} ${store.playerLevel}',
                  excludeSemantics: true,
                  child: Center(
                    child: Float(
                      distance: 8,
                      child: _LevelBean(
                        level: store.playerLevel,
                        stars: _beanStars(store.starsTowardNext),
                      ),
                    ),
                  ),
                ),
                Center(
                  child: OutlinedGameText(
                    lang.txtLevel,
                    fontSize: 24,
                    fill: CoffeePalette.gold,
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: StarMeter(
                    value: store.starsTowardNext,
                    max: RewardStore.starsPerGift,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    lang.txtStarsToNextGift(
                      RewardStore.starsPerGift - store.starsTowardNext,
                    ),
                    style: TextStyle(
                      color: BackgroundTheme.of(context).onBackdrop,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      shadows: BackgroundTheme.of(context).textShadows,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    _StatTile(
                      image: 'ui_star',
                      value: '${store.totalStars}/${store.maxStars}',
                      label: lang.txtStars,
                    ),
                    const SizedBox(width: 10),
                    _StatTile(
                      image: 'ui_check',
                      value: '${store.quizzesDone}/${store.quizCount}',
                      label: lang.txtQuizzesDone,
                    ),
                    const SizedBox(width: 10),
                    _StatTile(
                      image: 'nav_treats',
                      value: '${store.distinctTreats}/${Treats.all.length}',
                      label: lang.txtTreatsCollected,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                for (final c in QuizCatalog.categories)
                  _CategoryRow(category: c, name: c.nameFor(code)),
              ],
            ),
      ),
    );
  }
}

/// Maps 0-4 stars toward the next gift onto the bean art's 0-3 stars.
int _beanStars(int towardNext) =>
    (towardNext * 3 / (RewardStore.starsPerGift - 1)).round().clamp(0, 3);

/// The level_item_X bean artwork (same as the quiz buttons) with a big
/// outlined number on it.
class _LevelBean extends StatelessWidget {
  final int level;
  final int stars;

  const _LevelBean({required this.level, required this.stars});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 230,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset("assets/images/level_item_$stars.webp"),
          Padding(
            padding: const EdgeInsets.only(bottom: 44),
            child: OutlinedGameText(
              '$level',
              fontSize: 64,
              strokeWidth: 10,
              fill: CoffeePalette.foam,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  /// Icon3D name.
  final String image;
  final String value;
  final String label;

  const _StatTile({
    required this.image,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        label: '$value $label',
        excludeSemantics: true,
        child: Coffee3DPanel(
          depth: 7,
          padding: const EdgeInsets.fromLTRB(6, 10, 6, 10),
          child: Column(
            children: [
              Icon3D(image, size: 40),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: const TextStyle(
                    fontFamily: kGameFont,
                    fontSize: 24,
                    color: CoffeePalette.roast,
                  ),
                ),
              ),
              SizedBox(
                height: 34,
                child: Center(
                  child: Text(
                    label,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.1,
                      fontWeight: FontWeight.w700,
                      color: CoffeePalette.mocha,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A topic's star progress, in the shared cream card style: the category's
/// 3D picture in an accent chip, its name, and the standard progress bar.
class _CategoryRow extends StatelessWidget {
  final QuizCategory category;
  final String name;

  const _CategoryRow({required this.category, required this.name});

  @override
  Widget build(BuildContext context) {
    final RewardStore store = RewardStore.instance;
    final int stars = category.quizzes.fold(
      0,
      (sum, q) => sum + store.starsFor(q.level),
    );
    final int max = category.count * 3;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Semantics(
        label: '$name, $stars / $max',
        excludeSemantics: true,
        child: Coffee3DPanel(
          depth: 6,
          padding: const EdgeInsets.fromLTRB(10, 8, 14, 10),
          child: Row(
            children: [
              Coffee3DIconButton(
                image: category.icon3d,
                color: category.colors.last,
                size: 48,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: CoffeePalette.roast,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: CategoryProgressBar(done: stars, total: max),
                        ),
                        const SizedBox(width: 8),
                        StarProgressLabel(done: stars, total: max),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
