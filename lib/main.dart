import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:kaldi_app/common/coffee3d/background_theme.dart';
import 'package:kaldi_app/localization/locale_constant.dart';
import 'package:kaldi_app/localization/localizations_delegate.dart';
import 'package:kaldi_app/ui/splash/splash_screen.dart';
import 'package:kaldi_app/utils/color.dart';
import 'package:kaldi_app/utils/constant.dart';
import 'package:kaldi_app/utils/game_audio.dart';
import 'package:kaldi_app/utils/preference.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Preference().instance();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  static final navigatorKey = GlobalKey<NavigatorState>();

  const MyApp({super.key});

  static void setLocale(BuildContext context, Locale newLocale) {
    var state = context.findAncestorStateOfType<MyAppState>()!;
    state.setLocale(newLocale);
  }

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> with WidgetsBindingObserver {
  Locale? _locale;
  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    GameAudio.startMusic();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pauses the music while the app is in the background and resumes it
    // when the player comes back (if music is switched on).
    GameAudio.onAppLifecycleChanged(state);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() async {
    _locale = getLocale();
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: MyApp.navigatorKey,
      builder: (context, child) {
        // Follow the phone's "larger text" setting for low-vision children,
        // up to 130% so the game layouts still fit; never smaller than 100%.
        return BackgroundThemeScope(
          child: Builder(
            builder: (context) => AnnotatedRegion<SystemUiOverlayStyle>(
              value: BackgroundTheme.of(context).overlayStyle,
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: MediaQuery.textScalerOf(
                    context,
                  ).clamp(minScaleFactor: 1.0, maxScaleFactor: 1.3),
                ),
                child: child!,
              ),
            ),
          ),
        );
      },
      // Escape works like the back button on every screen (dialogs and the
      // quiz handle it themselves first). Keyboard and JAWS/NVDA users rely
      // on it.
      actions: <Type, Action<Intent>>{
        ...WidgetsApp.defaultActions,
        DismissIntent: CallbackAction<DismissIntent>(
          onInvoke: (_) {
            MyApp.navigatorKey.currentState?.maybePop();
            return null;
          },
        ),
      },
      theme: ThemeData(
        splashColor: Colur.transparent,
        highlightColor: Colur.transparent,
        fontFamily: Constant.fontKids,
        fontFamilyFallback: const [Constant.fontMenbere],
      ),
      debugShowCheckedModeBanner: false,
      locale: _locale,
      supportedLocales: const [Locale('en'), Locale('am')],
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        // Match on language only: the saved locale is Locale('en', '') whose
        // empty country code never equals the supported Locale('en').
        for (var supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale?.languageCode) {
            return supportedLocale;
          }
        }
        return supportedLocales.first;
      },
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: Colur.white,
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(backgroundColor: Colur.transparent),
        fontFamily: Constant.fontKids,
        fontFamilyFallback: const [Constant.fontMenbere],
      ),

      home: const SplashScreen(),
    );
  }
}
