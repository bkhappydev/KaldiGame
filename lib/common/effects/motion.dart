import 'dart:math';

import 'package:flutter/material.dart';

/// Shakes its child side to side each time [trigger] changes to a new value.
/// Used for a wrong answer.
class Shake extends StatefulWidget {
  final Widget child;
  final Object? trigger;

  const Shake({super.key, required this.child, this.trigger});

  @override
  State<Shake> createState() => _ShakeState();
}

class _ShakeState extends State<Shake> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  @override
  void didUpdateWidget(Shake oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != null && widget.trigger != oldWidget.trigger) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double t = _controller.value;
        final double dx = sin(t * pi * 8) * 12 * (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: widget.child,
    );
  }
}

/// Gently grows and shrinks forever, to say "tap me".
class Pulse extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final double amount;
  final Duration period;

  const Pulse({
    super.key,
    required this.child,
    this.enabled = true,
    this.amount = 0.07,
    this.period = const Duration(milliseconds: 900),
  });

  @override
  State<Pulse> createState() => _PulseState();
}

class _PulseState extends State<Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.period);

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(Pulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    if (widget.enabled && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.enabled && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return ScaleTransition(
      scale: Tween<double>(begin: 1, end: 1 + widget.amount).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: widget.child,
    );
  }
}

/// Floats its child slowly up and down, like it is bobbing on water.
class Float extends StatefulWidget {
  final Widget child;
  final double distance;
  final Duration period;

  const Float({
    super.key,
    required this.child,
    this.distance = 8,
    this.period = const Duration(milliseconds: 1800),
  });

  @override
  State<Float> createState() => _FloatState();
}

class _FloatState extends State<Float> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.period)
        ..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double y =
            Curves.easeInOut.transform(_controller.value) * widget.distance -
                widget.distance / 2;
        return Transform.translate(offset: Offset(0, y), child: child);
      },
      child: widget.child,
    );
  }
}

/// Pops its child in from nothing with a springy overshoot when first built,
/// or whenever [popKey] changes.
class PopIn extends StatelessWidget {
  final Widget child;
  final Object? popKey;
  final Duration delay;
  final Duration duration;

  const PopIn({
    super.key,
    required this.child,
    this.popKey,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 700),
  });

  @override
  Widget build(BuildContext context) {
    final int total = (delay + duration).inMilliseconds;
    final double start = total == 0 ? 0 : delay.inMilliseconds / total;
    return TweenAnimationBuilder<double>(
      key: ValueKey(popKey),
      tween: Tween(begin: 0, end: 1),
      duration: delay + duration,
      builder: (context, t, child) {
        final double local = start >= 1
            ? 1
            : ((t - start) / (1 - start)).clamp(0.0, 1.0);
        final double scale = Curves.elasticOut.transform(local);
        return Opacity(
          opacity: local.clamp(0.0, 1.0),
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: child,
    );
  }
}
