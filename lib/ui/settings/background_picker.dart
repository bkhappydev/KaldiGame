import 'package:flutter/material.dart';
import 'package:kaldi_app/accessibility/key_activate.dart';
import 'package:kaldi_app/common/coffee3d/coffee_3d.dart';
import 'package:kaldi_app/common/effects/motion.dart';
import 'package:kaldi_app/localization/language/languages.dart';

/// Opens a popup with a preview of each background. Picking one applies it
/// and closes the popup; tapping outside (or Back / Escape) leaves it as is.
Future<void> showBackgroundPicker(BuildContext context) {
  return showCoffeePopup<void>(
    context,
    builder: (context) => const _BackgroundPopup(),
  );
}

/// A tiny preview of [theme], for the Settings row.
class BackgroundThumbnail extends StatelessWidget {
  final BackgroundTheme theme;

  const BackgroundThumbnail({super.key, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 48,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: CoffeePalette.caramel,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          theme.asset,
          fit: BoxFit.cover,
          cacheWidth: (34 * MediaQuery.devicePixelRatioOf(context)).round(),
        ),
      ),
    );
  }
}

class _BackgroundPopup extends StatefulWidget {
  const _BackgroundPopup();

  @override
  State<_BackgroundPopup> createState() => _BackgroundPopupState();
}

class _BackgroundPopupState extends State<_BackgroundPopup> {
  /// A fast double tap must not close the popup and then whatever is under it.
  bool _picking = false;

  Future<void> _pick(BackgroundTheme theme) async {
    if (_picking) return;
    _picking = true;
    // Decode first, so the cross-fade never shows an empty background.
    await precacheImage(AssetImage(theme.asset), context);
    await BackgroundThemeStore.instance.select(theme);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final Languages lang = Languages.of(context)!;
    final BackgroundTheme current = BackgroundTheme.of(context);
    return Coffee3DPanel(
      title: lang.txtBackground,
      padding: const EdgeInsets.fromLTRB(10, 36, 10, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final BackgroundTheme theme in BackgroundTheme.values)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _BackgroundChoice(
                  theme: theme,
                  name: lang.backgroundName(theme.index),
                  selected: theme == current,
                  onTap: () => _pick(theme),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A preview of one background, ticked when it is the chosen one.
class _BackgroundChoice extends StatelessWidget {
  final BackgroundTheme theme;
  final String name;
  final bool selected;
  final VoidCallback onTap;

  const _BackgroundChoice({
    required this.theme,
    required this.name,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(16);
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: name,
      excludeSemantics: true,
      onTap: onTap,
      child: TapArea(
        onTap: onTap,
        borderRadius: radius,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 0.72,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: selected
                          ? CoffeePalette.leaf
                          : CoffeePalette.latte,
                      borderRadius: radius,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: Image.asset(
                        theme.asset,
                        fit: BoxFit.cover,
                        // A preview needs only a small decode.
                        cacheWidth:
                            (120 * MediaQuery.devicePixelRatioOf(context))
                                .round(),
                      ),
                    ),
                  ),
                ),
                if (selected)
                  const Positioned(
                    right: 6,
                    top: 6,
                    child: PopIn(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: CoffeePalette.foam,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_circle_rounded,
                          color: CoffeePalette.leaf,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                  color: CoffeePalette.roast,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
