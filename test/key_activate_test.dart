import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaldi_app/accessibility/key_activate.dart';

void main() {
  testWidgets('Tab focuses a KeyActivate, shows the ring, Enter activates',
      (tester) async {
    int taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: KeyActivate(
              onActivate: () => taps++,
              child: const SizedBox(width: 100, height: 50),
            ),
          ),
        ),
      ),
    );

    // No ring before keyboard use.
    expect(find.byType(DecoratedBox), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(find.byType(DecoratedBox), findsWidgets,
        reason: 'focus ring should show after Tab');

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(taps, 1);

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(taps, 2);
  });

  testWidgets('wrapping does not change the size of the button',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Row(
          children: [
            Expanded(
              child: KeyActivate(
                onActivate: () {},
                child: Container(key: const Key('face'), height: 40),
              ),
            ),
          ],
        ),
      ),
    );
    final Size size = tester.getSize(find.byKey(const Key('face')));
    expect(size.width, 800);
  });
}

