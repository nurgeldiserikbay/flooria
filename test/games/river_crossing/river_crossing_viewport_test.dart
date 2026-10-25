import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/river_crossing/river_crossing_page.dart';

void main() {
  for (final size in <Size>[const Size(360, 640), const Size(390, 844)]) {
    testWidgets('River Crossing fits $size without scrolling', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(home: RiverCrossingPage(
        floor: 10, onComplete: () {}, onSessionEnd: (_, __, ___) {})));
      await tester.pump();
      expect(find.byKey(const ValueKey('river-cross-button')), findsOneWidget);
      expect(find.byKey(const ValueKey('river-passenger-0')), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('invalid crossing and restart preserve safety', (tester) async {
    await tester.pumpWidget(MaterialApp(home: RiverCrossingPage(
      floor: 11, onComplete: () {}, onSessionEnd: (_, __, ___) {})));
    await tester.tap(find.byKey(const ValueKey('river-cross-button')));
    await tester.pump();
    expect(find.text('Unsafe crossing! Change your passengers.'),
        findsOneWidget);
    await tester.tap(find.byTooltip('Restart'));
    await tester.pump();
    expect(find.text('0 crossings'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
