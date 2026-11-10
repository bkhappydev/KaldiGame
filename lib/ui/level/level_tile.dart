import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:kaldi_app/common/coffee3d/coffee_3d.dart';
import 'package:kaldi_app/common/effects/bouncy_button.dart';
import 'package:kaldi_app/common/effects/motion.dart';

/// One quiz button: the star artwork for its best score, its number within
/// the category, and its topic name underneath.
class LevelTile extends StatelessWidget {
  final int number;
  final String title;
  final double score;

  /// Gently pulses to invite a tap (the next quiz to play).
  final bool highlight;
  final VoidCallback? onTap;

  const LevelTile({
    super.key,
    required this.number,
    required this.title,
    required this.score,
    this.highlight = false,
    this.onTap,
  });

  static String starImage(double score) {
    if (score >= 0.9) return "assets/images/level_item_3.webp";
    if (score >= 0.6) return "assets/images/level_item_2.webp";
    if (score >= 0.2) return "assets/images/level_item_1.webp";
    return "assets/images/level_item_0.webp";
  }

  @override
  Widget build(BuildContext context) {
    final BackgroundTheme background = BackgroundTheme.of(context);
    return Pulse(
      enabled: highlight,
      child: BouncyButton(
        onTap: onTap,
        child: Column(
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset(starImage(score)),
                  // Chunky game-style number: cream fill, dark espresso
                  // outline and a drop shadow so it pops off the bean.
                  Container(
                    margin: const EdgeInsets.only(bottom: 30),
                    child: OutlinedGameText(
                      "$number",
                      fontSize: 46,
                      strokeWidth: 8,
                      fill: CoffeePalette.foam,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 44,
              child: Center(
                child: AutoSizeText(
                  title,
                  maxLines: 2,
                  minFontSize: 11,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: background.onBackdrop,
                    fontSize: 17,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                    shadows: background.textShadows,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
