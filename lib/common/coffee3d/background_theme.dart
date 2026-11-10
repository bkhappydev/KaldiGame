import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kaldi_app/common/coffee3d/coffee_3d.dart';
import 'package:kaldi_app/utils/preference.dart';

/// The picture behind every screen, chosen in Settings. [theme2] is the
/// default.
///
/// Theme 1 is light and the others are dark, so anything drawn straight on
/// the background (not on a card) must take its colours from here instead
/// of hard-coding white or cream.
enum BackgroundTheme {
  theme1('assets/images/Theme1.png', Color(0XFFFDF2DF), isLight: true),
  theme2('assets/images/Theme2.png', Color(0XFF874124)),
  theme3('assets/images/Theme3.png', Color(0XFF652323));

  final String asset;

  /// The picture's main colour: shown behind screens during transitions and
  /// in the strip beside the Android navigation bar.
  final Color base;
  final bool isLight;

  const BackgroundTheme(this.asset, this.base, {this.isLight = false});

  /// The theme in use. Rebuilds [context] when the player picks another one.
  static BackgroundTheme of(BuildContext context) {
    final BackgroundThemeStore store =
        context
            .dependOnInheritedWidgetOfExactType<BackgroundThemeScope>()
            ?.notifier ??
        BackgroundThemeStore.instance;
    return store.current;
  }

  /// Text and icons drawn straight on the background.
  Color get onBackdrop => isLight ? CoffeePalette.roast : CoffeePalette.foam;

  /// Quieter text drawn straight on the background.
  Color get onBackdropMuted =>
      isLight ? CoffeePalette.mocha : CoffeePalette.latte;

  /// A highlighted word drawn straight on the background.
  Color get onBackdropAccent =>
      isLight ? CoffeePalette.cinnamon : CoffeePalette.honey;

  /// A pill behind white text drawn on the background.
  Color get pill =>
      isLight ? CoffeePalette.mocha : Colors.black.withValues(alpha: 0.25);

  /// Keeps text readable where it crosses a coffee bean in the picture.
  List<Shadow> get textShadows => isLight
      ? const [
          Shadow(color: CoffeePalette.foam, blurRadius: 3),
          Shadow(color: CoffeePalette.foam, blurRadius: 6),
        ]
      : [
          Shadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ];

  /// Status bar icons that stay visible on this background.
  SystemUiOverlayStyle get overlayStyle => SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isLight ? Brightness.dark : Brightness.light,
        statusBarBrightness: isLight ? Brightness.light : Brightness.dark,
        systemNavigationBarIconBrightness:
            isLight ? Brightness.dark : Brightness.light,
      );
}

/// Remembers the chosen background on the device.
class BackgroundThemeStore extends ChangeNotifier {
  BackgroundThemeStore._();

  static final BackgroundThemeStore instance = BackgroundThemeStore._();

  static const String _key = 'BACKGROUND_THEME';

  BackgroundTheme get current =>
      BackgroundTheme.values.asNameMap()[Preference.shared.getString(_key)] ??
      BackgroundTheme.theme2;

  Future<void> select(BackgroundTheme theme) async {
    if (theme == current) return;
    await Preference.shared.setString(_key, theme.name);
    notifyListeners();
  }
}

/// Placed above the navigator, so every screen follows a background change.
class BackgroundThemeScope extends InheritedNotifier<BackgroundThemeStore> {
  BackgroundThemeScope({super.key, required super.child})
      : super(notifier: BackgroundThemeStore.instance);
}
