import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/bridge_cut/bridge_cut_page.dart';

void main() {
  for (final size in <Size>[const Size(360, 640), const Size(390, 844)]) {
    testWidgets('Bridge Cut fits $size without scrolling',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(home: BridgeCutPage(
        floor: 17, onComplete: () {}, onSessionEnd: (_, __, ___) {})));
      await tester.pump();
      expect(find.byKey(const ValueKey('bridge-cut-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('bridge-check')), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('toggle and restart reset the action counter', (tester) async {
    await tester.pumpWidget(MaterialApp(home: BridgeCutPage(
      floor: 9, onComplete: () {}, onSessionEnd: (_, __, ___) {})));
    await tester.tap(find.byKey(const ValueKey('bridge-cut-0')));
    await tester.pump();
    expect(find.text('1 actions'), findsOneWidget);
    await tester.tap(find.byTooltip('Restart'));
    await tester.pump();
    expect(find.text('0 actions'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
