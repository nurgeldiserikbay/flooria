import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/cube_vista/cube_vista_engine.dart';
import 'package:flooria/games/cube_vista/cube_vista_page.dart';

void main() {
  for (final size in <Size>[
    const Size(360, 640),
    const Size(390, 844),
  ]) {
    testWidgets('Cube Vista fits $size with every option visible',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp(home: CubeVistaPage(
        floor: 1,
        onComplete: () {},
        onSessionEnd: (_, __) {},
      )));
      expect(find.text('Cube Vista'), findsOneWidget);
      expect(find.textContaining('Structure 1 of 6'), findsOneWidget);
      for (var index = 0; index < 3; index++) {
        final rect = tester.getRect(
          find.byKey(ValueKey('cube-vista-option-$index')),
        );
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.top, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(size.width));
        expect(rect.bottom, lessThanOrEqualTo(size.height));
      }
      expect(tester.takeException(), isNull);

      final expected = CubeVistaSession(seed: 91337);
      await tester.tap(find.byKey(ValueKey(
        'cube-vista-option-${expected.current.answerIndex}',
      )));
      await tester.pumpAndSettle();
      expect(find.textContaining('Structure 2 of 6'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('finishing the session reports results once', (tester) async {
    var completions = 0;
    var correct = 0;
    var mistakes = -1;
    final expected = CubeVistaSession(seed: 91337);

    await tester.pumpWidget(MaterialApp(home: CubeVistaPage(
      floor: 1,
      onComplete: () => completions++,
      onSessionEnd: (wins, slips) {
        correct = wins;
        mistakes = slips;
      },
    )));

    for (var round = 0; round < CubeVistaSession.roundCount; round++) {
      final answer = expected.current.answerIndex;
      await tester.tap(find.byKey(ValueKey('cube-vista-option-$answer')));
      await tester.pumpAndSettle();
      expected.choose(answer);
    }
    expect(find.text('Great spatial thinking!'), findsOneWidget);
    expect(completions, 1);
    expect(correct, CubeVistaSession.roundCount);
    expect(mistakes, 0);
    expect(tester.takeException(), isNull);
  });
}
