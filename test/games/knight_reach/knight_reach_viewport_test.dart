import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/knight_reach/knight_reach_page.dart';

void main() {
  for (final size in <Size>[const Size(360, 640), const Size(390, 844)]) {
    testWidgets('Knight Reach fits compact $size without scrolling',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(home: KnightReachPage(
        floor: 10,
        onComplete: () {},
        onSessionEnd: (_, __, ___) {},
      )));
      await tester.pump();
      expect(find.byKey(const ValueKey('knight-cell-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('knight-cell-24')), findsOneWidget);
      expect(find.byKey(const ValueKey('knight-restart')), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('restart returns measured jumps to zero', (tester) async {
    await tester.pumpWidget(MaterialApp(home: KnightReachPage(
      floor: 5,
      onComplete: () {},
      onSessionEnd: (_, __, ___) {},
    )));
    await tester.tap(find.byKey(const ValueKey('knight-restart')));
    await tester.pump();
    expect(find.text('0 jumps'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
