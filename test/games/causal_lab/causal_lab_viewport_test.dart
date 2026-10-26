import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/causal_lab/causal_lab_page.dart';

void main() {
  for (final size in <Size>[const Size(360, 640), const Size(390, 844)]) {
    testWidgets('causal lab fits $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(home: CausalLabPage(
        floor: 3, onComplete: () {}, onSessionEnd: (_, __) {})));
      await tester.pump();
      expect(find.text('Causal Lab'), findsOneWidget);
      expect(find.byKey(const ValueKey('causal-test-0-0')), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('experiment tap advances the round', (tester) async {
    await tester.pumpWidget(MaterialApp(home: CausalLabPage(
      floor: 1, onComplete: () {}, onSessionEnd: (_, __) {})));
    await tester.tap(find.byKey(const ValueKey('causal-test-0-0')));
    await tester.pump();
    expect(find.text('2 / 5'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
