import 'package:flutter/material.dart';
import 'package:kaldi_app/common/coffee3d/coffee_3d.dart';

/// A simple, flat rounded tile in a solid [accent] colour behind a category
/// picture, with a thin cream border so it stands out from the card it
/// overlaps.
class IconTile extends StatelessWidget {
  final Color accent;
  final Widget child;
  final double radius;

  const IconTile({
    super.key,
    required this.accent,
    required this.child,
    this.radius = 24,
  });

  @override
  Widget build(BuildContext context) {
    final HSLColor hsl = HSLColor.fromColor(accent);
    return Container(
      decoration: BoxDecoration(
        color: hsl.withLightness(0.70).toColor(),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: CoffeePalette.foam, width: 3),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}
