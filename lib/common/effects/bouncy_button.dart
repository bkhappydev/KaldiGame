import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kaldi_app/accessibility/key_activate.dart';

/// Wraps any widget so it squashes when pressed and springs back with a
/// little overshoot when released, with a click sound and a light vibration.
///
/// Use it in place of InkWell for anything a child taps.
class BouncyButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  /// Scale while the finger is down (1.0 = no squash).
  final double pressedScale;

  const BouncyButton({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.88,
  });

  @override
  State<BouncyButton> createState() => _BouncyButtonState();
}

class _BouncyButtonState extends State<BouncyButton>
    with SingleTickerProviderStateMixin {
  // 0 = resting, 1 = fully pressed. The release curve overshoots below 0,
  // which briefly scales the child above 1 for the "boing".
  late final AnimationController _press = AnimationController(
    vsync: this,
    lowerBound: -0.5,
    upperBound: 1.0,
    value: 0,
  );

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  void _down() {
    if (widget.onTap == null) return;
    _press.animateTo(
      1,
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeOut,
    );
  }

  void _release() {
    _press.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.elasticOut,
    );
  }

  void _tap() {
    if (widget.onTap == null) return;
    HapticFeedback.lightImpact();
    SystemSound.play(SystemSoundType.click);
    widget.onTap!();
  }

  @override
  Widget build(BuildContext context) {
    // Keyboard users (Tab + Enter/Space) get the same squash and bounce.
    return KeyActivate(
      onActivate: widget.onTap == null
          ? null
          : () {
              _down();
              Future.delayed(const Duration(milliseconds: 90), () {
                if (mounted) _release();
              });
              _tap();
            },
      child: _semantics(),
    );
  }

  // Screen readers announce it as one button; the child's text becomes the
  // label unless the child sets its own Semantics.
  Widget _semantics() {
    return Semantics(
      container: true,
      button: true,
      enabled: widget.onTap != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _down(),
        onTapUp: (_) => _release(),
        onTapCancel: _release,
        onTap: widget.onTap == null ? null : _tap,
        child: AnimatedBuilder(
          animation: _press,
          builder: (context, child) {
            final double scale = 1 - (1 - widget.pressedScale) * _press.value;
            return Transform.scale(scale: scale, child: child);
          },
          child: widget.child,
        ),
      ),
    );
  }
}
