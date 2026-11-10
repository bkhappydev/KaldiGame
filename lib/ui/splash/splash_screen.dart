import 'dart:math';

import 'package:flutter/material.dart';
import 'package:kaldi_app/accessibility/audio_clues.dart';
import 'package:kaldi_app/accessibility/narrator.dart';
import 'package:kaldi_app/common/banner/game_banner.dart';
import 'package:kaldi_app/common/coffee3d/coffee_3d.dart';
import 'package:kaldi_app/common/effects/coffee_bean_loader.dart';
import 'package:kaldi_app/rewards/reward_store.dart';
import 'package:kaldi_app/ui/shell/main_shell.dart';
import 'package:kaldi_app/ui/update/force_update_screen.dart';
import 'package:kaldi_app/utils/app_updater.dart';
import 'package:kaldi_app/utils/constant.dart';

/// Animated intro: the round Kaldi logo pops in inside a caramel ring while
/// coffee beans orbit it, the name appears, then it fades into the app.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  /// One-off entrance (logo pop, title rise).
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  /// Endless orbit of the beans around the logo.
  late final AnimationController _orbit = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  @override
  void initState() {
    super.initState();
    // Start the entrance and the timer only once the first frame is on
    // screen, so slow first frames never eat into the animation.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _intro.forward(from: 0);
      _goHome();
    });
  }

  Future<void> _goHome() async {
    // Forced update: if Google Play has a newer version, Play's full-screen
    // update runs; if it is declined, the game stays locked behind
    // ForceUpdateScreen. Started now so a slow or offline check overlaps the
    // intro instead of adding to it.
    final Future<UpdateCheck> updateCheck = AppUpdater.check();
    // Load rewards while the intro plays, and show it for at least ~2.2 s.
    await Future.wait([
      RewardStore.instance.load(),
      _precacheImages(),
      AudioClues.load(),
      Narrator.instance.init(),
      Future.delayed(const Duration(milliseconds: 3000)),
    ]);
    if (!mounted) return;
    final UpdateCheck update = await updateCheck;
    if (!mounted) return;
    final bool mustUpdate = update == UpdateCheck.mustUpdate;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder:
            (_, __, ___) =>
                mustUpdate ? const ForceUpdateScreen() : const MainShell(),
        transitionsBuilder:
            (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  /// Decodes the pictures every first screen shows (banners, bottom-bar
  /// icons, quiz card and answer stamps) while the intro plays, so they
  /// appear at once instead of popping in a moment later.
  Future<void> _precacheImages() async {
    final double dpr = MediaQuery.devicePixelRatioOf(context);
    final List<Future<void>> jobs = [
      for (final String path in [
        'assets/images/quiz_que.webp',
        'assets/images/right.webp',
        'assets/images/wrong.webp',
        for (final GameBannerItem b in kBannerRotation) b.asset,
      ])
        precacheImage(AssetImage(path), context),
      // Icon3D decodes at its display size, so warm the same size here.
      for (final String name in [
        'nav_play',
        'nav_treats',
        'nav_level',
        'nav_settings',
      ])
        precacheImage(
          ResizeImage(AssetImage(Icon3D.path(name)), width: (32 * dpr).round()),
          context,
        ),
    ];
    try {
      await Future.wait(jobs);
    } catch (_) {
      // A missing picture must never hold up the start of the game.
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    _orbit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double logo = 170;
    const double orbitSize = 250;
    return Scaffold(
      backgroundColor: BackgroundTheme.of(context).base,
      body: CoffeeBackdrop(
        child: Center(
          child: AnimatedBuilder(
            animation: Listenable.merge([_intro, _orbit]),
            builder: (context, _) {
              final double t = _intro.value;
              final double pop = Curves.elasticOut.transform(
                (t / 0.8).clamp(0.0, 1.0),
              );
              final double rise = Curves.easeOutCubic.transform(
                ((t - 0.45) / 0.55).clamp(0.0, 1.0),
              );
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: orbitSize,
                    height: orbitSize,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Spinning ring of coffee beans.
                        Opacity(
                          opacity: pop.clamp(0.0, 1.0),
                          child: CustomPaint(
                            size: const Size.square(orbitSize),
                            painter: _BeanOrbitPainter(
                              _orbit.value,
                              ringRadius: logo / 2 + 12,
                            ),
                          ),
                        ),
                        // Round logo with a caramel ring.
                        // Pops in, then breathes gently.
                        Transform.scale(
                          scale: pop * (1 + 0.03 * sin(_orbit.value * 4 * pi)),
                          child: Container(
                            width: logo,
                            height: logo,
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  CoffeePalette.honey,
                                  CoffeePalette.cinnamon,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.45),
                                  blurRadius: 18,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: CoffeePalette.crema,
                                  width: 3,
                                ),
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/images/kaldi_logo.png',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Opacity(
                    opacity: rise,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - rise)),
                      child: Column(
                        children: [
                          const OutlinedGameText(
                            'Kaldi',
                            fontSize: 52,
                            strokeWidth: 9,
                            fill: CoffeePalette.gold,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'by ${Constant.developerName}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: BackgroundTheme.of(context).onBackdropMuted,
                            ),
                          ),
                          const SizedBox(height: 18),
                          const CoffeeBeanLoader(size: 26),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Eight roasted coffee beans travelling round a circle, each one gently
/// tumbling as it goes.
class _BeanOrbitPainter extends CustomPainter {
  final double progress;

  /// Radius of the spinning caramel arcs hugging the logo.
  final double ringRadius;

  _BeanOrbitPainter(this.progress, {required this.ringRadius});

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = size.center(Offset.zero);
    final double r = size.width / 2 - 16;

    // Two caramel arcs spinning round the logo, the opposite way to the beans.
    final Paint arc =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round
          ..color = CoffeePalette.honey;
    final Rect ring = Rect.fromCircle(center: c, radius: ringRadius);
    final double spin = -progress * 2 * pi * 1.5;
    canvas.drawArc(ring, spin, pi * 0.6, false, arc);
    canvas.drawArc(ring, spin + pi, pi * 0.6, false, arc);

    // Faint dotted track.
    final Paint track =
        Paint()
          ..color = CoffeePalette.caramel.withValues(alpha: 0.35)
          ..style = PaintingStyle.fill;
    for (int i = 0; i < 48; i++) {
      final double a = i * 2 * pi / 48;
      canvas.drawCircle(c + Offset(cos(a), sin(a)) * r, 1.6, track);
    }

    const int beans = 8;
    for (int i = 0; i < beans; i++) {
      final double a = progress * 2 * pi + i * 2 * pi / beans;
      final Offset p = c + Offset(cos(a), sin(a)) * r;
      // Beans grow slightly toward the bottom for a sense of depth.
      final double s = 1 + 0.18 * sin(a);
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(a + progress * 4 * pi);
      canvas.scale(s);
      _bean(canvas);
      canvas.restore();
    }
  }

  void _bean(Canvas canvas) {
    const Rect body = Rect.fromLTWH(-9, -12, 18, 24);
    canvas.drawOval(
      body.shift(const Offset(0, 2)),
      Paint()..color = CoffeePalette.espresso.withValues(alpha: 0.6),
    );
    canvas.drawOval(
      body,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.4, -0.5),
          colors: [CoffeePalette.cinnamon, CoffeePalette.mocha],
        ).createShader(body),
    );
    final Path crease =
        Path()
          ..moveTo(0, -10)
          ..cubicTo(-5, -3, 5, 3, 0, 10);
    canvas.drawPath(
      crease,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..color = CoffeePalette.espresso,
    );
    canvas.drawOval(
      const Rect.fromLTWH(-6, -9, 6, 7),
      Paint()..color = Colors.white.withValues(alpha: 0.3),
    );
  }

  @override
  bool shouldRepaint(_BeanOrbitPainter old) => old.progress != progress;
}
