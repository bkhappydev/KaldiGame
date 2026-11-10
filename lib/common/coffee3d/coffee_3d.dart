import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kaldi_app/accessibility/key_activate.dart';
import 'package:kaldi_app/common/coffee3d/background_theme.dart';

export 'package:kaldi_app/common/coffee3d/background_theme.dart';

/// Coffee brand colours: from dark espresso to light milk foam, plus the red
/// coffee cherry Kaldi's goats ate.
class CoffeePalette {
  CoffeePalette._();

  static const espresso = Color(0XFF2B140C);
  static const roast = Color(0XFF4A1D1F);
  static const mocha = Color(0XFF6F3B22);
  static const cinnamon = Color(0XFF9A5A2C);
  static const caramel = Color(0XFFCE9352);
  static const honey = Color(0XFFE8B36A);
  static const latte = Color(0XFFE9C9A0);
  static const crema = Color(0XFFF3DFC0);
  static const foam = Color(0XFFFFF6E6);
  static const cherry = Color(0XFFD7263D);
  static const cherryDark = Color(0XFF8E1023);
  static const leaf = Color(0XFF3E8E41);
  static const gold = Color(0XFFFFC93C);
}

/// Chunky rounded font for numbers and game titles.
const String kGameFont = 'LilitaOne';

/// Darkens ([amount] > 0) or lightens ([amount] < 0) a colour.
Color shade(Color c, double amount) {
  final HSLColor hsl = HSLColor.fromColor(c);
  return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
}

/// Text with a thick dark outline and a drop shadow, like a game title.
class OutlinedGameText extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color fill;
  final Color stroke;
  final double strokeWidth;
  final String? fontFamily;

  const OutlinedGameText(
    this.text, {
    super.key,
    this.fontSize = 28,
    this.fill = Colors.white,
    this.stroke = CoffeePalette.espresso,
    this.strokeWidth = 5,
    this.fontFamily = kGameFont,
  });

  @override
  Widget build(BuildContext context) {
    final TextStyle base = TextStyle(
      fontSize: fontSize,
      fontFamily: fontFamily,
      // Lilita One has Latin and digits only; Amharic falls back to Menbere.
      fontFamilyFallback: const ['Menbere'],
      fontWeight: FontWeight.w700,
      height: 1.1,
      letterSpacing: 0.5,
    );
    return Stack(
      children: [
        Text(
          text,
          textAlign: TextAlign.center,
          style: base.copyWith(
            foreground:
                Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = strokeWidth
                  ..strokeJoin = StrokeJoin.round
                  ..color = stroke,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.45),
                offset: Offset(0, fontSize * 0.08),
                blurRadius: 2,
              ),
            ],
          ),
        ),
        Text(
          text,
          textAlign: TextAlign.center,
          style: base.copyWith(color: fill),
        ),
      ],
    );
  }
}

/// A raised, glossy, pressable block — the base of every 3D button.
///
/// The face sits [depth] pixels above a darker "side". Pressing pushes the
/// face down onto the side, so it feels like a real button.
class Coffee3DButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color color;
  final double depth;
  final BorderRadius borderRadius;
  final EdgeInsets padding;
  final bool circle;
  final double? width;
  final double? height;

  /// What a screen reader says for this button. When set, the inner
  /// content is not read separately.
  final String? semanticLabel;

  const Coffee3DButton({
    super.key,
    required this.child,
    this.onTap,
    this.color = CoffeePalette.caramel,
    this.depth = 6,
    this.borderRadius = const BorderRadius.all(Radius.circular(22)),
    this.padding = const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
    this.circle = false,
    this.width,
    this.height,
    this.semanticLabel,
  });

  @override
  State<Coffee3DButton> createState() => _Coffee3DButtonState();
}

