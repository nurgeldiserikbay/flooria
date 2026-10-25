import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/pattern_trio/pattern_trio_page.dart';

void main() {
  for (final size in <Size>[
    const Size(360, 640),
    const Size(390, 844),
  ]) {
    testWidgets('Pattern Trio fits without scrolling at $size',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(home: PatternTrioPage(
        floor: 12,
        onComplete: () {},
        onSessionEnd: (_, __, ___) {},
      )));
      await tester.pump();
      expect(find.byKey(const ValueKey('pattern-card-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('pattern-card-8')), findsOneWidget);
      expect(find.byKey(const ValueKey('pattern-restart')), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('selection and restart reset attempts', (tester) async {
    await tester.pumpWidget(MaterialApp(home: PatternTrioPage(
      floor: 4,
      onComplete: () {},
      onSessionEnd: (_, __, ___) {},
    )));
    await tester.tap(find.byKey(const ValueKey('pattern-card-0')));
    await tester.pump();
    expect(find.text('Pick 3 cards. 1/3 selected.'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('pattern-restart')));
    await tester.pump();
    expect(find.text('0 tries • 0 misses'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
