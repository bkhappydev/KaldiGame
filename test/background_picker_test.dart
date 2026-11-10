import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaldi_app/common/coffee3d/background_theme.dart';
import 'package:kaldi_app/localization/localizations_delegate.dart';
import 'package:kaldi_app/ui/settings/background_picker.dart';
import 'package:kaldi_app/utils/preference.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _app() => BackgroundThemeScope(
      child: MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const [Locale('en')],
        localizationsDelegates: const [
          AppLocalizationsDelegate(),
          DefaultMaterialLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showBackgroundPicker(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

/// Lets real image decoding finish, then settles the animations.
Future<void> _settle(WidgetTester t) async {
  for (int i = 0; i < 4; i++) {
    await t.runAsync(() => Future.delayed(const Duration(milliseconds: 100)));
    await t.pump(const Duration(milliseconds: 300));
  }
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Preference().instance();
  });

  setUp(() async {
    await (await SharedPreferences.getInstance()).clear();
  });

  testWidgets('shows every background and ticks the current one', (t) async {
    await t.pumpWidget(_app());
    await _settle(t);
    await t.tap(find.text('open'));
    await _settle(t);

    // The title ribbon draws its text twice: an outline and a fill.
    expect(find.text('Background'), findsWidgets);
    expect(find.text('Cream'), findsOneWidget);
    expect(find.text('Caramel'), findsOneWidget);
    expect(find.text('Dark Roast'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
  });

  testWidgets('picking one applies it and closes the popup', (t) async {
    await t.pumpWidget(_app());
    await _settle(t);
    await t.tap(find.text('open'));
    await _settle(t);

    await t.tap(find.text('Dark Roast'));
    await _settle(t);

    expect(BackgroundThemeStore.instance.current, BackgroundTheme.theme3);
    expect(find.text('Dark Roast'), findsNothing);
  });

  testWidgets('tapping outside keeps the current background', (t) async {
    await t.pumpWidget(_app());
    await _settle(t);
    await t.tap(find.text('open'));
    await _settle(t);

    await t.tapAt(const Offset(5, 5));
    await _settle(t);

    expect(BackgroundThemeStore.instance.current, BackgroundTheme.theme2);
    expect(find.text('Caramel'), findsNothing);
  });
}