class _Coffee3DButtonState extends State<Coffee3DButton> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap == null || _down == v) return;
    setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final double lift = _down ? widget.depth * 0.25 : widget.depth;
    final Color top = shade(widget.color, -0.12);
    final Color bottom = shade(widget.color, 0.06);
    final Color side = shade(widget.color, 0.22);
    final BoxShape shape = widget.circle ? BoxShape.circle : BoxShape.rectangle;
    final BorderRadius? radius = widget.circle ? null : widget.borderRadius;

    final Widget button = Semantics(
      container: true,
      button: true,
      enabled: widget.onTap != null,
      label: widget.semanticLabel,
      excludeSemantics: widget.semanticLabel != null,
      // excludeSemantics also drops the GestureDetector's tap action, so give
      // screen readers (TalkBack double-tap, JAWS/NVDA Enter) their own.
      onTap: widget.onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap:
            widget.onTap == null
                ? null
                : () {
                  HapticFeedback.lightImpact();
                  SystemSound.play(SystemSoundType.click);
                  widget.onTap!();
                },
        child: SizedBox(
          width: widget.width,
          height: widget.height == null ? null : widget.height! + widget.depth,
          child: Stack(
            children: [
              // Side / thickness of the button, with a soft floor shadow.
              Positioned.fill(
                top: widget.depth,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: shape,
                    borderRadius: radius,
                    color: side,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),
              // Face.
              AnimatedPadding(
                duration: const Duration(milliseconds: 70),
                padding: EdgeInsets.only(
                  top: widget.depth - lift,
                  bottom: lift,
                ),
                child: Container(
                  width: widget.width,
                  height: widget.height,
                  padding: widget.padding,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: shape,
                    borderRadius: radius,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [top, bottom],
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      // Gloss highlight across the top half.
                      Positioned(
                        top: -widget.padding.top + 3,
                        left: 0,
                        right: 0,
                        child: IgnorePointer(
                          child: FractionallySizedBox(
                            widthFactor: 0.82,
                            child: Container(
                              height: max(6, ((widget.height ?? 44) * 0.28)),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(40),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.white.withValues(alpha: 0.45),
                                    Colors.white.withValues(alpha: 0.0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      widget.child,
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Keyboard (Tab + Enter/Space) and desktop screen readers.
    return KeyActivate(
      onActivate: widget.onTap == null
          ? null
          : () {
              _set(true);
              Future.delayed(const Duration(milliseconds: 90), () {
                if (mounted) _set(false);
              });
              widget.onTap!();
            },
      borderRadius: widget.borderRadius,
      circle: widget.circle,
      child: button,
    );
  }
}

/// A 3D illustrated icon from assets/3d (Fluent Emoji 3D, MIT licence),
/// e.g. `Icon3D('nav_treats')`.
class Icon3D extends StatelessWidget {
  final String name;
  final double size;

  const Icon3D(this.name, {super.key, this.size = 40});

  static String path(String name) => 'assets/3d/$name.png';

  @override
  Widget build(BuildContext context) {
    // Decorative: the button or label around it says what it is.
    return ExcludeSemantics(
      child: Image.asset(
        path(name),
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
      ),
    );
  }
}

/// Round 3D button showing either a white [icon] or a 3D [image]
/// (an [Icon3D] name).
class Coffee3DIconButton extends StatelessWidget {
  final IconData? icon;
  final String? image;
  final VoidCallback? onTap;

  /// What a screen reader says for this button.
  final String? semanticLabel;
  final Color color;
  final double size;

  const Coffee3DIconButton({
    super.key,
    this.icon,
    this.image,
    this.onTap,
    this.color = CoffeePalette.caramel,
    this.size = 52,
    this.semanticLabel,
  }) : assert(icon != null || image != null);

  @override
  Widget build(BuildContext context) {
    return Coffee3DButton(
      semanticLabel: semanticLabel,
      onTap: onTap,
      color: color,
      circle: true,
      width: size,
      height: size,
      depth: size * 0.1,
      padding: EdgeInsets.zero,
      child:
          image != null
              ? Icon3D(image!, size: size * 0.62)
              : Icon(
                icon,
                color: Colors.white,
                size: size * 0.55,
                shadows: [
                  Shadow(
                    color: CoffeePalette.espresso.withValues(alpha: 0.6),
                    offset: const Offset(0, 2),
                    blurRadius: 2,
                  ),
                ],
              ),
    );
  }
}

/// A thick, bevelled cream card with a caramel rim — the body of every popup.
/// Optionally wears a 3D caramel ribbon with [title] across its top edge.
class Coffee3DPanel extends StatelessWidget {
  final Widget child;
  final String? title;
  final EdgeInsets padding;
  final double depth;

  const Coffee3DPanel({
    super.key,
    required this.child,
    this.title,
    this.padding = const EdgeInsets.fromLTRB(20, 34, 20, 22),
    this.depth = 10,
  });

  @override
  Widget build(BuildContext context) {
    final Widget card = Container(
      margin: EdgeInsets.only(top: title == null ? 0 : 26),
      decoration: BoxDecoration(
        // Rim: the caramel "thickness" showing under the card.
        color: CoffeePalette.cinnamon,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      padding: EdgeInsets.only(bottom: depth),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: CoffeePalette.caramel, width: 5),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [CoffeePalette.foam, CoffeePalette.crema],
          ),
        ),
        child: Container(
          // Inner bevel line for a moulded look.
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.9),
              width: 2,
            ),
          ),
          padding: padding,
          child: child,
        ),
      ),
    );

    if (title == null) return card;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [card, Positioned(top: 0, child: CoffeeRibbon(title!))],
    );
  }
}

/// A raised caramel banner with outlined text, used as a popup/page title.
class CoffeeRibbon extends StatelessWidget {
  final String text;
  final double fontSize;

  const CoffeeRibbon(this.text, {super.key, this.fontSize = 26});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: CoffeePalette.mocha,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: CoffeePalette.crema, width: 3),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [CoffeePalette.honey, CoffeePalette.cinnamon],
          ),
        ),
        child: OutlinedGameText(text, fontSize: fontSize, strokeWidth: 4),
      ),
    );
  }
}

