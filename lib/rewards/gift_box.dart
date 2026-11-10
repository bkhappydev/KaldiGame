import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kaldi_app/accessibility/key_activate.dart';
import 'package:kaldi_app/common/coffee3d/coffee_3d.dart';
import 'package:kaldi_app/common/effects/confetti.dart';
import 'package:kaldi_app/localization/language/languages.dart';
import 'package:kaldi_app/rewards/reward_store.dart';
import 'package:kaldi_app/rewards/treats.dart';

/// A 3D wrapped present: front and side faces, a lid with its own top face,
/// a ribbon all the way round and a glossy bow.
class GiftBox3D extends StatelessWidget {
  final double size;

  /// [wrap, ribbon] colours (see [Treats.wrapColors]).
  final List<Color> colors;

  /// 0 = closed, 1 = lid blown off.
  final double lidOpen;

  const GiftBox3D({
    super.key,
    this.size = 140,
    this.colors = const [Color(0XFFFF5A5F), Color(0XFFFFC93C)],
    this.lidOpen = 0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GiftPainter(colors[0], colors[1], lidOpen)),
    );
  }
}

class _GiftPainter extends CustomPainter {
  final Color wrap;
  final Color ribbon;
  final double lidOpen;

  _GiftPainter(this.wrap, this.ribbon, this.lidOpen);

