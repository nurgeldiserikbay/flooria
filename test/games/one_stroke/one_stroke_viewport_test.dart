import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/one_stroke/one_stroke_page.dart';

void main() {
  for (final size in <Size>[const Size(360, 640), const Size(390, 844)]) {
    testWidgets('One Stroke fits $size without scrolling', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(home: OneStrokePage(
        floor: 12, onComplete: () {}, onSessionEnd: (_, __, ___) {})));
      await tester.pump();
      expect(find.byKey(const ValueKey('stroke-node-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('stroke-restart')), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
      expect(find.byType(GridView), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('restart clears moves and invalid actions are handled',
      (tester) async {
    await tester.pumpWidget(MaterialApp(home: OneStrokePage(
      floor: 19, onComplete: () {}, onSessionEnd: (_, __, ___) {})));
    await tester.tap(find.byKey(const ValueKey('stroke-node-0')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('stroke-restart')));
    await tester.pump();
    expect(find.text('0 moves'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
