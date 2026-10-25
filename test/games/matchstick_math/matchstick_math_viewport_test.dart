import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/matchstick_math/matchstick_math_engine.dart';
import 'package:flooria/games/matchstick_math/matchstick_math_page.dart';

void main() {
  for (final size in <Size>[
    const Size(360, 640),
    const Size(390, 844),
  ]) {
    testWidgets('Matchstick Math fits $size with all moves visible',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp(home: MatchstickMathPage(
        floor: 1,
        onComplete: () {},
        onSessionEnd: (_, __) {},
      )));
      expect(find.text('Matchstick Math'), findsOneWidget);
      expect(find.textContaining('Puzzle 1 of 5'), findsOneWidget);
      for (var index = 0; index < 3; index++) {
        final rect = tester.getRect(
          find.byKey(ValueKey('matchstick-move-$index')),
        );
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.top, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(size.width));
        expect(rect.bottom, lessThanOrEqualTo(size.height));
      }
      expect(tester.takeException(), isNull);

      final expected = MatchstickMathSession(seed: 104729);
      final answer = expected.current.choices.indexOf(expected.current.answer);
      await tester.tap(find.byKey(ValueKey('matchstick-move-$answer')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Puzzle 2 of 5'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('completion callback fires once after all equations are fixed',
      (tester) async {
    var completions = 0;
    var correct = 0;
    var mistakes = -1;
    final expected = MatchstickMathSession(seed: 104729);

    await tester.pumpWidget(MaterialApp(home: MatchstickMathPage(
      floor: 1,
      onComplete: () => completions++,
      onSessionEnd: (wins, slips) {
        correct = wins;
        mistakes = slips;
      },
    )));

    for (var round = 0; round < MatchstickMathSession.roundCount; round++) {
      final answer = expected.current.choices.indexOf(expected.current.answer);
      await tester.tap(find.byKey(ValueKey('matchstick-move-$answer')));
      await tester.pumpAndSettle();
      expected.choose(answer);
    }

    expect(find.text('Equation expert!'), findsOneWidget);
    expect(completions, 1);
    expect(correct, MatchstickMathSession.roundCount);
    expect(mistakes, 0);
    expect(tester.takeException(), isNull);
  });
}
