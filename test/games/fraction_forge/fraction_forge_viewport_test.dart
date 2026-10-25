import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/fraction_forge/fraction_forge_engine.dart';
import 'package:flooria/games/fraction_forge/fraction_forge_page.dart';

void main() {
  for (final size in <Size>[
    const Size(360, 640),
    const Size(390, 844),
  ]) {
    testWidgets('Fraction Forge fits $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp(home: FractionForgePage(
        floor: 1,
        onComplete: () {},
        onSessionEnd: (_, __) {},
      )));
      expect(find.text('Fraction Forge'), findsOneWidget);
      expect(find.textContaining('Question 1 of 8'), findsOneWidget);
      final challenge = FractionForgeSession(seed: 65537).current;
      for (var index = 0; index < challenge.options.length; index++) {
        final rect = tester.getRect(
          find.byKey(ValueKey('fraction-forge-option-$index')),
        );
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.top, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(size.width));
        expect(rect.bottom, lessThanOrEqualTo(size.height));
      }
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(ValueKey(
        'fraction-forge-option-${challenge.answerIndex}',
      )));
      await tester.pumpAndSettle();
      expect(find.textContaining('Question 2 of 8'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('completion callbacks run once', (tester) async {
    var completions = 0;
    var correct = 0;
    var mistakes = -1;
    final expected = FractionForgeSession(seed: 65537);
    await tester.pumpWidget(MaterialApp(home: FractionForgePage(
      floor: 1,
      onComplete: () => completions++,
      onSessionEnd: (wins, slips) {
        correct = wins;
        mistakes = slips;
      },
    )));

    for (var round = 0; round < FractionForgeSession.roundCount; round++) {
      final answer = expected.current.answerIndex;
      await tester.tap(find.byKey(
        ValueKey('fraction-forge-option-$answer'),
      ));
      await tester.pumpAndSettle();
      expected.choose(answer);
    }
    expect(find.text('Fractions mastered!'), findsOneWidget);
    expect(completions, 1);
    expect(correct, FractionForgeSession.roundCount);
    expect(mistakes, 0);
    expect(tester.takeException(), isNull);
  });
}
