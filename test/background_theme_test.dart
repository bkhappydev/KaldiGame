import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaldi_app/common/coffee3d/background_theme.dart';
import 'package:kaldi_app/utils/preference.dart';
import 'package:shared_preferences/shared_preferences.dart';

double _contrast(Color a, Color b) {
  final double la = a.computeLuminance();
  final double lb = b.computeLuminance();
  final double hi = la > lb ? la : lb;
  final double lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('choosing a background', () {
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      await Preference().instance();
    });

    setUp(() async {
      // Preference holds this same instance.
      await (await SharedPreferences.getInstance()).clear();
    });

    test('Theme 2 is the default', () {
      expect(BackgroundThemeStore.instance.current, BackgroundTheme.theme2);
    });

    test('a choice is remembered and listeners are told', () async {
      int changes = 0;
      void listener() => changes++;
      BackgroundThemeStore.instance.addListener(listener);
      await BackgroundThemeStore.instance.select(BackgroundTheme.theme3);
      BackgroundThemeStore.instance.removeListener(listener);

      expect(BackgroundThemeStore.instance.current, BackgroundTheme.theme3);
      expect(changes, 1);
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('BACKGROUND_THEME'), 'theme3');
    });

    test('an unknown saved value falls back to Theme 2', () async {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('BACKGROUND_THEME', 'nope');
      expect(BackgroundThemeStore.instance.current, BackgroundTheme.theme2);
    });
  });

  group('every background', () {
    for (final BackgroundTheme theme in BackgroundTheme.values) {
      test('${theme.name} has its picture on disk', () {
        expect(File(theme.asset).existsSync(), isTrue);
      });

      test('${theme.name} keeps text on it readable', () {
        expect(_contrast(theme.onBackdrop, theme.base), greaterThan(4.5));
        expect(_contrast(theme.onBackdropMuted, theme.base), greaterThan(3));
        expect(_contrast(theme.onBackdropAccent, theme.base), greaterThan(3));
      });
    }

    test('Theme 1 is light and uses dark status bar icons', () {
      expect(BackgroundTheme.theme1.isLight, isTrue);
      expect(
        BackgroundTheme.theme1.overlayStyle.statusBarIconBrightness,
        Brightness.dark,
      );
      expect(
        BackgroundTheme.theme3.overlayStyle.statusBarIconBrightness,
        Brightness.light,
      );
    });
  });
}
