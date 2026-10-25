import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/mirror_mosaic/mirror_mosaic_engine.dart';
import 'package:flooria/games/mirror_mosaic/mirror_mosaic_page.dart';

void main() {
  for (final size in <Size>[const Size(360, 640), const Size(390, 844)]) {
    testWidgets('Mirror Mosaic fits $size with all tiles visible', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp(
        home: MirrorMosaicPage(
          floor: 1,
          onComplete: () {},
          onSessionEnd: (_, __) {},
        ),
      ));

      expect(find.text('Mirror Mosaic'), findsOneWidget);
      expect(find.text('Copy the pattern across the axis.'), findsOneWidget);
      expect(find.textContaining('MATCH'), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
      for (var index = 0; index < 25; index++) {
        final rect = tester.getRect(
          find.byKey(ValueKey('mirror-mosaic-cell-$index')),
        );
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.top, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(size.width));
        expect(rect.bottom, lessThanOrEqualTo(size.height));
      }
      expect(tester.takeException(), isNull);

      final generated = MirrorMosaicSession(seed: 32452843);
      final target = generated.current.targetCells.first;
      await tester.tap(
        find.byKey(ValueKey('mirror-mosaic-cell-$target')),
      );
      await tester.pumpAndSettle();
      expect(find.text('1 picked'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('finishing the session reports completion once', (tester) async {
    var completions = 0;
    var reportedBoards = 0;
    var reportedMistakes = -1;
    const floor = 1;
    final generated = MirrorMosaicSession(seed: floor * 32452843);

    await tester.pumpWidget(MaterialApp(
      home: MirrorMosaicPage(
        floor: floor,
        onComplete: () => completions++,
        onSessionEnd: (boards, mistakes) {
          reportedBoards = boards;
          reportedMistakes = mistakes;
        },
      ),
    ));

    for (var round = 0; round < MirrorMosaicSession.boardCount; round++) {
      final targets = generated.current.targetCells.toList();
      for (final target in targets) {
        await tester.tap(find.byKey(ValueKey('mirror-mosaic-cell-$target')));
        await tester.pumpAndSettle();
        generated.toggle(target);
      }
    }

    expect(find.text('Perfectly balanced!'), findsOneWidget);
    expect(completions, 1);
    expect(reportedBoards, MirrorMosaicSession.boardCount);
    expect(reportedMistakes, 0);
    expect(tester.takeException(), isNull);
  });
}
