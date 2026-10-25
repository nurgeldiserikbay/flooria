import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/queens_guard/queens_guard_page.dart';

void main() {
  for (final size in <Size>[
    const Size(360, 640),
    const Size(390, 844),
  ]) {
    testWidgets('Queens Guard fits without scrolling on $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(home: QueensGuardPage(
        floor: 14,
        onComplete: () {},
        onSessionEnd: (_, __, ___) {},
      )));
      await tester.pump();
      expect(find.byKey(const ValueKey('queens-cell-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('queens-check-button')), findsOneWidget);
      expect(find.byType(GridView), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('restart clears player marks and progress', (tester) async {
    await tester.pumpWidget(MaterialApp(home: QueensGuardPage(
      floor: 5,
      onComplete: () {},
      onSessionEnd: (_, __, ___) {},
    )));
    await tester.tap(find.byTooltip('Restart'));
    await tester.pump();
    expect(find.text('1/5 queens'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
