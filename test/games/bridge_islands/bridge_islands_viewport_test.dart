import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/bridge_islands/bridge_islands_page.dart';

void main() {
  for (final size in <Size>[
    const Size(360, 640),
    const Size(390, 844),
  ]) {
    testWidgets('Bridge Islands is visible at $size without page scroll',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(home: BridgeIslandsPage(
        floor: 9, onComplete: () {}, onSessionEnd: (_, __, ___) {})));
      await tester.pump();
      for (var i = 0; i < 7; i++) {
        expect(find.byKey(ValueKey('bridge-edge-$i')), findsOneWidget);
      }
      expect(find.byKey(const ValueKey('bridge-check')), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('bridge tap and restart reset recorded moves', (tester) async {
    await tester.pumpWidget(MaterialApp(home: BridgeIslandsPage(
      floor: 5, onComplete: () {}, onSessionEnd: (_, __, ___) {})));
    await tester.tap(find.byKey(const ValueKey('bridge-edge-0')));
    await tester.pump();
    expect(find.text('1 taps'), findsOneWidget);
    await tester.tap(find.byTooltip('Restart'));
    await tester.pump();
    expect(find.text('0 taps'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
