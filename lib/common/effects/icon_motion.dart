import 'dart:math';

import 'package:flutter/material.dart';

/// A playful, looping movement for a picture. Each home-screen category gets
/// a different one that suits its picture, so the screen feels alive and
/// every card catches the eye in its own way.
enum IconMotion {
  /// Jumps up and lands with a little squash (number blocks).
  hop,

  /// Quick head shake, then a rest (lion).
  shake,

  /// Gentle sway and bob, like a cup being carried (coffee).
  sway,

  /// Jelly wobble: stretches tall, then wide (apple).
  jelly,

  /// Tilts its head left and right as if saying hello (face).
  tilt,

  /// Double "ba-dum" heartbeat pulse (house).
  heartbeat,

  /// Blasts forward along its nose and back, with a rumble (rocket).
  blast,

  /// Rolls left and right, turning as it goes (ball).
  roll,

  /// Turns around its own axis like a spinning globe (Ethiopia & world).
  turn,

  /// Swings from side to side and sparkles bigger (crown).
  swing,
}

/// Plays [motion] on [child] forever. Each motion has its own speed, and
/// every icon starts at a different point, so neighbours never move in sync.
///
/// Respects the phone's "remove animations" accessibility setting: the
/// picture then stays still.
class MovingIcon extends StatefulWidget {
  final IconMotion motion;
  final Widget child;

  /// Size of the picture, used to scale how far it moves.
  final double size;

  const MovingIcon({
    super.key,
    required this.motion,
    required this.size,
    required this.child,
  });

  /// The movement for each home-screen category (QuizCategory.id).
  static IconMotion forCategory(String id) => switch (id) {
        'basics' => IconMotion.hop,
        'animals' => IconMotion.shake,
        'culture' => IconMotion.sway,
        'food' => IconMotion.jelly,
        'me' => IconMotion.tilt,
        'home' => IconMotion.heartbeat,
        'science' => IconMotion.blast,
        'fun' => IconMotion.roll,
        'ethiopia' => IconMotion.turn,
        'people' => IconMotion.swing,
        _ => IconMotion.hop,
      };

  @override
  State<MovingIcon> createState() => _MovingIconState();
}

class _MovingIconState extends State<MovingIcon>
    with SingleTickerProviderStateMixin {
  static Duration _periodOf(IconMotion m) => Duration(
        milliseconds: switch (m) {
          IconMotion.hop => 1300,
          IconMotion.shake => 2600,
          IconMotion.sway => 3000,
          IconMotion.jelly => 1700,
          IconMotion.tilt => 2800,
          IconMotion.heartbeat => 1600,
          IconMotion.blast => 2400,
          IconMotion.roll => 3600,
          IconMotion.turn => 4000,
          IconMotion.swing => 2400,
        },
      );

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: _periodOf(widget.motion),
    // Start each motion part-way through so the cards don't move in step.
    value: (widget.motion.index * 0.37) % 1.0,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.stop();
      _c.value = 0;
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    // RepaintBoundary: only the picture repaints each frame, not the card.
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) =>
            _apply(widget.motion, _c.value, widget.size, child!),
        child: widget.child,
      ),
    );
  }

  /// One full cycle of [motion] at phase [t] (0..1).
  static Widget _apply(IconMotion motion, double t, double size, Widget child) {
    final double s = sin(2 * pi * t);
    switch (motion) {
      case IconMotion.hop:
        // Up and down on a bouncy arc; squashes for a moment on landing.
        final double air = (sin(pi * t)).abs();
        final double land = t < 0.12 || t > 0.88 ? 1 - air : 0;
        return Transform.translate(
          offset: Offset(0, -air * size * 0.12),
          child: Transform.scale(
            scaleX: 1 + land * 0.10,
            scaleY: 1 - land * 0.10,
            alignment: Alignment.bottomCenter,
            child: child,
          ),
        );

      case IconMotion.shake:
        // Shake in the first third, then rest.
        final double k = t < 0.35 ? sin(t / 0.35 * pi * 4) * (1 - t / 0.35) : 0;
        return Transform.rotate(angle: k * 0.22, child: child);

      case IconMotion.sway:
        return Transform.translate(
          offset: Offset(0, -sin(4 * pi * t).abs() * size * 0.04),
          child: Transform.rotate(angle: s * 0.10, child: child),
        );

      case IconMotion.jelly:
        return Transform.scale(
          scaleX: 1 - s * 0.08,
          scaleY: 1 + s * 0.08,
          alignment: Alignment.bottomCenter,
          child: child,
        );

      case IconMotion.tilt:
        return Transform.translate(
          offset: Offset(0, -sin(4 * pi * t).abs() * size * 0.03),
          child: Transform.rotate(
            angle: s * 0.16,
            alignment: Alignment.bottomCenter,
            child: child,
          ),
        );

      case IconMotion.heartbeat:
        // Two quick beats, then a pause: ba-dum ... ba-dum.
        double beat(double at) {
          final double d = (t - at).abs();
          return d < 0.08 ? cos(d / 0.08 * pi / 2) : 0;
        }
        final double k = beat(0.12) + beat(0.32) * 0.7;
        return Transform.scale(scale: 1 + k * 0.10, child: child);

      case IconMotion.blast:
        // The rocket points up-right: fly that way and drift back, with a
        // fine rumble the whole time.
        final double push = sin(pi * t) * sin(pi * t);
        final double rumble = sin(2 * pi * t * 18) * size * 0.008;
        return Transform.translate(
          offset: Offset(
            push * size * 0.08 + rumble,
            -push * size * 0.08 + rumble,
          ),
          child: child,
        );

      case IconMotion.roll:
        // Rolls right then left; the turn matches the distance travelled.
        final double x = s * size * 0.10;
        return Transform.translate(
          offset: Offset(x, 0),
          child: Transform.rotate(angle: x / (size * 0.45), child: child),
        );

      case IconMotion.turn:
        // Turns to the left and right around its upright axis, with
        // perspective so it looks like a real globe turning.
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0015)
            ..rotateY(s * 0.55),
          child: child,
        );

      case IconMotion.swing:
        return Transform.rotate(
          angle: s * 0.14,
          alignment: Alignment.topCenter,
          child: Transform.scale(
            scale: 1 + sin(4 * pi * t).abs() * 0.05,
            child: child,
          ),
        );
    }
  }
}
