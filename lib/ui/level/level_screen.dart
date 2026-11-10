import 'dart:math';
import 'dart:ui' show ImageFilter;

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:kaldi_app/accessibility/narrator.dart';
import 'package:kaldi_app/common/banner/game_banner.dart';
import 'package:kaldi_app/localization/language/languages.dart';
import 'package:kaldi_app/common/coffee3d/coffee_3d.dart';
import 'package:kaldi_app/common/effects/bouncy_button.dart';
import 'package:kaldi_app/common/effects/icon_tile.dart';
import 'package:kaldi_app/common/effects/icon_motion.dart';
import 'package:kaldi_app/common/effects/motion.dart';
import 'package:kaldi_app/data/quiz_catalog.dart';
import 'package:kaldi_app/database/database_helper.dart';
import 'package:kaldi_app/database/tables/level_table.dart';
import 'package:kaldi_app/ui/category/category_screen.dart';
import 'package:kaldi_app/utils/color.dart';

/// Home screen: the quiz categories. Tapping a card opens [CategoryScreen]
/// with only that category's quizzes.
class LevelScreen extends StatefulWidget {
  const LevelScreen({super.key});

  @override
  LevelScreenState createState() => LevelScreenState();
}

class LevelScreenState extends State<LevelScreen> {
  Map<int, double> _scores = {};

  bool _opening = false;

  @override
  void initState() {
    super.initState();
    _loadScores();
    DataBaseHelper.scoresChanged.addListener(_loadScores);
  }

  @override
  void dispose() {
    DataBaseHelper.scoresChanged.removeListener(_loadScores);
    super.dispose();
  }

  Future<void> _loadScores() async {
    final List<LevelTable> levels = await DataBaseHelper().getLevelData();
    if (kDebugMode) QuizCatalog.debugValidate(levels.length);
    if (!mounted) return;
    setState(() {
      _scores = {for (final l in levels) l.level!: l.score ?? 0};
    });
  }

  int _doneIn(QuizCategory c) =>
      c.quizzes.where((q) => (_scores[q.level] ?? 0) >= kQuizDoneScore).length;

  @override
  Widget build(BuildContext context) {
    // Back handling and the exit popup live in MainShell (this is its first
    // tab), as do the music and settings controls.
    // No title bar: the category cards start right under the status bar.
    return CoffeeBackdrop(
      child: SafeArea(bottom: false, child: _categoryGrid()),
    );
  }

  /// Rows of category cards between two banners.
  static const int _rowsPerBanner = 1;

  Widget _categoryGrid() {
    const List<QuizCategory> categories = QuizCatalog.categories;
    final int total = categories.length;
    final Size size = MediaQuery.sizeOf(context);
    final int columns = size.width > size.height ? 3 : 2;
    final int perBlock = columns * _rowsPerBanner;
    final String lang = Localizations.localeOf(context).languageCode;

    final List<Widget> slivers = [
      const SliverToBoxAdapter(child: SizedBox(height: 20)),
    ];
    int bannerIndex = 0;

    for (int start = 0; start < total; start += perBlock) {
      final int end = (start + perBlock) < total ? start + perBlock : total;
      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: 18,
              crossAxisSpacing: 18,
              childAspectRatio: 0.82,
            ),
            delegate: SliverChildBuilderDelegate((context, i) {
              final int index = start + i;
              final QuizCategory c = categories[index];
              return AnimationConfiguration.staggeredGrid(
                columnCount: columns,
                position: index,
                duration: const Duration(milliseconds: 300),
                child: ScaleAnimation(
                  scale: 0.8,
                  child: CategoryCard(
                    category: c,
                    name: c.nameFor(lang),
                    done: _doneIn(c),
                    onTap: () {
                      Narrator.narrate(context, (s, l) => c.nameFor(l));
                      _openCategory(c);
                    },
                  ),
                ),
              );
            }, childCount: end - start),
          ),
        ),
      );

      // Banners separate blocks; none after the last row.
      if (end < total) {
        final GameBannerItem item =
            kBannerRotation[bannerIndex % kBannerRotation.length];
        bannerIndex++;
        slivers.add(
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: GameBanner.fromItem(item),
            ),
          ),
        );
      }
    }

    // Clear the floating bottom bar.
    slivers.add(
      SliverToBoxAdapter(
        child: SizedBox(height: 20 + MediaQuery.paddingOf(context).bottom),
      ),
    );
    return AnimationLimiter(child: CustomScrollView(slivers: slivers));
  }

  Future<void> _openCategory(QuizCategory category) async {
    if (_opening) return;
    _opening = true;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CategoryScreen(category: category),
      ),
    );
    _opening = false;
  }
}

