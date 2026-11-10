import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kaldi_app/accessibility/a11y_settings.dart';
import 'package:kaldi_app/accessibility/audio_clues.dart';
import 'package:kaldi_app/accessibility/narrator.dart';
import 'package:kaldi_app/common/coffee3d/coffee_3d.dart';
import 'package:kaldi_app/common/coffee3d/coffee_dialogs.dart';
import 'package:kaldi_app/common/commonTopBar/common_topbar.dart';
import 'package:kaldi_app/common/effects/bouncy_button.dart';
import 'package:kaldi_app/common/effects/confetti.dart';
import 'package:kaldi_app/common/effects/coffee_bean_loader.dart';
import 'package:kaldi_app/common/effects/motion.dart';
import 'package:kaldi_app/data/quiz_catalog.dart';
import 'package:kaldi_app/database/database_helper.dart';
import 'package:kaldi_app/database/tables/item_table.dart';
import 'package:kaldi_app/rewards/reward_store.dart';
import 'package:kaldi_app/interfaces/topbar_clicklistener.dart';
import 'package:kaldi_app/localization/language/languages.dart';
import 'package:kaldi_app/ui/result/result_screen.dart';
import 'package:kaldi_app/utils/color.dart';
import 'package:kaldi_app/utils/constant.dart';
import 'package:kaldi_app/utils/debug.dart';
import 'package:kaldi_app/utils/game_audio.dart';

class QuizScreen extends StatefulWidget {
  final int level;

  const QuizScreen({super.key, this.level = 1});

  @override
  QuizScreenState createState() => QuizScreenState();
}

/// How a finished question went, for the star progress row.
enum _QuestionResult { correct, wrong }

