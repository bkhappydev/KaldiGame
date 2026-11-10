import 'package:flutter/material.dart';
import 'package:kaldi_app/accessibility/a11y_settings.dart';
import 'package:kaldi_app/accessibility/key_activate.dart';
import 'package:kaldi_app/accessibility/narrator.dart';
import 'package:kaldi_app/common/coffee3d/coffee_3d.dart';
import 'package:kaldi_app/common/commonTopBar/common_topbar.dart';
import 'package:kaldi_app/common/effects/motion.dart';
import 'package:kaldi_app/interfaces/topbar_clicklistener.dart';
import 'package:kaldi_app/localization/language/languages.dart';
import 'package:kaldi_app/localization/locale_constant.dart';
import 'package:kaldi_app/ui/settings/background_picker.dart';
import 'package:kaldi_app/ui/settings/photo_credits_screen.dart';
import 'package:kaldi_app/utils/constant.dart';
import 'package:kaldi_app/utils/game_audio.dart';
import 'package:share_plus/share_plus.dart';
import 'package:kaldi_app/ui/settings/privacy_policy_screen.dart';
import 'package:url_launcher/url_launcher.dart';

/// Settings: music, language, accessibility, share, contact and privacy, as
/// 3D coffee rows. The title scrolls away with the list.
///
/// [embedded] is true when shown as a bottom-navigation tab (no back button).
class SettingsScreen extends StatefulWidget {
  final bool embedded;

