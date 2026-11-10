import 'dart:math';

import 'package:flutter/material.dart';

/// Bright, child-friendly confetti colours.
const List<Color> kConfettiColors = [
  Color(0xFFFF5A5F),
  Color(0xFFFFC93C),
  Color(0xFF3CB878),
  Color(0xFF00B4D8),
  Color(0xFF9B5DE5),
  Color(0xFFFF8FAB),
  Color(0xFFFFFFFF),
];

/// Triggers bursts on a [Confetti] layer.
class ConfettiController extends ChangeNotifier {
  Offset _origin = const Offset(0.5, 0.4);
  bool _rain = false;

  Offset get origin => _origin;
  bool get rain => _rain;

  /// Pops confetti outward from [origin], given as a fraction of the layer
  /// size (0,0 = top left, 1,1 = bottom right).
  void burst({Offset origin = const Offset(0.5, 0.4)}) {
    _origin = origin;
    _rain = false;
    notifyListeners();
  }

  /// Drops confetti from the top edge across the whole width.
  void shower() {
    _rain = true;
    notifyListeners();
  }
}

/// A full-size, touch-transparent layer that draws confetti when its
/// [controller] fires. Put it on top of the screen content in a Stack.
class Confetti extends StatefulWidget {
  final ConfettiController controller;
  final int particleCount;

  const Confetti({
    super.key,
    required this.controller,
    this.particleCount = 70,
  });

  @override
  State<Confetti> createState() => _ConfettiState();
}

class _Particle {
  Offset position;
  Offset velocity;
  final Color color;
  final double size;
  final bool circle;
  double angle;
  final double spin;

  _Particle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
    required this.circle,
    required this.angle,
    required this.spin,
  });
}

class _ConfettiState extends State<Confetti>
    with SingleTickerProviderStateMixin {
  final Random _random = Random();
  final List<_Particle> _particles = [];
  late final AnimationController _ticker = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..addListener(_step);
  Duration _last = Duration.zero;
  Size _size = Size.zero;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_fire);
  }

  @override
  void didUpdateWidget(Confetti oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_fire);
      widget.controller.addListener(_fire);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_fire);
    _ticker.dispose();
    super.dispose();
  }

  void _fire() {
    if (_size.isEmpty) return;
    _particles.clear();
    final bool rain = widget.controller.rain;
    final Offset origin = Offset(
      widget.controller.origin.dx * _size.width,
      widget.controller.origin.dy * _size.height,
    );
    for (int i = 0; i < widget.particleCount; i++) {
      final Offset velocity;
      final Offset position;
      if (rain) {
        position = Offset(_random.nextDouble() * _size.width,
            -20 - _random.nextDouble() * _size.height * 0.4);
        velocity = Offset((_random.nextDouble() - 0.5) * 120,
            150 + _random.nextDouble() * 200);
      } else {
        final double angle = _random.nextDouble() * 2 * pi;
        final double speed = 250 + _random.nextDouble() * 550;
        position = origin;
        velocity = Offset(cos(angle) * speed, sin(angle) * speed - 300);
      }
      _particles.add(_Particle(
        position: position,
        velocity: velocity,
        color: kConfettiColors[_random.nextInt(kConfettiColors.length)],
        size: 6 + _random.nextDouble() * 8,
        circle: _random.nextBool(),
        angle: _random.nextDouble() * pi,
        spin: (_random.nextDouble() - 0.5) * 12,
      ));
    }
    _last = Duration.zero;
    _ticker.forward(from: 0);
  }

  void _step() {
    final Duration now = _ticker.lastElapsedDuration ?? Duration.zero;
    final double dt = (now - _last).inMicroseconds / 1e6;
    _last = now;
    if (dt <= 0) return;
    for (final p in _particles) {
      // Gravity plus air drag so pieces flutter down instead of falling fast.
      p.velocity = Offset(p.velocity.dx * 0.985, p.velocity.dy * 0.985 + 600 * dt);
      p.position += p.velocity * dt;
      p.angle += p.spin * dt;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          _size = constraints.biggest;
          return CustomPaint(
            size: _size,
            painter: _ConfettiPainter(
              _ticker.isAnimating ? _particles : const [],
              // Fade everything out over the last third of the animation.
              opacity: (1 - ((_ticker.value - 0.66) / 0.34)).clamp(0.0, 1.0),
            ),
          );
        },
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double opacity;

  _ConfettiPainter(this.particles, {required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint();
    for (final p in particles) {
      paint.color = p.color.withValues(alpha: opacity);
      canvas.save();
      canvas.translate(p.position.dx, p.position.dy);
      canvas.rotate(p.angle);
      if (p.circle) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.5),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}
