import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/domino_fit/domino_fit_page.dart';

void main() {
  for (final size in <Size>[const Size(360, 640), const Size(390, 844)]) {
    testWidgets('Domino Fit is playable without page scrolling at $size',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(home: DominoFitPage(
        floor: 11, onComplete: () {}, onSessionEnd: (_, __, ___) {})));
      await tester.pump();
      expect(find.byKey(const ValueKey('domino-cell-0')), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
      expect(find.byType(GridView), findsOneWidget);
      expect(find.text('RESTART'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a selected tile can be restarted', (tester) async {
    await tester.pumpWidget(MaterialApp(home: DominoFitPage(
      floor: 10, onComplete: () {}, onSessionEnd: (_, __, ___) {})));
    await tester.tap(find.byKey(const ValueKey('domino-cell-0')));
    await tester.pump();
    await tester.tap(find.text('RESTART'));
    await tester.pump();
    expect(find.text('0 moves'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