/// The quiz. It runs in one of two modes, switchable at any time:
///
/// * **Picture quiz**: a picture and four coloured answer buttons.
/// * **Audio quiz** ([A11ySettings.audioMode]), for blind and low-vision
///   children: the question is a spoken riddle, the four answers are big
///   numbered buttons read aloud, and there are spoken hints. Without a
///   screen reader the first tap on an answer reads it, and a second tap
///   chooses it. With TalkBack / VoiceOver, focusing an answer reads it and
///   activating it chooses it.
///
/// Both modes share the same questions, scores, stars and gifts.
class QuizScreenState extends State<QuizScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver
    implements TopBarClickListener {
  final PageController pageController = PageController();
  final ConfettiController _confetti = ConfettiController();
  final A11ySettings _a11y = A11ySettings.instance;

  List<ItemTable> quizData = [];
  int get totalQue => quizData.length;
  int _pageIndex = 0;

  /// The four choices for the current question; one of them is [_answer].
  List<ItemTable> options = [];
  ItemTable? _answer;

  /// Index into [options] the child tapped, or null while still choosing.
  int? _selected;
  final List<_QuestionResult> _results = [];

  int correctAnswer = 0;
  double? score;

  // Audio quiz state for the current question.
  /// Answer read out by a first tap, waiting for a second tap to choose it.
  int? _pending;
  int _hintLevel = 0;
  String? _hintText;

  /// Wrong answers taken away by the second hint.
  final Set<int> _removed = {};

  /// After an answer with a screen reader on, the quiz waits for the child
  /// to press "Next question" instead of moving on by itself, so nothing
  /// changes while the screen reader is still talking.
  bool _waitingForNext = false;
  bool _overlayHidden = false;

  /// Page the quiz has already moved on from, so the timer and the Next
  /// button can't both advance it.
  int _advancedFrom = -1;

  late final AnimationController _slideIn = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  bool get _audioMode => _a11y.audioMode;
  String get _lang => Localizations.localeOf(context).languageCode;
  bool get _screenReader => A11ySettings.screenReaderOn(context);
  bool get _isDesktop =>
      Platform.isWindows || Platform.isMacOS || Platform.isLinux;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _a11y.addListener(_onA11yChanged);
    Narrator.instance.init();
    _getDataFromDatabase();
  }

  bool _checkedScreenReader = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_checkedScreenReader) {
      _checkedScreenReader = true;
      _adoptScreenReader();
    }
  }

  /// A blind child using TalkBack gets the audio quiz without having to
  /// find the setting first (only the first time; parents can turn it off).
  Future<void> _adoptScreenReader() async {
    final bool turnedOn = await _a11y.adoptScreenReader(_screenReader);
    if (!turnedOn || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(Languages.of(context)!.txtAudioQuizTurnedOn),
        duration: const Duration(seconds: 6),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed &&
        state != AppLifecycleState.inactive) {
      Narrator.instance.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _a11y.removeListener(_onA11yChanged);
    Narrator.instance.stop();
    _slideIn.dispose();
    _confetti.dispose();
    pageController.dispose();
    super.dispose();
  }

  bool _wasAudioMode = A11ySettings.instance.audioMode;

  void _onA11yChanged() {
    if (!mounted) return;
    final bool modeChanged = _wasAudioMode != _audioMode;
    _wasAudioMode = _audioMode;
    setState(() => _pending = null);
    if (!modeChanged) return;
    Narrator.instance.stop();
    _slideIn.forward(from: 0);
    _announceQuestion();
  }

  bool get _answered => _selected != null;
  bool get _answeredCorrectly =>
      _answered && options[_selected!].itemId == _answer?.itemId;

  String _quizTitle(String language) =>
      QuizCatalog.titleFor(widget.level, language) ??
      Languages.of(context)!.txtLevel_ + widget.level.toString();

  @override
  Widget build(BuildContext context) {
    return _withKeys(PopScope(
      // Ask before leaving instead of popping straight away.
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _goBack();
      },
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
                  CommonTopBar(_quizTitle(_lang), this, isShowBack: true),
                  Expanded(child: _quizWidget()),
                ],
              ),
              Positioned.fill(child: _feedbackOverlay()),
              Positioned.fill(child: Confetti(controller: _confetti)),
            ],
          ),
        ),
      ),
    ));
  }

  /// Keyboard play, for computers and for screen-reader users (JAWS, NVDA)
  /// who drive everything from the keyboard: 1-4 choose an answer (the same
  /// "hear it, then press again" as tapping in the audio quiz), H gives a
  /// hint, R repeats the question, N goes on after an answer. Esc asks to
  /// leave, like the back button. Tab still moves between the buttons.
  Widget _withKeys(Widget child) {
    final Map<ShortcutActivator, VoidCallback> bindings = {
      for (int i = 0; i < 4; i++) ...{
        SingleActivator(LogicalKeyboardKey(LogicalKeyboardKey.digit1.keyId + i)):
            () => _onOptionKey(i),
        SingleActivator(
          LogicalKeyboardKey(LogicalKeyboardKey.numpad1.keyId + i),
        ): () => _onOptionKey(i),
      },
      const SingleActivator(LogicalKeyboardKey.keyH): () {
        if (_audioMode) _onHint();
      },
      const SingleActivator(LogicalKeyboardKey.keyR): _replayQuestion,
      const SingleActivator(LogicalKeyboardKey.keyN): () {
        if (_waitingForNext) _nextQuestion();
      },
      const SingleActivator(LogicalKeyboardKey.escape): _goBack,
    };
    return CallbackShortcuts(
      bindings: bindings,
      child: Focus(autofocus: true, child: child),
    );
  }

  void _onOptionKey(int index) {
    if (quizData.isEmpty || index >= options.length) return;
    _onOptionTap(index);
  }

  Widget _quizWidget() {
    if (quizData.isEmpty) {
      // Shown while the questions load from the database.
      return const Center(child: CoffeeBeanLoader(size: 40));
    }
    return PageView.builder(
      physics: const NeverScrollableScrollPhysics(),
      controller: pageController,
      itemCount: totalQue,
      itemBuilder: (BuildContext context, int pageIndex) {
        if (_audioMode) return _audioQuestion(context, pageIndex);
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _progress(context, pageIndex),
            _queImage(context, pageIndex),
            _options(context),
            if (_waitingForNext) _nextButton(context),
          ],
        );
      },
    );
  }

  /// "Question 2/5" plus a row of stars: gold for right answers, faded for
  /// wrong ones, and a pulsing star for the current question. The round
  /// button beside it switches between the picture and audio quiz.
  Widget _progress(BuildContext context, int pageIndex) {
    final Languages lang = Languages.of(context)!;
    final BackgroundTheme background = BackgroundTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              label: lang.a11yQuestionOf(pageIndex + 1, totalQue),
              excludeSemantics: true,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                decoration: BoxDecoration(
                  color: background.pill,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  "${lang.txtQuestion} ${pageIndex + 1} / $totalQue",
                  style: const TextStyle(
                    color: Colur.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            _modeSwitch(lang),
          ],
        ),
        const SizedBox(height: 8),
        ExcludeSemantics(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(totalQue, (i) {
              final Widget star;
              if (i < _results.length) {
                final bool right = _results[i] == _QuestionResult.correct;
                star = PopIn(
                  child: Icon(
                    right ? Icons.star_rounded : Icons.star_border_rounded,
                    size: 34,
                    color: right
                        ? Colur.starGold
                        : background.onBackdrop.withValues(alpha: 0.5),
                    // Gold alone is faint on the light background.
                    shadows: right && background.isLight
                        ? const [
                            Shadow(
                              color: CoffeePalette.cinnamon,
                              offset: Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                );
              } else if (i == pageIndex) {
                star = Pulse(
                  amount: 0.2,
                  child: Icon(
                    Icons.star_rounded,
                    size: 34,
                    color: background.onBackdrop,
                  ),
                );
              } else {
                star = Icon(
                  Icons.star_rounded,
                  size: 26,
                  color: background.onBackdrop.withValues(alpha: 0.3),
                );
              }
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: Center(child: star),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  /// Ear button (picture quiz) or picture button (audio quiz).
  Widget _modeSwitch(Languages lang) {
    final bool audio = _audioMode;
    void toggle() => _a11y.setAudioMode(!audio);
    return Semantics(
      button: true,
      label: audio ? lang.txtSwitchToPictures : lang.txtSwitchToAudio,
      excludeSemantics: true,
      onTap: toggle,
      child: Coffee3DIconButton(
        icon: audio ? Icons.image_rounded : Icons.hearing_rounded,
        size: 48,
        color: CoffeePalette.mocha,
        onTap: toggle,
      ),
    );
  }

  Widget _queImage(BuildContext context, int pageIndex) {
    final double height = MediaQuery.sizeOf(context).height;
    final Languages lang = Languages.of(context)!;
    // The label must not give the answer away.
    return Semantics(
      image: true,
      label: "${lang.txtQuestionPicture}. ${lang.txtWhatIsThis}",
      excludeSemantics: true,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 30),
            child: Image.asset(
              "assets/images/quiz_que.webp",
              height: height * 0.40,
            ),
          ),
          // The picture pops in for every new question, then bobs gently.
          PopIn(
            popKey: pageIndex,
            delay: const Duration(milliseconds: 250),
            child: Float(
              distance: 10,
              // The picture keeps its own shape (no letterboxing), so photos
              // that still have their background get softly rounded corners.
              // Cut-out pictures are unaffected: their corners are empty.
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: height * 0.27,
                  maxHeight: height * 0.27,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    "assets/${quizData[pageIndex].itemImage!}${Constant.extensionWebp}",
                    // Decode at display size instead of the full source.
                    cacheWidth:
                        (height * 0.27 * MediaQuery.devicePixelRatioOf(context))
                            .round(),
                    // Never leave the card blank if a path in the database is
                    // wrong.
                    errorBuilder: (context, error, stackTrace) {
                      Debug.printLog(
                        "Missing item image: ${quizData[pageIndex].itemImage}",
                      );
                      return Icon(
                        Icons.image_not_supported_outlined,
                        size: height * 0.12,
                        color: Colur.brown,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _options(BuildContext context) {
    final double gap = MediaQuery.sizeOf(context).height * 0.025;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [_optionButton(context, 0), _optionButton(context, 1)],
        ),
        SizedBox(height: gap),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [_optionButton(context, 2), _optionButton(context, 3)],
        ),
      ],
    );
  }

  /// One answer button. Left-column buttons grow out of the left screen edge
  /// and right-column ones out of the right edge, sliding in from that side.
  Widget _optionButton(BuildContext context, int index) {
    if (index >= options.length) return const SizedBox.shrink();

    final bool isLeft = index.isEven;
    final ItemTable item = options[index];
    final bool isAnswer = item.itemId == _answer?.itemId;
    final bool isSelected = _selected == index;
    final String lang = _lang;
    final Size size = MediaQuery.sizeOf(context);

    // After a choice: the tapped one turns green or red, and the right answer
    // always lights up green so the child learns it.
    final bool showRight = _answered && isAnswer;
    final bool showWrong = isSelected && !isAnswer;

    final List<Color> border = showRight
        ? Colur.passGradient
        : showWrong
            ? Colur.failGradient
            : Colur.optionGradients[index % Colur.optionGradients.length];
    final Color fill = showRight
        ? Colur.passGreen
        : showWrong
            ? Colur.failRed
            : Colur.white;
    final Color textColor =
        (showRight || showWrong) ? Colur.white : border.last;

    const Radius round = Radius.circular(50);
    final BorderRadius radius = isLeft
        ? const BorderRadius.only(topRight: round, bottomRight: round)
        : const BorderRadius.only(topLeft: round, bottomLeft: round);

    Widget button = AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: EdgeInsets.only(
        top: 4,
        bottom: 4,
        right: isLeft ? 4 : 0,
        left: isLeft ? 0 : 4,
      ),
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          colors: border,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: Colur.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: size.width * 0.46,
        height: size.height * 0.07,
        padding: EdgeInsets.only(
          left: isLeft ? 12 : 22,
          right: isLeft ? 22 : 12,
        ),
        decoration: BoxDecoration(borderRadius: radius, color: fill),
        child: Row(
          children: [
            if (showRight || showWrong)
              PopIn(
                child: Icon(
                  showRight ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: Colur.white,
                  size: 26,
                ),
              ),
            Expanded(
              child: Center(
                child: AutoSizeText(
                  item.nameFor(lang),
                  maxLines: 2,
                  minFontSize: 11,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 22,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    button = Shake(trigger: showWrong ? _pageIndex : null, child: button);
    button = Pulse(enabled: showRight, amount: 0.06, child: button);

    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset(isLeft ? -1.5 : 1.5, 0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _slideIn,
          // Stagger: top row first, then the bottom row.
          curve: Interval(index < 2 ? 0 : 0.2, 1, curve: Curves.easeOutBack),
        ),
      ),
      child: _optionSemantics(
        index,
        BouncyButton(
          onTap: _answered ? null : () => _onOptionTap(index),
          child: button,
        ),
      ),
    );
  }

  /// "Number 2: Banana" for screen readers, the same in both quiz modes.
  Widget _optionSemantics(int index, Widget child) {
    final bool enabled = !_answered && !_removed.contains(index);
    final ItemTable item = options[index];
    final bool isAnswer = item.itemId == _answer?.itemId;
    final Languages lang = Languages.of(context)!;
    String label = lang.a11yOption(index + 1, item.nameFor(_lang));
    if (_answered && isAnswer) label = "$label ✓";
    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      selected: _pending == index || _selected == index,
      label: label,
      excludeSemantics: true,
      onTap: enabled ? () => _onOptionTap(index) : null,
      child: child,
    );
  }

  // ---------------------------------------------------------------------
  // Audio quiz
  // ---------------------------------------------------------------------

  Widget _audioQuestion(BuildContext context, int pageIndex) {
    final Languages lang = Languages.of(context)!;
    final String clue =
        AudioClues.clueFor(_answer!, _lang) ?? lang.txtWhatIsThis;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        4,
        20,
        24 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        children: [
          _progress(context, pageIndex),
          const SizedBox(height: 16),
          _clueCard(lang, clue, pageIndex),
          const SizedBox(height: 16),
          _hintRow(lang),
          const SizedBox(height: 16),
          for (int i = 0; i < options.length; i++) _audioOption(lang, i),
          if (_waitingForNext) ...[
            const SizedBox(height: 4),
            _nextButton(context),
          ],
        ],
      ),
    );
  }

  /// The spoken riddle, also printed large for children with some sight.
  /// Tapping it reads the question and answers again.
  Widget _clueCard(Languages lang, String clue, int pageIndex) {
    return Semantics(
      container: true,
      liveRegion: true,
      button: true,
      label: "${lang.a11yQuestionOf(pageIndex + 1, totalQue)} $clue",
      // On computers, JAWS / NVDA users also hear the keyboard keys.
      hint: _isDesktop
          ? "${lang.txtTapToHearAgain}. ${lang.txtKeyboardHelp}"
          : lang.txtTapToHearAgain,
      excludeSemantics: true,
      onTap: _answered ? null : _replayQuestion,
      child: PopIn(
        popKey: pageIndex,
        child: BouncyButton(
          pressedScale: 0.96,
          onTap: _answered ? null : _replayQuestion,
          child: Coffee3DPanel(
            depth: 8,
            padding: const EdgeInsets.fromLTRB(14, 14, 16, 16),
            child: Row(
              children: [
                // The screen's one moving focal point: "listen here".
                Pulse(
                  enabled: !_answered,
                  amount: 0.08,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: CoffeePalette.caramel,
                      boxShadow: [
                        BoxShadow(
                          color: shade(CoffeePalette.caramel, 0.22),
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.hearing_rounded,
                      size: 38,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            lang.txtListen,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: CoffeePalette.cinnamon,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.replay_rounded,
                            size: 18,
                            color: CoffeePalette.cinnamon,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        clue,
                        style: const TextStyle(
                          fontSize: 21,
                          height: 1.25,
                          fontWeight: FontWeight.w800,
                          color: CoffeePalette.roast,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Hint button plus the latest hint. First hint: the first sound of the
  /// answer. Second hint: two wrong answers are taken away. Neither says
  /// the answer itself.
  Widget _hintRow(Languages lang) {
    final bool canHint = !_answered && _hintLevel < 2;
    return Row(
      children: [
        Semantics(
          container: true,
          button: true,
          enabled: canHint,
          label: lang.txtHint,
          excludeSemantics: true,
          onTap: canHint ? _onHint : null,
          child: Opacity(
            opacity: canHint ? 1 : 0.5,
            child: Coffee3DButton(
              color: CoffeePalette.honey,
              height: 52,
              depth: 5,
              borderRadius: BorderRadius.circular(26),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              onTap: canHint ? _onHint : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lightbulb_rounded,
                    color: CoffeePalette.roast,
                    size: 26,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    lang.txtHint,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: CoffeePalette.roast,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Semantics(
            liveRegion: true,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _hintText == null
                  ? const SizedBox.shrink()
                  : PopIn(
                      key: ValueKey(_hintText),
                      child: Text(
                        _hintText!,
                        style: TextStyle(
                          fontSize: 18,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                          color: BackgroundTheme.of(context).onBackdrop,
                          shadows: BackgroundTheme.of(context).textShadows,
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  /// A big, full-width, numbered answer button for the audio quiz.
  Widget _audioOption(Languages lang, int index) {
    final ItemTable item = options[index];
    final bool isAnswer = item.itemId == _answer?.itemId;
    final bool removed = _removed.contains(index);
    final bool pending = _pending == index && !_answered;
    final bool showRight = _answered && isAnswer;
    final bool showWrong = _selected == index && !isAnswer;

    final Color face = showRight
        ? CoffeePalette.leaf
        : showWrong
            ? CoffeePalette.cherry
            : pending
                ? CoffeePalette.honey
                : CoffeePalette.foam;
    final Color text =
        (showRight || showWrong) ? Colors.white : CoffeePalette.roast;
    final IconData? trailing = showRight
        ? Icons.check_circle_rounded
        : showWrong
            ? Icons.cancel_rounded
            : pending
                ? Icons.volume_up_rounded
                : null;

    Widget button = Coffee3DButton(
      color: face,
      height: 64,
      depth: 6,
      borderRadius: BorderRadius.circular(32),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      onTap: (_answered || removed) ? null : () => _onOptionTap(index),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: CoffeePalette.mocha,
            ),
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                fontFamily: kGameFont,
                fontSize: 26,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: AutoSizeText(
              item.nameFor(_lang),
              maxLines: 2,
              minFontSize: 14,
              style: TextStyle(
                fontSize: 24,
                height: 1.1,
                fontWeight: FontWeight.w900,
                color: text,
              ),
            ),
          ),
          if (trailing != null)
            PopIn(
              key: ValueKey(trailing),
              child: Icon(trailing, color: text, size: 30),
            ),
          const SizedBox(width: 8),
        ],
      ),
    );

    button = Shake(trigger: showWrong ? _pageIndex : null, child: button);
    button = Pulse(enabled: showRight, amount: 0.04, child: button);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: removed ? 0.3 : 1,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: Offset(index.isEven ? -1.5 : 1.5, 0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(
              parent: _slideIn,
              curve: Interval(0.08 * index, 1, curve: Curves.easeOutBack),
            ),
          ),
          child: _optionSemantics(index, button),
        ),
      ),
    );
  }

  /// Shown after an answer when a screen reader is on (see [_waitingForNext]).
  Widget _nextButton(BuildContext context) {
    final Languages lang = Languages.of(context)!;
    return Semantics(
      container: true,
      button: true,
      label: lang.txtNextQuestion,
      excludeSemantics: true,
      onTap: _nextQuestion,
      child: PopIn(
        child: Coffee3DButton(
          color: CoffeePalette.leaf,
          height: 62,
          depth: 7,
          borderRadius: BorderRadius.circular(31),
          onTap: _nextQuestion,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedGameText(lang.txtNextQuestion, fontSize: 24),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 30,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// What the narrator says for the current question, in [language].
  String _questionSpeech(Languages s, String language) {
    final StringBuffer b = StringBuffer();
    if (_pageIndex == 0 && _audioMode) {
      b.write('${s.a11yQuizIntro(_quizTitle(language))} ');
    }
    b.write('${s.a11yQuestionOf(_pageIndex + 1, totalQue)} ');
    final String? clue =
        _audioMode ? AudioClues.clueFor(_answer!, language) : null;
    b.write('${clue ?? s.txtWhatIsThis} ');
    for (int i = 0; i < options.length; i++) {
      if (_removed.contains(i)) continue;
      b.write('${s.a11yOption(i + 1, options[i].nameFor(language))} ');
    }
    b.write(s.txtWhichOne);
    return b.toString();
  }

  /// Reads the question aloud (if narration is on and no screen reader is
  /// talking), once the new question has slid in.
  Future<void> _announceQuestion({Duration delay = Duration.zero}) async {
    final int page = _pageIndex;
    if (delay > Duration.zero) await Future.delayed(delay);
    if (!mounted || quizData.isEmpty || _answered || page != _pageIndex) {
      return;
    }
    // Don't talk over the exit dialog or Settings.
    if (ModalRoute.of(context)?.isCurrent != true) return;
    Narrator.narrate(context, _questionSpeech);
  }

  void _replayQuestion() {
    if (_answered) return;
    setState(() => _pending = null);
    _announceQuestion();
  }

  void _onHint() {
    if (_answered || _hintLevel >= 2 || _answer == null) return;
    final Languages lang = Languages.of(context)!;
    HapticFeedback.selectionClick();
    if (_hintLevel == 0) {
      setState(() {
        _hintLevel = 1;
        _hintText =
            lang.a11yStartsWith(AudioClues.firstSound(_answer!, _lang));
      });
      Narrator.narrate(
        context,
        (s, l) => s.a11yStartsWith(AudioClues.firstSound(_answer!, l)),
      );
      return;
    }
    // Second hint: take away two wrong answers.
    final List<int> wrong = [
      for (int i = 0; i < options.length; i++)
        if (options[i].itemId != _answer!.itemId) i,
    ]..shuffle();
    final List<int> gone = wrong.take(2).toList();
    if (gone.length < 2) return;
    setState(() {
      _hintLevel = 2;
      _removed.addAll(gone);
      if (gone.contains(_pending)) _pending = null;
      _hintText = lang.a11yNotThese(
        options[gone[0]].nameFor(_lang),
        options[gone[1]].nameFor(_lang),
      );
    });
    Narrator.narrate(
      context,
      (s, l) =>
          '${s.a11yNotThese(options[gone[0]].nameFor(l), options[gone[1]].nameFor(l))} ${s.txtWhichOne}',
    );
  }

  // ---------------------------------------------------------------------
  // Answer feedback
  // ---------------------------------------------------------------------

  String _feedbackText(Languages s, String language) {
    final String answer = _answer!.nameFor(language);
    if (_answeredCorrectly) return s.a11yCorrect(answer);
    return s.a11yWrong(options[_selected!].nameFor(language), answer);
  }

  /// Big tick or cross that pops up over the screen after each answer, with
  /// the answer written underneath (and announced to screen readers).
  Widget _feedbackOverlay() {
    final bool show = _answered && !_overlayHidden;
    return IgnorePointer(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: !show
            ? const SizedBox.shrink()
            : Semantics(
                key: ValueKey("feedback$_pageIndex"),
                container: true,
                liveRegion: true,
                label: _feedbackText(Languages.of(context)!, _lang),
                excludeSemantics: true,
                child: Container(
                  color: Colur.black.withValues(alpha: 0.15),
                  alignment: Alignment.center,
                  child: PopIn(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            _answeredCorrectly
                                ? "assets/images/right.webp"
                                : "assets/images/wrong.webp",
                            height: MediaQuery.sizeOf(context).height * 0.30,
                          ),
                          const SizedBox(height: 12),
                          OutlinedGameText(
                            _answer!.nameFor(_lang),
                            fontSize: 34,
                            strokeWidth: 7,
                            fill: _answeredCorrectly
                                ? CoffeePalette.gold
                                : CoffeePalette.foam,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  void _onOptionTap(int index) {
    if (_answered || _removed.contains(index)) return;
    // Audio quiz without a screen reader: the first tap reads the answer,
    // and a second tap on the same one chooses it.
    if (_audioMode && Narrator.shouldSpeak(context) && _pending != index) {
      HapticFeedback.selectionClick();
      setState(() => _pending = index);
      Narrator.narrate(
        context,
        (s, l) => s.a11yTapAgainToChoose(index + 1, options[index].nameFor(l)),
      );
      return;
    }
    _submit(index);
  }

  Future<void> _submit(int index) async {
    final bool correct = options[index].itemId == _answer?.itemId;
    final bool speak = Narrator.shouldSpeak(context);
    final bool screenReader = _screenReader;
    final int page = _pageIndex;
    Narrator.instance.stop();
    setState(() {
      _selected = index;
      _pending = null;
      _results.add(correct ? _QuestionResult.correct : _QuestionResult.wrong);
      if (correct) correctAnswer += 1;
    });

    if (correct) {
      GameAudio.playCorrect();
      HapticFeedback.mediumImpact();
      _confetti.burst(origin: const Offset(0.5, 0.45));
    } else {
      GameAudio.playWrong();
      HapticFeedback.heavyImpact();
    }
    Debug.printLog("correct: $correctAnswer");

    // With a screen reader (or Kaldi's voice switched off in the audio quiz)
    // nothing should move on by itself: the screen reader reads the
    // feedback, then the child presses "Next question" (or N).
    if (screenReader || (_audioMode && !speak)) {
      setState(() => _waitingForNext = true);
      Future.delayed(const Duration(milliseconds: 1800), () {
        if (mounted && page == _pageIndex) {
          setState(() => _overlayHidden = true);
        }
      });
      return;
    }

    if (speak) {
      // Let the chime ring first, then say whether it was right, and move
      // on once the sentence has finished.
      await Future.delayed(const Duration(milliseconds: 450));
      if (!mounted || page != _pageIndex) return;
      final bool finished = await Narrator.narrate(context, _feedbackText);
      if (!mounted || page != _pageIndex) return;
      await Future.delayed(Duration(milliseconds: finished ? 400 : 1200));
      _nextQuestion();
      return;
    }

    Future.delayed(const Duration(milliseconds: 1600), _nextQuestion);
  }

  Future<void> _nextQuestion() async {
    if (!mounted || _advancedFrom == _pageIndex) return;
    _advancedFrom = _pageIndex;
    if (_pageIndex < totalQue - 1) {
      setState(() {
        _pageIndex += 1;
        _selected = null;
        _pending = null;
        _hintLevel = 0;
        _hintText = null;
        _removed.clear();
        _waitingForNext = false;
        _overlayHidden = false;
        _getOptions(_pageIndex);
      });
      pageController.jumpToPage(_pageIndex);
      _slideIn.forward(from: 0);
      _announceQuestion(delay: const Duration(milliseconds: 500));
    } else {
      score = correctAnswer / totalQue;
      Debug.printLog("score: $score");
      await DataBaseHelper().updateScore(widget.level, score!);
      _newGifts = await RewardStore.instance.recordResult(widget.level, score!);
      _navigateAfterQuizCompletion();
    }
  }

  Future<void> _getDataFromDatabase() async {
    final List<ItemTable> items =
        await DataBaseHelper().getItemData(widget.level);
    await AudioClues.load();
    items.shuffle();
    if (!mounted) return;
    setState(() {
      quizData = items;
      if (quizData.isNotEmpty) _getOptions(0);
    });
    _slideIn.forward(from: 0);
    _announceQuestion(delay: const Duration(milliseconds: 600));
  }

  /// Set when the quiz ends while a dialog or Settings covers this screen;
  /// the result screen then opens once the player is back on the quiz.
  bool _finishPending = false;
  bool _finished = false;

  /// Gift boxes this quiz just earned (shown on the result screen).
  int _newGifts = 0;

  void _navigateAfterQuizCompletion() {
    if (!mounted || _finished) return;
    // pushReplacement replaces whatever route is on top. If the exit dialog,
    // the grown-ups dialog or Settings is showing, that would replace *it*
    // and strand this quiz underneath, so wait until we are on top again.
    if (ModalRoute.of(context)?.isCurrent != true) {
      _finishPending = true;
      return;
    }
    _finishPending = false;
    _finished = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => ResultScreen(
          level: widget.level,
          score: score,
          nextLevel: QuizCatalog.nextLevelAfter(widget.level),
          newGifts: _newGifts,
        ),
      ),
    );
  }

  /// Picks the right answer plus three other items from this level, shuffled.
  void _getOptions(int index) {
    _answer = quizData[index];
    final Map<int, ItemTable> picked = {_answer!.itemId!: _answer!};
    for (final ItemTable item in List.of(quizData)..shuffle()) {
      if (picked.length == 4) break;
      picked.putIfAbsent(item.itemId!, () => item);
    }
    options = picked.values.toList()..shuffle();
  }

  /// Runs a finish that was deferred while something covered the quiz.
  void _resumePendingFinish() {
    if (!mounted || !_finishPending) return;
    // Let the dialog's closing pop fully settle before navigating again.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _finishPending) _navigateAfterQuizCompletion();
    });
  }

  bool _exitDialogOpen = false;

  Future<void> _goBack() async {
    // Back tapped twice (or system back + top bar back) used to stack two
    // exit dialogs; the second "Yes" then popped routes that were already
    // going away.
    if (_exitDialogOpen || _finished) return;
    _exitDialogOpen = true;
    Narrator.instance.stop();
    final NavigatorState navigator = Navigator.of(context);
    final String message =
        Languages.of(context)!.txtAreYouSureYouWantToExitGame;
    Narrator.narrate(context, (s, l) => s.txtAreYouSureYouWantToExitGame);
    final bool? leave = await showCoffeeConfirm(
      context,
      message: message,
      image: 'ui_door',
    );
    _exitDialogOpen = false;
    if (!mounted) return;
    Narrator.instance.stop();
    if (leave == true) {
      _finishPending = false;
      _finished = true;
      // Pop just this quiz; the level list underneath refreshes its stars.
      navigator.pop();
    } else {
      _resumePendingFinish();
      _replayQuestion();
    }
  }

  @override
  void onTopBarClick(String name, {bool value = true}) {
    if (name == Constant.strBack) {
      _goBack();
    }
  }
}
