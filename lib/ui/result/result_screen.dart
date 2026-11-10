import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kaldi_app/accessibility/narrator.dart';
import 'package:kaldi_app/common/coffee3d/coffee_3d.dart';
import 'package:kaldi_app/common/commonTopBar/common_topbar.dart';
import 'package:kaldi_app/common/effects/bouncy_button.dart';
import 'package:kaldi_app/common/effects/confetti.dart';
import 'package:kaldi_app/common/effects/motion.dart';
import 'package:kaldi_app/rewards/gift_box.dart';
import 'package:kaldi_app/rewards/reward_store.dart';
import 'package:kaldi_app/rewards/treats.dart';
import 'package:kaldi_app/interfaces/topbar_clicklistener.dart';
import 'package:kaldi_app/localization/language/languages.dart';
import 'package:kaldi_app/data/quiz_catalog.dart';
import 'package:kaldi_app/ui/quiz/quiz_screen.dart';
import 'package:kaldi_app/utils/constant.dart';

class ResultScreen extends StatefulWidget {
  final int? level;
  final double? score;

  /// Next quiz in the same category, or null after the category's last quiz
  /// (then "Play Next" is hidden).
  final int? nextLevel;

  /// Gift boxes this quiz just earned; a wiggling gift invites the child to
  /// open them.
  final int newGifts;

  const ResultScreen({
    super.key,
    this.level = 1,
    this.score,
    this.nextLevel,
    this.newGifts = 0,
  });

  @override
  ResultScreenState createState() => ResultScreenState();
}

class ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin
    implements TopBarClickListener {
  final ConfettiController _confetti = ConfettiController();

  late final AnimationController animationController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  double get _score => widget.score ?? 0;
  bool get _passed => _score >= 0.6;

  @override
  void initState() {
    super.initState();
    // Read the result aloud when narration is on (5 questions per quiz).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Narrator.narrate(
        context,
        (s, l) =>
            '${s.a11yResult((_score * 5).round(), 5)} '
            '${_passed ? s.txtAwesome : s.txtTryAgainNow}',
      );
    });
    // Celebrate once the stars have landed.
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      if (_passed) {
        _confetti.shower();
      } else if (_score > 0) {
        _confetti.burst(origin: const Offset(0.5, 0.3));
      }
    });
  }

  @override
  void dispose() {
    animationController.dispose();
    _confetti.dispose();
    super.dispose();
  }

  /// Set once a button has started navigating, so a fast double tap cannot
  /// fire a second push/pop while the first is still running.
  bool _navigating = false;

  void _navigate(void Function(NavigatorState navigator) action) {
    if (_navigating) return;
    _navigating = true;
    action(Navigator.of(context));
  }

  /// Back to the category list this quiz was opened from.
  void _backToCategory() => _navigate((n) => n.maybePop());

  /// All the way back to the categories home screen.
  void _goHome() => _navigate((n) => n.popUntil((route) => route.isFirst));

  void _playQuiz(int level) => _navigate(
    (n) => n.pushReplacement(
      MaterialPageRoute(builder: (context) => QuizScreen(level: level)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final String lang = Localizations.localeOf(context).languageCode;
    final String title =
        QuizCatalog.titleFor(widget.level!, lang) ??
        Languages.of(context)!.txtLevel_ + widget.level.toString();
    // The system back gesture pops this route straight back to the category
    // list, the same as the top bar Back button.
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: BackgroundTheme.of(context).base,
        body: SafeArea(
          top: false,
          bottom: Platform.isAndroid,
          child: Stack(
            children: [
              const Positioned.fill(
                child: CoffeeBackdrop(child: SizedBox.shrink()),
              ),
              Column(
                children: [
                  CommonTopBar(title, this, isShowBack: true),
                  Expanded(child: _resultWidget()),
                ],
              ),
              Positioned.fill(child: Confetti(controller: _confetti)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resultWidget() {
    final int? nextLevel = widget.nextLevel;
    final double height = MediaQuery.sizeOf(context).height;

    // The main action is big and pulses: Play Next after a pass, Play Again
    // after a miss. Go Home is always the quiet, smaller option.
    final bool nextIsMain = _passed && nextLevel != null;
    final List<Widget> buttons = [
      if (nextLevel != null)
        _ResultButton(
          label: Languages.of(context)!.txtPlayNext,
          image: 'ui_next',
          color: CoffeePalette.leaf,
          primary: nextIsMain,
          onTap: () => _playQuiz(nextLevel),
        ),
      _ResultButton(
        label: Languages.of(context)!.txtPlayAgain,
        image: 'ui_again',
        color: CoffeePalette.caramel,
        primary: !nextIsMain,
        onTap: () => _playQuiz(widget.level!),
      ),
      _ResultButton(
        label: Languages.of(context)!.txtGoToHome,
        image: 'cat_home',
        color: CoffeePalette.mocha,
        onTap: _goHome,
      ),
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(vertical: height * 0.015, horizontal: 20),
      child: Column(
        children: [
          PopIn(
            delay: const Duration(milliseconds: 150),
            duration: const Duration(milliseconds: 1000),
            child: Semantics(
              label: Languages.of(context)!.a11yStars(_stars),
              excludeSemantics: true,
              child: Float(
                child: Image.asset(_levelStarImage(), height: height * 0.30),
              ),
            ),
          ),
          PopIn(
            delay: const Duration(milliseconds: 500),
            child: Semantics(
              liveRegion: true,
              child: OutlinedGameText(
                _passed
                    ? Languages.of(context)!.txtAwesome
                    : Languages.of(context)!.txtTryAgainNow,
                fontSize: 36,
                strokeWidth: 7,
                fill: _passed ? CoffeePalette.gold : CoffeePalette.foam,
              ),
            ),
          ),
          SizedBox(height: height * 0.03),
          if (widget.newGifts > 0) _giftCard(),
          for (int i = 0; i < buttons.length; i++)
            SlideTransition(
              position: Tween<Offset>(
                begin: Offset(i.isEven ? -1.5 : 1.5, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: animationController,
                  curve: Interval(0.15 * i, 1, curve: Curves.easeOutBack),
                ),
              ),
              child: buttons[i],
            ),
        ],
      ),
    );
  }

  /// "You won a gift!" with a wiggling 3D present. Hidden once opened.
  Widget _giftCard() {
    return ListenableBuilder(
      listenable: RewardStore.instance,
      builder: (context, _) {
        if (RewardStore.instance.pendingGifts == 0) {
          return const SizedBox.shrink();
        }
        final Languages lang = Languages.of(context)!;
        return PopIn(
          delay: const Duration(milliseconds: 900),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Semantics(
              button: true,
              label: '${lang.txtYouWonGift} ${lang.txtTapToOpen}',
              excludeSemantics: true,
              onTap: () => openWaitingGifts(context),
              child: BouncyButton(
                onTap: () => openWaitingGifts(context),
                child: Coffee3DPanel(
                  title: lang.txtYouWonGift,
                  padding: const EdgeInsets.fromLTRB(16, 34, 16, 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      WigglingGift(
                        size: 96,
                        colors:
                            Treats.wrapColors[RewardStore.instance.giftsOpened %
                                Treats.wrapColors.length],
                      ),
                      const SizedBox(width: 14),
                      Flexible(
                        child: Pulse(
                          child: Text(
                            lang.txtTapToOpen,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: CoffeePalette.cherry,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Stars earned (0-3), same thresholds as the star artwork.
  int get _stars => RewardStore.starsForScore(_score);

  String _levelStarImage() {
    if (_score >= 0.9) {
      return "assets/images/star_3.webp";
    } else if (_score >= 0.6) {
      return "assets/images/star_2.webp";
    } else if (_score >= 0.2) {
      return "assets/images/star_1.webp";
    } else {
      return "assets/images/star_0.webp";
    }
  }

  @override
  void onTopBarClick(String name, {bool value = true}) {
    if (name == Constant.strBack) {
      _backToCategory();
    }
  }
}

/// A wide 3D coffee button for the result screen: a 3D picture in a cream
/// disc on the left and a big outlined label. [primary] makes it taller and
/// gently pulsing — the thing to tap next.
class _ResultButton extends StatelessWidget {
  final String label;

  /// Icon3D name.
  final String image;
  final Color color;
  final bool primary;
  final VoidCallback onTap;

  const _ResultButton({
    required this.label,
    required this.image,
    required this.color,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    final double h = primary ? 70 : 58;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Pulse(
        enabled: primary,
        amount: 0.035,
        child: Coffee3DButton(
          semanticLabel: label,
          color: color,
          height: h,
          depth: primary ? 8 : 6,
          borderRadius: BorderRadius.circular(h / 2),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          onTap: onTap,
          child: Row(
            children: [
              Container(
                width: h - 14,
                height: h - 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: CoffeePalette.foam,
                  boxShadow: [
                    BoxShadow(
                      color: shade(color, 0.2),
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(child: Icon3D(image, size: (h - 14) * 0.68)),
              ),
              Expanded(
                child: Padding(
                  // Balances the disc on the left so the label is centred.
                  padding: EdgeInsets.only(right: h - 14),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: OutlinedGameText(
                      label,
                      fontSize: primary ? 26 : 22,
                      strokeWidth: 5,
                      stroke: shade(color, 0.3),
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
