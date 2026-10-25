import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/pixel_garden/pixel_garden_engine.dart';
import 'package:flooria/games/pixel_garden/pixel_garden_page.dart';

void main() {
  for (final size in <Size>[
    const Size(360, 640),
    const Size(390, 844),
  ]) {
    testWidgets('Pixel Garden fits without scrolling at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp(
        home: PixelGardenPage(onComplete: () {}, onSessionEnd: (_, __) {}),
      ));

      expect(find.text('Pixel Garden'), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('pixel-cell-0')), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('reports campaign completion exactly once after three pictures',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const floor = 7;
    final expected = PixelGardenSession(seed: floor * 1877);
    var completeCalls = 0;
    var endCalls = 0;
    await tester.pumpWidget(MaterialApp(
      home: PixelGardenPage(
        floor: floor,
        onComplete: () => completeCalls++,
        onSessionEnd: (_, __) => endCalls++,
      ),
    ));

    for (var round = 0; round < PixelGardenSession.totalRounds; round++) {
      for (final cell in expected.puzzle.targetCells) {
        await tester.tap(
          find.byKey(ValueKey<String>('pixel-cell-$cell')),
        );
        await tester.pump();
        expected.toggle(cell);
      }
      expect(find.text('Picture complete!'), findsOneWidget);
      await tester.tap(find.text('NEXT PICTURE'));
      await tester.pump();
      expected.advance();
    }

    expect(find.text('Your garden is in bloom!'), findsOneWidget);
    expect(completeCalls, 1);
    expect(endCalls, 1);
    expect(tester.takeException(), isNull);
  });
}
