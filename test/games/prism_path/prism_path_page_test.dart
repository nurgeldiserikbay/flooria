import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/prism_path/prism_path_engine.dart';
import 'package:flooria/games/prism_path/prism_path_page.dart';

void main() {
  for (final size in <Size>[
    const Size(360, 640),
    const Size(390, 844),
  ]) {
    testWidgets('Prism Path fits without scrolling at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp(
        home: PrismPathPage(
          onComplete: () {},
          onSessionEnd: (_, __, ___) {},
        ),
      ));
      await tester.pump();

      expect(find.byType(GridView), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
      expect(find.text('RESTART'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('campaign completion is reported once after all three routes',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const floor = 8;
    final expected = PrismPathSession(seed: floor * 1877);
    var completeCalls = 0;
    var sessionCalls = 0;
    var reportedRounds = 0;

    await tester.pumpWidget(MaterialApp(
      home: PrismPathPage(
        floor: floor,
        onComplete: () => completeCalls++,
        onSessionEnd: (rounds, _, __) {
          sessionCalls++;
          reportedRounds = rounds;
        },
      ),
    ));
    await tester.pump();

    for (var round = 0; round < PrismPathSession.totalRounds; round++) {
      final targets = expected.puzzle.mirrors
          .where((mirror) => !mirror.isDecoy)
          .map((mirror) => mirror.cell)
          .toList(growable: false);
      for (final cell in targets) {
        await tester.tap(find.byKey(ValueKey<String>(
          'prism-cell-${cell.row}-${cell.column}',
        )));
        await tester.pump();
        expected.rotate(cell.row, cell.column);
      }

      expect(find.text('Path restored!'), findsOneWidget);
      await tester.tap(find.text('NEXT PATH'));
      await tester.pump();
      expected.advance();
    }

    expect(find.text('Crystal charged!'), findsOneWidget);
    expect(completeCalls, 1);
    expect(sessionCalls, 1);
    expect(reportedRounds, PrismPathSession.totalRounds);
    expect(tester.takeException(), isNull);
  });
}
