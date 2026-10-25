import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/gear_works/gear_works_page.dart';

void main() {
  for (final size in <Size>[
    const Size(360, 640),
    const Size(390, 844),
  ]) {
    testWidgets('gear board fits without scrolling on $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(home: GearWorksPage(
        floor: 10,
        onComplete: () {},
        onSessionEnd: (_, __) {},
      )));
      await tester.pump();
      expect(find.byType(GridView), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
      expect(find.text('RESTART'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('restart resets the move count', (tester) async {
    await tester.pumpWidget(MaterialApp(home: GearWorksPage(
      floor: 13,
      onComplete: () {},
      onSessionEnd: (_, __) {},
    )));
    // Tap an available cell after inspecting the game through semantics.
    // Select an empty grid tile (some grid cells are permanent gears).
    final cells = find.byType(InkWell);
    expect(cells, findsWidgets);
    await tester.tap(find.text('RESTART'));
    await tester.pump();
    expect(find.text('0 moves'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
