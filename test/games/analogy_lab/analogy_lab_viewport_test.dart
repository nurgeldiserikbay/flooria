import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/analogy_lab/analogy_lab_engine.dart';
import 'package:flooria/games/analogy_lab/analogy_lab_page.dart';

void main() {
  for (final size in <Size>[
    const Size(360, 640),
    const Size(390, 844),
  ]) {
    testWidgets('Analogy Lab fits $size with example and choices visible',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp(
        home: AnalogyLabPage(
          floor: 1,
          onComplete: () {},
          onSessionEnd: (_, __) {},
        ),
      ));

      expect(find.text('Analogy Lab'), findsOneWidget);
      expect(find.text('Analogy 1 of 8'), findsOneWidget);
      expect(find.text('EXAMPLE'), findsOneWidget);
      expect(find.text('NOW'), findsOneWidget);

      for (var index = 0; index < 4; index++) {
        final rect = tester.getRect(
          find.byKey(ValueKey('analogy-option-$index')),
        );
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.top, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(size.width));
        expect(rect.bottom, lessThanOrEqualTo(size.height));
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('correct analogies report earned completion once',
      (tester) async {
    var completions = 0;
    var correct = -1;
    var mistakes = -1;
    final expected = AnalogyLabSession(seed: 104729, level: 1);

    await tester.pumpWidget(MaterialApp(
      home: AnalogyLabPage(
        floor: 1,
        onComplete: () => completions++,
        onSessionEnd: (wins, misses) {
          correct = wins;
          mistakes = misses;
        },
      ),
    ));

    for (var index = 0; index < AnalogyLabSession.roundCount; index++) {
      await tester.tap(find.byKey(
        ValueKey('analogy-option-${expected.current.correctIndex}'),
      ));
      await tester.pumpAndSettle();
      expected.submit(expected.current.correctIndex);

      if (index < AnalogyLabSession.roundCount - 1) {
        expect(find.text('Correct — you found the rule.'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('analogy-next')));
        await tester.pumpAndSettle();
      }
    }

    expect(find.text('Rule spotted!'), findsOneWidget);
    expect(completions, 1);
    expect(correct, AnalogyLabSession.roundCount);
    expect(mistakes, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('low score records misses without earning completion',
      (tester) async {
    var completions = 0;
    var recordedMistakes = -1;
    final expected = AnalogyLabSession(seed: 104729, level: 1);

    await tester.pumpWidget(MaterialApp(
      home: AnalogyLabPage(
        floor: 1,
        onComplete: () => completions++,
        onSessionEnd: (_, misses) => recordedMistakes = misses,
      ),
    ));

    for (var index = 0; index < AnalogyLabSession.roundCount; index++) {
      final wrongIndex = (expected.current.correctIndex + 1) % 4;
      await tester.tap(
        find.byKey(ValueKey('analogy-option-$wrongIndex')),
      );
      await tester.pumpAndSettle();
      expected.submit(wrongIndex);

      if (index < AnalogyLabSession.roundCount - 1) {
        await tester.tap(find.byKey(const ValueKey('analogy-next')));
        await tester.pumpAndSettle();
      }
    }

    expect(find.text('Keep looking for the pattern'), findsOneWidget);
    expect(completions, 0);
    expect(recordedMistakes, AnalogyLabSession.roundCount);
    expect(tester.takeException(), isNull);
  });
}
