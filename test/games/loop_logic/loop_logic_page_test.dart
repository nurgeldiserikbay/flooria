import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/loop_logic/loop_logic_engine.dart';
import 'package:flooria/games/loop_logic/loop_logic_page.dart';

void main() {
  for (final size in <Size>[
    const Size(360, 640),
    const Size(390, 844),
  ]) {
    testWidgets('Loop Logic fits without scrolling at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp(
        home: LoopLogicPage(onComplete: () {}, onSessionEnd: (_, __) {}),
      ));

      expect(find.text('Loop Logic'), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('loop-board-painter')),
          findsOneWidget);
      expect(find.byType(ListView), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('reports one campaign completion after three closed loops',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const floor = 5;
    final expected = LoopLogicSession(seed: floor * 1877);
    var completeCalls = 0;
    var endCalls = 0;
    await tester.pumpWidget(MaterialApp(
      home: LoopLogicPage(
        floor: floor,
        onComplete: () => completeCalls++,
        onSessionEnd: (_, __) => endCalls++,
      ),
    ));

    for (var round = 0; round < LoopLogicSession.totalRounds; round++) {
      for (final edge in expected.puzzle.solutionEdges) {
        await tester.tap(
          find.byKey(ValueKey<String>('loop-edge-${edge.id}')),
        );
        await tester.pump();
        expected.toggle(edge);
      }
      expect(find.text('Loop closed!'), findsOneWidget);
      await tester.tap(find.text('NEXT LOOP'));
      await tester.pump();
      expected.advance();
    }

    expect(find.text('Three loops complete!'), findsOneWidget);
    expect(completeCalls, 1);
    expect(endCalls, 1);
    expect(tester.takeException(), isNull);
  });
}
