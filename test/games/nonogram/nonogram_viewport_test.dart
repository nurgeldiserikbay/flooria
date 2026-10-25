import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/nonogram/nonogram_page.dart';

void main() {
  for (final size in <Size>[
    const Size(360, 640),
    const Size(390, 844),
  ]) {
    testWidgets('Pixel Clues has a scroll-free board at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(home: NonogramPage(
        floor: 10,
        onComplete: () {},
        onSessionEnd: (_, __, ___) {},
      )));
      await tester.pump();
      expect(find.byType(GridView), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
      expect(find.byKey(const ValueKey('nonogram-cell-0')), findsOneWidget);
      expect(find.text('CHECK'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('cell state cycles and restart clears inputs', (tester) async {
    await tester.pumpWidget(MaterialApp(home: NonogramPage(
      floor: 6,
      onComplete: () {},
      onSessionEnd: (_, __, ___) {},
    )));
    await tester.tap(find.byKey(const ValueKey('nonogram-cell-0')));
    await tester.pump();
    expect(find.byIcon(Icons.check_rounded), findsWidgets);
    await tester.tap(find.byTooltip('Restart puzzle'));
    await tester.pump();
    expect(find.text('0 checks'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
