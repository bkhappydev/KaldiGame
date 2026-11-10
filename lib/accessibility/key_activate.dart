import 'package:flutter/material.dart';
import 'package:kaldi_app/common/coffee3d/coffee_3d.dart';

/// Makes a custom tap target usable without a touch screen.
///
/// * It joins the Tab / Shift+Tab focus order (and the focus order screen
///   readers such as JAWS, NVDA, Narrator, TalkBack and VoiceOver follow).
/// * Enter, Space and the gamepad/TV "select" button activate it.
/// * While it has keyboard focus it shows a thick white-and-espresso ring,
///   visible on both the dark coffee background and the cream cards.
///
/// Wrap the visual of a button in it; it adds nothing on touch-only use.
class KeyActivate extends StatefulWidget {
  final Widget child;
  final VoidCallback? onActivate;
  final BorderRadius borderRadius;
  final bool circle;
  final bool autofocus;

  const KeyActivate({
    super.key,
    required this.child,
    required this.onActivate,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.circle = false,
    this.autofocus = false,
  });

  @override
  State<KeyActivate> createState() => _KeyActivateState();
}

class _KeyActivateState extends State<KeyActivate> {
  bool _showRing = false;

  late final Map<Type, Action<Intent>> _actions = {
    ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: _invoke),
    ButtonActivateIntent:
        CallbackAction<ButtonActivateIntent>(onInvoke: _invoke),
  };

  Object? _invoke(Intent _) {
    widget.onActivate?.call();
    return null;
  }

  BoxDecoration _ring(Color color, double grow) => BoxDecoration(
        shape: widget.circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: widget.circle
            ? null
            : widget.borderRadius.add(BorderRadius.all(Radius.circular(grow))),
        border: Border.all(color: color, width: 3),
      );

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onActivate != null;
    return FocusableActionDetector(
      enabled: enabled,
      autofocus: widget.autofocus,
      actions: _actions,
      onShowFocusHighlight: (show) {
        if (show != _showRing) setState(() => _showRing = show);
      },
      child: Stack(
        // Pass the parent's constraints straight to the button, so wrapping
        // never changes its size (a plain Stack would loosen them).
        fit: StackFit.passthrough,
        clipBehavior: Clip.none,
        children: [
          widget.child,
          if (_showRing && enabled)
            Positioned(
              left: -8,
              top: -8,
              right: -8,
              bottom: -8,
              child: IgnorePointer(
                // Espresso outer line + white inner line: one of the two
                // always contrasts with whatever is behind the button.
                child: DecoratedBox(
                  decoration: _ring(CoffeePalette.espresso, 8),
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: DecoratedBox(decoration: _ring(Colors.white, 5)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A plain tap area (like an opaque GestureDetector) that keyboard users can
/// also focus with Tab and press with Enter or Space.
class TapArea extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget child;
  final BorderRadius borderRadius;

  const TapArea({
    super.key,
    required this.onTap,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
  });

  @override
  Widget build(BuildContext context) {
    return KeyActivate(
      onActivate: onTap,
      borderRadius: borderRadius,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: child,
      ),
    );
  }
}
