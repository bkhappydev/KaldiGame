import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kaldi_app/accessibility/key_activate.dart';
import 'package:kaldi_app/common/coffee3d/coffee_3d.dart';
import 'package:kaldi_app/common/commonTopBar/common_topbar.dart';
import 'package:kaldi_app/common/effects/coffee_bean_loader.dart';
import 'package:kaldi_app/interfaces/topbar_clicklistener.dart';
import 'package:kaldi_app/localization/language/languages.dart';
import 'package:kaldi_app/utils/constant.dart';
import 'package:url_launcher/url_launcher.dart';

/// One photo used under a Creative Commons licence.
class PhotoCredit {
  final String image;
  final String subject;
  final String author;
  final String license;
  final String? licenseUrl;
  final String? source;

  const PhotoCredit({
    required this.image,
    required this.subject,
    required this.author,
    required this.license,
    this.licenseUrl,
    this.source,
  });

  factory PhotoCredit.fromJson(Map<String, dynamic> j) => PhotoCredit(
        image: j['image'] as String? ?? '',
        subject: j['subject'] as String? ?? '',
        author: j['author'] as String? ?? '',
        license: j['license'] as String? ?? '',
        licenseUrl: j['licenseUrl'] as String?,
        source: j['source'] as String?,
      );
}

/// Credits for the photos used under CC BY / CC BY-SA licences, from
/// `assets/credits/photo_credits.json`.
class PhotoCreditsScreen extends StatefulWidget {
  const PhotoCreditsScreen({super.key});

  static const String asset = 'assets/credits/photo_credits.json';

  @override
  State<PhotoCreditsScreen> createState() => _PhotoCreditsScreenState();
}

class _PhotoCreditsScreenState extends State<PhotoCreditsScreen>
    implements TopBarClickListener {
  late final Future<List<PhotoCredit>> _credits = _load();

  Future<List<PhotoCredit>> _load() async {
    try {
      final List<dynamic> raw =
          jsonDecode(await rootBundle.loadString(PhotoCreditsScreen.asset))
              as List<dynamic>;
      return [
        for (final e in raw) PhotoCredit.fromJson(e as Map<String, dynamic>),
      ];
    } catch (_) {
      return const [];
    }
  }

  Future<void> _open(String? url) async {
    if (url == null || url.isEmpty) return;
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final Languages lang = Languages.of(context)!;
    return Scaffold(
      backgroundColor: BackgroundTheme.of(context).base,
      body: CoffeeBackdrop(
        child: FutureBuilder<List<PhotoCredit>>(
          future: _credits,
          builder: (context, snap) {
            final List<PhotoCredit> credits = snap.data ?? const [];
            return ListView(
              padding: EdgeInsets.fromLTRB(
                20,
                0,
                20,
                32 + MediaQuery.paddingOf(context).bottom,
              ),
              children: [
                // The title scrolls away with the list.
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CommonTopBar(
                    lang.txtPhotoCredits,
                    this,
                    isShowBack: true,
                  ),
                ),
                if (snap.connectionState != ConnectionState.done)
                  const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(child: CoffeeBeanLoader(size: 40)),
                  )
                else
                  Coffee3DPanel(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    child: credits.isEmpty
                        ? const Text(
                            '—',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              color: CoffeePalette.mocha,
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (int i = 0; i < credits.length; i++) ...[
                                if (i > 0)
                                  Container(
                                    height: 2,
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    color: CoffeePalette.latte,
                                  ),
                                _creditRow(credits[i]),
                              ],
                            ],
                          ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _creditRow(PhotoCredit c) {
    final String byLine = [c.author, c.license]
        .where((s) => s.isNotEmpty)
        .join(' · ');
    return Semantics(
      container: true,
      button: c.source != null,
      label: '${c.subject}. $byLine',
      excludeSemantics: true,
      onTap: c.source == null ? null : () => _open(c.source),
      child: TapArea(
        onTap: () => _open(c.source),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/${c.image}${Constant.extensionWebp}',
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                cacheWidth:
                    (56 * MediaQuery.devicePixelRatioOf(context)).round(),
                errorBuilder: (_, _, _) =>
                    const SizedBox(width: 56, height: 56),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.subject,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: CoffeePalette.roast,
                    ),
                  ),
                  Text(
                    byLine,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                      color: CoffeePalette.mocha,
                    ),
                  ),
                  if (c.licenseUrl != null)
                    GestureDetector(
                      onTap: () => _open(c.licenseUrl),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          c.licenseUrl!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: CoffeePalette.cinnamon,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (c.source != null)
              const Icon(
                Icons.open_in_new_rounded,
                color: CoffeePalette.cinnamon,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }

  @override
  void onTopBarClick(String name, {bool value = true}) {
    if (name == Constant.strBack) Navigator.of(context).maybePop();
  }
}
