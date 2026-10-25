import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/bead_sort/bead_sort_engine.dart';
import 'package:flooria/games/bead_sort/bead_sort_page.dart';

void main() {
  for (final size in <Size>[
    const Size(360, 640),
    const Size(390, 844),
  ]) {
    testWidgets('Bead Sort fits without scrolling at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp(
        home: BeadSortPage(onComplete: () {}, onSessionEnd: (_, __) {}),
      ));

      expect(find.text('Bead Sort'), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('bead-tube-0')), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('reports completion once after the third sorted board',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const floor = 6;
    final solution = BeadSortSession(seed: floor * 1877, floor: floor);
    var completeCalls = 0;
    var endCalls = 0;
    await tester.pumpWidget(MaterialApp(home: BeadSortPage(
      floor: floor,
      onComplete: () => completeCalls++,
      onSessionEnd: (_, __) => endCalls++,
    )));

    for (var round = 0; round < BeadSortSession.totalRounds; round++) {
      for (final move in solution.puzzle.solutionMoves) {
        await tester.tap(find.byKey(ValueKey<String>('bead-tube-${move.from}')));
        await tester.tap(find.byKey(ValueKey<String>('bead-tube-${move.to}')));
        await tester.pump();
        solution.move(move.from, move.to);
      }
      if (round < BeadSortSession.totalRounds - 1) {
        await tester.tap(find.text('NEXT ROUND'));
        await tester.pump();
        solution.advance();
      }
    }

    expect(find.text('All colors sorted!'), findsOneWidget);
    expect(completeCalls, 1);
    expect(endCalls, 1);
    expect(tester.takeException(), isNull);
  });
}
