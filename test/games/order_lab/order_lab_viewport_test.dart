import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/order_lab/order_lab_page.dart';

void main() {
  for (final size in <Size>[const Size(360, 640), const Size(390, 844)]) {
    testWidgets('Order Lab is visible without scrolling at $size',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(home: OrderLabPage(
        floor: 8, onComplete: () {}, onSessionEnd: (_, __, ___) {})));
      await tester.pump();
      expect(find.byKey(const ValueKey('order-tile-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('order-tile-3')), findsOneWidget);
      expect(find.byKey(const ValueKey('order-check')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('swap and restart reset the counter', (tester) async {
    await tester.pumpWidget(MaterialApp(home: OrderLabPage(
      floor: 12, onComplete: () {}, onSessionEnd: (_, __, ___) {})));
    await tester.tap(find.byKey(const ValueKey('order-tile-0')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('order-tile-1')));
    await tester.pump();
    expect(find.text('1 swaps'), findsOneWidget);
    await tester.tap(find.byTooltip('Restart'));
    await tester.pump();
    expect(find.text('0 swaps'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
