import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/clover_sweep/clover_sweep_engine.dart';
import 'package:flooria/games/clover_sweep/clover_sweep_page.dart';

void main() {
  for (final size in <Size>[
    const Size(360, 640),
    const Size(390, 844),
  ]) {
    testWidgets('Clover Sweep fits without scrolling at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp(
        home: CloverSweepPage(onComplete: () {}, onSessionEnd: (_, __) {}),
      ));

      expect(find.text('Clover Sweep'), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('clover-grid')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('clover-cell-0')), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('reports campaign completion once after three safe patches',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const floor = 9;
    final expected = CloverSweepSession(seed: floor * 1877);
    var completeCalls = 0;
    var endCalls = 0;
    await tester.pumpWidget(MaterialApp(
      home: CloverSweepPage(
        floor: floor,
        onComplete: () => completeCalls++,
        onSessionEnd: (_, __) => endCalls++,
      ),
    ));

    for (var round = 0; round < CloverSweepSession.totalRounds; round++) {
      for (var cell = 0;
          cell < CloverSweepPuzzle.cellCount && !expected.roundComplete;
          cell++) {
        if (expected.puzzle.mines.contains(cell) ||
            expected.puzzle.revealedSafeCells.contains(cell)) {
          continue;
        }
        await tester.tap(
          find.byKey(ValueKey<String>('clover-cell-$cell')),
        );
        await tester.pump();
        expected.reveal(cell);
      }
      expect(find.text('Patch cleared!'), findsOneWidget);
      await tester.tap(find.text('NEXT PATCH'));
      await tester.pump();
      expected.advance();
    }

    expect(find.text('The garden is safe!'), findsOneWidget);
    expect(completeCalls, 1);
    expect(endCalls, 1);
    expect(tester.takeException(), isNull);
  });
}
