import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/belief_detective/belief_detective_engine.dart';
import 'package:flooria/games/belief_detective/belief_detective_page.dart';

void main() {
  for (final size in <Size>[
    const Size(360, 640),
    const Size(390, 844),
  ]) {
    testWidgets('Belief Detective fits $size with all clues and choices',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp(
        home: BeliefDetectivePage(
          floor: 1,
          onComplete: () {},
          onSessionEnd: (_, __) {},
        ),
      ));

      expect(find.text('Belief Detective'), findsOneWidget);
      expect(find.text('Story 1 of 6'), findsOneWidget);
      expect(find.textContaining('saw it in the'), findsOneWidget);
      for (final place in BeliefPlace.values) {
        final rect = tester.getRect(
          find.byKey(ValueKey('belief-place-${place.index}')),
        );
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.top, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(size.width));
        expect(rect.bottom, lessThanOrEqualTo(size.height));
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('correct perspective answers report completion once',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var completions = 0;
    var correct = -1;
    var mistakes = -1;
    final expected = BeliefDetectiveSession(seed: 104729, level: 1);

    await tester.pumpWidget(MaterialApp(
      home: BeliefDetectivePage(
        floor: 1,
        onComplete: () => completions++,
        onSessionEnd: (wins, misses) {
          correct = wins;
          mistakes = misses;
        },
      ),
    ));

    for (var index = 0; index < BeliefDetectiveSession.roundCount; index++) {
      await tester.tap(find.byKey(
        ValueKey('belief-place-${expected.current.correctPlace.index}'),
      ));
      await tester.pumpAndSettle();
      expected.answer(expected.current.correctPlace);

      if (index < BeliefDetectiveSession.roundCount - 1) {
        await tester.tap(find.byKey(const ValueKey('belief-next')));
        await tester.pumpAndSettle();
      }
    }

    expect(find.text('Great perspective!'), findsOneWidget);
    expect(completions, 1);
    expect(correct, BeliefDetectiveSession.roundCount);
    expect(mistakes, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('low score records the session without awarding completion',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var completions = 0;
    var recordedMistakes = -1;
    final expected = BeliefDetectiveSession(seed: 104729, level: 1);

    await tester.pumpWidget(MaterialApp(
      home: BeliefDetectivePage(
        floor: 1,
        onComplete: () => completions++,
        onSessionEnd: (_, misses) => recordedMistakes = misses,
      ),
    ));

    for (var index = 0; index < BeliefDetectiveSession.roundCount; index++) {
      final wrong = BeliefPlace.values.firstWhere(
        (place) => place != expected.current.correctPlace,
      );
      await tester.tap(find.byKey(ValueKey('belief-place-${wrong.index}')));
      await tester.pumpAndSettle();
      expected.answer(wrong);

      if (index < BeliefDetectiveSession.roundCount - 1) {
        await tester.tap(find.byKey(const ValueKey('belief-next')));
        await tester.pumpAndSettle();
      }
    }

    expect(find.text('Try tracking the clues again'), findsOneWidget);
    expect(completions, 0);
    expect(recordedMistakes, BeliefDetectiveSession.roundCount);
    expect(tester.takeException(), isNull);
  });
}
