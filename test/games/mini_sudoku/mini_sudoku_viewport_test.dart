import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/mini_sudoku/mini_sudoku_page.dart';

void main() {
  for (final size in <Size>[const Size(360, 640), const Size(390, 844)]) {
    testWidgets('Mini Sudoku fits phone viewport $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(home: MiniSudokuPage(
        floor: 9,
        onComplete: () {},
        onSessionEnd: (_, __, ___) {},
      )));
      await tester.pump();
      expect(find.byKey(const ValueKey('sudoku-cell-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('sudoku-cell-15')), findsOneWidget);
      expect(find.byKey(const ValueKey('sudoku-check')), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('restart keeps the UI usable', (tester) async {
    await tester.pumpWidget(MaterialApp(home: MiniSudokuPage(
      floor: 12,
      onComplete: () {},
      onSessionEnd: (_, __, ___) {},
    )));
    await tester.tap(find.byTooltip('Restart'));
    await tester.pump();
    expect(find.text('0 edits'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
