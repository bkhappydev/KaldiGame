import 'package:flutter/material.dart';
import 'package:kaldi_app/localization/language/language_am.dart';
import 'package:kaldi_app/localization/language/language_en.dart';
import 'package:kaldi_app/localization/language/languages.dart';

class AppLocalizationsDelegate extends LocalizationsDelegate<Languages> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'am'].contains(locale.languageCode);

  @override
  Future<Languages> load(Locale locale) => _load(locale);

  static Future<Languages> _load(Locale locale) async {
    switch (locale.languageCode) {
      case 'am':
        return LanguageAm();
      case 'en':
        return LanguageEn();
      default:
        // English is the app's default language.
        return LanguageEn();
    }
  }

  @override
  bool shouldReload(LocalizationsDelegate<Languages> old) => false;
}