  const SettingsScreen({super.key, this.embedded = false});

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen>
    implements TopBarClickListener {
  bool _music = GameAudio.musicEnabled;
  final A11ySettings _a11y = A11ySettings.instance;

  @override
  void initState() {
    super.initState();
    _a11y.addListener(_refresh);
    // Learn whether an Amharic voice exists, for the note below.
    Narrator.instance.init().then((_) => _refresh());
  }

  @override
  void dispose() {
    _a11y.removeListener(_refresh);
    Narrator.instance.stop();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _toggleMusic() {
    final bool enable = !_music;
    setState(() => _music = enable);
    GameAudio.setMusicEnabled(enable);
  }

  Future<void> _share() async {
    final Languages lang = Languages.of(context)!;
    await SharePlus.instance.share(
      ShareParams(
        text: lang.txtShareDesc + Constant.shareLink,
        subject: lang.txtKidsGames,
        // Title of the system share sheet (WhatsApp, Telegram, Facebook...).
        title: lang.txtShare,
      ),
    );
  }

  /// Opens the email app addressed to the developer.
  Future<void> _contactUs() async {
    final Uri uri = Uri(
      scheme: 'mailto',
      path: Constant.emailPath,
      query: 'subject=${Uri.encodeComponent('Kaldi Game')}',
    );
    await launchUrl(uri);
  }

  /// Opens the support chat in the Telegram app (or the browser).
  Future<void> _telegram() async {
    await launchUrl(
      Uri.parse(Constant.telegramUrl),
      mode: LaunchMode.externalApplication,
    );
  }

  /// Opens the phone's dialer with the support number filled in (the parent
  /// still presses call, so no phone permission is needed).
  Future<void> _call() async {
    await launchUrl(Uri(scheme: 'tel', path: Constant.supportPhoneTel));
  }

  /// Opens the publisher's website in the browser.
  Future<void> _website() async {
    await launchUrl(
      Uri.parse(Constant.websiteUrl),
      mode: LaunchMode.externalApplication,
    );
  }

  /// Speaks a short sample so a parent can hear the speed and volume.
  Future<void> _testVoice() async {
    final String appLanguage = Localizations.localeOf(context).languageCode;
    await Narrator.instance.init();
    final String language = Narrator.instance.voiceLanguage(appLanguage);
    Narrator.instance.say(
      Narrator.instance.strings(appLanguage).txtVoiceSample,
      language: language,
    );
  }

  /// After a speed or volume change, let them hear it (unless a screen
  /// reader is talking).
  void _previewVoice() {
    if (!MediaQuery.accessibleNavigationOf(context)) _testVoice();
  }

  /// Quiet developer credit at the end of the list.
  Widget _credit(Languages lang) {
    final BackgroundTheme background = BackgroundTheme.of(context);
    final TextStyle small = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: background.onBackdropMuted,
      shadows: background.textShadows,
    );
    return Column(
      children: [
        Text(lang.txtDevelopedBy, style: small),
        const SizedBox(height: 2),
        Text(
          Constant.developerName,
          style: TextStyle(
            fontFamily: kGameFont,
            fontSize: 20,
            color: background.onBackdropAccent,
            shadows: background.textShadows,
          ),
        ),
        const SizedBox(height: 2),
        Text(Constant.emailPath, style: small),
        Text(Constant.telegramHandle, style: small),
        Text(Constant.supportPhone, style: small),
        Text(Constant.websiteName, style: small),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final Languages lang = Languages.of(context)!;
    int step = 0;
    Widget pop(Widget child) =>
        PopIn(delay: Duration(milliseconds: 60 * step++), child: child);

    final Widget body = CoffeeBackdrop(
      child: ListView(
        padding: EdgeInsets.only(
          bottom: 24 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          // Part of the list, so it scrolls away instead of staying pinned.
          CommonTopBar(lang.txtSettings, this, isShowBack: !widget.embedded),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                pop(
                  _SettingRow(
                    image: 'ui_music',
                    label: lang.txtMusic,
                    toggled: _music,
                    trailing: _Switch3D(value: _music),
                    onTap: _toggleMusic,
                  ),
                ),
                pop(_languageRow(lang)),
                pop(_backgroundRow(lang)),
                pop(_sectionTitle(lang.txtAccessibility)),
                pop(_accessibilityCard(lang)),
                pop(
                  _SettingRow(
                    image: 'ui_share',
                    label: lang.txtShare,
                    onTap: _share,
                  ),
                ),
                pop(_contactRow(lang)),
                pop(
                  _SettingRow(
                    image: 'ui_star',
                    label: lang.txtPhotoCredits,
                    onTap:
                        () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const PhotoCreditsScreen(),
                          ),
                        ),
                  ),
                ),
                pop(
                  _SettingRow(
                    image: 'ui_privacy',
                    label: lang.txtPrivacyPolicy,
                    onTap:
                        () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const PrivacyPolicyScreen(),
                          ),
                        ),
                  ),
                ),
                const SizedBox(height: 8),
                _credit(lang),
              ],
            ),
          ),
        ],
      ),
    );

    if (widget.embedded) return body;
    return Scaffold(
      backgroundColor: BackgroundTheme.of(context).base,
      body: body,
    );
  }

  /// Contact Us: one card with Email and Telegram buttons, then Call and the website
  /// underneath.
  Widget _contactRow(Languages lang) {
    Widget button({
      String? image,
      IconData? icon,
      required String label,
      required String detail,
      required VoidCallback onTap,
    }) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Coffee3DButton(
          color: CoffeePalette.caramel,
          height: 58,
          depth: 5,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          semanticLabel: label == detail ? label : '$label, $detail',
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (image != null)
                Icon3D(image, size: 30)
              else
                Icon(icon, size: 30, color: Colors.white),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _SettingRow(
      image: 'ui_email',
      label: lang.txtContactUs,
      below: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: button(
                  image: 'ui_email',
                  label: lang.txtEmail,
                  detail: Constant.emailPath,
                  onTap: _contactUs,
                ),
              ),
              Expanded(
                child: button(
                  image: 'ui_chat',
                  label: lang.txtTelegram,
                  detail: Constant.telegramHandle,
                  onTap: _telegram,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          button(
            image: 'ui_phone',
            label: '${lang.txtCall} ${Constant.supportPhone}',
            detail: Constant.supportPhone,
            onTap: _call,
          ),
          const SizedBox(height: 12),
          button(
            icon: Icons.language_rounded,
            label: Constant.websiteName,
            detail: Constant.websiteName,
            onTap: _website,
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 6, 6, 12),
        child: OutlinedGameText(text, fontSize: 24, strokeWidth: 5),
      ),
    );
  }

  Widget _languageRow(Languages lang) {
    final String current = Localizations.localeOf(context).languageCode;
    return _SettingRow(
      image: 'cat_ethiopia',
      label: lang.txtLanguage,
      below: _ChoiceChips<String>(
        current: current,
        choices: const [('am', 'አማርኛ'), ('en', 'English')],
        onPick: (code) {
          changeLanguage(context, code);
          setState(() {});
        },
      ),
    );
  }

  /// The picture behind every screen: one line here, choices in a popup.
  Widget _backgroundRow(Languages lang) {
    final BackgroundTheme current = BackgroundTheme.of(context);
    return _SettingRow(
      icon: Icons.wallpaper_rounded,
      label: lang.txtBackground,
      description: lang.backgroundName(current.index),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          BackgroundThumbnail(theme: current),
          const Icon(
            Icons.chevron_right_rounded,
            size: 32,
            color: CoffeePalette.cinnamon,
          ),
        ],
      ),
      onTap: () => showBackgroundPicker(context),
    );
  }

  /// Audio quiz, read aloud, voice speed and volume, in one card.
  Widget _accessibilityCard(Languages lang) {
    final String current = Localizations.localeOf(context).languageCode;
    final bool missingAmharic =
        current == 'am' && !Narrator.instance.amharicVoice && _a11y.narrationOn;
    return _SettingRow(
      icon: Icons.hearing_rounded,
      label: lang.txtAudioQuiz,
      description: lang.txtAudioQuizDesc,
      toggled: _a11y.audioMode,
      trailing: _Switch3D(value: _a11y.audioMode),
      onTap: () => _a11y.setAudioMode(!_a11y.audioMode),
      below: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Divider(),
          _SubRow(
            icon: Icons.record_voice_over_rounded,
            label: lang.txtReadAloud,
            description: lang.txtReadAloudDesc,
            toggled: _a11y.readAloud,
            onTap: () => _a11y.setReadAloud(!_a11y.readAloud),
          ),
          const _Divider(),
          _SubRow(
            icon: Icons.campaign_rounded,
            label: lang.txtAppVoice,
            description: lang.txtAppVoiceDesc,
            toggled: _a11y.appVoice,
            onTap: () => _a11y.setAppVoice(!_a11y.appVoice),
          ),
          if (_a11y.narrationOn) ...[
            const _Divider(),
            _SubLabel(icon: Icons.speed_rounded, label: lang.txtVoiceSpeed),
            _ChoiceChips<SpeechSpeed>(
              current: _a11y.speed,
              choices: [
                (SpeechSpeed.slow, lang.txtSlow),
                (SpeechSpeed.normal, lang.txtNormal),
                (SpeechSpeed.fast, lang.txtFast),
              ],
              onPick: (s) async {
                await _a11y.setSpeed(s);
                _previewVoice();
              },
            ),
            const SizedBox(height: 12),
            _SubLabel(
              icon: Icons.volume_up_rounded,
              label: lang.txtVoiceVolume,
            ),
            _ChoiceChips<SpeechVolume>(
              current: _a11y.volume,
              choices: [
                (SpeechVolume.low, lang.txtLow),
                (SpeechVolume.medium, lang.txtMedium),
                (SpeechVolume.high, lang.txtHigh),
              ],
              onPick: (v) async {
                await _a11y.setVolume(v);
                _previewVoice();
              },
            ),
            const SizedBox(height: 14),
            Coffee3DButton(
              color: CoffeePalette.leaf,
              height: 52,
              depth: 5,
              borderRadius: BorderRadius.circular(26),
              semanticLabel: lang.txtTestVoice,
              onTap: _testVoice,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    lang.txtTestVoice,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (missingAmharic) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_rounded,
                  color: CoffeePalette.cinnamon,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    lang.txtNoAmharicVoice,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                      color: CoffeePalette.mocha,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  void onTopBarClick(String name, {bool value = true}) {
    if (name == Constant.strBack) Navigator.of(context).maybePop();
  }
}

/// One settings entry: a 3D cream card with a round coloured icon. Shows a
/// 3D picture ([image], an Icon3D name) or a white [icon].
class _SettingRow extends StatelessWidget {
  final String? image;
  final IconData? icon;
  final String label;
  final String? description;

  /// On/off state for switch rows, announced by screen readers.
  final bool? toggled;
  final Widget? trailing;
  final Widget? below;
  final VoidCallback? onTap;

  const _SettingRow({
    this.image,
    this.icon,
    required this.label,
    this.description,
    this.toggled,
    this.trailing,
    this.below,
    this.onTap,
  }) : assert(image != null || icon != null);

  @override
  Widget build(BuildContext context) {
    Widget header = Row(
      children: [
        Coffee3DIconButton(image: image, icon: icon, size: 48),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: CoffeePalette.roast,
                ),
              ),
              if (description != null)
                Text(
                  description!,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                    color: CoffeePalette.mocha,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        trailing ??
            (onTap == null
                ? const SizedBox.shrink()
                : const Icon(
                  Icons.chevron_right_rounded,
                  size: 32,
                  color: CoffeePalette.cinnamon,
                )),
      ],
    );

    if (onTap != null) {
      header = Semantics(
        container: true,
        button: toggled == null,
        toggled: toggled,
        label: label,
        hint: description,
        excludeSemantics: true,
        onTap: onTap,
        child: TapArea(onTap: onTap, child: header),
      );
    } else {
      header = Semantics(header: true, child: header);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Coffee3DPanel(
        depth: 8,
        padding: const EdgeInsets.fromLTRB(12, 10, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            if (below != null) ...[const SizedBox(height: 10), below!],
          ],
        ),
      ),
    );
  }
}

/// A switch line inside a card (no card of its own).
class _SubRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final bool toggled;
  final VoidCallback onTap;

  const _SubRow({
    required this.icon,
    required this.label,
    required this.description,
    required this.toggled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      toggled: toggled,
      label: label,
      hint: description,
      excludeSemantics: true,
      onTap: onTap,
      child: TapArea(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Coffee3DIconButton(
                icon: icon,
                size: 44,
                color: CoffeePalette.mocha,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: CoffeePalette.roast,
                      ),
                    ),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.2,
                        fontWeight: FontWeight.w600,
                        color: CoffeePalette.mocha,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _Switch3D(value: toggled),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SubLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        header: true,
        child: Row(
          children: [
            Icon(icon, size: 24, color: CoffeePalette.cinnamon),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: CoffeePalette.roast,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 2,
      margin: const EdgeInsets.symmetric(vertical: 12),
      color: CoffeePalette.latte,
    );
  }
}

/// A row of 3D pill buttons where exactly one is chosen.
class _ChoiceChips<T> extends StatelessWidget {
  final T current;
  final List<(T, String)> choices;
  final ValueChanged<T> onPick;

  const _ChoiceChips({
    required this.current,
    required this.choices,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final (value, label) in choices)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Semantics(
                selected: value == current,
                inMutuallyExclusiveGroup: true,
                child: Coffee3DButton(
                  depth: 4,
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  semanticLabel: label,
                  color:
                      value == current
                          ? CoffeePalette.caramel
                          : CoffeePalette.mocha,
                  onTap: value == current ? null : () => onPick(value),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color:
                            value == current
                                ? Colors.white
                                : CoffeePalette.latte,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// A chunky on/off switch with a raised knob.
class _Switch3D extends StatelessWidget {
  final bool value;

  const _Switch3D({required this.value});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: 66,
      height: 36,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: value ? CoffeePalette.leaf : CoffeePalette.mocha,
        boxShadow: const [
          BoxShadow(color: CoffeePalette.roast, offset: Offset(0, 3)),
        ],
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, CoffeePalette.crema],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 3,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