/// A category on the home screen, in the shared cream-ceramic card style:
/// the category colour only tints the plate behind the cover picture.
class CategoryCard extends StatelessWidget {
  final QuizCategory category;
  final String name;
  final int done;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.category,
    required this.name,
    required this.done,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool complete = done == category.count;
    final Color accent = category.colors.last;
    return Semantics(
      button: true,
      label:
          '$name, ${Languages.of(context)!.a11yProgress(done, category.count)}',
      excludeSemantics: true,
      onTap: onTap,
      child: BouncyButton(
        onTap: onTap,
        child: LayoutBuilder(
          builder: (context, box) {
            final double w = box.maxWidth;
            // The picture plate sits across the card's top edge: its top
            // half pokes out above the card, its bottom half is inside.
            final double plateW = w * 0.80;
            final double plateH = min(plateW * 0.80, box.maxHeight * 0.52);
            final double overhang = plateH / 2;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  top: overhang,
                  child: _body(overhang),
                ),
                Positioned(
                  top: 0,
                  left: (w - plateW) / 2,
                  width: plateW,
                  height: plateH,
                  child: _plate(accent, plateW, plateH),
                ),
                if (complete)
                  Positioned(
                    top: -8,
                    left: (w - plateW) / 2 - 8,
                    child: const PopIn(
                      child: Icon(
                        Icons.emoji_events_rounded,
                        color: CoffeePalette.gold,
                        size: 32,
                        shadows: [
                          Shadow(
                            color: CoffeePalette.cinnamon,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// The cream card: room for the plate's lower half, then the name and the
  /// progress bar.
  Widget _body(double overhang) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [CoffeePalette.foam, CoffeePalette.crema],
        ),
        border: Border.all(color: CoffeePalette.caramel, width: 3),
        boxShadow: [
          // Solid cinnamon edge under the card = its 3D thickness.
          const BoxShadow(
            color: CoffeePalette.cinnamon,
            offset: Offset(0, 7),
          ),
          BoxShadow(
            color: Colur.black.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 11),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(10, overhang + 6, 10, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Center(
              child: AutoSizeText(
                name,
                maxLines: 2,
                minFontSize: 12,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: CoffeePalette.roast,
                  fontSize: 17,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: CategoryProgressBar(
                  done: done,
                  total: category.count,
                ),
              ),
              const SizedBox(width: 8),
              StarProgressLabel(done: done, total: category.count),
            ],
          ),
        ],
      ),
    );
  }

  /// The flat rounded tile with the moving 3D picture, sitting on the
  /// card's top edge.
  Widget _plate(Color accent, double w, double h) {
    final double size = min(w, h) * 0.84;
    return IconTile(
      accent: accent,
      child: MovingIcon(
        motion: MovingIcon.forCategory(category.id),
        size: size,
        child: _ShadowedIcon(name: category.icon3d, size: size),
      ),
    );
  }
}

/// A 3D picture with a soft drop shadow underneath, so it stands out
/// clearly from the coloured glass tile behind it.
class _ShadowedIcon extends StatelessWidget {
  final String name;
  final double size;

  const _ShadowedIcon({required this.name, required this.size});

  @override
  Widget build(BuildContext context) {
    final Widget icon = Icon3D(name, size: size);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Transform.translate(
          offset: Offset(0, size * 0.05),
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colur.black.withValues(alpha: 0.35),
                BlendMode.srcIn,
              ),
              child: icon,
            ),
          ),
        ),
        icon,
      ],
    );
  }
}
