import 'package:flutter/material.dart';
import 'package:kaldi_app/common/coffee3d/coffee_3d.dart';
import 'package:kaldi_app/common/effects/motion.dart';
import 'package:kaldi_app/localization/language/languages.dart';

/// A 3D coffee yes/no popup. Returns true for Yes, false/null otherwise.
Future<bool?> showCoffeeConfirm(
  BuildContext context, {
  required String message,
  String image = 'ui_coffee',
}) {
  return showCoffeePopup<bool>(
    context,
    builder: (context) {
      final Languages lang = Languages.of(context)!;
      return Coffee3DPanel(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Float(
              distance: 6,
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    center: Alignment(-0.3, -0.4),
                    colors: [CoffeePalette.cinnamon, CoffeePalette.roast],
                  ),
                  border: Border.all(color: CoffeePalette.caramel, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Center(child: Icon3D(image, size: 56)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: CoffeePalette.roast,
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: Coffee3DButton(
                    color: CoffeePalette.cherry,
                    onTap: () => Navigator.of(context).pop(true),
                    child: _label(lang.txtYes),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Coffee3DButton(
                    color: CoffeePalette.leaf,
                    onTap: () => Navigator.of(context).pop(false),
                    child: _label(lang.txtNo),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

Widget _label(String text) => Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.w900,
      ),
    );
