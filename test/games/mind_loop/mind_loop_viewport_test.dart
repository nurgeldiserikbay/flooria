import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/games/mind_loop/mind_loop_engine.dart';
import 'package:flooria/games/mind_loop/mind_loop_page.dart';

void main() {
  for (final size in <Size>[
    const Size(360, 640),
    const Size(390, 844),
  ]) {
    testWidgets('Mind Loop fits $size with both answers visible',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp(
        home: MindLoopPage(
          floor: 1,
          onComplete: () {},
          onSessionEnd: (_, __) {},
        ),
      ));

      expect(find.text('Mind Loop'), findsOneWidget);
      expect(find.text('Trial 1 of 12'), findsOneWidget);
      for (final key in const ['mind-answer-match', 'mind-answer-new']) {
        final rect = tester.getRect(find.byKey(ValueKey(key)));
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.top, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(size.width));
        expect(rect.bottom, lessThanOrEqualTo(size.height));
      }
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const ValueKey('mind-answer-new')));
      await tester.pumpAndSettle();
      expect(find.text('Trial 2 of 12'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('pass completion callback fires once after correct answers',
      (tester) async {
    var completions = 0;
    var correct = 0;
    var mistakes = -1;
    final expected = MindLoopSession(seed: 104729, level: 1);

    await tester.pumpWidget(MaterialApp(
      home: MindLoopPage(
        floor: 1,
        onComplete: () => completions++,
        onSessionEnd: (wins, misses) {
          correct = wins;
          mistakes = misses;
        },
      ),
    ));

    for (var index = 0; index < MindLoopSession.roundCount; index++) {
      final key = expected.currentIsMatch
          ? const ValueKey('mind-answer-match')
          : const ValueKey('mind-answer-new');
      await tester.tap(find.byKey(key));
      await tester.pumpAndSettle();
      expected.respond(expected.currentIsMatch);
    }

    expect(find.text('Loop mastered!'), findsOneWidget);
    expect(completions, 1);
    expect(correct, MindLoopSession.roundCount);
    expect(mistakes, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('finishing below pass score records results without completion',
      (tester) async {
    var completions = 0;
    var recordedMistakes = 0;
    final expected = MindLoopSession(seed: 104729, level: 1);

    await tester.pumpWidget(MaterialApp(
      home: MindLoopPage(
        floor: 1,
        onComplete: () => completions++,
        onSessionEnd: (_, misses) => recordedMistakes = misses,
      ),
    ));

    for (var index = 0; index < MindLoopSession.roundCount; index++) {
      final key = expected.currentIsMatch
          ? const ValueKey('mind-answer-new')
          : const ValueKey('mind-answer-match');
      await tester.tap(find.byKey(key));
      await tester.pumpAndSettle();
      expected.respond(!expected.currentIsMatch);
    }

    expect(find.text('Try the sequence again'), findsOneWidget);
    expect(completions, 0);
    expect(recordedMistakes, MindLoopSession.roundCount);
    expect(tester.takeException(), isNull);
  });
}
