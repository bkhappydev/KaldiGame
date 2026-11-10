import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaldi_app/common/effects/bouncy_button.dart';

void main() {
  testWidgets('Enter on a BouncyButton that opens a page springs back',
      (tester) async {
    final GlobalKey<NavigatorState> nav = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: nav,
        home: Scaffold(
          body: Center(
            child: BouncyButton(
              onTap: () => nav.currentState!.push(
                MaterialPageRoute(builder: (_) => const Scaffold()),
              ),
              child: const SizedBox(
                key: Key('face'),
                width: 100,
                height: 50,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    nav.currentState!.pop();
    await tester.pumpAndSettle();

    final Transform t = tester.widget<Transform>(
      find.ancestor(
        of: find.byKey(const Key('face')),
        matching: find.byType(Transform),
      ).first,
    );
    expect(t.transform.getMaxScaleOnAxis(), closeTo(1.0, 0.001));
  });
}
