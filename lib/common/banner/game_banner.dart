import 'package:flutter/material.dart';
import 'package:kaldi_app/utils/color.dart';
import 'package:kaldi_app/utils/constant.dart';
import 'package:kaldi_app/utils/debug.dart';
import 'package:url_launcher/url_launcher.dart';

/// One banner in the rotation: the artwork plus the store page it opens.
class GameBannerItem {
  final String asset;
  final String url;

  /// What a screen reader says for the banner (the app it promotes).
  final String label;

  const GameBannerItem({
    required this.asset,
    required this.url,
    required this.label,
  });
}

/// Banners in display order. The level grid cycles through this list, so the
/// page reads AynuKids -> AdeyKids -> AynuKids -> ... top to bottom.
const List<GameBannerItem> kBannerRotation = [
  GameBannerItem(
    asset: Constant.bannerAynuKids,
    url: Constant.bannerAynuKidsUrl,
    label: "Aynu Kids, Google Play",
  ),
  GameBannerItem(
    asset: Constant.bannerAdeyKids,
    url: Constant.bannerAdeyKidsUrl,
    label: "Adey Kids, Google Play",
  ),
];

/// Promotional banner shown between blocks of level tiles.
///
/// The banner keeps the artwork's native 940x300 proportions so neither image
/// is stretched or cropped. It fills the available width (minus the horizontal
/// margin applied by the caller) and, in landscape, is capped by [maxHeight] so
/// the strip cannot swallow the viewport.
class GameBanner extends StatelessWidget {
  /// Native proportions of the supplied banner artwork (940 x 300).
  static const double aspectRatio = 940 / 300;

  /// Asset path of the banner artwork. When null a placeholder is drawn.
  final String? imageAsset;

  /// Store page opened when the banner is tapped.
  final String? linkUrl;

  /// Overrides the default [linkUrl] tap behaviour when supplied.
  final VoidCallback? onTap;

  /// Label drawn on the placeholder, and read by screen readers.
  final String placeholderLabel;

  const GameBanner({
    super.key,
    this.imageAsset,
    this.linkUrl,
    this.onTap,
    this.placeholderLabel = "Banner",
  });

  /// Builds a banner straight from a rotation entry.
  factory GameBanner.fromItem(GameBannerItem item, {Key? key}) =>
      GameBanner(
        key: key,
        imageAsset: item.asset,
        linkUrl: item.url,
        placeholderLabel: item.label,
      );

  Future<void> _openLink() async {
    final String? url = linkUrl;
    if (url == null) {
      return;
    }
    final Uri uri = Uri.parse(url);
    // externalApplication hands off to the Play Store app when it is installed,
    // falling back to the browser otherwise.
    final bool launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched) {
      Debug.printLog("Could not open banner link: $url");
    }
  }

  /// Upper bound on banner height, so a wide (landscape) viewport does not turn
  /// the 3.13:1 strip into a full-screen block.
  static double maxHeightFor(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    final bool isLandscape = size.width > size.height;
    return isLandscape ? size.height * 0.30 : size.height * 0.22;
  }

  @override
  Widget build(BuildContext context) {
    // An explicit onTap wins; otherwise a supplied link makes the banner
    // tappable, and a banner with neither stays inert.
    final VoidCallback? tapHandler =
        onTap ?? (linkUrl != null ? _openLink : null);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeightFor(context)),
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Keep the curve proportional to the rendered size.
              final BorderRadius radius = BorderRadius.circular(
                constraints.maxHeight * 0.16,
              );
              return Semantics(
                label: placeholderLabel,
                button: tapHandler != null,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    boxShadow: [
                      // Solid caramel edge underneath = 3D card thickness.
                      const BoxShadow(
                        color: Color(0XFF9A5A2C),
                        offset: Offset(0, 7),
                      ),
                      BoxShadow(
                        color: Colur.black.withValues(alpha: 0.45),
                        blurRadius: 12,
                        offset: const Offset(0, 11),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: radius,
                    child: Material(
                      color: Colur.transparent,
                      child: InkWell(
                        onTap: tapHandler,
                        child:
                            imageAsset == null
                                ? _placeholder(radius, constraints.maxHeight)
                                : Image.asset(
                                  imageAsset!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _placeholder(BorderRadius radius, double height) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: Colur.bannerBorder, width: 2),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: Colur.bannerGradient,
        ),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.image_outlined,
              size: height * 0.30,
              color: Colur.bannerBorder,
            ),
            SizedBox(width: height * 0.10),
            Text(
              placeholderLabel,
              style: TextStyle(
                color: Colur.bannerBorder,
                fontSize: height * 0.20,
                fontFamily: Constant.fontMenbere,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
