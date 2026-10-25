import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/paper_fold/paper_fold_page.dart';

void main() {
  for (final size in <Size>[
    const Size(360, 640),
    const Size(390, 844),
  ]) {
    testWidgets('folded preview and answer board fit $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(home: PaperFoldPage(
        floor: 10,
        onComplete: () {},
        onSessionEnd: (_, __, ___) {},
      )));
      await tester.pump();
      expect(find.byKey(const ValueKey('paper-fold-cell-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('paper-fold-punch-0')), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
      expect(find.text('CHECK'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('answer marking can be reset', (tester) async {
    await tester.pumpWidget(MaterialApp(home: PaperFoldPage(
      floor: 5,
      onComplete: () {},
      onSessionEnd: (_, __, ___) {},
    )));
    await tester.tap(find.byKey(const ValueKey('paper-fold-cell-0')));
    await tester.pump();
    final check = tester.widget<FilledButton>(
        find.byKey(const ValueKey('paper-fold-check')));
    expect(check.onPressed, isNotNull);
    await tester.tap(find.byTooltip('Restart'));
    await tester.pump();
    expect(find.text('0 checks'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
