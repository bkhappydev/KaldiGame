import 'package:flutter/material.dart';
import 'package:kaldi_app/common/coffee3d/coffee_3d.dart';
import 'package:kaldi_app/common/commonTopBar/common_topbar.dart';
import 'package:kaldi_app/interfaces/topbar_clicklistener.dart';
import 'package:kaldi_app/localization/language/languages.dart';
import 'package:kaldi_app/utils/constant.dart';

/// The privacy policy, shown inside the app so it works offline.
/// Keep in sync with docs/privacy-policy.html (the public copy for Play).
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const String effectiveDate = '8 November 2026';

  static const List<(String, String)> sections = [
    (
      'Who we are',
      'Kaldi Game ("the app", package com.aynu.kids.kaldi_app) is made by '
          '${Constant.developerName}. This policy explains how the app '
          'handles information. Questions: ${Constant.emailPath}.',
    ),
    (
      'Made for children',
      'Kaldi is a learning game for young children. We designed it to '
          'follow the Google Play Families Policy and children\'s privacy '
          'laws such as COPPA and GDPR-K. Children can play without an '
          'account and without typing any personal details.',
    ),
    (
      'Information we collect',
      'None. The app does not collect, store on our servers, or share any '
          'personal information: no names, emails, phone numbers, photos, '
          'contacts, location or device/advertising identifiers. The app '
          'does not need an internet connection to play.',
    ),
    (
      'What stays on the device',
      'To remember progress, the app saves the stars earned in each quiz, '
          'the rewards won, the chosen language and music setting, and the '
          'accessibility choices (audio quiz, read aloud, voice speed and '
          'volume) on the device itself. This never leaves the device, and is '
          'deleted when the app is uninstalled or its data is cleared.',
    ),
    (
      'Read aloud and audio quiz',
      'When read aloud or the audio quiz is turned on, the app speaks using '
          'the text-to-speech engine built into the phone. The app itself '
          'sends nothing anywhere and does not record or listen to the child.',
    ),
    (
      'No ads, no analytics, no tracking',
      'The app shows no third-party advertising, contains no analytics or '
          'tracking tools, and has no in-app purchases or chat.',
    ),
    (
      'App updates',
      'When the app starts, it asks the Google Play Store app on the phone '
          'whether a newer version of Kaldi is available and, if so, shows '
          'Google Play\'s update screen. The app sends no information about '
          'the child for this.',
    ),
    (
      'Links that leave the app',
      'A few buttons open other apps: the promotion cards and Share open '
          'Google Play or the device\'s share menu, and Contact Us opens the '
          'email app, Telegram (t.me/aynukidssupport) or the phone dialer '
          '(${Constant.supportPhone}). Those apps have their own privacy '
          'policies. We do not receive any information when they are used, '
          'unless you choose to message or call us.',
    ),
    (
      'If you contact us',
      'If a parent contacts us by email (${Constant.emailPath}), on '
          'Telegram or by phone (${Constant.supportPhone}), we use the '
          'contact details and message only to reply, '
          'and delete them when no longer needed. Please do not send us a '
          'child\'s personal information.',
    ),
    (
      'Parents\' rights',
      'Because we hold no data about your child, there is nothing for us to '
          'access, correct or delete. To erase the progress saved on the '
          'device, uninstall the app or clear its data in the device '
          'settings.',
    ),
    (
      'Changes to this policy',
      'If the app changes how it handles information, we will update this '
          'policy and its effective date, and publish it in the app and on '
          'our Google Play page before the change takes effect.',
    ),
    (
      'Contact',
      '${Constant.developerName}\nEmail: ${Constant.emailPath}\n'
          'Phone: ${Constant.supportPhone}',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final Languages lang = Languages.of(context)!;
    return Scaffold(
      backgroundColor: BackgroundTheme.of(context).base,
      body: CoffeeBackdrop(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: [
            // The title scrolls away with the text.
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CommonTopBar(
                lang.txtPrivacyPolicy,
                _PopListener(context),
                isShowBack: true,
              ),
            ),
            Coffee3DPanel(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Effective $effectiveDate',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: CoffeePalette.cinnamon,
                    ),
                  ),
                  for (final (title, body) in sections) ...[
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: CoffeePalette.roast,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      body,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                        color: CoffeePalette.mocha,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Closes this page when the top bar back button is tapped.
class _PopListener implements TopBarClickListener {
  final BuildContext context;

  _PopListener(this.context);

  @override
  void onTopBarClick(String name, {bool value = true}) {
    if (name == Constant.strBack) Navigator.of(context).maybePop();
  }
}
