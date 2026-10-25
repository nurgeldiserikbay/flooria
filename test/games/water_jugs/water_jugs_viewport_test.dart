import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/water_jugs/water_jugs_page.dart';

void main() {
  for (final size in <Size>[const Size(360, 640), const Size(390, 844)]) {
    testWidgets('Water Jugs fits $size without scrolling', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(home: WaterJugsPage(
        floor: 10, onComplete: () {}, onSessionEnd: (_, __, ___) {})));
      await tester.pump();
      expect(find.byKey(const ValueKey('jug-fillA')), findsOneWidget);
      expect(find.byKey(const ValueKey('jug-pourAtoB')), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
      expect(find.byType(GridView), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('actions and restart clear the measured moves', (tester) async {
    await tester.pumpWidget(MaterialApp(home: WaterJugsPage(
      floor: 19, onComplete: () {}, onSessionEnd: (_, __, ___) {})));
    await tester.tap(find.byKey(const ValueKey('jug-fillA')));
    await tester.pump();
    expect(find.text('1 moves'), findsOneWidget);
    await tester.tap(find.byTooltip('Restart'));
    await tester.pump();
    expect(find.text('0 moves'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