/// Full-screen coffee backdrop: the bean-pattern coffee artwork.
class CoffeeBackdrop extends StatelessWidget {
  final Widget child;

  const CoffeeBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final BackgroundTheme theme = BackgroundTheme.of(context);
    return Stack(
      children: [
        Positioned.fill(
          child: ExcludeSemantics(
            child: ColoredBox(
              color: theme.base,
              // Cross-fades when another background is picked in Settings.
              child: AnimatedSwitcher(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 350),
                layoutBuilder: (current, previous) => Stack(
                  fit: StackFit.expand,
                  children: [...previous, if (current != null) current],
                ),
                // cover keeps the beans round on any screen shape.
                child: Image.asset(
                  theme.asset,
                  key: ValueKey(theme),
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}

/// A glossy 3D roasted coffee bean with a big outlined number on it.
/// [stars] (0-3) shows how well the level went; [highlight] glows it.
class CoffeeBeanBadge extends StatelessWidget {
  final int number;
  final int stars;
  final bool highlight;

  const CoffeeBeanBadge({
    super.key,
    required this.number,
    this.stars = 0,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final double w = box.maxWidth.isFinite ? box.maxWidth : 140;
        final double h = box.maxHeight.isFinite ? box.maxHeight : w / 1.4;
        final double beanH = h * 0.78;
        return Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            SizedBox(
              width: w,
              height: beanH,
              child: CustomPaint(
                painter: _BeanPainter(glow: highlight),
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: beanH * 0.04),
                    child: OutlinedGameText(
                      '$number',
                      fontSize: beanH * 0.42,
                      strokeWidth: beanH * 0.07,
                      fill: CoffeePalette.foam,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: beanH * 0.86,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  final bool on = i < stars;
                  final double s = h * (i == 1 ? 0.25 : 0.21);
                  return Padding(
                    padding: EdgeInsets.only(
                      top: i == 1 ? 0 : s * 0.15,
                      left: 1,
                      right: 1,
                    ),
                    child: Icon(
                      Icons.star_rounded,
                      size: s,
                      color:
                          on
                              ? CoffeePalette.gold
                              : CoffeePalette.espresso.withValues(alpha: 0.55),
                      shadows: [
                        Shadow(
                          color:
                              on
                                  ? CoffeePalette.cinnamon
                                  : Colors.black.withValues(alpha: 0.4),
                          offset: const Offset(0, 2),
                          blurRadius: 1,
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BeanPainter extends CustomPainter {
  final bool glow;

  _BeanPainter({this.glow = false});

  @override
  void paint(Canvas canvas, Size size) {
    final Rect bean = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: size.width * 0.92,
      height: size.height * 0.92,
    );
    final double depth = size.height * 0.07;

    if (glow) {
      canvas.drawOval(
        bean.inflate(size.height * 0.06),
        Paint()
          ..color = CoffeePalette.gold.withValues(alpha: 0.55)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }

    // Floor shadow.
    canvas.drawOval(
      bean.shift(Offset(0, depth * 1.4)).deflate(4),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Bean thickness (darker underside).
    canvas.drawOval(
      bean.shift(Offset(0, depth)),
      Paint()..color = CoffeePalette.espresso,
    );

    // Top face with a roasted gradient lit from the top-left.
    canvas.drawOval(
      bean,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.35, -0.55),
          radius: 0.95,
          colors: [
            CoffeePalette.cinnamon,
            CoffeePalette.mocha,
            CoffeePalette.roast,
          ],
          stops: [0.0, 0.55, 1.0],
        ).createShader(bean),
    );

    // The bean's S-shaped centre crease, drawn as a carved groove.
    final Path crease =
        Path()
          ..moveTo(
            bean.center.dx - bean.width * 0.40,
            bean.center.dy + bean.height * 0.10,
          )
          ..cubicTo(
            bean.center.dx - bean.width * 0.15,
            bean.center.dy - bean.height * 0.30,
            bean.center.dx + bean.width * 0.15,
            bean.center.dy + bean.height * 0.30,
            bean.center.dx + bean.width * 0.40,
            bean.center.dy - bean.height * 0.10,
          );
    canvas.drawPath(
      crease,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = size.height * 0.07
        ..color = CoffeePalette.espresso.withValues(alpha: 0.75),
    );
    canvas.drawPath(
      crease.shift(Offset(0, size.height * 0.035)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = size.height * 0.02
        ..color = CoffeePalette.honey.withValues(alpha: 0.35),
    );

    // Specular gloss on the upper-left.
    final Rect gloss = Rect.fromLTWH(
      bean.left + bean.width * 0.14,
      bean.top + bean.height * 0.08,
      bean.width * 0.42,
      bean.height * 0.24,
    );
    canvas.drawOval(
      gloss,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.55),
            Colors.white.withValues(alpha: 0.0),
          ],
        ).createShader(gloss),
    );

    // Rim light.
    canvas.drawOval(
      bean.deflate(1.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = CoffeePalette.honey.withValues(alpha: 0.45),
    );
  }

  @override
  bool shouldRepaint(_BeanPainter old) => old.glow != glow;
}

/// Shows [child] as a popup that springs in over a dimmed background.
Future<T?> showCoffeePopup<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool dismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: dismissible,
    barrierLabel: 'popup',
    barrierColor: CoffeePalette.espresso.withValues(alpha: 0.7),
    transitionDuration: const Duration(milliseconds: 450),
    pageBuilder:
        (context, a, b) => SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Material(
                type: MaterialType.transparency,
                child: builder(context),
              ),
            ),
          ),
        ),
    transitionBuilder: (context, anim, b, child) {
      final double t = Curves.elasticOut.transform(anim.value);
      return Opacity(
        opacity: anim.value.clamp(0.0, 1.0),
        child: Transform.scale(scale: 0.6 + 0.4 * t, child: child),
      );
    },
  );
}
