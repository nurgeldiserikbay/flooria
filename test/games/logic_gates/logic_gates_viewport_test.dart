import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/logic_gates/logic_gates_page.dart';

void main() {
  for (final size in <Size>[
    const Size(360, 640),
    const Size(390, 844),
  ]) {
    testWidgets('logic puzzle fits $size without scrolling', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(home: LogicGatesPage(
        floor: 9, onComplete: () {}, onSessionEnd: (_, __, ___) {})));
      await tester.pump();
      expect(find.byKey(const ValueKey('logic-switch-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('logic-switch-3')), findsOneWidget);
      expect(find.byKey(const ValueKey('logic-check')), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
      expect(find.byType(GridView), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('switches work and restart resets the counter', (tester) async {
    await tester.pumpWidget(MaterialApp(home: LogicGatesPage(
      floor: 8, onComplete: () {}, onSessionEnd: (_, __, ___) {})));
    await tester.tap(find.byKey(const ValueKey('logic-switch-0')));
    await tester.pump();
    expect(find.text('1 toggles'), findsOneWidget);
    await tester.tap(find.byTooltip('Restart'));
    await tester.pump();
    expect(find.text('0 toggles'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
