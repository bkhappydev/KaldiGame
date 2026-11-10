import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kaldi_app/common/coffee3d/coffee_3d.dart';

/// Loading indicator for Kaldi: three roasted coffee beans that hop in turn,
/// tilting as they jump, with soft shadows that shrink under them.
///
/// Use it anywhere the app waits (database, pictures) instead of a
/// CircularProgressIndicator.
class CoffeeBeanLoader extends StatefulWidget {
  /// Height of one bean; the whole loader is about 3.6x as wide.
  final double size;

  /// Optional text under the beans, e.g. "Loading…".
  final String? label;

  const CoffeeBeanLoader({super.key, this.size = 34, this.label});

  @override
  State<CoffeeBeanLoader> createState() => _CoffeeBeanLoaderState();
}

class _CoffeeBeanLoaderState extends State<CoffeeBeanLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double s = widget.size;
    final Widget beans = AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(3, (i) {
            // Each bean hops for the first 45% of its own staggered cycle.
            final double t = (_c.value - i * 0.18) % 1.0;
            final double hop = t < 0.45 ? math.sin(t / 0.45 * math.pi) : 0.0;
            final double tilt = t < 0.45
                ? math.sin(t / 0.45 * 2 * math.pi) * 0.35
                : 0.0;
            // Squash a little on landing.
            final double squash =
                (t >= 0.45 && t < 0.55) ? 1 - math.sin((t - 0.45) / 0.1 * math.pi) * 0.12 : 1.0;
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: s * 0.14),
              child: SizedBox(
                width: s * 0.78,
                height: s * 1.75,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    // Shadow shrinks while the bean is in the air.
                    Container(
                      width: s * 0.7 * (1 - hop * 0.45),
                      height: s * 0.14,
                      decoration: BoxDecoration(
                        color: CoffeePalette.espresso
                            .withValues(alpha: 0.28 * (1 - hop * 0.5)),
                        borderRadius: BorderRadius.circular(s),
                      ),
                    ),
                    Positioned(
                      bottom: s * 0.06 + hop * s * 0.65,
                      child: Transform(
                        alignment: Alignment.bottomCenter,
                        transform: Matrix4.identity()
                          ..rotateZ(tilt)
                          ..scaleByDouble(1 / squash, squash, 1, 1),
                        child: CustomPaint(
                          size: Size(s * 0.78, s),
                          painter: const _BeanPainter(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        );
      },
    );

    return Semantics(
      label: widget.label ?? 'Loading',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          beans,
          if (widget.label != null) ...[
            SizedBox(height: s * 0.3),
            Text(
              widget.label!,
              style: const TextStyle(
                color: CoffeePalette.foam,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                shadows: [
                  Shadow(color: CoffeePalette.espresso, blurRadius: 4),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A single roasted bean: glossy oval with the curved centre crease.
class _BeanPainter extends CustomPainter {
  const _BeanPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Rect r = Offset.zero & size;
    final RRect body = RRect.fromRectXY(r, size.width / 2, size.height / 2);

    canvas.drawRRect(
      body,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.35, -0.45),
          radius: 0.95,
          colors: [
            CoffeePalette.cinnamon,
            CoffeePalette.mocha,
            CoffeePalette.roast,
          ],
          stops: [0.0, 0.55, 1.0],
        ).createShader(r),
    );

    // Centre crease: a gentle S-curve from top to bottom.
    final double w = size.width, h = size.height;
    final Path crease = Path()
      ..moveTo(w * 0.52, h * 0.1)
      ..cubicTo(w * 0.30, h * 0.35, w * 0.70, h * 0.62, w * 0.48, h * 0.9);
    canvas.drawPath(
      crease,
      Paint()
        ..color = CoffeePalette.espresso
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.11
        ..strokeCap = StrokeCap.round,
    );
    // Light edge along the crease so it reads as a groove.
    canvas.drawPath(
      crease.shift(Offset(w * 0.06, 0)),
      Paint()
        ..color = CoffeePalette.honey.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.04
        ..strokeCap = StrokeCap.round,
    );

    // Glossy highlight.
    canvas.drawOval(
      Rect.fromLTWH(w * 0.14, h * 0.12, w * 0.22, h * 0.26),
      Paint()..color = CoffeePalette.foam.withValues(alpha: 0.45),
    );
  }

  @override
  bool shouldRepaint(covariant _BeanPainter oldDelegate) => false;
}