  @override
  void paint(Canvas canvas, Size s) {
    final double w = s.width, h = s.height;
    final double d = w * 0.14; // depth of the side face
    final Offset up = Offset(d, -d * 0.6); // direction "into" the scene

    final double l = w * 0.08, r = w * 0.76;
    final double top = h * 0.46, bottom = h * 0.94;
    final double cx = (l + r) / 2;
    final double band = w * 0.11;

    // Floor shadow.
    canvas.drawOval(
      Rect.fromLTRB(
        l - w * 0.02,
        bottom - h * 0.05,
        r + d + w * 0.04,
        bottom + h * 0.05,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // ---- Box body ----
    final Rect front = Rect.fromLTRB(l, top, r, bottom);
    _face(canvas, front, wrap, light: true);
    final Path side =
        Path()
          ..moveTo(r, top)
          ..lineTo(r + up.dx, top + up.dy)
          ..lineTo(r + up.dx, bottom + up.dy)
          ..lineTo(r, bottom)
          ..close();
    canvas.drawPath(side, Paint()..color = shade(wrap, 0.16));

    // Ribbon down the front and across the side.
    canvas.drawRect(
      Rect.fromLTRB(cx - band / 2, top, cx + band / 2, bottom),
      _ribbonPaint(Rect.fromLTRB(cx - band / 2, top, cx + band / 2, bottom)),
    );
    final double midY = (top + bottom) / 2;
    final Path sideBand =
        Path()
          ..moveTo(r, midY - band / 2)
          ..lineTo(r + up.dx, midY - band / 2 + up.dy)
          ..lineTo(r + up.dx, midY + band / 2 + up.dy)
          ..lineTo(r, midY + band / 2)
          ..close();
    canvas.drawPath(sideBand, Paint()..color = shade(ribbon, 0.14));

    // Gloss stripe on the front.
    canvas.drawRect(
      Rect.fromLTRB(
        l + w * 0.04,
        top + h * 0.04,
        l + w * 0.1,
        bottom - h * 0.06,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.22),
    );

    // ---- Lid (lifted and tilted while opening) ----
    canvas.save();
    final double lift = Curves.easeOut.transform(lidOpen);
    canvas.translate(-w * 0.25 * lift, -h * 0.55 * lift);
    canvas.translate(cx, top);
    canvas.rotate(-0.6 * lift);
    canvas.translate(-cx, -top);

    final double ll = l - w * 0.04, lr = r + w * 0.04;
    final double lt = top - h * 0.13, lb = top + h * 0.02;
    final Rect lidFront = Rect.fromLTRB(ll, lt, lr, lb);
    final Path lidTop =
        Path()
          ..moveTo(ll, lt)
          ..lineTo(ll + up.dx, lt + up.dy)
          ..lineTo(lr + up.dx, lt + up.dy)
          ..lineTo(lr, lt)
          ..close();
    final Path lidSide =
        Path()
          ..moveTo(lr, lt)
          ..lineTo(lr + up.dx, lt + up.dy)
          ..lineTo(lr + up.dx, lb + up.dy)
          ..lineTo(lr, lb)
          ..close();
    canvas.drawPath(lidTop, Paint()..color = shade(wrap, -0.1));
    canvas.drawPath(lidSide, Paint()..color = shade(wrap, 0.2));
    _face(canvas, lidFront, shade(wrap, -0.03), light: true);

    // Ribbon over the lid: front strip and a strip across the top face.
    canvas.drawRect(
      Rect.fromLTRB(cx - band / 2, lt, cx + band / 2, lb),
      _ribbonPaint(Rect.fromLTRB(cx - band / 2, lt, cx + band / 2, lb)),
    );
    final Path topBand =
        Path()
          ..moveTo(cx - band / 2, lt)
          ..lineTo(cx - band / 2 + up.dx, lt + up.dy)
          ..lineTo(cx + band / 2 + up.dx, lt + up.dy)
          ..lineTo(cx + band / 2, lt)
          ..close();
    canvas.drawPath(topBand, Paint()..color = shade(ribbon, -0.08));
    final Path topBand2 =
        Path()
          ..moveTo(ll + up.dx / 2, lt + up.dy / 2 - band * 0.3)
          ..lineTo(lr + up.dx / 2, lt + up.dy / 2 - band * 0.3)
          ..lineTo(lr + up.dx / 2, lt + up.dy / 2 + band * 0.3)
          ..lineTo(ll + up.dx / 2, lt + up.dy / 2 + band * 0.3)
          ..close();
    canvas.drawPath(topBand2, Paint()..color = shade(ribbon, -0.02));

    // Bow on top.
    final Offset knot = Offset(cx + up.dx / 2, lt + up.dy / 2);
    final double loop = w * 0.16;
    for (final double angle in [-0.55, 0.55]) {
      canvas.save();
      canvas.translate(knot.dx, knot.dy);
      canvas.rotate(angle);
      final Rect loopRect = Rect.fromCenter(
        center: Offset(angle < 0 ? -loop * 0.6 : loop * 0.6, -loop * 0.35),
        width: loop * 1.3,
        height: loop * 0.85,
      );
      canvas.drawOval(
        loopRect,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.3, -0.4),
            colors: [shade(ribbon, -0.18), ribbon, shade(ribbon, 0.18)],
            stops: const [0.0, 0.6, 1.0],
          ).createShader(loopRect),
      );
      canvas.drawOval(
        loopRect.deflate(loop * 0.22),
        Paint()..color = shade(ribbon, 0.25).withValues(alpha: 0.75),
      );
      canvas.restore();
    }
    canvas.drawCircle(
      knot,
      loop * 0.3,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.4),
          colors: [shade(ribbon, -0.2), shade(ribbon, 0.1)],
        ).createShader(Rect.fromCircle(center: knot, radius: loop * 0.3)),
    );
    canvas.restore();
  }

  void _face(Canvas canvas, Rect rect, Color c, {bool light = false}) {
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [shade(c, -0.08), c, shade(c, 0.08)],
        ).createShader(rect),
    );
  }

  Paint _ribbonPaint(Rect rect) =>
      Paint()
        ..shader = LinearGradient(
          colors: [
            shade(ribbon, 0.08),
            shade(ribbon, -0.15),
            shade(ribbon, 0.08),
          ],
        ).createShader(rect);

  @override
  bool shouldRepaint(_GiftPainter old) =>
      old.lidOpen != lidOpen || old.wrap != wrap || old.ribbon != ribbon;
}

/// A gift that wiggles every couple of seconds to say "open me".
class WigglingGift extends StatefulWidget {
  final double size;
  final List<Color> colors;

