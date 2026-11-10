import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:kaldi_app/accessibility/narrator.dart';
import 'package:kaldi_app/common/coffee3d/coffee_3d.dart';
import 'package:kaldi_app/common/commonTopBar/common_topbar.dart';
import 'package:kaldi_app/data/quiz_catalog.dart';
import 'package:kaldi_app/database/database_helper.dart';
import 'package:kaldi_app/database/tables/level_table.dart';
import 'package:kaldi_app/interfaces/topbar_clicklistener.dart';
import 'package:kaldi_app/localization/language/languages.dart';
import 'package:kaldi_app/ui/level/level_tile.dart';
import 'package:kaldi_app/ui/quiz/quiz_screen.dart';
import 'package:kaldi_app/utils/color.dart';
import 'package:kaldi_app/utils/constant.dart';

/// The quizzes of one category. Opened from a category card on the home
/// screen; Back returns to the categories.
class CategoryScreen extends StatefulWidget {
  final QuizCategory category;

  const CategoryScreen({super.key, required this.category});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen>
    implements TopBarClickListener {
  Map<int, double> _scores = {};

  /// Blocks a second quiz from opening on a fast double tap.
  bool _opening = false;

  QuizCategory get _category => widget.category;

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
    if (!mounted) return;
    setState(() {
      _scores = {for (final l in levels) l.level!: l.score ?? 0};
    });
  }

  double _scoreOf(int level) => _scores[level] ?? 0;

  int get _doneCount =>
      _category.quizzes
          .where((q) => _scoreOf(q.level) >= kQuizDoneScore)
          .length;

  /// First quiz without a star yet; it pulses.
  int get _nextIndex =>
      _category.quizzes.indexWhere((q) => _scoreOf(q.level) < kQuizDoneScore);

  Future<void> _openQuiz(int level) async {
    if (_opening) return;
    _opening = true;
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => QuizScreen(level: level)));
    _opening = false;
  }

  @override
  Widget build(BuildContext context) {
    final String lang = Localizations.localeOf(context).languageCode;
    return Scaffold(
      backgroundColor: BackgroundTheme.of(context).base,
      body: SafeArea(
        top: false,
        bottom: Platform.isAndroid,
        // Title, progress header and quiz grid scroll together.
        child: CoffeeBackdrop(child: _grid(context, lang)),
      ),
    );
  }

  /// "6 quizzes" plus a star count and progress bar for this category.
  Widget _header(BuildContext context) {
    final int done = _doneCount;
    final int total = _category.count;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      // Cream ceramic card; the category colour is only the icon chip.
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [CoffeePalette.foam, CoffeePalette.crema],
        ),
        border: Border.all(color: CoffeePalette.caramel, width: 3),
        boxShadow: [
          const BoxShadow(color: CoffeePalette.cinnamon, offset: Offset(0, 6)),
          BoxShadow(
            color: Colur.black.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        children: [
          Coffee3DIconButton(
            image: _category.icon3d,
            color: _category.colors.last,
            size: 46,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        Languages.of(context)!.quizCount(total),
                        style: const TextStyle(
                          color: CoffeePalette.roast,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    StarProgressLabel(done: done, total: total),
                  ],
                ),
                const SizedBox(height: 6),
                CategoryProgressBar(done: done, total: total),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _grid(BuildContext context, String lang) {
    final Size size = MediaQuery.sizeOf(context);
    final int columns = size.width > size.height ? 4 : 2;
    final int next = _nextIndex;
    return AnimationLimiter(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: CommonTopBar(
              _category.nameFor(lang),
              this,
              isShowBack: true,
            ),
          ),
          SliverToBoxAdapter(child: _header(context)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: 18,
                crossAxisSpacing: 23,
                // Room for the topic name under the tile artwork.
                childAspectRatio: 1.05,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final QuizInfo quiz = _category.quizzes[index];
                final int stars = _starsFor(_scoreOf(quiz.level));
                return AnimationConfiguration.staggeredGrid(
                  columnCount: columns,
                  position: index,
                  duration: const Duration(milliseconds: 250),
                  child: ScaleAnimation(
                    scale: 0.8,
                    // Read as one button: "Numbers, 2 ★".
                    child: Semantics(
                      button: true,
                      label:
                          '${quiz.nameFor(lang)}, ${Languages.of(context)!.a11yStars(stars)}',
                      excludeSemantics: true,
                      onTap: () => _openQuiz(quiz.level),
                      child: LevelTile(
                        number: index + 1,
                        title: quiz.nameFor(lang),
                        score: _scoreOf(quiz.level),
                        highlight: index == next,
                        onTap: () {
                          // Read the quiz name aloud when narration is on.
                          Narrator.narrate(context, (s, l) => quiz.nameFor(l));
                          _openQuiz(quiz.level);
                        },
                      ),
                    ),
                  ),
                );
              }, childCount: _category.count),
            ),
          ),
        ],
      ),
    );
  }

  static int _starsFor(double score) {
    if (score >= 0.9) return 3;
    if (score >= 0.6) return 2;
    if (score >= 0.2) return 1;
    return 0;
  }

  @override
  void onTopBarClick(String name, {bool value = true}) {
    if (name == Constant.strBack) {
      Navigator.of(context).maybePop();
    }
  }
}

/// "★ 2/6": quizzes with at least one star out of the category total.
class StarProgressLabel extends StatelessWidget {
  final int done;
  final int total;

  const StarProgressLabel({super.key, required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          done == total ? Icons.emoji_events_rounded : Icons.star_rounded,
          color: CoffeePalette.gold,
          size: 20,
          shadows: const [
            Shadow(color: CoffeePalette.cinnamon, offset: Offset(0, 1.5)),
          ],
        ),
        const SizedBox(width: 3),
        Text(
          "$done/$total",
          style: const TextStyle(
            fontFamily: kGameFont,
            color: CoffeePalette.roast,
            fontSize: 17,
          ),
        ),
      ],
    );
  }
}

class CategoryProgressBar extends StatelessWidget {
  final int done;
  final int total;

  const CategoryProgressBar({
    super.key,
    required this.done,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    // Same bar everywhere: recessed espresso track, gold fill.
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: CoffeePalette.roast,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: total == 0 ? 0 : done / total),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          builder:
              (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: CoffeePalette.mocha,
                valueColor: const AlwaysStoppedAnimation(CoffeePalette.gold),
              ),
        ),
      ),
    );
  }
}
