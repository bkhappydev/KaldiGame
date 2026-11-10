// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:kaldi_app/main.dart';
import 'package:kaldi_app/utils/preference.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<Locale> setLocale(String languageCode) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString(Preference.language, languageCode);
  return _locale(languageCode);
}

Locale getLocale() {
  String languageCode =
      Preference.shared.getString(Preference.language) ?? "en";
  return _locale(languageCode);
}

Locale _locale(String languageCode) {
  return languageCode.isNotEmpty
      ? Locale(languageCode, '')
      : const Locale('en', '');
}

void changeLanguage(BuildContext context, String selectedLanguageCode) async {
  var locale = await setLocale(selectedLanguageCode);
  MyApp.setLocale(context, locale);
}