  const WigglingGift({
    super.key,
    this.size = 140,
    this.colors = const [Color(0XFFFF5A5F), Color(0XFFFFC93C)],
  });

  @override
  State<WigglingGift> createState() => _WigglingGiftState();
}

class _WigglingGiftState extends State<WigglingGift>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        // Wiggle during the first 30% of each cycle, rest otherwise.
        final double t = (_c.value / 0.3).clamp(0.0, 1.0);
        final double angle = t >= 1 ? 0 : sin(t * pi * 6) * 0.09 * (1 - t);
        final double hop = t >= 1 ? 0 : -sin(t * pi) * widget.size * 0.06;
        return Transform.translate(
          offset: Offset(0, hop),
          child: Transform.rotate(angle: angle, child: child),
        );
      },
      child: GiftBox3D(size: widget.size, colors: widget.colors),
    );
  }
}

/// A treat drawn big and glossy: a glowing coloured plate behind the sweet,
/// a soft shadow under it and a shine on top.
class Treat3D extends StatelessWidget {
  final Treat treat;
  final double size;
  final bool locked;

  const Treat3D({
    super.key,
    required this.treat,
    this.size = 90,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color c = locked ? CoffeePalette.mocha : treat.color;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glowing plate.
          Container(
            width: size * 0.92,
            height: size * 0.92,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.3, -0.4),
                colors: [shade(c, -0.25), c, shade(c, 0.2)],
                stops: const [0.0, 0.65, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: size * 0.1,
                  offset: Offset(0, size * 0.07),
                ),
              ],
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.7),
                width: size * 0.03,
              ),
            ),
          ),
          // The 3D treat picture (or a "?" while still locked).
          if (locked)
            Text(
              '?',
              style: TextStyle(
                fontSize: size * 0.45,
                fontFamily: kGameFont,
                color: CoffeePalette.crema,
                height: 1.0,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    offset: Offset(0, size * 0.05),
                    blurRadius: size * 0.05,
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: EdgeInsets.only(bottom: size * 0.04),
              child: Icon3D(treat.id, size: size * 0.66),
            ),
          // Shine across the top of the plate.
          Positioned(
            top: size * 0.1,
            left: size * 0.22,
            child: IgnorePointer(
              child: Container(
                width: size * 0.32,
                height: size * 0.14,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size),
                  color: Colors.white.withValues(alpha: 0.35),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Opens every waiting gift one by one in a celebratory popup.
Future<void> openWaitingGifts(BuildContext context) async {
  final RewardStore store = RewardStore.instance;
  while (store.pendingGifts > 0 && context.mounted) {
    final bool? again = await showCoffeePopup<bool>(
      context,
      dismissible: false,
      builder: (context) => _GiftOpenPopup(giftIndex: store.giftsOpened),
    );
    if (again != true) break;
  }
}

class _GiftOpenPopup extends StatefulWidget {
  final int giftIndex;

  const _GiftOpenPopup({required this.giftIndex});

  @override
  State<_GiftOpenPopup> createState() => _GiftOpenPopupState();
}

class _GiftOpenPopupState extends State<_GiftOpenPopup>
    with SingleTickerProviderStateMixin {
  final ConfettiController _confetti = ConfettiController();
  late final AnimationController _open = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  Treat? _treat;

  List<Color> get _colors =>
      Treats.wrapColors[widget.giftIndex % Treats.wrapColors.length];

  @override
  void dispose() {
    _open.dispose();
    _confetti.dispose();
    super.dispose();
  }

  Future<void> _openGift() async {
    if (_treat != null) return;
    final Treat? treat = await RewardStore.instance.openGift();
    if (treat == null || !mounted) return;
    HapticFeedback.mediumImpact();
    setState(() => _treat = treat);
    _open.forward();
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) _confetti.burst(origin: const Offset(0.5, 0.45));
    });
  }

  @override
  Widget build(BuildContext context) {
    final Languages lang = Languages.of(context)!;
    final String code = Localizations.localeOf(context).languageCode;
    final bool opened = _treat != null;
    final bool more = RewardStore.instance.pendingGifts > 0;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Coffee3DPanel(
          title: lang.txtYouWonGift,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 230,
                child: AnimatedBuilder(
                  animation: _open,
                  builder: (context, _) {
                    final double t = _open.value;
                    final double pop = Curves.elasticOut.transform(
                      ((t - 0.25) / 0.75).clamp(0.0, 1.0),
                    );
                    return Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        // Light rays behind the treat.
                        if (opened)
                          Transform.rotate(
                            angle: t * 1.2,
                            child: Opacity(
                              opacity: (t * 2).clamp(0.0, 1.0),
                              child: CustomPaint(
                                size: const Size(240, 240),
                                painter: _RaysPainter(
                                  _treat!.color.withValues(alpha: 0.45),
                                ),
                              ),
                            ),
                          ),
                        // Box sinks and fades as the treat rises.
                        Opacity(
                          opacity: (1 - t * 1.4).clamp(0.0, 1.0),
                          child: Semantics(
                            button: true,
                            label: lang.txtTapToOpen,
                            excludeSemantics: true,
                            onTap: _openGift,
                            // Focused straight away, so Enter or Space opens
                            // it without hunting for it.
                            child: KeyActivate(
                              onActivate: opened ? null : _openGift,
                              circle: true,
                              autofocus: true,
                              child: GestureDetector(
                                onTap: _openGift,
                                child:
                                    opened
                                        ? GiftBox3D(
                                          size: 170,
                                          colors: _colors,
                                          lidOpen: (t * 2.5).clamp(0.0, 1.0),
                                        )
                                        : WigglingGift(
                                          size: 170,
                                          colors: _colors,
                                        ),
                              ),
                            ),
                          ),
                        ),
                        if (opened)
                          Transform.translate(
                            offset: Offset(0, 30 - 40 * pop),
                            child: Transform.scale(
                              scale: pop,
                              child: Treat3D(treat: _treat!, size: 150),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Semantics(
                liveRegion: true,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child:
                      opened
                          ? OutlinedGameText(
                            lang.txtYouGot(_treat!.nameFor(code)),
                            key: const ValueKey('got'),
                            fontSize: 26,
                            fontFamily: code == 'en' ? kGameFont : null,
                            fill: CoffeePalette.gold,
                          )
                          : OutlinedGameText(
                            lang.txtTapToOpen,
                            key: const ValueKey('tap'),
                            fontSize: 24,
                            fontFamily: code == 'en' ? kGameFont : null,
                          ),
                ),
              ),
              const SizedBox(height: 16),
              if (!opened)
                Coffee3DButton(
                  semanticLabel: lang.txtTapToOpen,
                  color: CoffeePalette.cherry,
                  onTap: _openGift,
                  child: const Icon3D('nav_treats', size: 36),
                )
              else
                Coffee3DButton(
                  color: CoffeePalette.leaf,
                  onTap: () => Navigator.of(context).pop(more),
                  child: Text(
                    more ? '${lang.txtYummy}  ➜' : lang.txtYummy,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(child: Confetti(controller: _confetti)),
        ),
      ],
    );
  }
}

class _RaysPainter extends CustomPainter {
  final Color color;

  _RaysPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = size.center(Offset.zero);
    final double r = size.width / 2;
    final Paint p =
        Paint()
          ..shader = RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ).createShader(Rect.fromCircle(center: c, radius: r));
    const int rays = 12;
    for (int i = 0; i < rays; i++) {
      final double a = i * 2 * pi / rays;
      final Path ray =
          Path()
            ..moveTo(c.dx, c.dy)
            ..lineTo(c.dx + r * cos(a - 0.12), c.dy + r * sin(a - 0.12))
            ..lineTo(c.dx + r * cos(a + 0.12), c.dy + r * sin(a + 0.12))
            ..close();
      canvas.drawPath(ray, p);
    }
  }

  @override
  bool shouldRepaint(_RaysPainter old) => old.color != color;
}
